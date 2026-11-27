# Ćwiczenie 03 — Terraform uruchamia aplikację Docker za Nginxem

Rozszerz własną konfigurację z ćwiczenia 02. Terraform ma utworzyć VM
DigitalOcean, zainstalować Docker i Nginx oraz uruchomić gotową aplikację
pogodową. GitHub Actions uruchamia Terraform, a osobny job sprawdza SSH,
WWW i prawdziwe API. Kod aplikacji i budowanie obrazu nie są częścią zadania.

Docelowa droga żądania:

```text
Użytkownik → http://PUBLICZNY_IP:80 → Nginx na VM
             → 127.0.0.1:18080 na VM → kontener:8080
```

## 1. Przygotuj runner i oddzielne zasoby ćwiczenia

Teraz wykorzystaj ten sam jeden aktywny runner Linux z ćwiczenia 02,
z etykietami `self-hosted` i `linux`, trwałym dyskiem i agentem co najmniej
`2.327.1`.
Sposób rejestracji i wymagane narzędzia znajdziesz w
[instrukcji ćwiczenia 02](../cwiczenie02/README.md).

Teraz sprawdź dodatkowo Python 3 i `curl` na hoście agenta. Są potrzebne
do testu HTTP uruchamianego z runnera:

```bash
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

## 5. Skopiuj własne źródła Terraform z CW02

Teraz utwórz publiczny katalog `CWICZENIA_TERRAFORM/cwiczenie03/terraform`.
Skopiuj do niego własne `versions.tf`, `variables.tf`, `main.tf`, `outputs.tf`
i `.terraform.lock.hcl` z ćwiczenia 02. Dodaj niesekretny przykład `.tfvars`,
który pozostanie przykładem, nie rzeczywistą konfiguracją sekretów.

Teraz zachowaj lokalny backend i zmienną `ssh_private_key_path` z CW02.
Podnieś minimalną wersję Terraform do `1.10`, potrzebnej do wartości
`ephemeral` w provisionerach. State tego ćwiczenia ma osobną lokalizację:

```text
<HOME_konta_agenta>/terraform-state/cwiczenie03/<GITHUB_REPOSITORY_ID>/terraform.tfstate
```

Pipeline dołącza `cwiczenie03/<GITHUB_REPOSITORY_ID>` do `TF_STATE_ROOT`.
Klucz zapisz w `keys/id_ed25519` obok tego state, z prawami `0600`.
Nie wskazuj nowego workflow na state CW02 i nie przenoś go tam na ślepo.

## 6. Dodaj zmienne aplikacji i sekret ephemeral

Teraz w `variables.tf` dodaj:

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

Teraz utwórz w publicznym katalogu `terraform` trzy pliki:

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

W firewallu zachowaj SSH `22` wyłącznie z `/32` agenta oraz publiczne TCP
`80`, `443` i `18000-18999` z CW02. Kontener mimo otwartej reguły zakresu
jest przypisany tylko do `127.0.0.1:18080`, więc użytkownik wchodzi przez
Nginxa pod `http://PUBLICZNY_IP/`, a nie bezpośrednio pod port `18080`.

Teraz dodaj output `app_url` z adresem `http://<publiczny_IP_VM>`.
Możesz także wystawić jawny output `image_reference`. Nie potrzebujesz
domeny, aby otworzyć adres aplikacji.

## 10. Udostępnij wszystkie źródła potrzebne runnerowi

Teraz dodaj do repozytorium pliki `.tf`, `.terraform.lock.hcl`, niesekretny
przykład wartości i **oba pliki w `terraform/files`**.
Runner nie ma dostępu do Twoich lokalnych nieopublikowanych plików ani
ignorowanego rozwiązania instruktora.

Nie dodawaj state, planów, `.keys/`, prawdziwych `.tfvars`, tokenów ani
klucza API. Dostarczony test w `tests/smoke_test.py` pozostaje zwykłym plikiem
źródłowym w katalogu CW03 — nie musisz pisać Pythona.

## 11. Przygotuj workflow provision i check-app

Teraz otwórz
[.github/workflows/terraform-cwiczenie03.yaml](../../.github/workflows/terraform-cwiczenie03.yaml).
To pełny plik GitHub Actions do tego zadania; kolejne kroki opisują jego
konfigurację i powiązanie z Twoim kodem Terraform.
Zachowaj z CW02 ręczny input `operation: apply|destroy`, jedno wspólne
`concurrency` repozytorium z `cancel-in-progress: false` i runner
`[self-hosted, linux]` dla obu jobów.

Job `provision` ma sprawdzić obecność źródeł ucznia, wyliczyć katalog state
CW03, przygotować Terraform `1.17.2` przez `hashicorp/setup-terraform@v4`
z `terraform_wrapper: false`, a następnie wykonać `fmt`, `init`, `validate`,
zapisany `plan` oraz `apply` planu.
Dla destroy użyj planu `-destroy`, tego samego katalogu state i tego samego
pliku prywatnego klucza. Zachowaj kontrolę utraconego state z CW02.

Teraz przekaż zmienne aplikacji przez środowisko:

| Zmienna procesu | Źródło |
| --- | --- |
| `TF_VAR_image_reference` | `vars.DOCKER_IMAGE_REFERENCE` lub domyślny digest |
| `TF_VAR_container_name` | `vars.CONTAINER_NAME` lub `cw03-pogoda` |
| `TF_VAR_deployment_revision` | `vars.DEPLOYMENT_REVISION` lub `1` |
| `TF_VAR_openweather_api_key` | `secrets.OPENWEATHER_API_KEY` |
| `TF_VAR_dockerhub_username` | Opcjonalne `vars.DOCKERHUB_USERNAME` |
| `TF_VAR_dockerhub_token` | Opcjonalne `secrets.DOCKERHUB_TOKEN` |

Wartości DO i ścieżkę pliku klucza przekaż jak w CW02. Sekrety podaj do plan
oraz apply, bez flag zawierających ich wartości w linii poleceń.
Sam deploy wykonuje Terraform; nie dodawaj obok niezależnego kroku GHA
z `docker run` przez SSH.

Odczytaj tylko `public_ip`, `private_key_path` i `app_url` jako metadane dla
kolejnego joba. Przekaż także znane z CW02 `state_directory` i `runner_name`.
Nie wypisuj wszystkich outputów przez `terraform output -json`.
Plan danego przebiegu usuń na końcu, ale zachowaj state i klucz.

## 12. Sprawdź SSH, WWW i prawdziwą pogodę w drugim jobie

Teraz przygotuj job `check-app` z `needs: provision`, uruchamiany tylko dla
`apply`. Sprawdź nazwę runnera i trwały plik klucza jak w CW02.
Dodaj checkout, aby runner otrzymał dostarczony test Pythona. Klucz pozostaje
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

Teraz zapisz workflow, własne źródła Terraform, template'y i dostarczony
test w repozytorium. Udostępnij workflow także na domyślnej gałęzi,
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
