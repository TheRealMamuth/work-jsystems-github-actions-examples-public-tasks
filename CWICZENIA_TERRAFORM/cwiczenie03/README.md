# Ćwiczenie 03 — Terraform uruchamia aplikację Docker za Nginxem

Teraz utwórz kompletną konfigurację, w której Terraform tworzy VM
DigitalOcean, instaluje Docker i Nginx oraz uruchamia gotową aplikację
pogodową. GitHub Actions uruchamia Terraform, a osobny job sprawdza SSH,
WWW i prawdziwe API. Kod aplikacji i budowanie obrazu nie są częścią zadania.

Wszystkie pliki do utworzenia mają **pełną treść w końcowej części tego README**
pod nagłówkami `Plik:`. Nie potrzebujesz źródeł z wcześniejszych ćwiczeń ani
katalogu rozwiązania prowadzącego. Kroki 1–15 wyjaśniają kolejność pracy,
konfigurację GitHuba, uruchomienie i sprawdzenie rezultatu.

Docelowa droga żądania:

```text
Użytkownik → http://PUBLICZNY_IP:80 → Nginx na VM
             → 127.0.0.1:18080 na VM → kontener:8080
```

## 1. Przygotuj runner i oddzielne zasoby ćwiczenia

Teraz przygotuj jeden własny host Linux z trwałym dyskiem. W repozytorium
wejdź w **Settings → Actions → Runners → New self-hosted runner**, wybierz
Linux i wykonaj na tym hoście polecenia rejestracji pokazane przez GitHub.
Jeżeli masz już zarejestrowany własny runner, wykorzystaj go ponownie.
Uruchom go jako usługę zgodnie z instrukcją GitHuba i potwierdź status **Idle**.
Nie zapisuj tokenu rejestracyjnego w repozytorium.

Zachowaj etykiety `self-hosted` i `linux` oraz wersję agenta co najmniej
`2.327.1`, wymaganą przez używane akcje Node.js 24. W tym ćwiczeniu pozostaw
**jednego aktywnego runnera pasującego do obu etykiet**. Oba joby oraz kolejne
uruchomienia muszą trafiać na ten sam fizyczny host i konto usługi, ponieważ
state i klucz SSH pozostają na jego dysku.

Teraz potwierdź obecność Bash, klienta OpenSSH, narzędzi `iproute2` i GNU
coreutils oraz Pythona 3 i `curl`. Workflow instaluje Terraform `1.17.2`
przez `hashicorp/setup-terraform@v4`. Do lokalnej walidacji plików z kroku 10
przygotuj także Terraform w wersji co najmniej `1.10`, zgodnej z `versions.tf`.
Na hoście agenta sprawdź:

```bash
bash --version
ssh -V
ip -V
realpath --version
stat --version
python3 --version
curl --version
```

Teraz uzgodnij wolną prywatną sieć `/24`, np. `10.33.36.0/24`.
Nie używaj zakresu zajętego przez CW01, CW02 lub innego uczestnika.
Losowy sufiks odróżnia nazwy, ale nie rozwiązuje kolizji adresacji VPC.

Na hoście agenta odczytaj publiczny IPv4 interfejsu `eth0`:

```bash
ip a
ip -4 addr show dev eth0
```

Weź sam adres z `inet`, usuń maskę interfejsu i dopisz `/32`.
`SSH_ALLOWED_CIDR` ma wskazywać ten host, nie laptop uczestnika.
Przykład `203.0.113.20/32` jest dokumentacyjny; użyj rzeczywistego adresu.

## 2. Ustaw zmienne repozytorium

Teraz w **Settings → Secrets and variables → Actions → Variables** ustaw:

| Variable | Wartość |
| --- | --- |
| `VM_NAME` | Własna podstawa nazwy, np. `jan-kowalski-cw03-vm` |
| `VPC_NAME` | Np. `jan-kowalski-cw03-vpc` |
| `FIREWALL_NAME` | Np. `jan-kowalski-cw03-firewall` |
| `VPC_CIDR` | Uzgodniony wolny zakres, np. `10.33.36.0/24` |
| `SSH_ALLOWED_CIDR` | Publiczny IPv4 z `eth0` agenta, z maską `/32` |

Opcjonalne ustawienia:

| Variable | Wartość domyślna lub przeznaczenie |
| --- | --- |
| `DO_REGION` | `fra1` |
| `DO_VM_IMAGE` | `ubuntu-24-04-x64` |
| `DO_VM_SIZE` | `s-1vcpu-1gb` |
| `TF_STATE_ROOT` | Katalog `terraform-state` w katalogu domowym konta agenta |
| `DOCKER_IMAGE_REFERENCE` | Pełna referencja obrazu z digestem podana w kroku 4 |
| `CONTAINER_NAME` | `cw03-pogoda`; zachowaj stałą nazwę przy ponawianiu wdrożeń |
| `DEPLOYMENT_REVISION` | `1`; zmień przy ponownym wdrażaniu po rotacji sekretu |
| `WEATHER_CITY` | `Warsaw`, miasto rzeczywistego testu API |
| `DOCKERHUB_USERNAME` | Opcjonalny login do pobierania obrazu z rejestru |

Pozostaw `TF_STATE_ROOT` bez zmian pomiędzy uruchomieniami. Gdy go ustawiasz,
podaj bezwzględną ścieżkę poza checkoutem i katalogiem tymczasowym.

## 3. Ustaw sekrety

Teraz w zakładce **Secrets** dodaj:

| Secret | Wymaganie |
| --- | --- |
| `DIGITALOCEAN_TOKEN` | Token zarządzający VM, VPC, firewallem i kluczami SSH; potrzebny do apply i destroy |
| `OPENWEATHER_API_KEY` | Prawdziwy aktywny klucz OpenWeatherMap; potrzebny do apply, aby aplikacja mogła pobierać pogodę |
| `DOCKERHUB_TOKEN` | Opcjonalny token pobierania obrazu; użyj razem z `DOCKERHUB_USERNAME`, jeśli potrzebujesz uwierzytelnienia |

Bez danych Docker Hub konfiguracja próbuje pobrać obraz anonimowo.
Sprawdź dostępność podanego obrazu. Jeśli wymaga logowania albo napotkasz
limit pobierania, ustaw parę `DOCKERHUB_USERNAME` i `DOCKERHUB_TOKEN`.
Nie dodawaj ręcznie klucza SSH do Secrets — nadal generuje go Terraform.

Nie zapisuj wartości sekretów w plikach `.tf`, `.tfvars`, template'ach,
outputs ani artefaktach. Klucz pogodowy ma trafić tylko do działającego
kontenera, nie do obrazu ani cloud-init.

## 4. Użyj dokładnie wskazanego obrazu

Teraz przygotuj domyślną referencję:

```text
piotrskoska/python_pogoda@sha256:ac30d995f5ca10e4c5db5c44d526398c435270ba1194c5987642f7179a224638
```

Odpowiada jej wskazany tag:

```text
piotrskoska/python_pogoda:piotr-koskareczny-9ecd809585dd33f76cc3f11e5c8204298765228c
```

W deployu korzystaj z referencji `@sha256:...`, aby wdrożyć dokładnie
określoną zawartość obrazu. Nie zastępuj jej tagiem `latest`.
Obraz już istnieje — pipeline tego ćwiczenia go nie buduje ani nie publikuje.

## 5. Utwórz katalogi i podstawowe pliki Terraform

Teraz otwórz terminal w katalogu głównym własnego repozytorium i utwórz
katalogi:

```bash
mkdir -p CWICZENIA_TERRAFORM/cwiczenie03/terraform/files
mkdir -p CWICZENIA_TERRAFORM/cwiczenie03/tests
mkdir -p .github/workflows
```

Teraz utwórz `versions.tf`, `main.tf`, `outputs.tf` oraz
`terraform.tfvars.example` w katalogu `CWICZENIA_TERRAFORM/cwiczenie03/terraform`.
Wklej do każdego pliku pełną treść z odpowiadającego mu nagłówka `Plik:`
w końcowej części instrukcji. W następnych krokach utworzysz `variables.tf`,
`application.tf` oraz oba skrypty.

| Plik | Co ma zawierać |
| --- | --- |
| `versions.tf` | Terraform co najmniej `1.10`, lokalny backend i wersje czterech providerów |
| `main.tf` | Stały losowy sufiks, klucz SSH ED25519, zapis klucza, rejestrację klucza w DigitalOcean, VPC, VM i firewall |
| `outputs.tf` | Jawne metadane infrastruktury i URL aplikacji; prywatny output klucza oznaczony `sensitive` |
| `terraform.tfvars.example` | Niesekretny przykład nazw, zakresów i konfiguracji aplikacji |

W `main.tf` nazwy VM, VPC, firewalla i zarejestrowanego klucza zawierają
wspólny sześcioznakowy losowy sufiks. Pozostaje on w state i nie zmienia się
przy każdym plan/apply. VM korzysta z utworzonej VPC, a firewall jest
przypisany do jej identyfikatora.

Zachowaj pusty blok `backend "local" {}`. Workflow poda bezwzględną ścieżkę
przy `terraform init`. State tego ćwiczenia ma osobną lokalizację:

```text
<HOME_konta_agenta>/terraform-state/cwiczenie03/<GITHUB_REPOSITORY_ID>/terraform.tfstate
```

Pipeline dołącza `cwiczenie03/<GITHUB_REPOSITORY_ID>` do `TF_STATE_ROOT`.
Klucz zapisuje w `keys/id_ed25519` obok tego state, z prawami `0600`.
Nie wskazuj workflow na state innego ćwiczenia. Plik
`terraform.tfvars.example` pozostaw wzorcem: w pipeline wartości pochodzą
z Repository variables i Secrets, więc nie twórz obok rzeczywistego
`terraform.tfvars`, który nadpisywałby wartości `TF_VAR_*`.

## 6. Dodaj zmienne aplikacji i sekret ephemeral

Teraz utwórz `CWICZENIA_TERRAFORM/cwiczenie03/terraform/variables.tf`
i wklej jego pełną treść z części `Plik:`. Zawiera walidację nazw, VPC `/24`,
adresu SSH `/32` i ścieżki klucza, a także poniższe zmienne aplikacji:

| Zmienna Terraform | Przeznaczenie |
| --- | --- |
| `image_reference` | Domyślnie pełny obraz przypięty digestem z kroku 4 |
| `container_name` | Nazwa kontenera, domyślnie `cw03-pogoda` |
| `deployment_revision` | Numer rewizji jako tekst, domyślnie `1` |
| `openweather_api_key` | Klucz tylko na czas wykonania provisionera |
| `dockerhub_username` | Opcjonalny login rejestru |
| `dockerhub_token` | Opcjonalny token tylko na czas wykonania provisionera |

Dla klucza API i tokenu rejestru ustaw `sensitive = true` oraz
`ephemeral = true`. Pozostaw możliwość ich pominięcia podczas destroy.
Ephemeral sekretu używaj wyłącznie w kontekście provisionera, który wykonuje
deploy; nie umieszczaj go w `terraform_data.input`, `triggers_replace`,
`user_data` ani outputach zapisywanych w state.

Zachowaj wymagane wartości sekretów w środowisku **zarówno plan, jak i apply**.
Zapisany plan nie przechowuje wartości ephemeral potrzebnej później
provisionerowi. Samo `sensitive` maskuje zwykłe wyjście, ale nie zastępuje
`ephemeral`.

Klucz SSH nadal znajduje się w state — mechanizm ephemeral dotyczy tutaj
klucza aplikacji i tokenu rejestru, nie usuwa klucza SSH wygenerowanego przez TLS.

## 7. Dodaj application.tf i skrypty wykonywane przez Terraform

Teraz utwórz w katalogu `CWICZENIA_TERRAFORM/cwiczenie03/terraform`
poniższe trzy pliki i wklej ich pełną treść z końcowej części README:

| Plik | Zadanie |
| --- | --- |
| `application.tf` | Zasób `terraform_data.application`, połączenie SSH i dwa provisionery |
| `files/bootstrap.sh` | Instalacja i uruchomienie usług na VM, bez sekretów aplikacji |
| `files/deploy.sh.tftpl` | Pobranie obrazu, uruchomienie kontenera i konfiguracja proxy |

Użyj provisionerów `remote-exec`.
Połączenie ma wskazywać publiczny IP Dropleta, użytkownika `root` i klucz
`tls_private_key.ssh.private_key_openssh`.

Uzależnij wykonanie od utworzenia firewalla. W `triggers_replace` uwzględnij
VM, referencję obrazu, nazwę kontenera, rewizję wdrożenia i hashe obu skryptów.
Nie wpisuj tam wartości sekretów. Pierwszy provisioner uruchamia
`files/bootstrap.sh` przez `script`, a drugi korzysta z
`templatefile` dla `files/deploy.sh.tftpl` w dozwolonym kontekście provisionera.

Teraz przygotuj dwa etapy wykonywane na VM:

1. Poczekaj na zakończenie inicjalizacji systemu. Zainstaluj Docker, Nginx,
   `curl` i certyfikaty CA; uruchom wymagane usługi. Błąd pakietów lub Dockera
   ma zakończyć apply błędem.
2. Pobierz obraz i uruchom aplikację, a następnie skonfiguruj proxy.

Skrypt zawierający wartości runtime umieść w prywatnym katalogu `/root`.
Usuń go po wykonaniu także przy błędzie. Nie zapisuj sekretu w publicznym
katalogu ani w trwałym pliku konfiguracji Nginxa.
Do template'u możesz przekazać sekrety zakodowane base64 i odtworzyć je
w skrypcie, aby poprawnie obsłużyć znaki powłoki. Base64 nie szyfruje danych;
zachowaj prywatną lokalizację skryptu i sprzątanie.

W tym laboratorium natywne połączenie SSH provisionera nie przypina klucza
hosta. Późniejszy test `accept-new` nie jest niezależnym uwierzytelnieniem
pierwszego połączenia wykonywanego przez Terraform.

## 8. Uruchom kontener z kluczem wyłącznie runtime

Teraz w skrypcie deploya:

1. Opcjonalnie zaloguj się do Docker Hub w prywatnym tymczasowym
   `DOCKER_CONFIG`, jeśli przekazano dane uwierzytelniające.
2. Pobierz obraz przez `docker pull` **przed usuwaniem starego kontenera**.
3. Znajdź dokładną nazwę swojego kontenera, także wśród zatrzymanych,
   i usuń tylko jego poprzednią instancję.
4. Uruchom kontener z `--restart unless-stopped` i mapowaniem
   `127.0.0.1:18080:8080`.
5. Przekaż klucz przez środowisko skryptu i `-e OPENWEATHER_API_KEY`;
   nie wpisuj jego wartości w argumentach polecenia.
6. Sprawdź stan kontenera i odpowiedź jego `/healthz`.
7. Zawsze wyloguj Docker Hub, usuń tymczasową konfigurację logowania
   i skrypt zawierający sekret.

Główne polecenie uruchomienia ma używać zmiennej środowiskowej, np.:

```bash
export OPENWEATHER_API_KEY
docker run -d --name "$CONTAINER_NAME" --restart unless-stopped \
  -p 127.0.0.1:18080:8080 -e OPENWEATHER_API_KEY "$IMAGE_REFERENCE"
```

Zmienną sekretu wykorzystuje aplikacja wewnątrz kontenera. Użytkownik WWW
lub API podaje wyłącznie miasto.

## 9. Skonfiguruj Nginx na hoście VM

Teraz przygotuj konfigurację Nginxa nasłuchującego na porcie `80`.
W lokalizacji `/` użyj:

```nginx
proxy_pass http://127.0.0.1:18080;
```

Przekazuj nagłówki hosta i adresu klienta. Sprawdź konfigurację przez
`nginx -t`, a dopiero potem przeładuj lub uruchom usługę.
WWW, zasoby statyczne i API mają korzystać z tego samego publicznego adresu.

W `main.tf` zachowaj SSH `22` wyłącznie z `/32` agenta oraz publiczne TCP
`80`, `443` i `18000-18999`. Kontener mimo otwartej reguły zakresu
jest przypisany tylko do `127.0.0.1:18080`, więc użytkownik wchodzi przez
Nginxa pod `http://PUBLICZNY_IP/`, a nie bezpośrednio pod port `18080`.

Teraz dodaj output `app_url` z adresem `http://<publiczny_IP_VM>`.
Możesz także wystawić jawny output `image_reference`. Nie potrzebujesz
domeny, aby otworzyć adres aplikacji.

## 10. Utwórz test, przygotuj Git i wygeneruj lockfile

Teraz utwórz `CWICZENIA_TERRAFORM/cwiczenie03/tests/smoke_test.py`
z pełnego bloku `Plik:`. To gotowy test WWW i prawdziwej pogody — wklej go
w całości; nie musisz samodzielnie pisać Pythona.

Teraz sprawdź główny `.gitignore`. Jego pełną treść dla tego repozytorium
podano niżej. Jeżeli plik już zawiera Twoje inne reguły, **dopisz tylko
brakujące reguły z podanego bloku, zachowując istniejące wpisy**.
Ignorowane mają być state, plany, rzeczywiste `.tfvars`, `.terraform/`
i katalogi kluczy `.keys/`. Wersjonowane pozostają `.tf`, skrypty, test,
`terraform.tfvars.example` oraz `.terraform.lock.hcl`.

Teraz na maszynie z Terraform wykonaj lokalne przygotowanie providerów
i walidację. Te polecenia nie tworzą zasobów w DigitalOcean:

```bash
terraform -chdir=CWICZENIA_TERRAFORM/cwiczenie03/terraform fmt
terraform -chdir=CWICZENIA_TERRAFORM/cwiczenie03/terraform init -backend=false
terraform -chdir=CWICZENIA_TERRAFORM/cwiczenie03/terraform validate
```

`init` wygeneruje `.terraform.lock.hcl`. Nie twórz go ręcznie i nie przepisuj
hashy providerów z dokumentacji. Późniejszy `init -reconfigure` w workflow
wskaże właściwy lokalny backend na hoście agenta.

Teraz przejdź do utworzenia workflow w kolejnym kroku. Komplet plików
sprawdzisz i zapiszesz w Gicie w kroku 13, po przygotowaniu całego pipeline.

## 11. Przygotuj workflow provision i check-app

Teraz utwórz plik `.github/workflows/terraform-cwiczenie03.yaml` w głównym
katalogu repozytorium i wklej **cały YAML** z jego bloku `Plik:` poniżej.
Jeżeli plik już istnieje, porównaj go z pełną treścią w instrukcji.
Zachowaj ręczny input `operation: apply|destroy`, jedno wspólne `concurrency`
repozytorium z `cancel-in-progress: false` i runner `[self-hosted, linux]`
dla obu jobów.

[Pełny workflow jako osobny plik](../../.github/workflows/terraform-cwiczenie03.yaml)
ma identyczną treść jak blok w tym README.

Job `provision` ma sprawdzić obecność źródeł ucznia, wyliczyć katalog state
CW03, przygotować Terraform `1.17.2` przez `hashicorp/setup-terraform@v4`
z `terraform_wrapper: false`, a następnie wykonać `fmt`, `init`, `validate`,
zapisany `plan` oraz `apply` planu.
Dla destroy użyj planu `-destroy`, tego samego katalogu state i tego samego
pliku prywatnego klucza. Zachowaj kontrolę utraconego state: gdy istnieje
marker `.initialized`, ale brakuje wcześniej używanego state, workflow ma
przerwać pracę, zamiast tworzyć drugi zestaw zasobów.

Teraz przekaż zmienne aplikacji przez środowisko:

| Zmienna procesu | Źródło |
| --- | --- |
| `TF_VAR_image_reference` | `vars.DOCKER_IMAGE_REFERENCE` lub domyślny digest |
| `TF_VAR_container_name` | `vars.CONTAINER_NAME` lub `cw03-pogoda` |
| `TF_VAR_deployment_revision` | `vars.DEPLOYMENT_REVISION` lub `1` |
| `TF_VAR_openweather_api_key` | `secrets.OPENWEATHER_API_KEY` |
| `TF_VAR_dockerhub_username` | Opcjonalne `vars.DOCKERHUB_USERNAME` |
| `TF_VAR_dockerhub_token` | Opcjonalne `secrets.DOCKERHUB_TOKEN` |

Wartości `VM_NAME`, `VPC_NAME`, `FIREWALL_NAME`, `VPC_CIDR`
i `SSH_ALLOWED_CIDR` przekaż przez odpowiadające im zmienne procesu
`TF_VAR_vm_name`, `TF_VAR_vpc_name`, `TF_VAR_firewall_name`, `TF_VAR_vpc_cidr`
i `TF_VAR_ssh_allowed_cidr`. Ustaw także region, obraz systemu i rozmiar VM
z opcjonalnych Variables. Pełny YAML zawiera te powiązania.
Ścieżkę `TF_VAR_ssh_private_key_path` workflow wylicza w trwałym katalogu
state i przekazuje między krokami przez `GITHUB_ENV`.
Sekrety podaj do plan oraz apply, bez flag zawierających ich wartości
w linii poleceń.
Sam deploy wykonuje Terraform; nie dodawaj obok niezależnego kroku GHA
z `docker run` przez SSH.

Odczytaj tylko `public_ip`, `private_key_path` i `app_url` jako metadane dla
kolejnego joba. Przekaż także wyliczone `state_directory` i `runner_name`.
Nie wypisuj wszystkich outputów przez `terraform output -json`.
Plan danego przebiegu usuń na końcu, ale zachowaj state i klucz.

## 12. Sprawdź SSH, WWW i prawdziwą pogodę w drugim jobie

Teraz przygotuj job `check-app` z `needs: provision`, uruchamiany tylko dla
`apply`. Porównaj nazwę runnera z outputem pierwszego joba i potwierdź,
że trwały plik klucza należy do konta agenta, nie jest symlinkiem i ma prawa
`0600`. Dodaj checkout, aby runner otrzymał test Pythona. Klucz pozostaje
poza checkoutem. Zaloguj się nim do VM z ponowieniami oraz trwałym `known_hosts`.

Po zalogowaniu potwierdź użytkownika `root`, działanie Nginxa i kontenera.
Następnie z hosta agenta uruchom dostarczony `tests/smoke_test.py`, kierując
go pod publiczny `app_url` i podając miasto z `WEATHER_CITY`.
Test ma sprawdzić `/healthz`, formularz WWW, zasoby, schemat API i odpowiedź
OpenWeatherMap — sam kod HTTP `200` ze strony powitalnej Nginxa nie wystarcza.

Nie przekazuj klucza pogodowego jako argumentu testu lub w URL.
Test używa API aplikacji, która posiada klucz wyłącznie w swoim runtime.
Brak działającego API ma dać błąd joba, zamiast przykładowej pogody.

## 13. Uruchom apply i sprawdź adres aplikacji

Teraz dodaj jawnie komplet przygotowanych źródeł do Gita:

```bash
git add .gitignore .github/workflows/terraform-cwiczenie03.yaml
git add CWICZENIA_TERRAFORM/cwiczenie03/terraform/versions.tf
git add CWICZENIA_TERRAFORM/cwiczenie03/terraform/variables.tf
git add CWICZENIA_TERRAFORM/cwiczenie03/terraform/main.tf
git add CWICZENIA_TERRAFORM/cwiczenie03/terraform/application.tf
git add CWICZENIA_TERRAFORM/cwiczenie03/terraform/outputs.tf
git add CWICZENIA_TERRAFORM/cwiczenie03/terraform/terraform.tfvars.example
git add CWICZENIA_TERRAFORM/cwiczenie03/terraform/.terraform.lock.hcl
git add CWICZENIA_TERRAFORM/cwiczenie03/terraform/files/bootstrap.sh
git add CWICZENIA_TERRAFORM/cwiczenie03/terraform/files/deploy.sh.tftpl
git add CWICZENIA_TERRAFORM/cwiczenie03/tests/smoke_test.py
git diff --cached --stat
git diff --cached --check
```

Teraz sprawdź, że przygotowany zestaw zawiera wyłącznie zamierzone źródła.
Nie dodawaj state, planów, `.keys/`, prawdziwych `.tfvars`, tokenów ani
klucza API. Runner otrzymuje pliki z commita; komplet musi obejmować także
oba pliki w `terraform/files` i test Pythona. Zapisz commit i wyślij swoją
gałąź do GitHuba:

```bash
git commit -m "feat: add Terraform weather deployment exercise 03"
git push -u origin HEAD
```

Udostępnij workflow także na domyślnej gałęzi,
aby pojawił się formularz ręcznego uruchomienia.
W **Actions** uruchom workflow CW03 przez **Run workflow**,
wybierając `operation: apply`. Użyj gałęzi zawierającej komplet nowych plików.

Teraz potwierdź kolejno: sukces apply, poprawne logowanie w `check-app`,
stan usług oraz sukces rzeczywistego testu pogody. Odczytaj z podsumowania
`app_url` i otwórz:

```text
http://PUBLICZNY_IP_VM/
http://PUBLICZNY_IP_VM/api/weather?city=Warsaw
```

W WWW wpisz własne miasto. Do użytkowania nie podajesz klucza API.
Jeśli dostajesz stronę domyślną Nginxa lub `502`, wróć do konfiguracji proxy,
stanu kontenera i jego lokalnego endpointu.

### Gdy bootstrap kończy się kodem `124`

Kod `124` oznacza przekroczenie limitu czasu polecenia. Teraz znajdź ostatni
wpis `[bootstrap] START`, `END` lub `TIMEOUT` i odczytaj `stage`, `exit`
oraz `duration`. Limity dla `cloud-init-wait`, `apt-update` i `apt-install`
wynoszą odpowiednio 480, 300 i 600 sekund. Sam łączny czas joba nie wskazuje,
które polecenie się zatrzymało.

We [wcześniejszym nieudanym przebiegu](https://github.com/JsystemsSzkolenia/gha-szkolenie-23-11-2026/actions/runs/45957698114/job/140367920148)
potwierdzono timeout `apt-install`: pakiety zostały pobrane, Docker i Nginx
przeszły konfigurację, a ostatni komunikat dotyczył `Processing triggers for
man-db`. Nie ustala to jeszcze procesu, który zatrzymał zakończenie APT.
Ten pierwszy provisioner przygotowuje system i usługi; nie używa klucza
OpenWeatherMap ani nie pobiera obrazu aplikacji.

W [kolejnym przebiegu](https://github.com/JsystemsSzkolenia/gha-szkolenie-23-11-2026/actions/runs/45999767247/job/140508125454)
przygotowanie `man-db` i sprawdzenie `dpkg` już się udały. APT pobrał
73,9 MB w 2 sekundy, ale zatrzymał się na `Preconfiguring packages ...`
przed rozpakowaniem pakietów. Etap `apt-install` osiągnął limit 600 sekund.
To inny punkt zatrzymania niż we wcześniejszym logu. Brak `docker.service`
i `nginx.service` w końcowej diagnostyce jest wtedy skutkiem niedokończonej
instalacji, a nie dowodem błędnej konfiguracji usług.

Teraz zachowaj w `run_stage` uruchamianie przez
`setsid --wait timeout --kill-after=30s`. Terraform SSH przydziela terminal;
`setsid` tworzy dla polecenia osobną sesję bez tego terminala, a `--wait`
przekazuje kod zakończenia programu. Umieść `setsid` **przed** `timeout`,
aby polecenie i jego skrypty pozostały w grupie nadzorowanej przez timeout.
Do poleceń APT i konfiguracji `dpkg` dodaj `</dev/null` oraz zachowaj
`DEBIAN_FRONTEND=noninteractive`. Etap `man-db-preseed` musi nadal otrzymać
swój here-string — nie zamykaj wejścia dla wszystkich etapów bez wyjątku.

Ta poprawka usuwa zależność instalacji od terminala i wejścia SSH.
Nie pomija hooków APT ani konfiguracji pakietów i nie zwiększa limitu
`apt-install`. Sam log nie rozstrzyga, który skrypt Debconf oczekiwał;
skuteczność poprawki na konkretnej VM potwierdzi dopiero nowy przebieg.
Mechanizmy opisują [kod komunikatora SSH Terraform](https://github.com/hashicorp/terraform/blob/main/internal/communicator/ssh/communicator.go),
[setsid](https://manpages.debian.org/bookworm/util-linux/setsid.1.en.html)
i [prekonfiguracja Debconf](https://manpages.debian.org/bookworm/debconf-doc/debconf.7.en.html).

Poprawiony bootstrap czeka ograniczony czas na zwolnienie blokad pakietów,
wyłącza przebudowę indeksu dokumentacji `man-db` podczas instalacji pakietów
i sprawdza, czy trzeba dokończyć przerwaną konfigurację `dpkg`. Nie wyłącza
aktualizacji pakietów. Wznawia konfigurację tylko wtedy,
gdy stan pakietów tego wymaga. Instaluje wyłącznie brakujące pakiety,
a kolejne etapy mają własne limity i diagnostykę w logu.

Jeśli problem się powtórzy, teraz wykonaj **ręczną diagnostykę przez SSH**
z własnego hosta agenta. Podstaw rzeczywisty katalog state CW03 oraz publiczny
IP wyłącznie własnej VM CW03. Użyj `public_ip` z metadanych własnego state;
jeśli przerwany apply nie zapisał jeszcze tego outputu, sprawdź IP tej VM
w panelu DigitalOcean. Nie wypisuj całego state, ponieważ zawiera klucz prywatny.

```bash
CW03_STATE_DIRECTORY="$HOME/terraform-state/cwiczenie03/IDENTYFIKATOR_REPOZYTORIUM"
CW03_VM_IP="PUBLICZNY_IP_TWOJEJ_VM_CW03"
ssh -i "$CW03_STATE_DIRECTORY/keys/id_ed25519" \
  -o IdentitiesOnly=yes \
  -o "UserKnownHostsFile=$CW03_STATE_DIRECTORY/known_hosts" \
  -o StrictHostKeyChecking=accept-new \
  "root@$CW03_VM_IP"
```

Jeżeli ustawiłeś `TF_STATE_ROOT`, dostosuj również katalog state.
Po zalogowaniu teraz odczytaj stan usług, logi pakietów i dostępność zasobów:

```bash
cloud-init status --long
systemctl status apt-daily.service apt-daily-upgrade.service --no-pager
ps -eo pid,ppid,pgid,sid,tpgid,stat,wchan:24,etimes,comm
lslocks --output PID,COMMAND,TYPE,PATH
journalctl -u cloud-final -u apt-daily -u apt-daily-upgrade \
  --since "30 minutes ago" --no-pager -n 100
tail -n 80 /var/log/apt/term.log
df -h
free -h
curl -4 -I --max-time 10 https://archive.ubuntu.com
exit
```

To polecenia diagnostyczne; nie usuwaj blokad `dpkg`, nie zabijaj procesu APT
i nie wyłączaj cloud-init. Ustal przyczynę na podstawie ostatniego etapu
i logów. Nie publikuj state, prywatnego klucza ani pełnych logów z sekretami.

Sam wpis `SubState=dead` oznacza stan wskazanej jednostki systemd — odczytaj
również jej `Id`, `ActiveState` i `Result`. Nazwa procesu `unattended-upgr`
jest skrócona i może dotyczyć usługi oczekującej na zamknięcie systemu;
nie dowodzi trzymania blokady APT. Snapshot wykonany dopiero po timeout
nie pokaże już ubitych procesów. Gdy problem się powtarza, odczytaj procesy
i blokady z drugiej sesji SSH jeszcze podczas zatrzymania instalacji.

Po zapisaniu poprawionego `files/bootstrap.sh` w repozytorium teraz uruchom
**nowe Run workflow** z poprawionego commita. Funkcja **Re-run jobs** używa
[tego samego commita co poprzedni przebieg](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs).
Zachowaj dotychczasowy state, klucz i VM. Hash pliku w `triggers_replace`
powoduje ponowienie `terraform_data.application`; po błędzie provisionera
Terraform również planuje ponowienie tego zasobu. Sprawdź w planie, że ponawiasz
konfigurację aplikacji, zamiast wymieniać VM. Nie twórz nowego state jako naprawy.

## 14. Ponów wdrożenie i przećwicz zmianę sekretu

Teraz uruchom ponownie apply bez zmian. Terraform ma użyć tego samego state,
zachować VM i nazwy oraz ponownie umożliwić test aplikacji.

Zmiana samego GitHub Secret nie zmienia zasobów ani nie wymusza wykonania
provisionera. Po rotacji `OPENWEATHER_API_KEY` teraz zwiększ
`DEPLOYMENT_REVISION`, np. z `1` na `2`, i uruchom nowe apply.
To wymusza ponowne uruchomienie deploya z nowym sekretem. Nie używaj treści
sekretu jako triggera ani outputu tylko po to, aby wykrywać jego zmianę.

Analogicznie zmiana referencji obrazu lub template'ów ma uruchamiać deploy
aplikacji. Zmieniaj konfigurację świadomie, czytając plan; zmiana obrazu
aplikacji nie powinna wymagać wymiany samej VM.

## 15. Usuń zasoby po ćwiczeniu

Teraz uruchom ten sam workflow z `operation: destroy`. Terraform ma usunąć
zasoby tego state, a `check-app` ma zostać pominięty. Klucz pogodowy nie jest
potrzebny do niszczenia zasobów; token DigitalOcean nadal jest potrzebny.

Nie usuwaj state przed udanym destroy. Jeśli VPC stała się domyślną siecią
regionu, uzgodnij z prowadzącym bezpieczne wskazanie innej istniejącej sieci
jako domyślnej i ponów operację. Nie zmieniaj cudzych sieci samodzielnie.

Chroń state i jego kopie, które nadal mogą zawierać prywatny klucz SSH.
Zadanie jest ukończone, gdy Terraform wykonuje cały deploy, drugi job
potwierdza SSH i rzeczywiste WWW/API, użytkownik korzysta z adresu HTTP
bez domeny, a osobny state pozwala ponawiać apply oraz destroy.
Lokalna walidacja kodu nie stanowi dowodu działania VM lub aplikacji.

Dokumentacja:
[provisionery Terraform](https://developer.hashicorp.com/terraform/language/provisioners),
[wartości ephemeral](https://developer.hashicorp.com/terraform/language/manage-sensitive-data/ephemeral)
oraz [proxy_pass Nginxa](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_pass).

## Pełna treść plików do utworzenia

Teraz utwórz kolejno poniższe pliki pod ścieżkami liczonymi od katalogu
głównego repozytorium. Każdy blok zawiera pełną treść jednego pliku.
Zachowaj wcięcia, apostrofy, heredoc i wyrażenia `${{ ... }}` w YAML.
Wartości przykładowe nazw i adresów zastępujesz w GitHub Variables;
rzeczywiste klucze podajesz wyłącznie w Secrets.

Docelowy zestaw źródeł:

```text
.github/workflows/terraform-cwiczenie03.yaml
.gitignore
CWICZENIA_TERRAFORM/cwiczenie03/
├── terraform/
│   ├── versions.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── application.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   ├── .terraform.lock.hcl       # generowany przez terraform init
│   └── files/
│       ├── bootstrap.sh
│       └── deploy.sh.tftpl
└── tests/
    └── smoke_test.py
```

Nie twórz ręcznie `.terraform.lock.hcl`; wygeneruj i dodaj go do Gita
poleceniami z kroku 10. Klucze, state i plany powstają w czasie wykonania
i nie są plikami źródłowymi do odtworzenia z README.

### Plik: `.gitignore`

Jeżeli `.gitignore` już istnieje, dopisz brakujące reguły bez usuwania własnych wpisów.

````gitignore
# Lokalne rozwiązania prowadzącego — nie trafiają do repozytorium uczniów.
/CWICZENIA_TERRAFORM/**/rozwiazanie_ukryte/

# Terraform — reguły obowiązują we wszystkich katalogach repozytorium.
# Pobrane providery, moduły i lokalne metadane.
.terraform/

# Stan, kopie stanu i jego blokady mogą zawierać hasła i prywatne klucze.
*.tfstate
*.tfstate.*

# Lokalne wartości zmiennych: terraform.tfvars, terraform.tfvars.json,
# a także *.auto.tfvars i *.auto.tfvars.json.
*.tfvars
*.tfvars.json

# Zapisane plany mogą zawierać dane wrażliwe.
*.tfplan
tfplan
*.tfplan.json
tfplan.json

# Raporty awarii i lokalne nadpisania konfiguracji.
crash.log
crash.*.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Lokalne ustawienia CLI, poświadczenia i cache Terraform.
.terraformrc
terraform.rc
.terraform.d/
*.tfrc
*.tfrc.json

# Klucze SSH generowane w ćwiczeniach.
/CWICZENIA_TERRAFORM/**/.keys/

# Lokalne dane ćwiczeń Ansible: jawny klucz API i adres hosta uczestnika.
/CWICZENIA_TERRAFORM/**/vars.local.yml
/CWICZENIA_TERRAFORM/**/inventory.ini
/CWICZENIA_TERRAFORM/**/.collections/
/CWICZENIA_TERRAFORM/**/*.retry

# .terraform.lock.hcl i przykładowe *.tfvars.example pozostają wersjonowane
# poza całkowicie ignorowanym katalogiem rozwiazanie_ukryte.
````

### Plik: `CWICZENIA_TERRAFORM/cwiczenie03/terraform/versions.tf`

Teraz utwórz konfigurację wersji, providerów i lokalnego backendu.

````hcl
terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  # Pipeline przekazuje bezwzględny path podczas terraform init.
  # Stan pozostaje lokalnym plikiem na trwałym dysku self-hosted runnera.
  backend "local" {}

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.109.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.4.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.9.1"
    }
  }
}

# Provider odczytuje token ze zmiennej środowiskowej DIGITALOCEAN_TOKEN.
# Bez zmiennej token i bez tfvars z tokenem; backend nie wymaga poświadczeń.
provider "digitalocean" {}
````

### Plik: `CWICZENIA_TERRAFORM/cwiczenie03/terraform/variables.tf`

Teraz utwórz wszystkie zmienne infrastruktury i aplikacji z walidacją.

````hcl
variable "vm_name" {
  description = "Nazwa bazowa VM, np. jan-kowalski-vm. Terraform dopisuje stały losowy sufiks."
  type        = string

  validation {
    condition     = length(var.vm_name) >= 3 && length(var.vm_name) <= 50 && can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.vm_name))
    error_message = "Nazwa VM musi mieć 3–50 znaków: małe litery, cyfry i myślniki; początek to litera, a koniec to litera lub cyfra."
  }
}

variable "vpc_name" {
  description = "Nazwa bazowa prywatnej sieci VPC, np. jan-kowalski-vpc."
  type        = string

  validation {
    condition     = length(var.vpc_name) >= 3 && length(var.vpc_name) <= 50 && can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.vpc_name))
    error_message = "Nazwa VPC musi mieć 3–50 znaków: małe litery, cyfry i myślniki; początek to litera, a koniec to litera lub cyfra."
  }
}

variable "firewall_name" {
  description = "Nazwa bazowa firewalla, np. jan-kowalski-firewall."
  type        = string

  validation {
    condition     = length(var.firewall_name) >= 3 && length(var.firewall_name) <= 50 && can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.firewall_name))
    error_message = "Nazwa firewalla musi mieć 3–50 znaków: małe litery, cyfry i myślniki; początek to litera, a koniec to litera lub cyfra."
  }
}

variable "region" {
  description = "Region DigitalOcean wspólny dla VM i VPC."
  type        = string
  default     = "fra1"

  validation {
    condition     = can(regex("^[a-z]{3}[0-9]+$", var.region))
    error_message = "Podaj slug regionu DigitalOcean, np. fra1 albo ams3."
  }
}

variable "vm_image" {
  description = "Slug obrazu systemu operacyjnego VM."
  type        = string
  default     = "ubuntu-24-04-x64"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*$", var.vm_image))
    error_message = "Podaj slug obrazu DigitalOcean, np. ubuntu-24-04-x64."
  }
}

variable "vm_size" {
  description = "Slug rozmiaru VM dostępnego w wybranym regionie."
  type        = string
  default     = "s-1vcpu-1gb"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*$", var.vm_size))
    error_message = "Podaj slug rozmiaru DigitalOcean, np. s-1vcpu-1gb."
  }
}

variable "vpc_cidr" {
  description = "Niepokrywająca się z innymi VPC prywatna sieć IPv4 z maską /24."
  type        = string
  default     = "10.33.34.0/24"

  validation {
    condition = can(cidrnetmask(var.vpc_cidr)) && can(regex("/24$", var.vpc_cidr)) && can(
      regex("^(10\\.|192\\.168\\.|172\\.(1[6-9]|2[0-9]|3[01])\\.)", var.vpc_cidr)
    ) && try(cidrhost(var.vpc_cidr, 0) == split("/", var.vpc_cidr)[0], false)
    error_message = "Podaj adres prywatnej sieci IPv4 RFC1918 z maską /24, np. 10.33.34.0/24; adres hosta ani publiczna sieć nie są dozwolone."
  }
}

variable "ssh_allowed_cidr" {
  description = "Publiczny adres IPv4 self-hosted runnera z maską /32; tylko ten host otrzyma dostęp SSH do VM."
  type        = string

  validation {
    condition = can(cidrnetmask(var.ssh_allowed_cidr)) && try(
      tonumber(split("/", var.ssh_allowed_cidr)[1]) == 32 &&
      cidrhost(var.ssh_allowed_cidr, 0) == split("/", var.ssh_allowed_cidr)[0],
      false
    )
    error_message = "Podaj jeden publiczny adres IPv4 z maską /32, np. 203.0.113.10/32; nie używaj 0.0.0.0/0."
  }
}

variable "ssh_private_key_path" {
  description = "Ścieżka pliku klucza SSH; pipeline przekazuje bezwzględną ścieżkę w trwałym katalogu stanu, poza checkoutem."
  type        = string
  default     = ".keys/id_ed25519"

  validation {
    condition     = length(trimspace(var.ssh_private_key_path)) > 0 && !can(regex("[[:cntrl:]]", var.ssh_private_key_path))
    error_message = "Podaj niepustą ścieżkę pliku klucza SSH, bez znaków sterujących i nowych linii."
  }
}

variable "image_reference" {
  description = "Gotowy obraz aplikacji przypięty niezmiennym digestem SHA256. Terraform nie buduje obrazu."
  type        = string
  default     = "piotrskoska/python_pogoda@sha256:ac30d995f5ca10e4c5db5c44d526398c435270ba1194c5987642f7179a224638"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9._/-]*@sha256:[a-f0-9]{64}$", var.image_reference))
    error_message = "Podaj obraz w postaci login/obraz@sha256:<64 znaki hex>; nie używaj ruchomego tagu."
  }
}

variable "container_name" {
  description = "Stała nazwa kontenera aplikacji na VM; ponowny deploy zastępuje wyłącznie kontener o tej nazwie."
  type        = string
  default     = "cw03-pogoda"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9_.-]{0,62}$", var.container_name))
    error_message = "Nazwa kontenera: 1–63 małe litery, cyfry, myślniki, podkreślenia lub kropki; początek to litera lub cyfra."
  }
}

variable "deployment_revision" {
  description = "Niepoufna rewizja deploya; zwiększ np. z 1 na 2 po zmianie sekretu API lub danych logowania Docker Hub."
  type        = string
  default     = "1"

  validation {
    condition     = length(trimspace(var.deployment_revision)) > 0 && length(var.deployment_revision) <= 64 && !can(regex("[[:cntrl:]]", var.deployment_revision))
    error_message = "Podaj niepustą rewizję deploya o długości do 64 znaków, bez nowych linii i znaków sterujących."
  }
}

variable "openweather_api_key" {
  description = "Klucz OpenWeatherMap przekazany przez TF_VAR_openweather_api_key wyłącznie do provisionera; pomijany przy destroy."
  type        = string
  default     = null
  sensitive   = true
  ephemeral   = true
}

variable "dockerhub_username" {
  description = "Opcjonalny publiczny login Docker Hub; potrzebny tylko wraz z tokenem do uwierzytelnionego pobrania obrazu."
  type        = string
  default     = ""

  validation {
    condition     = var.dockerhub_username == "" || can(regex("^[a-z0-9][a-z0-9_-]*$", var.dockerhub_username))
    error_message = "Podaj poprawny login Docker Hub małymi literami albo pozostaw pustą wartość dla pobrania publicznego."
  }
}

variable "dockerhub_token" {
  description = "Opcjonalny token Docker Hub przekazany przez TF_VAR_dockerhub_token tylko do provisionera."
  type        = string
  default     = ""
  sensitive   = true
  ephemeral   = true
}
````

### Plik: `CWICZENIA_TERRAFORM/cwiczenie03/terraform/main.tf`

Teraz utwórz zasoby infrastruktury oraz zapis klucza SSH.

````hcl
# Wartość jest zapisana w state. Kolejne plan/apply zachowują ten sam sufiks.
resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

resource "local_sensitive_file" "private_key" {
  filename             = var.ssh_private_key_path
  content              = tls_private_key.ssh.private_key_openssh
  file_permission      = "0600"
  directory_permission = "0700"
}

resource "digitalocean_ssh_key" "student" {
  name       = "${var.vm_name}-${random_string.suffix.result}-ssh"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "digitalocean_vpc" "lab" {
  name     = "${var.vpc_name}-${random_string.suffix.result}"
  region   = var.region
  ip_range = var.vpc_cidr
}

resource "digitalocean_droplet" "vm" {
  name     = "${var.vm_name}-${random_string.suffix.result}"
  region   = var.region
  image    = var.vm_image
  size     = var.vm_size
  vpc_uuid = digitalocean_vpc.lab.id
  ssh_keys = [digitalocean_ssh_key.student.fingerprint]
  ipv6     = false
}

resource "digitalocean_firewall" "vm" {
  name        = "${var.firewall_name}-${random_string.suffix.result}"
  droplet_ids = [digitalocean_droplet.vm.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = [var.ssh_allowed_cidr]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "18000-18999"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
````

### Plik: `CWICZENIA_TERRAFORM/cwiczenie03/terraform/application.tf`

Teraz utwórz zasób uruchamiający bootstrap i deploy przez Terraform.

````hcl
# Aplikację wdraża Terraform przez natywny provisioner SSH, bez osobnego joba deploy.
# Zmiana kodu skryptów, VM, obrazu lub rewizji ponawia deploy bez odtwarzania VM.
resource "terraform_data" "application" {
  triggers_replace = [
    digitalocean_droplet.vm.id,
    var.image_reference,
    var.container_name,
    var.deployment_revision,
    filesha256("${path.module}/files/bootstrap.sh"),
    filesha256("${path.module}/files/deploy.sh.tftpl"),
  ]

  depends_on = [digitalocean_firewall.vm]

  connection {
    type        = "ssh"
    user        = "root"
    host        = digitalocean_droplet.vm.ipv4_address
    private_key = tls_private_key.ssh.private_key_openssh
    timeout     = "10m"
    script_path = "/root/cw03-%RAND%.sh"
  }

  provisioner "remote-exec" {
    script = "${path.module}/files/bootstrap.sh"
  }

  # Ephemeral sekrety są używane tylko w dozwolonym kontekście provisionera.
  # Nie zapisuj ich w input/triggers_replace, user_data, tfvars ani outputs.
  provisioner "remote-exec" {
    inline = [templatefile("${path.module}/files/deploy.sh.tftpl", {
      image_reference            = var.image_reference
      container_name             = var.container_name
      openweather_api_key_base64 = base64encode(var.openweather_api_key == null ? "" : var.openweather_api_key)
      dockerhub_username_base64  = base64encode(var.dockerhub_username == null ? "" : var.dockerhub_username)
      dockerhub_token_base64     = base64encode(var.dockerhub_token == null ? "" : var.dockerhub_token)
    })]
  }
}
````

### Plik: `CWICZENIA_TERRAFORM/cwiczenie03/terraform/outputs.tf`

Teraz utwórz outputy; nie wypisuj prywatnego klucza w pipeline.

````hcl
output "vm_id" {
  description = "Identyfikator utworzonej VM DigitalOcean."
  value       = digitalocean_droplet.vm.id
}

output "vm_name" {
  description = "Pełna nazwa VM ze stałym losowym sufiksem."
  value       = digitalocean_droplet.vm.name
}

output "public_ip" {
  description = "Publiczny adres IPv4 VM."
  value       = digitalocean_droplet.vm.ipv4_address
}

output "private_ip" {
  description = "Prywatny adres IPv4 VM w utworzonej VPC."
  value       = digitalocean_droplet.vm.ipv4_address_private
}

output "vpc_id" {
  description = "Identyfikator utworzonej VPC."
  value       = digitalocean_vpc.lab.id
}

output "vpc_cidr" {
  description = "Zakres adresacji prywatnej VPC."
  value       = digitalocean_vpc.lab.ip_range
}

output "firewall_name" {
  description = "Pełna nazwa firewalla przypisanego do VM."
  value       = digitalocean_firewall.vm.name
}

output "private_key_path" {
  description = "Lokalna ścieżka wygenerowanego pliku klucza SSH; output nie zawiera jego wartości."
  value       = abspath(local_sensitive_file.private_key.filename)
}

output "ssh_public_key" {
  description = "Publiczny klucz SSH w formacie OpenSSH, zarejestrowany w DigitalOcean."
  value       = tls_private_key.ssh.public_key_openssh
}

output "ssh_private_key" {
  description = "Prywatny klucz SSH w formacie OpenSSH; jawny odczyt: terraform output -raw ssh_private_key."
  value       = tls_private_key.ssh.private_key_openssh
  sensitive   = true
}

output "ssh_command" {
  description = "Polecenie SSH do wykonania lokalnie po udanym apply."
  value       = "ssh -i \"${abspath(local_sensitive_file.private_key.filename)}\" root@${digitalocean_droplet.vm.ipv4_address}"
}

output "app_url" {
  description = "Publiczny URL HTTP aplikacji przez Nginx."
  value       = "http://${digitalocean_droplet.vm.ipv4_address}"
}

output "image_reference" {
  description = "Dokładny obraz aplikacji przypięty digestem SHA256."
  value       = var.image_reference
}
````

### Plik: `CWICZENIA_TERRAFORM/cwiczenie03/terraform/terraform.tfvars.example`

Teraz utwórz niesekretny przykład; pipeline używa Variables i Secrets zamiast rzeczywistego pliku `.tfvars`.

````hcl
# Skopiuj do terraform.tfvars i wpisz własne imię/nazwisko w nazwach zasobów.
vm_name       = "jan-kowalski-cw03-vm"
vpc_name      = "jan-kowalski-cw03-vpc"
firewall_name = "jan-kowalski-cw03-firewall"

region   = "fra1"
vm_image = "ubuntu-24-04-x64"
vm_size  = "s-1vcpu-1gb"

# Wybierz sieć niepokrywającą się z CW01, CW02 i innymi VPC na wspólnym koncie.
vpc_cidr = "10.33.36.0/24"

# To adres dokumentacyjny. ZASTĄP go publicznym IPv4 SELF-HOSTED RUNNERA /32.
# SSH będzie wykonywane z runnera w osobnym jobie, a nie z laptopa ucznia.
ssh_allowed_cidr = "203.0.113.10/32"

# W pipeline nie wpisuj tutaj ścieżki: workflow przekaże ssh_private_key_path
# do trwałego katalogu stanu poza checkoutem. Lokalny domyślny plik:
# ssh_private_key_path = ".keys/id_ed25519"

image_reference     = "piotrskoska/python_pogoda@sha256:ac30d995f5ca10e4c5db5c44d526398c435270ba1194c5987642f7179a224638"
container_name      = "cw03-pogoda"
deployment_revision = "1"

# Opcjonalny publiczny login; token podawaj tylko przez TF_VAR_dockerhub_token.
# dockerhub_username = "piotrskoska"
# Klucz API podawaj tylko przez TF_VAR_openweather_api_key, nie przez tfvars.
# Po zmianie sekretów zwiększ deployment_revision, aby ponowić provisioner.

# Token API ustaw tylko przez zmienną środowiskową DIGITALOCEAN_TOKEN.
# Nie dopisuj tokenu do tego pliku.
````

### Plik: `CWICZENIA_TERRAFORM/cwiczenie03/terraform/files/bootstrap.sh`

Teraz utwórz pełny skrypt przygotowania VM, wraz z obsługą timeoutów i przerwanej konfiguracji pakietów.

````bash
#!/usr/bin/env bash
set -euo pipefail
umask 077

current_stage='bootstrap-start'
stage_started=$SECONDS

diagnostics() {
  echo '[bootstrap] Failure diagnostics (service state and process names only).' >&2
  if command -v cloud-init >/dev/null 2>&1; then
    timeout --kill-after=5s 15 cloud-init status --long >&2 || true
  fi
  timeout --kill-after=5s 15 systemctl --no-pager show \
    --property=Id,LoadState,ActiveState,SubState,Result,ExecMainStatus \
    cloud-init.service cloud-final.service apt-daily.service apt-daily-upgrade.service \
    docker.service nginx.service >&2 || true
  ps -eo pid,ppid,stat,etimes,comm |
    awk 'NR == 1 || $5 ~ /^(apt|apt-get|dpkg|unattended|cloud-init|mandb|needrestart)/' >&2 || true
}

finish() {
  local status=$?
  trap - EXIT HUP INT TERM
  set +e
  if [ "$status" -ne 0 ]; then
    printf '[bootstrap] FAILED stage=%s exit=%s duration=%ss\n' \
      "$current_stage" "$status" "$((SECONDS - stage_started))" >&2
    diagnostics
  fi
  rm -f -- "$0"
  exit "$status"
}
trap finish EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

run_stage() {
  current_stage=$1
  local limit=$2
  shift 2
  stage_started=$SECONDS
  printf '[bootstrap] START stage=%s limit=%ss command=' "$current_stage" "$limit" >&2
  printf '%q ' "$@" >&2
  printf '\n' >&2
  local status
  # Terraform SSH allocates a PTY. Package configuration must not inherit
  # its controlling terminal. Keep timeout INSIDE setsid so its process
  # group still includes package scripts when a stage reaches its limit.
  # Preserve stdin here: man-db-preseed deliberately supplies a here-string.
  if setsid --wait timeout --kill-after=30s "$limit" "$@"; then
    status=0
  else
    status=$?
  fi
  printf '[bootstrap] END stage=%s exit=%s duration=%ss\n' \
    "$current_stage" "$status" "$((SECONDS - stage_started))" >&2
  if [ "$status" -eq 124 ]; then
    printf '[bootstrap] TIMEOUT stage=%s exceeded %ss; bootstrap stopped.\n' \
      "$current_stage" "$limit" >&2
  fi
  return "$status"
}

if ! command -v setsid >/dev/null 2>&1; then
  echo '[bootstrap] setsid from util-linux is required for noninteractive provisioning.' >&2
  exit 1
fi

if command -v cloud-init >/dev/null 2>&1; then
  if run_stage cloud-init-wait 480 cloud-init status --wait; then
    cloud_init_status=0
  else
    cloud_init_status=$?
  fi
  case "$cloud_init_status" in
    0) ;;
    2) echo '::warning::Cloud-init finished with recoverable warnings; checking its final status.' ;;
    *) exit "$cloud_init_status" ;;
  esac
  current_stage='cloud-init-final-status'
  stage_started=$SECONDS
  echo '[bootstrap] Checking final cloud-init status (limit=20s).' >&2
  if cloud_init_details="$(timeout --kill-after=5s 20 cloud-init status --long 2>&1)"; then
    cloud_init_details_status=0
  else
    cloud_init_details_status=$?
  fi
  case "$cloud_init_details_status" in
    0|2) ;;
    *) printf '%s\n' "$cloud_init_details" >&2; exit "$cloud_init_details_status" ;;
  esac
  if ! grep -Eq '^[[:space:]]*status:[[:space:]]+done([[:space:]]|$)' <<< "$cloud_init_details"; then
    printf '%s\n' "$cloud_init_details" >&2
    echo 'Cloud-init must finish before installing application services.' >&2
    exit 1
  fi
fi

# APT/dpkg use fcntl locks: never remove their files or use flock as a substitute.
wait_for_package_locks() {
  local busy lock_path locked_paths
  while true; do
    busy=0
    if command -v fuser >/dev/null 2>&1; then
      for lock_path in /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock \
        /var/lib/apt/lists/lock /var/cache/apt/archives/lock; do
        if [ -e "$lock_path" ] && fuser -s "$lock_path"; then
          busy=1
        fi
      done
    elif command -v lslocks >/dev/null 2>&1; then
      if ! locked_paths="$(lslocks --noheadings --notruncate --output PATH)"; then
        echo '[bootstrap] Could not read package-manager locks.' >&2
        return 1
      fi
      if grep -Eq '^[[:space:]]*/(var/lib/dpkg/lock(-frontend)?|var/lib/apt/lists/lock|var/cache/apt/archives/lock)[[:space:]]*$' <<< "$locked_paths"; then
        busy=1
      fi
    else
      echo '[bootstrap] Neither fuser nor lslocks is available; cannot safely check package-manager locks.' >&2
      return 1
    fi
    if [ "$busy" -eq 0 ]; then
      return 0
    fi
    echo '[bootstrap] Another package-manager process is active; waiting without removing its locks.' >&2
    sleep 5
  done
}
export -f wait_for_package_locks
run_stage package-lock-wait 180 bash -c wait_for_package_locks

# The observed apt-install timeout followed the man-db trigger message.
# Preseed its supported setting before reconfiguring or resuming interrupted dpkg.
export DEBIAN_FRONTEND=noninteractive
run_stage man-db-preseed 30 debconf-set-selections <<<'man-db man-db/auto-update boolean false'
current_stage='man-db-state'
stage_started=$SECONDS
man_db_state="$(dpkg-query -W '-f=${db:Status-Status}' man-db 2>/dev/null || true)"
case "$man_db_state" in
  installed|unpacked|half-configured|triggers-pending|triggers-awaited)
    run_stage man-db-reconfigure 180 dpkg-reconfigure --frontend=noninteractive --force man-db </dev/null
    ;;
esac
current_stage='man-db-auto-update-check'
stage_started=$SECONDS
if [ -e /var/lib/man-db/auto-update ]; then
  echo '[bootstrap] man-db automatic indexing is still enabled after reconfiguration; refusing to resume dpkg.' >&2
  exit 1
fi

current_stage='dpkg-audit'
stage_started=$SECONDS
echo '[bootstrap] Checking for interrupted package configuration (limit=30s).' >&2
if dpkg_audit="$(timeout --kill-after=5s 30 dpkg --audit 2>&1)"; then
  :
else
  dpkg_audit_status=$?
  printf '%s\n' "$dpkg_audit" >&2
  exit "$dpkg_audit_status"
fi
# shellcheck disable=SC2016 # dpkg-query expands this format, not Bash.
package_states="$(timeout --kill-after=5s 30 dpkg-query -W '-f=${db:Status-Status}\n')"
if [ -n "$dpkg_audit" ] ||
  grep -Eq '^(unpacked|half-configured|half-installed|triggers-pending|triggers-awaited)$' <<< "$package_states"; then
  echo '[bootstrap] Resuming interrupted dpkg configuration with man-db indexing disabled.' >&2
  run_stage dpkg-recovery 600 dpkg --configure -a </dev/null
else
  echo '[bootstrap] No interrupted package configuration; skipping dpkg recovery.' >&2
fi

current_stage='package-check'
stage_started=$SECONDS
missing_packages=()
for package in docker.io nginx ca-certificates curl; do
  if [ "$(dpkg-query -W '-f=${Status}' "$package" 2>/dev/null || true)" = 'install ok installed' ]; then
    printf '[bootstrap] Package already installed: %s\n' "$package" >&2
    continue
  fi
  if [ "$package" = docker.io ] && command -v docker >/dev/null 2>&1; then
    echo '[bootstrap] Using the existing Docker installation; not replacing it with docker.io.' >&2
    continue
  fi
  if [ "$package" = nginx ] && command -v nginx >/dev/null 2>&1; then
    echo '[bootstrap] Using the existing Nginx installation.' >&2
    continue
  fi
  if [ "$package" = docker.io ]; then
    for existing_package in docker-ce docker-ce-cli moby-engine moby-cli; do
      if [ "$(dpkg-query -W '-f=${Status}' "$existing_package" 2>/dev/null || true)" = 'install ok installed' ]; then
        echo 'An existing Docker CE/Moby package has no working Docker CLI; repair it before rerunning.' >&2
        exit 1
      fi
    done
  fi
  missing_packages+=("$package")
done

if [ "${#missing_packages[@]}" -gt 0 ]; then
  export DEBIAN_FRONTEND=noninteractive
  apt_options=(
    -o Acquire::Retries=3
    -o Acquire::http::Timeout=30
    -o Acquire::https::Timeout=30
    -o Acquire::ForceIPv4=true
    -o DPkg::Lock::Timeout=180
    -o Dpkg::Use-Pty=0
    -o Dpkg::Options::=--force-confdef
    -o Dpkg::Options::=--force-confold
  )
  # EOF prevents inherited SSH input from becoming an unattended prompt.
  # Package hooks and normal dpkg configuration remain enabled.
  run_stage apt-update 300 apt-get "${apt_options[@]}" -o APT::Update::Error-Mode=any update </dev/null
  run_stage apt-install 600 apt-get "${apt_options[@]}" install -y --no-upgrade --no-install-recommends "${missing_packages[@]}" </dev/null
else
  echo '[bootstrap] All required packages are installed; skipping apt update/install.' >&2
fi

run_stage docker-cli-check 15 docker --version
run_stage nginx-cli-check 15 nginx -v
run_stage docker-start 60 systemctl enable --now docker
run_stage docker-active 30 systemctl is-active --quiet docker
run_stage docker-info 30 docker info >/dev/null

current_stage='nginx-vhost'
stage_started=$SECONDS
# Manage only the packaged default and this exercise's own virtual host.
rm -f -- /etc/nginx/sites-enabled/default
if [ ! -e /etc/nginx/sites-available/cw03-pogoda ]; then
  cat > /etc/nginx/sites-available/cw03-pogoda <<'NGINX'
server {
    listen 80 default_server;
    server_name _;
    return 503;
}
NGINX
  chmod 644 /etc/nginx/sites-available/cw03-pogoda
fi
ln -sfn /etc/nginx/sites-available/cw03-pogoda /etc/nginx/sites-enabled/cw03-pogoda
run_stage nginx-config-check 30 nginx -t
run_stage nginx-start 60 systemctl enable --now nginx
run_stage nginx-reload 30 systemctl reload nginx
echo 'Docker and Nginx are ready; application credentials were not needed for bootstrap.'
````

### Plik: `CWICZENIA_TERRAFORM/cwiczenie03/terraform/files/deploy.sh.tftpl`

Teraz utwórz template deploya. Zachowaj składnię `${...}`: wartości podstawia Terraform przez `templatefile`.

````bash
#!/usr/bin/env bash
set -euo pipefail
umask 077
chmod 600 -- "$0"
DOCKER_CONFIG=''
nginx_candidate=''
nginx_backup=''
cleanup() {
  task_status=$?
  trap - EXIT
  if [ -n "$DOCKER_CONFIG" ]; then
    timeout 30 docker logout >/dev/null 2>&1 || true
    rm -f -- "$DOCKER_CONFIG/config.json"
    rmdir -- "$DOCKER_CONFIG" 2>/dev/null || true
  fi
  if [ -n "$nginx_candidate" ]; then
    rm -f -- "$nginx_candidate"
  fi
  if [ -n "$nginx_backup" ]; then
    rm -f -- "$nginx_backup"
  fi
  unset OPENWEATHER_API_KEY DOCKERHUB_TOKEN
  rm -f -- "$0"
  exit "$task_status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

OPENWEATHER_API_KEY="$(printf '%s' '${openweather_api_key_base64}' | base64 --decode)"
DOCKERHUB_USERNAME="$(printf '%s' '${dockerhub_username_base64}' | base64 --decode)"
DOCKERHUB_TOKEN="$(printf '%s' '${dockerhub_token_base64}' | base64 --decode)"
IMAGE_REFERENCE='${image_reference}'
CONTAINER_NAME='${container_name}'

if [ -z "$OPENWEATHER_API_KEY" ] || [[ "$OPENWEATHER_API_KEY" =~ [[:cntrl:]] ]]; then
  echo 'Pass a nonempty, single-line OpenWeather key through TF_VAR_openweather_api_key.' >&2
  exit 1
fi
if [ -n "$DOCKERHUB_USERNAME" ] || [ -n "$DOCKERHUB_TOKEN" ]; then
  if [ -z "$DOCKERHUB_USERNAME" ] || [ -z "$DOCKERHUB_TOKEN" ]; then
    echo 'Authenticated image pulls require both Docker Hub username and token.' >&2
    exit 1
  fi
  DOCKER_CONFIG="$(mktemp -d /root/cw03-docker-config.XXXXXX)"
  chmod 700 "$DOCKER_CONFIG"
  export DOCKER_CONFIG
  printf '%s' "$DOCKERHUB_TOKEN" | timeout 60 docker login \
    --username "$DOCKERHUB_USERNAME" --password-stdin >/dev/null
fi
unset DOCKERHUB_TOKEN

# A failed pull keeps the existing deployment container and Nginx proxy running.
timeout 180 docker pull "$IMAGE_REFERENCE"
# String equality also handles valid Docker names containing a dot literally.
existing_container="$(docker container ls --all --format '{{.ID}} {{.Names}}' | awk -v expected="$CONTAINER_NAME" '$2 == expected {print $1}')"
if [ -n "$existing_container" ]; then
  docker rm --force "$existing_container"
fi
export OPENWEATHER_API_KEY
docker run -d --name "$CONTAINER_NAME" --restart unless-stopped \
  -p 127.0.0.1:18080:8080 -e OPENWEATHER_API_KEY "$IMAGE_REFERENCE"
unset OPENWEATHER_API_KEY

curl --fail --silent --show-error \
  --retry 15 --retry-all-errors --retry-delay 2 \
  --retry-max-time 60 --max-time 5 \
  --output /dev/null http://127.0.0.1:18080/healthz
test "$(docker inspect --format '{{.State.Running}}' "$CONTAINER_NAME")" = true

nginx_candidate="$(mktemp /etc/nginx/sites-available/.cw03-pogoda.XXXXXX)"
cat > "$nginx_candidate" <<'NGINX'
server {
    listen 80 default_server;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:18080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX
chmod 644 "$nginx_candidate"
nginx_backup="$(mktemp /etc/nginx/sites-available/.cw03-backup.XXXXXX)"
cp -- /etc/nginx/sites-available/cw03-pogoda "$nginx_backup"
mv -- "$nginx_candidate" /etc/nginx/sites-available/cw03-pogoda
nginx_candidate=''
rm -f -- /etc/nginx/sites-enabled/default
ln -sfn /etc/nginx/sites-available/cw03-pogoda /etc/nginx/sites-enabled/cw03-pogoda
if ! nginx -t; then
  mv -- "$nginx_backup" /etc/nginx/sites-available/cw03-pogoda
  nginx_backup=''
  echo 'Nginx configuration validation failed; the previous owned configuration was restored.' >&2
  exit 1
fi
rm -f -- "$nginx_backup"
nginx_backup=''
systemctl reload nginx
curl --fail --silent --show-error \
  --retry 15 --retry-all-errors --retry-delay 2 \
  --retry-max-time 60 --max-time 5 \
  --output /dev/null http://127.0.0.1/healthz
echo 'Application container is running; Nginx serves its HTTP interface on port 80.'
````

### Plik: `.github/workflows/terraform-cwiczenie03.yaml`

Teraz utwórz cały workflow w głównym `.github/workflows`, a nie w katalogu Terraform.

````yaml
# Ćwiczenie 03 — najpierw przygotuj i dodaj do Gita własne pliki .tf w:
# CWICZENIA_TERRAFORM/cwiczenie03/terraform (instrukcja w cwiczenie03/README.md).
# Nie odwołuj się do rozwiazanie_ukryte: ten katalog nie trafia do GitHub.
# Settings → Secrets and variables → Actions:
# Secret: DIGITALOCEAN_TOKEN — token zarządzający VM, VPC, firewallem i kluczami SSH.
# Secret: OPENWEATHER_API_KEY — aktywny klucz pogody, wymagany dla apply.
# Opcjonalnie dla obrazu prywatnego: secret DOCKERHUB_TOKEN + variable DOCKERHUB_USERNAME.
# Variables wymagane:
#   VM_NAME = jan-kowalski-cw03-vm
#   VPC_NAME = jan-kowalski-cw03-vpc
#   FIREWALL_NAME = jan-kowalski-cw03-firewall
#   VPC_CIDR = 10.33.36.0/24 — wolny zakres, niepokrywający się z innymi VPC.
#   SSH_ALLOWED_CIDR = PUBLICZNY_IP_RUNNERA/32 (odczytaj ip a → eth0 na maszynie ćwiczeniowej).
# Variables opcjonalne: DO_REGION=fra1, DO_VM_IMAGE=ubuntu-24-04-x64,
#   DO_VM_SIZE=s-1vcpu-1gb, TF_STATE_ROOT=/home/student/terraform-state.
#   DOCKER_IMAGE_REFERENCE=piotrskoska/python_pogoda@sha256:ac30d995f5ca10e4c5db5c44d526398c435270ba1194c5987642f7179a224638
#   CONTAINER_NAME=cw03-pogoda, DEPLOYMENT_REVISION=1, WEATHER_CITY=Warsaw.
# Po zmianie klucza API zwiększ DEPLOYMENT_REVISION, aby ponowić provisioner aplikacji.
# Bez TF_STATE_ROOT używamy $HOME/terraform-state konta usługi runnera.
# Oba joby i kolejne uruchomienia MUSZĄ trafić na ten sam host z trwałym dyskiem.
# W tym ćwiczeniu repozytorium ma jednego aktywnego runnera self-hosted Linux.
# Akcje Node.js 24 wymagają runnera >= 2.327.1; zainstaluj aktualny runner.

name: Terraform — ćwiczenie 03 — Docker i Nginx
run-name: CW03 Terraform — ${{ inputs.operation }}

on:
  workflow_dispatch:
    inputs:
      operation:
        description: Utwórz lub zaktualizuj zasoby albo usuń zasoby tego ćwiczenia
        type: choice
        required: true
        default: apply
        options:
          - apply
          - destroy

permissions:
  contents: read

# Jeden przebieg repozytorium naraz; stan i znane klucze hostów są lokalne.
concurrency:
  group: terraform-cwiczenie03-${{ github.repository_id }}
  cancel-in-progress: false

defaults:
  run:
    shell: bash

env:
  TF_SOURCE_DIR: ./CWICZENIA_TERRAFORM/cwiczenie03/terraform
  TERRAFORM_VERSION: '1.17.2'
  TF_IN_AUTOMATION: 'true'
  TF_INPUT: 'false'
  TF_WORKSPACE: default

jobs:
  provision:
    name: Terraform — infrastruktura i wdrożenie aplikacji
    runs-on: [self-hosted, linux]
    timeout-minutes: 35
    outputs:
      public_ip: ${{ steps.metadata.outputs.public_ip }}
      app_url: ${{ steps.metadata.outputs.app_url }}
      private_key_path: ${{ steps.metadata.outputs.private_key_path }}
      state_directory: ${{ steps.paths.outputs.state_directory }}
      runner_name: ${{ steps.paths.outputs.runner_name }}
    env:
      DIGITALOCEAN_TOKEN: ${{ secrets.DIGITALOCEAN_TOKEN }}
      TF_VAR_vm_name: ${{ vars.VM_NAME }}
      TF_VAR_vpc_name: ${{ vars.VPC_NAME }}
      TF_VAR_firewall_name: ${{ vars.FIREWALL_NAME }}
      TF_VAR_vpc_cidr: ${{ vars.VPC_CIDR }}
      TF_VAR_ssh_allowed_cidr: ${{ vars.SSH_ALLOWED_CIDR }}
      TF_VAR_region: ${{ vars.DO_REGION || 'fra1' }}
      TF_VAR_vm_image: ${{ vars.DO_VM_IMAGE || 'ubuntu-24-04-x64' }}
      TF_VAR_vm_size: ${{ vars.DO_VM_SIZE || 's-1vcpu-1gb' }}
      TF_VAR_image_reference: ${{ vars.DOCKER_IMAGE_REFERENCE || 'piotrskoska/python_pogoda@sha256:ac30d995f5ca10e4c5db5c44d526398c435270ba1194c5987642f7179a224638' }}
      TF_VAR_container_name: ${{ vars.CONTAINER_NAME || 'cw03-pogoda' }}
      TF_VAR_deployment_revision: ${{ vars.DEPLOYMENT_REVISION || '1' }}
      TF_VAR_dockerhub_username: ${{ vars.DOCKERHUB_USERNAME }}
    steps:
      - name: Checkout konfiguracji ucznia
        uses: actions/checkout@v7
        with:
          persist-credentials: false

      - name: Sprawdź dane i przygotuj trwały katalog poza checkoutem
        id: paths
        env:
          REQUESTED_STATE_ROOT: ${{ vars.TF_STATE_ROOT }}
          OPERATION: ${{ inputs.operation }}
          OPENWEATHER_API_KEY: ${{ secrets.OPENWEATHER_API_KEY }}
          DOCKERHUB_TOKEN: ${{ secrets.DOCKERHUB_TOKEN }}
        run: |
          set -euo pipefail
          umask 077
          case "$OPERATION" in
            apply|destroy) ;;
            *) echo "::error::Dozwolone operacje to apply i destroy."; exit 1 ;;
          esac
          for file in versions.tf variables.tf main.tf outputs.tf application.tf files/bootstrap.sh files/deploy.sh.tftpl; do
            if [ ! -f "${TF_SOURCE_DIR}/${file}" ]; then
              echo "::error::Przygotuj i dodaj do Gita ${TF_SOURCE_DIR}/${file} zgodnie z instrukcją CW03."
              exit 1
            fi
          done
          for variable in TF_VAR_vm_name TF_VAR_vpc_name TF_VAR_firewall_name TF_VAR_vpc_cidr TF_VAR_ssh_allowed_cidr; do
            if [ -z "${!variable}" ]; then
              echo "::error::Uzupełnij Repository variables: VM_NAME, VPC_NAME, FIREWALL_NAME, VPC_CIDR i SSH_ALLOWED_CIDR."
              exit 1
            fi
          done
          if [ -z "$DIGITALOCEAN_TOKEN" ]; then
            echo "::error::Utwórz Repository secret DIGITALOCEAN_TOKEN."
            exit 1
          fi
          if [ "$OPERATION" = apply ] && [ -z "$OPENWEATHER_API_KEY" ]; then
            echo "::error::Utwórz Repository secret OPENWEATHER_API_KEY dla wdrożenia aplikacji."
            exit 1
          fi
          if [ "$OPERATION" = apply ]; then
            if { [ -n "$TF_VAR_dockerhub_username" ] && [ -z "$DOCKERHUB_TOKEN" ]; } ||
               { [ -z "$TF_VAR_dockerhub_username" ] && [ -n "$DOCKERHUB_TOKEN" ]; }; then
              echo "::error::Uwierzytelnione pobranie obrazu wymaga pary: variable DOCKERHUB_USERNAME i secret DOCKERHUB_TOKEN."
              exit 1
            fi
          fi
          state_root="${REQUESTED_STATE_ROOT:-${HOME}/terraform-state}"
          if [[ "$state_root" != /* || "$state_root" =~ [[:cntrl:]] ]]; then
            echo "::error::TF_STATE_ROOT musi być bezwzględną ścieżką na trwałym dysku runnera, bez znaków sterujących."
            exit 1
          fi
          state_root="$(realpath -m -- "$state_root")"
          workspace="$(realpath -e -- "$GITHUB_WORKSPACE")"
          runner_temporary="$(realpath -m -- "$RUNNER_TEMP")"
          state_directory="$(realpath -m -- "${state_root}/cwiczenie03/${GITHUB_REPOSITORY_ID}")"
          case "$state_directory/" in
            "$workspace/"*|"$runner_temporary/"*)
              echo "::error::Stan musi znajdować się poza checkoutem i katalogiem tymczasowym joba."
              exit 1
              ;;
          esac
          mkdir -p "${state_directory}/keys" "${state_directory}/plans"
          chmod 700 "$state_directory" "${state_directory}/keys" "${state_directory}/plans"
          state_file="${state_directory}/terraform.tfstate"
          if [ "$OPERATION" = destroy ] && [ ! -s "$state_file" ]; then
            echo "::error::Brak lokalnego state. Nie potwierdzam usunięcia zasobów bez ich stanu; sprawdź host i TF_STATE_ROOT."
            exit 1
          fi
          if [ -f "${state_directory}/.initialized" ] && [ ! -s "$state_file" ]; then
            echo "::error::Zniknął wcześniej używany state. Przywróć go przed kolejnym apply."
            exit 1
          fi
          {
            echo "STATE_DIRECTORY=$state_directory"
            echo "STATE_FILE=$state_file"
            echo "PLAN_FILE=${state_directory}/plans/${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}.tfplan"
            echo "TF_VAR_ssh_private_key_path=${state_directory}/keys/id_ed25519"
          } >> "$GITHUB_ENV"
          {
            echo "state_directory=$state_directory"
            echo "runner_name=$RUNNER_NAME"
          } >> "$GITHUB_OUTPUT"
          echo "Stan CW03 pozostaje na hoście runnera, poza checkoutem: $state_file"

      - name: Zainstaluj Terraform
        uses: hashicorp/setup-terraform@v4
        with:
          terraform_version: ${{ env.TERRAFORM_VERSION }}
          terraform_wrapper: false

      - name: Terraform fmt
        run: terraform -chdir="$TF_SOURCE_DIR" fmt -check

      - name: Terraform init z lokalnym stanem na hoście
        run: |
          umask 077
          terraform -chdir="$TF_SOURCE_DIR" init -input=false -reconfigure \
            -backend-config="path=$STATE_FILE"

      - name: Terraform validate
        run: terraform -chdir="$TF_SOURCE_DIR" validate

      - name: Terraform plan
        env:
          OPERATION: ${{ inputs.operation }}
          # Ephemeral credentials muszą być dostępne podczas plan i apply.
          TF_VAR_openweather_api_key: ${{ secrets.OPENWEATHER_API_KEY }}
          TF_VAR_dockerhub_token: ${{ secrets.DOCKERHUB_TOKEN }}
        run: |
          umask 077
          plan_arguments=()
          if [ "$OPERATION" = destroy ]; then
            plan_arguments+=(-destroy)
          fi
          terraform -chdir="$TF_SOURCE_DIR" plan -input=false \
            "${plan_arguments[@]}" -out="$PLAN_FILE"
          chmod 600 "$PLAN_FILE"

      - name: Terraform apply zapisanego planu
        env:
          TF_VAR_openweather_api_key: ${{ secrets.OPENWEATHER_API_KEY }}
          TF_VAR_dockerhub_token: ${{ secrets.DOCKERHUB_TOKEN }}
        run: |
          umask 077
          terraform -chdir="$TF_SOURCE_DIR" apply -input=false "$PLAN_FILE"
          test -s "$STATE_FILE"
          for file in "$STATE_FILE" "${STATE_FILE}.backup"; do
            if [ -f "$file" ]; then
              chmod 600 "$file"
            fi
          done
          printf '%s\n' 'cwiczenie03' > "${STATE_DIRECTORY}/.initialized"

      - name: Udostępnij IP i ścieżkę klucza, bez jego zawartości
        id: metadata
        if: ${{ inputs.operation == 'apply' }}
        run: |
          public_ip="$(terraform -chdir="$TF_SOURCE_DIR" output -raw public_ip)"
          app_url="$(terraform -chdir="$TF_SOURCE_DIR" output -raw app_url)"
          private_key_path="$(terraform -chdir="$TF_SOURCE_DIR" output -raw private_key_path)"
          [[ "$public_ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]
          test "$app_url" = "http://${public_ip}"
          test "$private_key_path" = "${STATE_DIRECTORY}/keys/id_ed25519"
          test -s "$private_key_path"
          {
            echo "public_ip=$public_ip"
            echo "app_url=$app_url"
            echo "private_key_path=$private_key_path"
          } >> "$GITHUB_OUTPUT"

      - name: Podsumuj wynik Terraform
        env:
          OPERATION: ${{ inputs.operation }}
          PUBLIC_IP: ${{ steps.metadata.outputs.public_ip }}
          APP_URL: ${{ steps.metadata.outputs.app_url }}
        run: |
          {
            echo "### CW03 — Terraform $OPERATION"
            echo ""
            echo "- Runner: $RUNNER_NAME"
            echo "- Lokalny state: $STATE_FILE"
            if [ "$OPERATION" = apply ]; then
              echo "- Publiczny IPv4 nowej VM: $PUBLIC_IP"
              echo "- WWW i API przez Nginx na porcie 80: $APP_URL"
              echo "- Kontener dostępny lokalnie na VM: 127.0.0.1:18080 → 8080"
              echo "- Porty publiczne TCP: 80, 443, 18000–18999"
              echo "- SSH: 22 wyłącznie z adresu runnera; osobny job sprawdzi SSH oraz WWW/API."
            else
              echo "- Usunięto zasoby z lokalnego state tego ćwiczenia."
            fi
          } >> "$GITHUB_STEP_SUMMARY"

      - name: Usuń tylko plan tego przebiegu, zachowaj state
        if: always()
        run: |
          if [ -n "${PLAN_FILE:-}" ] && [ -n "${STATE_DIRECTORY:-}" ]; then
            expected_plan="${STATE_DIRECTORY}/plans/${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}.tfplan"
            if [ "$PLAN_FILE" = "$expected_plan" ]; then
              rm -f -- "$PLAN_FILE"
            fi
          fi

  check-app:
    name: Sprawdź SSH, Nginx i prawdziwe WWW/API
    needs: provision
    if: ${{ inputs.operation == 'apply' }}
    runs-on: [self-hosted, linux]
    timeout-minutes: 10
    env:
      PUBLIC_IP: ${{ needs.provision.outputs.public_ip }}
      PRIVATE_KEY_PATH: ${{ needs.provision.outputs.private_key_path }}
      STATE_DIRECTORY: ${{ needs.provision.outputs.state_directory }}
      PROVISION_RUNNER_NAME: ${{ needs.provision.outputs.runner_name }}
      APP_URL: ${{ needs.provision.outputs.app_url }}
      WEATHER_CITY: ${{ vars.WEATHER_CITY || 'Warsaw' }}
    steps:
      - name: Checkout gotowego testu aplikacji
        uses: actions/checkout@v7
        with:
          persist-credentials: false

      - name: Sprawdź host oraz trwały plik klucza
        run: |
          set -euo pipefail
          umask 077
          if [ "$RUNNER_NAME" != "$PROVISION_RUNNER_NAME" ]; then
            echo "::error::Oba joby wymagają tego samego runnera i dysku. Pozostaw jednego pasującego runnera albo skonfiguruj wspólną unikalną etykietę."
            exit 1
          fi
          [[ "$PUBLIC_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]
          test "$APP_URL" = "http://${PUBLIC_IP}"
          test "$PRIVATE_KEY_PATH" = "${STATE_DIRECTORY}/keys/id_ed25519"
          test -s "$PRIVATE_KEY_PATH"
          test ! -L "$PRIVATE_KEY_PATH"
          test "$(stat -c '%u' "$PRIVATE_KEY_PATH")" = "$(id -u)"
          test "$(stat -c '%a' "$PRIVATE_KEY_PATH")" = 600
          command -v ssh
          command -v python3
          command -v curl

      - name: Potwierdź przez SSH Docker, Nginx i gotowość kontenera
        run: |
          umask 077
          for attempt in $(seq 1 30); do
            echo "Próba SSH ${attempt}/30 do $PUBLIC_IP"
            if ssh -i "$PRIVATE_KEY_PATH" \
              -o BatchMode=yes -o PasswordAuthentication=no -o IdentitiesOnly=yes \
              -o ConnectTimeout=5 -o ConnectionAttempts=1 \
              -o StrictHostKeyChecking=accept-new \
              -o "UserKnownHostsFile=${STATE_DIRECTORY}/known_hosts" \
              "root@${PUBLIC_IP}" \
              'set -eu; test "$(id -u)" -eq 0; hostname; systemctl is-active docker nginx; nginx -t; curl --fail --silent --show-error --output /dev/null http://127.0.0.1:18080/healthz'; then
              echo "SSH_OK — logowanie, usługi Docker/Nginx i lokalny kontener działają."
              exit 0
            fi
            if [ "$attempt" -lt 30 ]; then
              sleep 5
            fi
          done
          echo "::error::Nie udało się zalogować kluczem SSH. Sprawdź SSH_ALLOWED_CIDR, host runnera, firewall, klucz i known_hosts."
          exit 1

      - name: Sprawdź publiczny Nginx i prawdziwe API pogodowe
        run: |
          curl --fail --silent --show-error \
            --retry 15 --retry-all-errors --retry-delay 2 \
            --retry-max-time 60 --max-time 5 \
            --output /dev/null "${APP_URL}/healthz"
          python3 ./CWICZENIA_TERRAFORM/cwiczenie03/tests/smoke_test.py \
            --base-url "$APP_URL" --city "$WEATHER_CITY"
          {
            echo "### CW03 — aplikacja sprawdzona przez Nginx"
            echo ""
            echo "- WWW: $APP_URL/"
            echo "- API: $APP_URL/api/weather?city=Warsaw"
            echo "- Potwierdzono: SSH, Docker, Nginx, WWW i rzeczywistą pogodę z OpenWeatherMap."
          } >> "$GITHUB_STEP_SUMMARY"
````

### Plik: `CWICZENIA_TERRAFORM/cwiczenie03/tests/smoke_test.py`

Teraz utwórz gotowy test uruchamiany przez `check-app`; nie wpisuj do niego klucza API.

````python
#!/usr/bin/env python3
"""Test działającego kontenera: WWW, zasoby, health i prawdziwa pogoda z API.

Nie przyjmuje klucza ani danych przykładowych. Klucz jest wyłącznie w kontenerze.
Każdy błąd dostawcy, w tym zły klucz API, kończy test niepowodzeniem.
"""

from __future__ import annotations

import argparse
import json
import math
import ssl
import sys
import urllib.error
import urllib.parse
import urllib.request


def verify(base_url: str, city: str, ca_file: str | None = None) -> dict:
    context = ssl.create_default_context(cafile=ca_file)
    base = base_url.rstrip("/")
    parsed = urllib.parse.urlsplit(base)
    if parsed.scheme not in ("http", "https") or not parsed.hostname or parsed.username or parsed.password:
        raise ValueError("Podaj poprawny adres HTTP/HTTPS bez danych logowania.")

    def get(path: str, as_json: bool = False):
        request = urllib.request.Request(base + path, headers={"Accept": "application/json" if as_json else "*/*"})
        with urllib.request.urlopen(request, context=context, timeout=30) as response:
            if response.status != 200:
                raise ValueError("Nieoczekiwany status HTTP aplikacji.")
            content = response.read().decode("utf-8")
        return json.loads(content) if as_json else content

    if get("/healthz", True).get("status") != "ok":
        raise ValueError("Kontrola healthz nie potwierdziła gotowości aplikacji.")
    if 'id="weather-form"' not in get("/"):
        raise ValueError("Interfejs WWW nie zawiera formularza miasta.")
    for asset in ("/static/styles.css", "/static/app.js"):
        if not get(asset).strip():
            raise ValueError("Brakuje zasobu interfejsu WWW.")
    schema = get("/openapi.json", True)
    parameters = schema["paths"]["/api/weather"]["get"]["parameters"]
    if {parameter["name"] for parameter in parameters if parameter["in"] == "query"} != {"city"}:
        raise ValueError("API ma przyjmować wyłącznie miasto, bez klucza w URL.")

    weather = get("/api/weather?" + urllib.parse.urlencode({"city": city}), True)
    if weather.get("source") != "openweathermap" or weather.get("units") != "metric":
        raise ValueError("Brak potwierdzonej odpowiedzi pogodowej OpenWeatherMap.")
    if not isinstance(weather.get("city"), str) or not weather["city"].strip():
        raise ValueError("Odpowiedź pogodowa nie zawiera miasta.")
    for name in ("temperature", "feels_like", "humidity", "pressure", "wind_speed"):
        value = weather.get(name)
        if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value):
            raise ValueError("Odpowiedź pogodowa nie zawiera kompletnych pomiarów.")
    if not isinstance(weather.get("observed_at"), int) or weather["observed_at"] <= 0:
        raise ValueError("Brakuje czasu pomiaru pogody.")
    return weather


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-url", required=True)
    parser.add_argument("--city", default="Warsaw")
    parser.add_argument("--ca-file", help="Zaufany certyfikat CA dla opcjonalnego HTTPS")
    args = parser.parse_args()
    try:
        weather = verify(args.base_url, args.city, args.ca_file)
    except urllib.error.HTTPError as error:
        print(f"TEST NIEUDANY: aplikacja zwróciła HTTP {error.code}. Sprawdź konfigurację i dostępność dostawcy.", file=sys.stderr)
        return 1
    except (OSError, ValueError, KeyError, TypeError, AttributeError, ssl.SSLError, urllib.error.URLError):
        print("TEST NIEUDANY: niepoprawna odpowiedź, brak WWW/API albo błąd połączenia.", file=sys.stderr)
        return 1
    print(f"OPENWEATHER_OK: {weather['city']}, {weather['temperature']} °C; WWW i API działają.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
````
