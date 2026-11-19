# FAZA-4 — Terraform i deploy aplikacji na DigitalOcean

## Cel ćwiczenia

Rozszerz pipeline z [FAZY-3](../FAZA-3/README.md). Środowisko `test` nadal
działa jako kontener na dotychczasowym self-hosted runnerze. Dla `dev` i `prod`
utwórz po jednej VM DigitalOcean i udostępnij WWW oraz API pod adresami
`http://<IP_VM>/`, bez konfigurowania domeny.

Kod Terraform jest gotowy. Twoim zadaniem jest skonfigurowanie GitHub Actions,
sekretów i runnera oraz uruchomienie pipeline; nie musisz pisać zasobów
Terraform od początku. Terraform wygeneruje również oddzielne pary kluczy
SSH dla `dev` i `prod` — nie przygotowujesz ich ręcznie.

| Przygotowany plik lub katalog | Zastosowanie |
| --- | --- |
| [15A-FAZA4-pogoda.yaml](../../../.github/workflows/15A-FAZA4-pogoda.yaml) | Gotowy workflow w `.github/workflows/` |
| [terraform/](terraform/) | Wspólny kod infrastruktury dla `dev` i `prod` |
| [terraform/application.tf](terraform/application.tf) | Deploy kontenera przez `terraform_data` i provisionery `remote-exec` |

Joby infrastruktury działają na jednym self-hosted runnerze i wykonują
Terraform, który tworzy zasoby przez API DigitalOcean i w tym samym `apply`
uruchamia aplikację na VM przez SSH, za pomocą `remote-exec`. To deploy
wykonywany przez Terraform, bez Ansible i bez osobnego skryptu Python
sterującego kontenerem. Build, test, publikację oraz końcową publiczną
weryfikację WWW/API realizują joby GitHub Actions. Ścieżki, zmienne i metadane
przygotowują bezpośrednio kroki YAML, używając Bash oraz `jq`.
Ręczne usuwanie infrastruktury również wykonują polecenia Terraform w YAML.

**Dopiero uruchomienie joba `apply` przez słuchacza tworzy płatne zasoby
DigitalOcean.** Samo przygotowanie plików lub `terraform validate` ich nie tworzy.

## Krok 1. Sprawdź układ środowisk

| Environment | Miejsce działania | Tag obrazu | Adres aplikacji |
| --- | --- | --- | --- |
| `test` | Obecny self-hosted runner | `faza3-test` | `http://<IP_RUNNERA>:18093/` |
| `dev` | Osobny Droplet DigitalOcean | `faza4-dev` | `http://<IP_VM_DEV>/` |
| `prod` | Osobny Droplet DigitalOcean | `faza4-prod` | `http://<IP_VM_PROD>/` |

Wspólne repozytorium obrazu to `piotrskoska/python_pogoda`. Login i nazwę obrazu
możesz zastąpić własnymi w Repository variables.

Pipeline zachowuje jeden build i jeden rzeczywisty test CI. Publikacja używa
`matrix` dla `test`, `dev`, `prod`; infrastruktura i zdalny deploy używają
macierzy `dev`, `prod`. `test` nie otrzymuje Dropleta ani stanu Terraform.
Na VM port hosta `80` kieruje do Nginxa na `8080` wewnątrz kontenera.

## Krok 2. Przygotuj self-hosted runner

1. W **Settings → Actions → Runners** sprawdź, czy Twój runner Linux jest
   dostępny jako **Idle**.
2. W tym ćwiczeniu korzystaj z jednego self-hosted runnera Linux, na którego
   dysku pozostaje stan Terraform. Dodatkowa etykieta nie jest potrzebna.
3. Sprawdź, czy konto usługi runnera ma dostęp do Dockera i poleceń `git`,
   `python3`, `curl`, `unzip`, `jq` oraz narzędzi GNU: `realpath`, `stat`,
   `sha256sum` i `cmp`. Python jest nadal używany przez rzeczywisty test aplikacji.
4. Dopuść połączenia wychodzące HTTPS do GitHub, rejestru Terraform,
   DigitalOcean i Docker Hub, HTTP do aplikacji na VM oraz SSH do VM na `22`.
5. Ustal **publiczny IPv4, z którego runner wychodzi do Internetu**. Jeśli
   działa za NAT, potrzebujesz adresu NAT, a nie lokalnego `192.168.x.x`.
   Użyjesz go jako `FAZA4_SSH_ALLOWED_CIDR`, zwykle z maską `/32`.

Joby infrastruktury mają:

```yaml
runs-on: [self-hosted, linux]
```

Konfiguracja używa Twojego jednego runnera Linux. Kolejne joby odczytują
lokalne pliki z jego dysku, dlatego muszą działać na tym samym komputerze.
Build i test nadal korzystają z `ubuntu-latest`.

Na runnerze Ubuntu/Debian brakujące narzędzia JSON i plikowe zainstalujesz
jednorazowo przez:

```bash
sudo apt-get update
sudo apt-get install -y jq coreutils diffutils
command -v jq realpath stat sha256sum cmp
```

`jq` odczytuje metadane obrazu oraz buduje niesekretne pliki JSON Terraform.
`coreutils` dostarcza m.in. `realpath`, `stat` i `sha256sum`; `cmp` pochodzi
z `diffutils`. Workflow sprawdza dostępność wymaganych poleceń przed pracą
z trwałym katalogiem stanu.

## Krok 3. Przygotuj trwały katalog stanu

Zaloguj się na runnera i wykonaj polecenia **jako konto usługi runnera**,
np. `student`. To jednorazowe przygotowanie katalogu na hoście:

```bash
install -d -m 0700 "$HOME/terraform-state/pogoda-faza4"
touch "$HOME/terraform-state/pogoda-faza4/.faza4-state-root"
chmod 0600 "$HOME/terraform-state/pogoda-faza4/.faza4-state-root"
```

Jeżeli katalog domowy konta runnera to `/home/student`, wartością
`FAZA4_STATE_ROOT` będzie `/home/student/terraform-state/pogoda-faza4`.
W GitHub wpisz pełną ścieżkę. Wartości `~` i `$HOME` nie są tam automatycznie
rozwijane przez powłokę.

Katalog musi leżeć na trwałym dysku, poza checkoutem repozytorium, `_work`
i `RUNNER_TEMP`. Plik `.faza4-state-root` oznacza świadomie przygotowaną
lokalizację. Workflow sprawdza go przed rozpoczęciem pracy.

Stan jest rozdzielony przez repozytorium, nazwę słuchacza i workspace:

```text
/home/student/terraform-state/pogoda-faza4/
├── .faza4-state-root
└── <repository_id>/
    └── jan-kowalski/
        ├── workspaces/
        │   ├── dev/terraform.tfstate
        │   └── prod/terraform.tfstate
        └── runs/<run_id>/...
```

`<repository_id>` i `<run_id>` uzupełnia GitHub Actions. Nie wpisujesz ich
w zmiennych. Backend `local` przechowuje stan na dysku i używa blokady
systemowej. [Dokumentacja local backend](https://developer.hashicorp.com/terraform/language/backend/local).

**Pliki stanu i zapisane plany zawierają prywatne klucze SSH wygenerowane
przez Terraform.** Dlatego katalog ma prawa `0700`, a plików nie wolno
drukować w logach, dodawać do Git ani uploadować jako artefaktów GitHub.
Oznaczenie outputu jako `sensitive` ukrywa go w zwykłym podglądzie, ale
nie szyfruje lokalnego stanu ani planu. Dostęp do runnera i kopii zapasowych
oznacza również dostęp do tych kluczy.

## Krok 4. Dodaj Repository variables

W **Settings → Secrets and variables → Actions → Variables** ustaw:

| Repository variable | Wartość początkowa | Znaczenie |
| --- | --- | --- |
| `DOCKERHUB_USERNAME` | `piotrskoska` | Konto publikujące obrazy |
| `DOCKER_IMAGE_NAME` | `python_pogoda` | Repozytorium obrazu |
| `FAZA4_DEPLOY_BRANCH` | `main` | Gałąź dopuszczona do publikacji i deploya |
| `FAZA4_WEATHER_CITY` | `Warsaw` | Miasto wspólnego testu CI |
| `FAZA4_STATE_ROOT` | `/home/student/terraform-state/pogoda-faza4` | Pełna ścieżka przygotowana w kroku 3; dostosuj do konta runnera |
| `FAZA4_STUDENT_NAME` | `jan-kowalski` | Twoje imię i nazwisko małymi literami, bez polskich znaków i ze spacją zastąpioną myślnikiem |
| `FAZA4_REGION` | `fra1` | Region DigitalOcean dostępny na koncie |
| `FAZA4_DROPLET_SIZE` | `s-1vcpu-1gb` | Rozmiar VM dostępny w tym regionie |
| `FAZA4_SSH_ALLOWED_CIDR` | `<PUBLICZNY_IPV4_RUNNERA>/32` | Rzeczywisty adres wyjściowy runnera z maską |

`203.0.113.10/32` to przykład zapisu CIDR, a nie gotowa wartość Twojego runnera.
Zastąp także `jan-kowalski` swoim identyfikatorem. Nazwy VM będą miały postać
`jan-kowalski-pogoda-f4-dev-<6_znaków>` oraz
`jan-kowalski-pogoda-f4-prod-<6_znaków>`. Losowy sufiks jest generowany jeden
raz i zachowywany w stanie; zwykły kolejny przebieg go nie zmienia.
Nazwy rejestrowanych kluczy publicznych oraz firewalli również zawierają
identyfikator słuchacza, środowisko i ten sufiks.

Nie twórz nowych sieci na potrzeby ćwiczenia. Kod używa istniejącej domyślnej
VPC wybranego regionu. Konto musi mieć ją dostępną; w razie jej braku wybierz
z prowadzącym region z gotową siecią.

Po pierwszym wdrożeniu nie zmieniaj `FAZA4_STATE_ROOT` ani
`FAZA4_STUDENT_NAME` jako sposobu wykonania kolejnego deploya — wskazałoby
to inny stan. Zmiana regionu, nazwy lub klucza może wymagać odtworzenia zasobów;
oceniaj wtedy wynik `plan`.

## Krok 5. Dodaj Repository secrets

W **Settings → Secrets and variables → Actions → Secrets** ustaw:

| Repository secret | Wartość |
| --- | --- |
| `DIGITALOCEAN_TOKEN` | Przekazany przez prowadzącego token API DigitalOcean z uprawnieniami do infrastruktury tego ćwiczenia |
| `DOCKERHUB_TOKEN` | Token Docker Hub z prawem publikacji i pobierania obrazu |
| `OPENWEATHER_API_KEY` | Aktywny, prawdziwy klucz API OpenWeatherMap |

Nie zapisuj wartości tokenów w YAML, Terraform, Markdown ani w repozytorium.
Token DigitalOcean jest dostępny providerowi jako `DIGITALOCEAN_TOKEN`,
bez przekazywania w `tfvars`.
[Konfiguracja providera](https://github.com/digitalocean/terraform-provider-digitalocean/blob/main/docs/index.md).

Token musi pozwalać odczytywać, tworzyć, aktualizować i usuwać Droplety,
firewalle i klucze SSH oraz odczytywać potrzebne informacje o regionach,
obrazach, rozmiarach i istniejącej sieci. Przy tokenie z ograniczonym zakresem
prowadzący powinien dopasować uprawnienia do tych zasobów. Token tylko
do odczytu nie wykona `apply`.
[Zakresy API DigitalOcean](https://docs.digitalocean.com/reference/api/scopes/).

Klucz pogodowy na poziomie repozytorium jest nadal wymagany: wspólny test CI
nie ma GitHub Environment i nie odczyta samego sekretu z `dev` lub `prod`.

## Krok 6. Skonfiguruj GitHub Environments

W **Settings → Environments** wykorzystaj `test`, `dev` i `prod`. Jeżeli ich
nie ma, utwórz je przez **New environment**. Zachowaj istniejące reguły dostępu
i dopuść gałąź wskazaną w `FAZA4_DEPLOY_BRANCH`.

W Environment `test` zachowaj zmienne FAZY-3:

| Environment variable | `test` |
| --- | --- |
| `FAZA3_IMAGE_TAG` | `faza3-test` |
| `FAZA3_APP_PORT` | `18093` |
| `FAZA3_CONTAINER_NAME` | `pogoda_api_faza3_test` |
| `FAZA3_WEATHER_CITY` | `Warsaw` |

W Environments `dev` i `prod` dodaj:

| Environment variable | `dev` | `prod` |
| --- | --- | --- |
| `FAZA4_IMAGE_TAG` | `faza4-dev` | `faza4-prod` |
| `FAZA4_WEATHER_CITY` | `Warsaw` | `Warsaw` |

Dla VM nie ustawiasz zmiennych portu, nazwy kontenera, IP ani ścieżki workspace.
Port HTTP to `80`, nazwa kontenera wynika ze środowiska, a IP zwraca Terraform.

Opcjonalnie ustaw różne `DOCKERHUB_TOKEN` i `OPENWEATHER_API_KEY`
w Environment `test`, `dev`, `prod`, nadpisując sekrety repozytorium.
Token DigitalOcean jest potrzebny tylko jobom infrastruktury `dev` i `prod`.
Klucze SSH wygeneruje Terraform; nie dodawaj sekretu `DO_SSH_PRIVATE_KEY`.
Istniejące reguły zatwierdzania Environment mogą wstrzymywać joby; pipeline
ich nie omija.

Możesz dodatkowo ustawić Environment variable **`FAZA4_SSH_HOST_KEY`**
osobno w `dev` i `prod`. Wartością jest zaufany **publiczny klucz serwera SSH
danej VM**, np. pełna linia `ssh-ed25519 AAAA...`, uzyskana z konsoli VM
lub wcześniej zweryfikowanego wpisu `known_hosts`. Nie wpisuj przykładowego
`AAAA...` jako rzeczywistej wartości. To klucz hosta VM, a nie publiczna część
pary logowania generowanej przez Terraform.

Jeżeli zmienna jest pusta, natywne połączenie SSH provisionera Terraform
**nie weryfikuje klucza serwera**. Taki jest domyślny wariant laboratoryjny
tej konfiguracji; nie korzysta on automatycznie z wcześniejszego `known_hosts`
ani mechanizmu `accept-new`. Podanie zaufanego `FAZA4_SSH_HOST_KEY` włącza
weryfikację przez `connection.host_key`. Po odtworzeniu VM klucz hosta może
się zmienić — zweryfikuj nową wartość przed kolejnym deployem.
[Połączenia provisionerów Terraform](https://developer.hashicorp.com/terraform/language/provisioners).

## Krok 7. Sprawdź automatyczne generowanie kluczy SSH

1. W gotowym Terraform znajdź zasób `tls_private_key` używający `ED25519`.
2. Każdy workspace otrzyma własną parę kluczy. Terraform zarejestruje
   publiczną część w DigitalOcean i przypisze ją właściwej VM.
3. Nie uruchamiaj ręcznie `ssh-keygen`, nie wgrywaj kluczy do DigitalOcean
   i nie twórz GitHub Secret z prywatnym kluczem.
4. Zachowaj stan każdego workspace: przechowuje zarówno identyfikatory
   infrastruktury, losowy sufiks nazw, jak i wygenerowaną parę kluczy.

Zwykły kolejny przebieg wykorzystuje istniejące klucze ze stanu.
`connection.private_key` provisionera odczytuje wygenerowaną prywatną część
bezpośrednio w Terraform. Workflow nie eksportuje jej do osobnego pliku SSH.
Nie wykonuj `terraform output -json` dla wszystkich outputów: taka komenda
mogłaby ujawnić klucz również pomimo oznaczenia `sensitive`.

Klucz prywatny pozostaje w chronionym stanie i może być również zawarty
w zapisanym planie. Następny deploy ma ponownie skorzystać z tej samej pary.
Token Docker Hub i klucz OpenWeather są obsługiwane inaczej: provisioner
otrzymuje je jako zmienne `ephemeral` i `sensitive`, bez utrwalania w stanie
lub pliku planu.

## Krok 8. Sprawdź workflow w katalogu GitHub Actions

1. Pozostaw kod Terraform i tę instrukcję w katalogu `FAZA-4`.
2. Otwórz gotowy [workflow](../../../.github/workflows/15A-FAZA4-pogoda.yaml).
   Plik znajduje się już w `.github/workflows/15A-FAZA4-pogoda.yaml`.
3. Zatwierdź materiał ćwiczenia i plik workflow w swoim repozytorium,
   a następnie wyślij na gałąź `main` lub skonfigurowaną gałąź ćwiczenia.
   Aby pojawił się **Run workflow**, plik z `workflow_dispatch` powinien być
   obecny na domyślnej gałęzi repozytorium.
4. W **Actions** wyłącz wcześniejsze workflow FAZ 1–3 przez
   **… → Disable workflow**, jeśli ćwiczenia nie mają już działać równolegle.
   Ich filtry również reagują na zmiany aplikacji i mogłyby wykonywać kolejne
   publikacje lub deploye `test`.

GitHub odczytuje workflow z `.github/workflows/`. Edytuj bezpośrednio ten plik;
kod Terraform i instrukcja pozostają w `FAZA-4`.

## Krok 9. Zachowaj wspólny build, cache i rzeczywisty test

1. `build` buduje aplikację z
   `CWICZENIA/15A-Cwiczenia-pipeline-gha/pogoda_python_flusk` na `ubuntu-latest`.
2. Używa cache warstw BuildKit z GitHub Actions i stałym scope FAZY-4.
3. Nie otrzymuje klucza pogody ani tokenu DigitalOcean. Zapisuje obraz jako
   artefakt dla dalszych jobów.
4. `test` ładuje ten obraz i uruchamia kontener z prawdziwym
   `OPENWEATHER_API_KEY`, przekazanym dopiero do `docker run`.
5. Sprawdza WWW i API, wykonując prawdziwe zapytanie o pogodę.
6. Po teście usuwa kontener CI, także przy błędzie.

Nie zastępuj rzeczywistego testu samym sprawdzeniem, czy obraz się zbudował.
Zasady cache są takie jak w [FAZIE-2](../FAZA-2/README.md).

## Krok 10. Opublikuj przetestowany obraz dla trzech Environments

Job publikacji ma matrix z `test`, `dev`, `prod` oraz pole
`environment: ${{ matrix.environment }}`.

1. Każdy wariant pobiera ten sam przetestowany obraz.
2. Odczytuje tag: `FAZA3_IMAGE_TAG` dla `test`, `FAZA4_IMAGE_TAG` dla `dev` i `prod`.
3. Loguje się do Docker Hub przez `DOCKERHUB_TOKEN` i publikuje bez przebudowy.
4. Zapisuje oddzielne metadane środowiska z digestem `sha256`.

Deploy uruchomi obraz po digescie, a nie po ruchomym tagu. Oddzielne artefakty
unikają nadpisywania wspólnego outputu przez warianty macierzy.
[Matrix i artefakty w dokumentacji GitHub](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations).

## Krok 11. Wykonaj `init` jako osobny job

Job infrastruktury `init` działa przez matrix dla `dev` i `prod`, na Twoim
self-hosted runnerze Linux i z właściwym GitHub Environment.

1. Udostępnia Terraform `1.17.2` przez `hashicorp/setup-terraform@v3`.
2. Sprawdza katalog stanu i przygotowuje trwałe pliki robocze bieżącego
   przebiegu poza checkoutem.
3. Pobiera metadane opublikowanego obrazu swojego środowiska i sprawdza ich
   zgodność z tagiem, commitem oraz bieżącym przebiegiem w kroku Bash z `jq`.
4. Korzysta z tego samego kodu z checkoutu i przygotowuje zmienne niesekretne:
   środowisko, identyfikator słuchacza, region, rozmiar VM, CIDR SSH,
   `image_reference` z digestem, login Docker Hub i `deployment_id`
   bieżącego przebiegu. Opcjonalnie dodaje zaufany `ssh_host_key`.
   Tworzy plik `tfvars` przez `jq`, zapisuje jego sumę SHA256 i identyfikator
   commita, aby dalsze joby użyły tych samych wejść.
5. Konfiguruje backend `local`, wskazując `workspace_dir` na trwały katalog
   `workspaces` tego repozytorium i słuchacza.
6. Wykonuje `terraform init` oraz `terraform workspace select -or-create`
   dla `dev` albo `prod`.
7. Pierwsze `init` pobiera przypięte wersje providerów i tworzy lockfile.
   Pipeline zachowuje `.terraform.lock.hcl` przy trwałym `TF_DATA_DIR` danego
   środowiska i odtwarza go po checkoutach następnych jobów. Dzięki temu
   czyszczenie checkoutu nie usuwa informacji potrzebnych do `validate`,
   `plan` i `apply`.

Workspace Terraform i GitHub Environment to dwa mechanizmy. Environment
wybiera konfigurację i sekrety joba; workspace wybiera stan tego samego kodu
Terraform. W tym ćwiczeniu nazwy odpowiadają sobie. Operacje infrastruktury
na workspace `default` są blokowane.

`TF_DATA_DIR` jest oddzielny dla środowiska i przebiegu, w `runs/<run_id>/...`,
a nie w checkoutowym `.terraform`. Kolejne joby wracają do tej samej
zainicjalizowanej konfiguracji.

Wspólne kroki są zdefiniowane w samym YAML przez kotwice i aliasy:
`&terraform_paths` przygotowuje ścieżki, `&release_metadata` sprawdza metadane
publikacji, a `&restore_terraform_inputs` sprawdza zachowane wejścia kolejnych
jobów. Zapis `*terraform_paths` powtarza wcześniej zdefiniowany krok.
Nie dodawaj dla tych nazw Repository variables — to nazwy fragmentów YAML.
[Kotwice i aliasy w GitHub Actions](https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations).

## Krok 12. Wykonaj `validate` jako osobny job

1. Job `validate` startuje po sukcesie `init`.
2. Ponownie udostępnia tę samą wersję Terraform; ustawienie ścieżki polecenia
   jest wykonywane w każdym jobie.
3. Otwiera ten sam katalog roboczy i `TF_DATA_DIR` swojego środowiska.
4. Sprawdza zapisany commit, sumę SHA256 pliku zmiennych oraz dostępność
   wcześniejszych plików. Brak wcześniej używanego stanu zatrzymuje operację.
5. Sprawdza wybrany workspace i wykonuje `terraform validate`.

Nie przesyła stanu ani `.terraform` jako artefaktu GitHub. Pliki pozostają
na trwałym dysku jednego przypisanego runnera.

## Krok 13. Wykonaj `plan` jako osobny job

1. Job `plan` zależy od sukcesu `validate`.
2. Używa tego samego kodu, workspace i pliku stanu.
3. Otrzymuje token w `DIGITALOCEAN_TOKEN` oraz sekrety aplikacji przez
   `TF_VAR_dockerhub_token` i `TF_VAR_openweather_api_key`.
4. Wykonuje `terraform plan` i zapisuje plan na dysku runnera, w katalogu
   bieżącego przebiegu.
5. Przejrzyj w logu planowane zasoby i nazwy VM.

Pierwszy plan pokaże infrastrukturę wybranego środowiska, generowanie pary
kluczy SSH, rejestrację klucza publicznego, firewall, losowy sufiks i
`terraform_data.application`, który uruchomi provisionery aplikacji.
Kod nie tworzy VPC i nie zarządza infrastrukturą `test`.
Planu nie uploadujemy do GitHub jako artefaktu;
kolejny job wykorzystuje lokalny plik właściwego przebiegu i środowiska.

Obie zmienne `TF_VAR_*` są zadeklarowane jako `ephemeral = true` oraz
`sensitive = true`. Nie są zapisywane w planie i stanie. Trzeba przekazać je
zarówno w `plan`, jak i ponownie w `apply` — zapisany plan wymaga ponownego
dostarczenia użytych zmiennych ephemeral. Nie przenoś ich do pliku `tfvars`.
[Wartości ephemeral w provisionerach](https://developer.hashicorp.com/terraform/language/provisioners#ephemeral-values).

## Krok 14. Wykonaj `apply` jako osobny job

1. Job `apply` startuje po sukcesie `plan`.
2. Sprawdza workspace i wykonuje `terraform apply` dla **zapisanego planu**.
3. Terraform tworzy lub uzgadnia parę kluczy SSH, VM, klucz publiczny
   zarejestrowany w DigitalOcean oraz firewall.
4. `terraform_data.application` wykonuje `remote-exec` przez SSH: czeka na
   bootstrap VM, pobiera opublikowany obraz i uruchamia kontener.
5. Zapisuje stan niezależnie dla `dev` i `prod`.
6. Odczytuje tylko publiczne `public_ip`, `droplet_id`, `app_url` dla
   późniejszej weryfikacji. Nie eksportuje prywatnego klucza do metadanych.

Job `apply` ponownie dostarcza `TF_VAR_dockerhub_token` i
`TF_VAR_openweather_api_key` ze swoich GitHub Secrets. Provisioner korzysta
z nich w czasie wykonania. Kodowanie Base64 w skrypcie chroni składnię powłoki
przed znakami specjalnymi; nie jest szyfrowaniem. Transmisję chroni SSH.

Zmiana VM, digestu obrazu lub `deployment_id` wymusza ponowne wykonanie
provisionerów aplikacji. Nowy przebieg workflow dostaje nowy identyfikator,
więc może ponowić deploy tego samego obrazu. Nieudany provisioner oznacza
nieudany `apply` i ponowienie zasobu `terraform_data`; sam ten błąd nie wymaga
odtwarzania VM. Kontener jest uruchamiany przez polecenia provisionera,
a nie reprezentowany jako zasób osobnego providera Docker.

Cloud-init instaluje `docker.io`, `python3`, `curl` i certyfikaty CA,
a następnie włącza Dockera. Nie zawiera obrazu aplikacji ani sekretów.
Provisioner dodatkowo sprawdza wymagane pakiety i usługę Docker; gdy bootstrap
ich nie przygotował, instaluje brakujące składniki i uruchamia usługę przed
deployem. Krytyczny błąd cloud-init nadal zatrzymuje wykonanie.

Cały workflow ma wspólną grupę concurrency dla repozytorium oraz
`cancel-in-progress: false`, aby kolejny przebieg nie zmienił stanu pomiędzy
`plan` a `apply` pierwszego. Nie uruchamiaj równolegle ręcznych poleceń
Terraform poza pipeline.

Macierze mają wspólne zależności: kolejny etap czeka na sukces obu wariantów
poprzedniego etapu. Błąd infrastruktury `dev` może zatrzymać również dalszy
etap `prod`. `fail-fast: false` pozwala zakończyć uruchomione warianty, ale
nie usuwa tej zależności. Nie jest to sekwencyjna promocja dev → prod.

## Krok 15. Zachowaj deploy `test`

Job deploya `test` nadal:

1. Działa na self-hosted runnerze, w GitHub Environment `test`.
2. Odczytuje `FAZA3_APP_PORT`, `FAZA3_CONTAINER_NAME`, `FAZA3_WEATHER_CITY`.
3. Pobiera swój opublikowany obraz po digescie.
4. Usuwa poprzedni `pogoda_api_faza3_test`, jeżeli istnieje.
5. Uruchamia nowy na `18093:8080` i testuje WWW oraz prawdziwe API.
6. Czyści tymczasowe dane logowania Docker Hub także po błędzie.

Grupa `pogoda-faza3-deploy-test` zapobiega jednoczesnej podmianie tego samego
kontenera przez deploy testowy z FAZY-3 i FAZY-4. Job nie używa Terraform,
workspace ani tokenu DigitalOcean.

## Krok 16. Sprawdź deploy przez Terraform i publiczną weryfikację

W `apply` każdego środowiska natywne provisionery Terraform wykonują:

1. Połączenie SSH z VM i ograniczone czasem oczekiwanie na cloud-init.
2. Odczyt wyniku bootstrapu. Kod `0` oznacza sukces. Kod `2` z zakończonym
   statusem `done` oznacza problemy możliwe do odzyskania: pipeline pokazuje
   diagnostykę, zapewnia brakujące pakiety i uruchomienie Dockera, a potem
   wymaga działającej usługi oraz `docker info`.
   Błąd krytyczny, brak zakończenia lub timeout zatrzymuje deploy.
3. Logowanie Docker Hub na VM w osobnym tymczasowym katalogu konfiguracji.
4. Pobranie obrazu po digescie; błąd pobierania pozostawia obecny kontener.
5. Usunięcie poprzedniego `pogoda_api_faza4_dev` albo `pogoda_api_faza4_prod`
   i uruchomienie nowego z `--restart unless-stopped` oraz mapowaniem `80:8080`.
6. Przekazanie klucza pogody dopiero przy `docker run`, bez umieszczania go
   w obrazie lub cloud-init.
7. Sprawdzenie `/healthz` i stanu kontenera na VM.
8. Wylogowanie Docker Hub i usunięcie tymczasowego katalogu z tokenem oraz
   skryptu zawierającego dane dostępowe, także przy błędzie wykonania skryptu.

Skrypt provisionera trafia do prywatnego katalogu `/root`. Zawierająca sekrety
część jest oznaczona jako sensitive; Terraform ukrywa jej wyjście w logu.
Token Docker Hub, klucz OpenWeather i token DigitalOcean nie trafiają do stanu,
planu, cloud-init, obrazu ani cache. Prywatna część **pary SSH generowanej
w Terraform** pozostaje w chronionym stanie i może być zawarta w planie.

Po sukcesie `apply` startuje macierz **Verify DigitalOcean**. Zachowany
identyfikator joba to `deploy-digitalocean`, ale jego zadaniem jest teraz
wyłącznie weryfikacja publicznego adresu. Job:

1. W krokach Bash z `jq` sprawdza zgodność metadanych obrazu i publicznych
   wyników Terraform ze środowiskiem i bieżącym przebiegiem, w tym IP,
   identyfikator VM oraz zgodność URL z adresem IP.
2. Sprawdza publiczne `/healthz`, WWW oraz prawdziwe zapytanie pogodowe API.
3. Zapisuje działający URL w podsumowaniu i przy GitHub Environment.

Nie wykonuje SSH, nie instaluje providerów i nie uruchamia ponownie kontenera.
W tej fazie kod `2` cloud-init sam w sobie nie dowodzi awarii ani konkretnej
przyczyny ostrzeżenia; służy temu pokazana diagnostyka. Działanie aplikacji
potwierdza dopiero test Docker i końcowe WWW/API.
[Kody zakończenia cloud-init](https://docs.cloud-init.io/en/latest/explanation/failure_states.html).

HTTP jest protokołem tego ćwiczenia. Aplikacja nadal pozwala przygotować
HTTPS, ale domeny, certyfikaty i port TLS nie wchodzą w tę fazę.

## Krok 17. Uruchom pipeline i odczytaj URL

1. Otwórz **Actions → workflow FAZY-4 → Run workflow**.
2. Wybierz gałąź zgodną z `FAZA4_DEPLOY_BRANCH`, ustaw **operation: deploy**
   i uruchom przebieg. Jest to domyślna operacja.
3. Sprawdź wspólne `build` i `test`, potem trzy publikacje.
4. Otwórz osobne joby `init`, `validate`, `plan`, `apply` dla `dev` i `prod`.
   Sprawdź workspace oraz runner każdego wariantu.
5. Sprawdź deploy testowy, wykonanie provisionerów w obu `apply` i dwa joby
   **Verify DigitalOcean**.
6. Z podsumowań udanych weryfikacji skopiuj adresy `http://<IP_VM>/`.

Po poprawieniu kodu wyślij nowy commit i uruchom **nowy Run workflow**
z `operation: deploy` na gałęzi zawierającej zmianę. **Re-run jobs** starego
przebiegu używa jego wcześniejszego commita i nie pobierze poprawki.
Nowy przebieg daje też nowy `deployment_id`, wymuszający ponowienie deploya.

Dla `dev` i `prod` używaj IP właściwej VM, a nie runnera. Przykładowo dla
zwróconego `203.0.113.20` byłoby to `http://203.0.113.20/`, bez dopisywania
`:18094`, `:18095` lub `:8080`. Adres przykładowy zastąp rzeczywistym outputem.

Sam output `app_url` z Terraform wskazuje adres VM. Dopiero udany końcowy
test WWW i API potwierdza działającą aplikację pod tym adresem.

## Krok 18. Zweryfikuj wynik jako słuchacz

1. Wejdź w przeglądarce na URL `dev` i wpisz nazwę miasta.
2. Powtórz dla `prod` i dotychczasowego URL `test`.
3. Sprawdź API, zastępując przykładowy IP faktycznym:

   ```bash
   curl --fail http://203.0.113.20/healthz
   curl --fail --get --data-urlencode 'city=Warsaw' http://203.0.113.20/api/weather
   ```

4. W DigitalOcean sprawdź dwie VM z Twoim identyfikatorem i losowym sufiksem
   oraz firewall przypisany do każdej z nich.
5. Na runnerze sprawdź dwa pliki `terraform.tfstate`: w `workspaces/dev/`
   oraz `workspaces/prod/`.
6. Uruchom nowy **Run workflow → operation: deploy** bez zmiany kodu.
   Build powinien użyć cache,
   Terraform zachować VM i sufiksy nazw, a deploy podmienić właściwe kontenery.
7. Zmień `FAZA4_WEATHER_CITY` tylko w Environment `dev`, np. na `Gdansk`,
   i sprawdź, czy test tego środowiska używa nowej wartości.

## Krok 19. Zachowaj stan i rozpoznawaj błędy

| Objaw | Co sprawdzić |
| --- | --- |
| Job czeka na runnera | Czy Twój self-hosted runner Linux jest online i dostępny dla repozytorium |
| Brak znacznika katalogu stanu | Czy krok 3 wykonano jako konto usługi runnera i ustawiono poprawny pełny `FAZA4_STATE_ROOT` |
| Brak wcześniejszego stanu | Przywróć właściwy stan; nie obchodź kontroli nowym pustym katalogiem |
| `403` z DigitalOcean | Zakres, ważność i konto tokenu `DIGITALOCEAN_TOKEN` |
| Klucz SSH już istnieje | Właściwy zachowany stan; nie rejestruj ponownie kluczy po utracie stanu |
| SSH nie odpowiada | Publiczny adres runnera, CIDR `/32`, firewall, właściwy workspace i wygenerowany klucz ze stanu |
| Niezgodny klucz hosta SSH | Tożsamość VM i zaufany `FAZA4_SSH_HOST_KEY` właściwego Environment; nie podstawiaj klucza logowania zamiast klucza serwera |
| Cloud-init kończy się kodem `2` i `done` | Diagnostykę `status --long`, działanie Dockera oraz wynik WWW/API; sam kod nie wskazuje konkretnej przyczyny ostrzeżeń |
| Cloud-init zgłasza niedozwolony znak YAML `#x0082` | Kodowanie `cloud-init.yaml`; przygotowany plik używa ASCII, a szczegóły i wpływ zmiany `user_data` opisano poniżej |
| Krytyczny błąd cloud-init lub timeout | Instalację pakietów, dostęp VM do repozytoriów Ubuntu i logi bootstrapu |
| `docker pull` odrzucony | Prawo odczytu obrazu, login i token Docker Hub |
| `/healthz` działa, pogoda nie | Aktywność i limit prawdziwego klucza OpenWeather, miasto, dostęp VM do API |
| URL VM nie działa | Sukces publicznego testu po deployu, IP właściwej VM i regułę TCP80 |

W logach bootstrapu wystąpił komunikat o niedozwolonym znaku YAML `#x0082`.
Może on wynikać z błędnej interpretacji bajtów UTF-8 polskiego komentarza
w cloud-config. To wskazówka z logu i lokalnego pliku, bez niezależnego
potwierdzenia zawartości pliku na VM. Przygotowany `cloud-init.yaml` używa
teraz wyłącznie ASCII, a provisioner jawnie zapewnia pakiety i usługę Docker,
jeżeli wcześniejsza konfiguracja ich nie uruchomiła.

**Zmiana `cloud-init.yaml` zmienia `user_data` Dropleta. Terraform zaplanuje
zastąpienie istniejących VM utworzonych z poprzednią treścią `user_data`.**
Sprawdź ten wynik w następnym `plan`: odtworzone `dev` i `prod` mogą otrzymać
inne publiczne IP, więc po wdrożeniu użyj nowych URL z podsumowania.
Przygotowanie tej poprawki nie jest wykonaniem `apply` ani odtworzeniem hostów.

Nie usuwaj stanu również po **częściowo nieudanym `apply`**. Część zasobów
mogła już powstać, a zapisany stan pozwala kontynuować. Znaczniki pomagają
wykryć utratę poprzedniego stanu, ale nie zastępują kopii zapasowej.

Wykonuj kopię katalogu repozytorium i słuchacza w `FAZA4_STATE_ROOT`, gdy
workflow nie pracuje. Zachowaj stany `dev` i `prod`, kopie `.backup`, znaczniki
oraz ewentualne wcześniej zapisane zaufane klucze hostów SSH.
Backup przechowuj poza checkoutem i poza Git.
Nie usuwaj `runs/<run_id>` w trakcie przebiegu: zawiera konfigurację,
`TF_DATA_DIR` i plan potrzebny następnym jobom.

Jeśli zasoby istnieją, a stan zniknął, zatrzymaj uruchamianie pipeline
i odtwórz poprawny stan albo uzgodnij import z prowadzącym. Pusty stan
nie oznacza pustego konta DigitalOcean.

Po szkoleniu uzgodnij z prowadzącym usunięcie płatnych VM i ich zasobów
przez ręczną operację `destroy` opisaną poniżej. Nie kasuj stanu jako sposobu
usuwania infrastruktury. Zwykły push i operacja `deploy` nie wykonują `destroy`.

## Krok 20. Usuń równocześnie infrastrukturę `dev` i `prod`

W tym samym workflow jest ręczna operacja usuwająca **obie VM DigitalOcean**,
ich firewalle, zarejestrowane klucze SSH, zasób aplikacji `terraform_data`
oraz zasoby kluczy i losowych sufiksów zarządzane przez oba stany Terraform.
Kontener `test` na runnerze pozostaje.

1. Zachowaj na runnerze oba istniejące pliki stanu, ich workspace oraz te same
   wartości `FAZA4_STATE_ROOT` i `FAZA4_STUDENT_NAME`.
2. Otwórz **Actions → 15A FAZA-4 — Terraform workspaces i DigitalOcean → Run workflow**.
3. Wybierz gałąź zgodną z `FAZA4_DEPLOY_BRANCH`.
4. W polu **operation** wybierz **destroy** i uruchom workflow.
   Ten wybór uruchamia usuwanie obu środowisk; nie ma osobnego wyboru VM.
5. Sprawdź job **Terraform destroy (dev i prod równocześnie)**. Build, test,
   publikacja i deploy będą pominięte.
6. W logach odszukaj komunikaty z prefiksami `[dev]` i `[prod]`, a w podsumowaniu
   sprawdź wynik dla każdego środowiska.
7. W DigitalOcean sprawdź, że zniknęły obie VM oraz ich firewalle i klucze SSH.
   Pliki stanu i workspace pozostają na runnerze; po sukcesie stany nie zawierają
   zarządzanych zasobów.

Job uruchamia się na tym samym self-hosted runnerze Linux. Jeden runner wykonywałby
dwa joby macierzy kolejno, dlatego tutaj jeden job uruchamia **dwa procesy
Terraform równolegle przez Bash w kroku `run:` YAML**. Każdy otrzymuje własny
katalog roboczy, `TF_DATA_DIR` i workspace, a używa istniejącego pliku stanu
swojego środowiska. Kod źródłowy
Terraform jest wspólny. Powłoka uruchamia oba procesy w tle, zapamiętuje ich
identyfikatory i czeka na zakończenie obu przez `wait`.

Przed uruchomieniem któregokolwiek polecenia Terraform kroki Bash w YAML
sprawdzają obecność i poprawność JSON **obu** istniejących plików stanu.
Brak lub uszkodzenie jednego zatrzymuje operację przed wywołaniem Terraform.
Następnie `jq` tworzy niesekretne pliki zmiennych dla obu środowisk, a workflow
przygotowuje oddzielne katalogi kodu, danych i cache providerów.

Właściwe polecenia są zapisane bezpośrednio w jobie **Terraform destroy**.
Każdy proces wykonuje `terraform init`, wybór istniejącego workspace bez
`-or-create`, `terraform validate`, a następnie:

```bash
terraform destroy -auto-approve
```

Workflow dodaje do polecenia opcje automatyzacji, blokady stanu i plik zmiennych
właściwego środowiska. Na końcu sprawdza pustą listę zasobów.
Pliki state i workspaces pozostają na runnerze.

Operacja używa GitHub Environment **`prod`** i respektuje jego istniejące reguły
dostępu. Wystarczy dotychczasowy `DIGITALOCEAN_TOKEN` z prawem usunięcia zasobów
obu środowisk. Jeśli nadpisujesz ten sekret w Environment `prod`, jego wartość
musi mieć dostęp do obu VM. Pozostałe zmienne infrastruktury są te same co
dla deploya. Nie potrzeba nowych vars/secrets ani tokenu Docker Hub czy klucza
OpenWeather do tej operacji.

Zmienne aplikacji mają wartości domyślne `null`, a provisionery aplikacji
działają przy tworzeniu, nie przy usuwaniu. `destroy` może więc usunąć zasoby
bez dostarczania sekretów aplikacji i bez uruchamiania kontenera.

Wspólna grupa concurrency workflow zapobiega równoczesnemu deployowi i destroy.
Jeżeli usuwanie jednego środowiska nie powiedzie się, drugie może się zakończyć;
job po zakończeniu obu zwróci błąd. Zachowaj stany i ponów `operation: destroy`
po usunięciu przyczyny. Sam błąd nie odtwarza już usuniętych zasobów.

Kolejne uruchomienie z `operation: deploy` utworzy infrastrukturę ponownie,
z nowymi losowymi sufiksami, kluczami SSH i potencjalnie innymi IP.
[Dokumentacja polecenia destroy](https://developer.hashicorp.com/terraform/cli/commands/destroy).

## Kryteria ukończenia

- Jeden obraz zbudowany z cache i rzeczywiście przetestowany.
- Ten sam obraz opublikowany dla `test`, `dev`, `prod`.
- `init`, `validate`, `plan`, `apply` jako osobne joby GitHub Actions.
- Osobne VM oraz lokalne stany Terraform dla `dev` i `prod`.
- Deploy kontenera `dev` i `prod` wykonywany przez Terraform `remote-exec`
  podczas `apply`, z późniejszą publiczną weryfikacją WWW/API w GitHub Actions.
- `test` nadal na runnerze, z konfiguracją FAZY-3.
- WWW i rzeczywiste API sprawdzone przez pipeline oraz słuchacza.
- Podsumowania udanych deployów zawierają URL z publicznymi IP VM.
- Kolejny przebieg zachowuje infrastrukturę i podmienia kontenery.
- Ręczne `operation: destroy` usuwa równocześnie `dev` i `prod` i zachowuje lokalny `test`.
- Token Docker Hub i klucz pogody są ephemeral oraz sensitive w Terraform,
  poza zapisanym stanem, planem i obrazem. Stan i plany z wygenerowanymi
  kluczami SSH są chronione na runnerze; tymczasowe logowania Docker Hub
  i skrypty z sekretami na VM są sprzątane.

Przygotowanie materiału i lokalna walidacja nie są wykonaniem `apply` ani
dowodem działania na DigitalOcean. Realny wynik potwierdza udany przebieg
słuchacza i jego weryfikacja WWW/API pod zwróconymi adresami.
