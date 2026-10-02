# FULL_DEPLOY: Docker → registry → Terraform → Ansible

Workflow: `.github/workflows/full-deploy.yml`.

Konfiguracja buduje aplikację FastAPI, testuje ją, skanuje obraz i publikuje **ten sam przetestowany obraz**. Następnie opcjonalnie tworzy VM w AWS, DigitalOcean lub obu chmurach i wdraża obraz przez Ansible po niezmiennym digescie `sha256`.

Stan Terraform znajduje się w PostgreSQL dostępnym z runnera **`lab`**. Konfiguracja nie wymaga S3, Spaces ani konta HCP Terraform. Nie ma zasobów `local_file`, `local_sensitive_file` ani provisionerów zapisujących inventory lub klucz na komputerze uruchamiającym Terraform.

## 1. Przebieg i uruchamianie

| Zdarzenie | Testy / obraz | Publikacja | Infrastruktura i Ansible |
|---|---|---|---|
| Pull request zmieniający `FULL_DEPLOY` lub ten workflow | Tak | Nie | Nie |
| Push na `main`, ze zmianami w tych ścieżkach | Tak | Tag pełnego SHA commita | Według zmiennej `DEPLOY_CLOUD` |
| Push taga `vX.Y.Z` | Tak | Dokładny tag, np. `v1.2.3` | Według `DEPLOY_CLOUD` |
| Ręczne `Run workflow`, `operation=deploy` | Tak | SHA lub wskazany poprawny tag | Według wyboru `cloud` |
| Ręczne `Run workflow`, `operation=destroy` | Pomijane | Nie | Usunięcie zasobów ze stanu wybranej chmury; bez Ansible |

`DEPLOY_CLOUD` domyślnie wynosi `none`. Możliwe wartości: `none`, `aws`, `digitalocean`, `both`. Ustawienie go na `aws`, `digitalocean` lub `both` włącza automatyczne wdrażanie po pushu na `main` i po tagu wersji. Wybór ręczny ma pierwszeństwo, także `cloud=none`.

Przy ręcznym uruchomieniu wybierz `operation=deploy` (domyślnie) albo `operation=destroy`. Niszczenie wymaga `cloud=aws`, `digitalocean` lub `both`; połączenie `destroy` z `none` jest odrzucane. Push i pull request nigdy nie wybierają operacji `destroy`.

Akceptowane tagi: `v0.1.0`, `v1.2.3`, `v10.20.30`. Odrzucane: `v1`, `v1.2`, `v01.2.3`, `v1.2.3-rc.1`, `v1.2.3+build.7`. Inne tagi niż zaczynające się od `v` nie uruchamiają workflow. Filtr GitHub jest globem, dlatego skrypt dodatkowo sprawdza ścisły format. Nie powstają aliasy `latest`, `v1` ani `v1.2`. Nie przesuwaj istniejących tagów wersji; opublikuj kolejną wersję.

Joby `metadata`, `validate` i `image` działają na `ubuntu-24.04`. Joby `deploy` oraz `destroy` działają na **`runs-on: lab`** i łączą się z lokalnym PostgreSQL i chmurą. Dla `destroy` uruchamiają się wyłącznie `metadata` oraz `destroy`: testy aplikacji, budowanie i publikacja obrazu oraz Ansible są pomijane. Pull request nie uruchamia kodu na prywatnym runnerze `lab`.

Obraz jest budowany dla `linux/amd64`; VM również musi być x86_64. Cache BuildKit `type=gha,mode=max` zachowuje warstwy między uruchomieniami. Instalacja zależności jest przed kopiowaniem `app.py`, więc zmiana aplikacji nie wymusza ponownej instalacji pakietów. `pull: true` pozwala pobrać aktualizacje obrazu bazowego.

## 2. Sekrety GitHub Actions

Dodaj je w **Settings → Secrets and variables → Actions → Secrets**. Utwórz także **Settings → Environments → `full-deploy-aws` i/lub `full-deploy-digitalocean`**. Sekrety chmurowe najlepiej umieścić w odpowiednim Environment. Dla tych środowisk ustaw dozwolone branche/tagi (`main` i wydania `v*`); opcjonalnie dodaj reviewerów.

| Secret | Gdzie / kiedy | Wartość i wymagane uprawnienia |
|---|---|---|
| `TF_PG_CONN_STR` | Oba środowiska wdrożeniowe albo repozytorium | Pełny connection string do istniejącej bazy PostgreSQL, dostępnej z `lab`. |
| `AWS_ACCESS_KEY_ID` | `full-deploy-aws` | Access key ID użytkownika IAM z uprawnieniami do zasobów tego wdrożenia. |
| `AWS_SECRET_ACCESS_KEY` | `full-deploy-aws` | Secret access key należący do tej samej pary kluczy AWS. |
| `AWS_SESSION_TOKEN` | Opcjonalnie `full-deploy-aws` | Tylko dla tymczasowych credentials STS. Przy zwykłej parze kluczy IAM pozostaw ten sekret nieustawiony. |
| `DIGITALOCEAN_TOKEN` | `full-deploy-digitalocean` | Token API do zarządzania Dropletami, VPC, firewallami, kluczami SSH i Reserved IP; potrzebny też odczyt regionów, obrazów i rozmiarów. |
| `DOCKERHUB_USERNAME` | Sekret repozytorium; tylko Docker Hub | Login konta, które publikuje obraz. |
| `DOCKERHUB_TOKEN` | Sekret repozytorium; tylko Docker Hub | Personal Access Token z `Read & Write` dla repozytorium obrazu. Hasło konta nie jest potrzebne. |
| `DOCKERHUB_PULL_TOKEN` | Opcjonalnie środowiska; Docker Hub | Osobny token `Read` do pobierania obrazu na VM. Jeśli brak, używany jest `DOCKERHUB_TOKEN`. |
| `OPENWEATHER_API_KEY` | Środowiska wdrożeniowe | Klucz OpenWeatherMap, podawany aplikacji podczas uruchamiania. Opcjonalny dla samego wdrożenia i `/health`; potrzebny dla `/weather` bez klucza w żądaniu. |

**GHCR nie wymaga własnego sekretu do publikacji ani wdrożenia z tego repozytorium.** GitHub automatycznie dostarcza `GITHUB_TOKEN`; job obrazu ma `packages: write`, a wdrożenie `packages: read`. Token jest tymczasowo używany na VM do pobrania prywatnego obrazu, po czym plik logowania jest usuwany. Restart już pobranego kontenera nie wymaga ponownego pobierania obrazu.

Klucza SSH **nie dodajesz jako sekretu**. Terraform generuje go przez `tls_private_key` i zachowuje w stanie PostgreSQL. Kolejne uruchomienie odczytuje ten sam klucz. Oddzielny klucz hosta SSH jest również generowany przez TLS i instalowany przez cloud-init, aby Ansible mógł sprawdzić tożsamość nowej VM już przy pierwszym połączeniu.

## 3. Registry: GHCR albo Docker Hub

Domyślnie `CONTAINER_REGISTRY=ghcr`, a nazwa obrazu to:

```text
ghcr.io/<właściciel>/<repozytorium>/full-deploy:<pełny-SHA-lub-vX.Y.Z>
```

Nazwy są zamieniane na małe litery. Obraz pojawi się w sekcji Packages właściciela repozytorium. Pierwsza publikacja tworzy prywatny pakiet; publiczne repozytorium nie oznacza automatycznie publicznego obrazu. Etykieta OCI `org.opencontainers.image.source` łączy obraz z repozytorium. Jeśli pakiet o tej nazwie istniał wcześniej, sprawdź w jego ustawieniach **Manage Actions access** i nadaj temu repozytorium dostęp. Polityka organizacji musi pozwalać na tworzenie pakietów.

Aby przełączyć na Docker Hub:

1. Utwórz repozytorium obrazu w Docker Hub.
2. Ustaw zmienną repozytorium `CONTAINER_REGISTRY=dockerhub`.
3. Ustaw `DOCKERHUB_IMAGE=<namespace>/<repozytorium-obrazu>`, np. `mojekonto/pogoda` — bez taga i bez adresu `https://`.
4. Dodaj `DOCKERHUB_USERNAME` i `DOCKERHUB_TOKEN`.

W obu wariantach Ansible dostaje `repozytorium@sha256:...`. Nie przebudowuje obrazu na serwerze.

## 4. PostgreSQL na runnerze lab

Dodaj **pełny rzeczywisty URI** do `TF_PG_CONN_STR`. Schemat przykładowej wartości:

```text
postgresql://TF_USER:URL_ENCODED_PASSWORD@127.0.0.1:5432/szkolenie?sslmode=disable
```

Hasło w URI musi mieć zakodowane znaki specjalne: `@` → `%40`, `+` → `%2B`, `#` → `%23`, `%` → `%25`. Nie zapisuj URI z hasłem w workflow, `.tf`, `.tfvars` ani pliku przykładowym.

`localhost` / `127.0.0.1` oznacza komputer lub przestrzeń sieciową procesu runnera `lab`. PostgreSQL musi być tam osiągalny. Jeśli sam runner działa w kontenerze, `localhost` wskazuje ten kontener; dostosuj adres bazy. `sslmode=disable` zachowuje wskazany wariant lokalny. Dla połączenia przez sieć skonfiguruj TLS, np. `sslmode=verify-full`, i zaufany certyfikat CA.

Baza `szkolenie` musi już istnieć. Rola PostgreSQL potrzebuje połączenia z bazą i możliwości utworzenia własnych schematów, tabel, indeksów i sekwencji. Administrator może nadać jej `CONNECT, CREATE` na tej bazie; obiekty tworzone przez backend będą należeć do tej roli.

Konfiguracja wykorzystuje:

```hcl
terraform {
  backend "pg" {}
}
```

Workflow przekazuje sekret jako zmienną środowiskową `PG_CONN_STR`, a uruchomienie wygląda tak:

```bash
# PG_CONN_STR jest już w środowisku, z GitHub Secret.
terraform init -backend-config="schema_name=full_deploy_aws"
# W osobnym katalogu Terraform dla DigitalOcean:
terraform init -backend-config="schema_name=full_deploy_digitalocean"
```

To odpowiednik przekazania `conn_str` do `terraform init`, ale credentials nie są utrwalane w konfiguracji backendu i planie. Backend `pg` obsługuje blokowanie stanu. Dodatkowo GitHub `concurrency` używa wspólnej grupy `full-deploy-infrastructure-<cloud>` dla wdrożeń i usuwania, również między różnymi branchami/tagami. Nie uruchamia obu operacji równocześnie dla tej samej chmury i nie przerywa trwającego `apply`.

Każdy katalog używa workspace `default`, w swoim schemacie. Nie zmieniaj schematów między uruchomieniami i nie kieruj drugiego projektu do tych samych schematów. Zmiana `DEPLOY_NAME` **nie tworzy odrębnego stanu**. Jeśli dodasz następne środowisko, nadaj mu nowy schemat i osobną grupę `concurrency`.

**Trwałość bazy jest konieczna.** Jeśli PostgreSQL działa w Dockerze na `lab`, jego katalog danych musi mieć trwały wolumen. Sam backend zdalny nie zapewnia backupu. Stan zawiera prywatne klucze SSH; `sensitive = true` maskuje wyświetlanie, ale nie szyfruje wartości w bazie. Ogranicz dostęp do bazy i zabezpiecz dysk oraz backupy. Klucz hosta występuje też w cloud-init/user-data VM.

## 5. Dane między jobami i niezależność Terraform

Pomiędzy jobami przechodzą tylko nazwa/digest obrazu oraz wybór operacji i chmury. `terraform apply` i Ansible wykonują się kolejno w jednym jobie `deploy`.

Każdy nowy runner odtwarza dane z PostgreSQL przez `terraform init`. Następnie job pobiera:

```bash
umask 077
terraform output -json ansible_inventory > "$DEPLOY_TEMP/inventory.json"
terraform output -raw ssh_private_key > "$DEPLOY_TEMP/id_ed25519"
terraform output -raw ssh_known_hosts > "$DEPLOY_TEMP/known_hosts"
```

Pliki tworzy **warstwa uruchamiająca pipeline**, nie zasoby Terraform. Output `ansible_inventory` jest zwykłym obiektem JSON bez lokalnych ścieżek. Ansible dostaje ścieżkę klucza przez `--private-key`, a plik hostów przez `--ssh-common-args` z `StrictHostKeyChecking=yes`.

Klucz prywatny, plan ani stan nie trafiają do GitHub job outputs, cache czy artifacts. `terraform_wrapper: false` wyłącza przechwytywanie stdout przez akcję instalującą Terraform. Prywatny katalog tymczasowy na trwałym runnerze jest sprzątany w kroku `always()`. Awaryjne zatrzymanie samego runnera może wymagać ręcznego usunięcia pozostałego katalogu.

Jeśli kiedyś rozdzielisz Terraform i Ansible na osobne joby, drugi job również musi mieć dostęp do PostgreSQL: wykonuje `init` z **tym samym schematem** i ponownie odczytuje outputy. Nie musi pobierać klucza z artefaktu pierwszego joba. Wtedy blokada całego procesu wdrożenia powinna obejmować oba joby, żeby inny przebieg nie zmienił VM pomiędzy nimi.

## 6. AWS: access key i secret key

1. Wybierz lub utwórz użytkownika IAM przeznaczonego do tego pipeline.
2. Dołącz do niego politykę uprawnień opartą na `docs/aws-permissions-policy.json`. Przykład obejmuje tworzenie, aktualizację i usuwanie EC2/VPC, adresu IP i klucza SSH oraz odczyt publicznego parametru AMI Ubuntu. Ta sama polityka wystarcza dla `deploy` i `destroy`. Jeśli zmienisz region, popraw go także w polityce.
3. W IAM, w ustawieniach tego użytkownika, otwórz **Security credentials → Access keys → Create access key**. Możesz też użyć już posiadanej pary kluczy tego użytkownika.
4. W GitHub otwórz **Settings → Environments → full-deploy-aws → Environment secrets** i dodaj `AWS_ACCESS_KEY_ID` oraz `AWS_SECRET_ACCESS_KEY`.
5. Przy zwykłej parze kluczy IAM nie ustawiaj `AWS_SESSION_TOKEN`. Ten trzeci sekret jest potrzebny tylko wtedy, gdy używasz tymczasowych credentials STS.

Akcja `aws-actions/configure-aws-credentials` pobiera tę parę z sekretów i udostępnia ją Terraformowi jako zmienne środowiskowe. Przed konfiguracją usuwa poprzednie credentials z otoczenia procesu i nie przejmuje ustawień roli ani sesji z runnera `lab`. Nie zapisuje profilu w `~/.aws/credentials`. Konfiguracja nie wymaga OIDC, `AWS_ROLE_ARN` ani uprawnienia `id-token: write`.

Przykładowa polityka mutacji obejmuje zasoby EC2 w wybranym regionie, a nie tylko zasoby o konkretnej nazwie. Jest przeznaczona do konta szkoleniowego; w koncie współdzielonym zawęź ją według zasad organizacji. Workflow nie wymaga uprawnień S3, tworzenia IAM ani `iam:PassRole`.

Powstają VPC, publiczny subnet, Internet Gateway, routing, Security Group, klucz SSH, EC2 Ubuntu 24.04 z szyfrowanym dyskiem oraz Elastic IP. Domyślny typ to `t3.micro`. Wymagany jest IMDSv2. Aktualizacja opublikowanego przez Canonical parametru AMI może spowodować wymianę VM przy kolejnym `apply`; adres Elastic IP pozostaje zarządzany osobno. Aplikacja jest bezstanowa.

## 7. DigitalOcean

Utwórz token API i zapisz go jako `DIGITALOCEAN_TOKEN` w `full-deploy-digitalocean`. Wymagane są operacje odczytu, tworzenia, aktualizacji i usuwania zasobów wymienionych w tabeli sekretów. Dla prostego ćwiczenia można użyć tokena Full Access na wydzielonym koncie szkoleniowym; token nie jest ograniczony samą nazwą projektu.

Powstają VPC, Droplet Ubuntu 24.04 (`s-1vcpu-1gb`, domyślnie `fra1`), klucz SSH, firewall i Reserved IP z przypisaniem do Dropleta. Nie potrzeba tokena DigitalOcean Container Registry ani kluczy Spaces. Ansible loguje się jako `root`; w AWS jako `ubuntu` z `become`.

## 8. Zmienne Actions i runner

To **Variables**, nie sekrety:

| Zmienna | Domyślnie | Znaczenie |
|---|---|---|
| `CONTAINER_REGISTRY` | `ghcr` | `ghcr` lub `dockerhub`; ustaw na poziomie repozytorium. |
| `DOCKERHUB_IMAGE` | Brak | `namespace/repo`; wymagane tylko dla Docker Hub, na poziomie repozytorium. |
| `DEPLOY_CLOUD` | `none` | Automatyczne wdrożenia: `none`, `aws`, `digitalocean`, `both`; poziom repozytorium. |
| `DEPLOY_NAME` | `full-deploy` | Stabilna nazwa zasobów. |
| `AWS_REGION` | `eu-central-1` | Region AWS. |
| `AWS_INSTANCE_TYPE` | `t3.micro` | Typ x86_64; nie `t4g`. |
| `DO_REGION` | `fra1` | Region DigitalOcean. |
| `DO_DROPLET_SIZE` | `s-1vcpu-1gb` | Rozmiar Dropleta. |
| `APP_PORT` | `80` | Port HTTP VM, mapowany do portu kontenera 8000. |
| `APP_CIDR` | `0.0.0.0/0` | Kto może korzystać z aplikacji; musi obejmować runner dla końcowego testu HTTP. |
| `SSH_SOURCE_IP` | Autodetekcja | Publiczny IPv4 bez `/32`; ustaw, jeśli ruch SSH wychodzi innym adresem niż HTTPS. |

Zmienne infrastruktury mogą być ustawione w konkretnym Environment. SSH jest dopuszczony tylko z `/32` aktualnego adresu wyjściowego `lab`. Reguła pozostaje po wdrożeniu i jest aktualizowana przy kolejnym `apply`.

Runner `lab` powinien być Linux z aktualną aplikacją GitHub Runner oraz Git, Bash, curl, OpenSSH i obsługą Python `venv`. Akcje instalują Terraform 1.16.4 oraz Python 3.12; użytkownik runnera musi móc zapisywać do katalogu narzędzi. Wymagane są wyjścia HTTPS do GitHub, rejestrów pakietów, AWS/DigitalOcean i `checkip.amazonaws.com`, połączenie do bazy oraz SSH/HTTP do VM. Job wdrożeniowy nie potrzebuje lokalnego Dockera. Przy wielu runnerach o etykiecie `lab` wszystkie muszą trafiać do **tej samej bazy**, a nie do niezależnych baz na swoich localhostach.

## 9. Pierwszy przebieg

1. Dodaj workflow i katalog `FULL_DEPLOY` do repozytorium, na `main`.
2. Przy GHCR pozostaw domyślne registry. Przy Docker Hub dodaj jego zmienne i sekrety.
3. Przygotuj PostgreSQL i `TF_PG_CONN_STR`; utwórz GitHub Environments oraz credentials wybranej chmury.
4. Uruchom **Actions → FULL_DEPLOY → Run workflow → operation=deploy, cloud=none**. Sprawdź testy i publikację.
5. Uruchom ponownie z `operation=deploy` i `cloud=aws`, `digitalocean` albo `both`. Ten krok tworzy płatne zasoby.
6. Adres aplikacji pojawi się w podsumowaniu joba. `/health` działa bez zewnętrznego API; `/docs` pokazuje dokumentację; `/weather?city=Warsaw` używa sekretu aplikacji.
7. Opcjonalnie ustaw `DEPLOY_CLOUD`, aby następne commity i wydania wdrażały się automatycznie.

Nie ma automatycznego `destroy` po wdrożeniu: VM ma pozostać dostępna. Usuwanie uruchamiasz ręcznie zgodnie z sekcją 10. Kolejne uruchomienie aktualizuje te same zasoby i kontener. Wdrożenie na pojedynczej VM może powodować krótką przerwę podczas wymiany kontenera. Konfiguracja udostępnia HTTP; publiczne wdrożenie produkcyjne wymaga osobnego TLS, domeny i zasad dostępu.

## 10. Usuwanie zasobów przez workflow

1. Otwórz **Actions → FULL_DEPLOY → Run workflow**.
2. Wybierz branch zawierający aktualną konfigurację tego wdrożenia, zwykle `main`.
3. Ustaw **`operation=destroy`** oraz **`cloud=aws`**, **`digitalocean`** albo **`both`**.
4. Uruchom workflow. Job `destroy` na `lab` odczyta istniejący stan i usunie wszystkie zarządzane w nim zasoby wybranej chmury. Wynik pojawi się w podsumowaniu.

Ta operacja usuwa VM wraz z aplikacją i dyskiem, publiczny adres IP, sieć, reguły dostępu i klucz SSH zarządzane przez Terraform. Zakres wynika z **całego stanu** `full_deploy_aws` lub `full_deploy_digitalocean`, workspace `default`; nie jest filtrowany po `DEPLOY_NAME`. Dla `both` wykonywane są dwa niezależne joby, więc błąd jednej chmury nie zatrzymuje usuwania drugiej.

Job potrzebuje tego samego `TF_PG_CONN_STR`, credentials wybranej chmury oraz zmiennych infrastruktury (szczególnie regionu) jak przy wdrożeniu. Korzysta z tego samego GitHub Environment i jego ewentualnych reguł zatwierdzania. Nie potrzebuje sekretów registry, klucza OpenWeather ani dostępu SSH do VM. Brak lub błędna konfiguracja registry nie blokuje usuwania.

Skrypt `scripts/destroy.sh` wykonuje `terraform init` z tym samym schematem PostgreSQL, `validate`, `plan -destroy` i `apply` zapisanego planu. Obie operacje zmieniające stan czekają do 5 minut na jego blokadę. Wymagana zmienna `ssh_cidr` otrzymuje `127.0.0.1/32` wyłącznie do walidacji konfiguracji; plan usuwania nie aktualizuje reguł firewalla i nie wykrywa publicznego IP runnera. Plan jest zapisany w prywatnym katalogu tymczasowym, usuwanym w kroku `always()`, bez artefaktów i cache.

**Registry, obrazy kontenerów, użytkownik IAM i baza PostgreSQL pozostają.** Backend zapisuje stan po usunięciu zasobów; nie usuwaj bazy ani stanu przed zakończeniem `destroy`. Następne `operation=deploy` odtworzy infrastrukturę z nowymi kluczami SSH. Jeśli `DEPLOY_CLOUD` nadal wskazuje chmurę, kolejny push spełniający filtry workflow również może ją odtworzyć; ustaw `DEPLOY_CLOUD=none`, jeśli automatyczne wdrażanie ma być wyłączone.

Opcjonalnie te same operacje można wykonać ręcznie z dostępem do tej samej bazy:

```bash
# Przykład AWS; dla DO wybierz FULL_DEPLOY/terraform/digitalocean
# oraz schema_name=full_deploy_digitalocean i DIGITALOCEAN_TOKEN.
cd FULL_DEPLOY/terraform/aws
# PG_CONN_STR ustaw bezpiecznie w środowisku, np. przez read -rs i export.
# Uwierzytelnij AWS przez lokalny profil/SSO. GITHUB_TOKEN i Ansible nie są potrzebne.
terraform init -backend-config="schema_name=full_deploy_aws"
export TF_VAR_ssh_cidr="127.0.0.1/32" # Wymagany parametr, nie jest stosowany przy destroy.
# Ustaw TF_VAR_name, TF_VAR_region i pozostałe wartości tak jak przy wdrożeniu.
umask 077
terraform plan -destroy -input=false -lock-timeout=5m -out=destroy.tfplan
terraform apply -input=false -lock-timeout=5m destroy.tfplan
rm -f destroy.tfplan
```

Jeśli zapis stanu po `apply` nie powiedzie się i Terraform utworzy `errored.tfstate`, zachowaj ten chroniony plik i odzyskaj stan przed kolejnym przebiegiem; checkout może usunąć nieśledzone pliki.

## 11. Co jest sprawdzane

- `tests/`: zachowanie API z atrapami usług pogodowych, reguły tagów i ręcznego wyboru `deploy`/`destroy`. Testy skryptu usuwania używają atrapy Terraform: sprawdzają wybór stanu, plan z `-destroy`, brak `apply` po błędzie i brak wywołań przy brakujących sekretach. Nie wywołują chmur ani usług pogodowych.
- Terraform: `fmt`, `validate`, `terraform test` z mock providerami. Testy nie tworzą zasobów, nie uwierzytelniają chmur i sprawdzają m.in. firewall, dane inventory, zgodność kluczy oraz IMDSv2/szyfrowanie AWS.
- Obraz: `pip check`, UID 10001, uruchomienie z systemem plików tylko do odczytu, odpowiedzi HTTP i Docker healthcheck.
- Trivy: blokuje publikację przy podatnościach HIGH/CRITICAL z dostępną poprawką. Baza podatności zmienia się; nowy wynik może zatrzymać kolejny build. Bezwarunkowe pomijanie błędów skanera nie jest włączone.
- Ansible: sprawdzenie składni przed publikacją; podczas wdrożenia oczekiwanie na SSH/cloud-init, instalacja Dockera, uruchomienie obrazu i kontrola zdrowia.

Uruchomienie testów lokalnie, z katalogu `FULL_DEPLOY`:

```bash
python3.12 -m venv .venv
.venv/bin/python -m pip install -r requirements-test.txt
.venv/bin/python -m pytest -q
terraform fmt -check -recursive terraform
for cloud in aws digitalocean; do
  terraform -chdir="terraform/$cloud" init -backend=false -lockfile=readonly
  terraform -chdir="terraform/$cloud" validate
  terraform -chdir="terraform/$cloud" test
done
# Opcjonalnie, jeśli masz actionlint:
actionlint -config-file actionlint.yml ../.github/workflows/full-deploy.yml
```

`scripts/deploy.sh` jest skryptem wykonawczym: **tworzy/zmienia infrastrukturę i łączy się z VM po SSH**. `scripts/destroy.sh` **usuwa zasoby wskazanego stanu Terraform**. Nie uruchamiaj tych skryptów jako testów składni; do tego służą `bash -n` i `shellcheck`. `scripts/smoke.py` wykonuje żądania do przekazanego adresu aplikacji; nie publikuje obrazu i nie wdraża zasobów.

### Weryfikacja wykonana 2026-10-02

- 23 testy aplikacji i reguł tagowania przeszły także pod Pythonem 3.12 w kontenerze.
- Po dodaniu ręcznego `destroy`: 43 testy pod Pythonem 3.14 przeszły, w tym testy wyboru operacji i skryptu usuwania z atrapą Terraform. `actionlint`, `shellcheck` i `bash -n` przeszły; nie uruchamiano usuwania w chmurach.
- Terraform 1.16.4: formatowanie, walidacja i po 3 testy z mock providerami dla AWS oraz DigitalOcean przeszły. Pliki lock zawierają sumy dla Linux amd64 i macOS arm64.
- `actionlint` z etykietą `lab`, `shellcheck` oraz kontrola składni Ansible przeszły.
- Lokalny obraz amd64 przeszedł `pip check`, testy HTTP, sprawdzenie UID i healthcheck. Ponowna budowa wykorzystała warstwy cache.
- Trivy 0.75.0: zero podatności HIGH/CRITICAL z dostępną poprawką, zarówno w pakietach systemowych, jak i Pythonie, według bazy pobranej podczas testu.
- Rzeczywisty moduł kontenera Ansible uruchomił izolowany lokalny kontener z opcjami wdrożenia; powtórzenie nie zmieniło kontenera. To test samej części kontenerowej, bez instalacji pakietów i SSH do VM.
- Osobny, tymczasowy PostgreSQL 17 potwierdził dwa niezależne schematy, odzyskanie outputów w nowych katalogach roboczych oraz brak hasła w metadanych backendu. Nie używano bazy ani credentials użytkownika.


## Źródła

- [Terraform: backend PostgreSQL, zmienne środowiskowe i blokowanie stanu](https://developer.hashicorp.com/terraform/language/backend/pg)
- [Docker: cache w GitHub Actions](https://docs.docker.com/build/ci/github-actions/cache/)
- [GitHub: GHCR i uprawnienia GITHUB_TOKEN](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [AWS: konfiguracja credentials w GitHub Actions](https://github.com/aws-actions/configure-aws-credentials)
