# Ćwiczenie 02 — Terraform w GitHub Actions i osobny job testujący SSH

Przygotuj pipeline wykonujący Terraform na maszynie szkoleniowej z agentem
self-hosted. State i wygenerowany klucz SSH przechowuj na jej trwałym dysku.
Drugi job ma rzeczywiście zalogować się tym kluczem do VM DigitalOcean.

## 1. Przygotuj jeden host self-hosted

Teraz otwórz **Settings → Actions → Runners → New self-hosted runner**
w swoim repozytorium. Wybierz Linux i architekturę maszyny szkoleniowej.
Wykonaj na tej maszynie instrukcje rejestracji pokazane przez GitHub.

Teraz uruchom agenta i sprawdź w GitHub jego dostępność z etykietami
`self-hosted` i `linux`. Użyj runnera co najmniej `2.327.1`, obsługującego
akcje Node.js 24. Konto agenta potrzebuje Bash, klienta OpenSSH,
polecenia `ip` z pakietu iproute2 oraz GNU coreutils, m.in. `realpath`
i `stat`. Terraform przygotuje
akcja w pipeline.

Repozytorium ma korzystać z **jednego aktywnego runnera** pasującego do
`[self-hosted, linux]`. Oba joby i kolejne przebiegi muszą trafiać na ten sam
fizyczny host, ponieważ state i klucz nie są przesyłane między maszynami.
Nie dodawaj drugiego pasującego runnera w trakcie zadania.

## 2. Odczytaj publiczny IPv4 z eth0 maszyny agenta

Teraz na maszynie szkoleniowej, na której zainstalowałeś self-hosted agenta,
wykonaj:

```bash
ip a
ip -4 addr show dev eth0
```

Teraz znajdź adres z wiersza `inet` interfejsu `eth0`. W tym środowisku
szkoleniowym jest to publiczny IPv4 maszyny. Skopiuj sam adres, **bez maski
interfejsu**, i dopisz `/32`.

Przykład wyłącznie dokumentacyjny:

```text
Wynik ip:          inet 203.0.113.20/20 ... eth0
SSH_ALLOWED_CIDR:   203.0.113.20/32
```

Użyj rzeczywistego adresu. Nie wpisuj `203.0.113.20`, maski interfejsu `/20`
z przykładu ani adresu laptopa. Połączenie SSH wykona job z hosta agenta,
więc firewall ma dopuścić właśnie jego publiczny IPv4 `/32`.

## 3. Dodaj zmienne i sekret w GitHub

Teraz otwórz **Settings → Secrets and variables → Actions → Variables**
i dodaj Repository variables:

| Nazwa | Wartość dla Twojego ćwiczenia |
| --- | --- |
| `VM_NAME` | Własna podstawa nazwy VM, np. `jan-kowalski-vm-02` |
| `VPC_NAME` | Własna podstawa nazwy VPC, np. `jan-kowalski-vpc-02` |
| `FIREWALL_NAME` | Własna podstawa nazwy firewalla, np. `jan-kowalski-fw-02` |
| `VPC_CIDR` | Wolna prywatna sieć `/24` uzgodniona z prowadzącym, np. `10.33.35.0/24` |
| `SSH_ALLOWED_CIDR` | Publiczny IPv4 z `eth0` hosta agenta z dopisanym `/32` |

Opcjonalne zmienne mają wartości domyślne:

| Nazwa | Domyślnie |
| --- | --- |
| `DO_REGION` | `fra1` |
| `DO_VM_IMAGE` | `ubuntu-24-04-x64` |
| `DO_VM_SIZE` | `s-1vcpu-1gb` |
| `TF_STATE_ROOT` | `terraform-state` w katalogu domowym konta agenta |

Jeżeli ustawiasz `TF_STATE_ROOT`, podaj bezwzględną ścieżkę do trwałego
katalogu **poza checkoutem repozytorium**. Nie używaj `_work` ani katalogu
tymczasowego joba. Pipeline dołącza `cwiczenie02/<GITHUB_REPOSITORY_ID>`
do katalogu bazowego, aby rozdzielić dane repozytoriów. Przykładowa własna
wartość to `/home/student/terraform-state`.

Teraz w zakładce **Secrets** dodaj jeden Repository secret:

| Nazwa | Wartość |
| --- | --- |
| `DIGITALOCEAN_TOKEN` | Twój token DigitalOcean z prawami zarządzania VM, VPC, firewallami i kluczami SSH, w tym ich usuwania |

Nie dodawaj prywatnego klucza SSH do Secrets. Parę ED25519 utworzy Terraform.
Wartości tokenu nie wpisuj do YAML, `.tfvars` ani logów.

## 4. Skopiuj własny kod z ćwiczenia 01

Teraz utwórz `CWICZENIA_TERRAFORM/cwiczenie02/terraform`. Skopiuj do niego
**własne źródła** z ćwiczenia 01: `versions.tf`, `variables.tf`, `main.tf`
i `outputs.tf`. Dodaj niesekretny `terraform.tfvars.example`, jeśli nie
utworzyłeś go wcześniej. Lockfile `.terraform.lock.hcl` także możesz skopiować.

Nie kopiuj całego katalogu ćwiczenia 01: state, `.terraform/`, `.keys/`,
plany i rzeczywisty `terraform.tfvars` mają pozostać poza nową konfiguracją.
Wzorzec instruktora `rozwiazanie_ukryte/` jest ignorowany przez Git i nie
trafia do klonu ucznia. Workflow czyta **publiczny katalog
`cwiczenie02/terraform`**, a nie ukryte rozwiązanie.

To osobny state. Nie wskazuj pipeline na state z ćwiczenia 01. Najpierw
posprzątaj tamte zasoby albo uzgodnij nową wolną sieć `/24`. Losowy sufiks
zapobiega kolizjom nazw, ale nie pozwala tworzyć VPC z nakładającymi się
zakresami adresów.

## 5. Dodaj lokalny backend sterowany przez pipeline

Teraz w `versions.tf` dodaj do istniejącego bloku `terraform`:

```hcl
backend "local" {}
```

Pozostaw deklaracje providerów z ćwiczenia 01. Ścieżkę state przekaże
pipeline podczas `terraform init`, zamiast zapisywać ją na stałe w kodzie.
Domyślna lokalizacja na dysku self-hosted to:

```text
<HOME_konta_agenta>/terraform-state/cwiczenie02/<GITHUB_REPOSITORY_ID>/terraform.tfstate
```

Zachowaj ten sam katalog pomiędzy przebiegami. Usunięcie state nie usuwa
zasobów DigitalOcean i pozbawia Terraform informacji o nich.
Workflow zapisuje znacznik `.initialized` i odrzuca kolejne operacje, jeśli
wcześniej używany state zniknął. W takim przypadku przywróć właściwy state;
nie usuwaj znacznika ani nie zmieniaj `TF_STATE_ROOT`, aby ominąć ten błąd.

## 6. Przenieś plik klucza poza checkout

Teraz dodaj w `variables.tf` zmienną `ssh_private_key_path` typu `string`,
a w `local_sensitive_file.private_key` ustaw `filename` na jej wartość.
Pipeline przekaże bezwzględną ścieżkę `keys/id_ed25519` obok state.
Pozostaw prawa klucza `0600` i katalogu `0700`.

Teraz zaktualizuj output `private_key_path`, aby odczytywał rzeczywistą
ścieżkę utworzonego pliku. Output `ssh_private_key` zachowaj z
`sensitive = true`; pipeline nie ma odczytywać jego zawartości.

Job `provision` robi checkout, który może czyścić katalog repozytorium przy
kolejnych przebiegach. Dlatego state i klucz muszą być poza nim. Job SSH
korzysta wyłącznie z trwałego pliku i nie potrzebuje checkoutu. Zawartości
klucza nie przekazuj przez job outputs ani artefakty. State także zawiera
klucz prywatny i wymaga ochrony.

## 7. Rozszerz reguły firewalla

Teraz zmień `digitalocean_firewall` w `main.tf`. Zachowaj przypisanie przez
`droplet_ids` do VM i skonfiguruj reguły przychodzące:

| Protokół | Porty | Źródło |
| --- | --- | --- |
| TCP | `22` | Wyłącznie `var.ssh_allowed_cidr`, czyli IPv4 `/32` hosta agenta |
| TCP | `80` | Cały Internet |
| TCP | `443` | Cały Internet |
| TCP | `18000-18999` | Cały Internet |

Dla publicznych portów użyj `0.0.0.0/0` i `::/0`. Nie rozszerzaj reguły
SSH na te źródła. Zachowaj reguły wychodzące TCP, UDP i ICMP z ćwiczenia 01.

Otwarcie portu nie instaluje serwera WWW. To ćwiczenie tworzy VM i sprawdza
SSH; nie wymagaj udanego `curl` na porcie `80`, `443` ani `18000`.

## 8. Udostępnij źródła Terraform w repozytorium

Teraz sprawdź, że pliki `.tf` są w `CWICZENIA_TERRAFORM/cwiczenie02/terraform`
i są widoczne dla Gita. Zapisz i wyślij źródła, lockfile oraz niesekretny
`terraform.tfvars.example` do repozytorium.

Nie dodawaj state, rzeczywistych `.tfvars`, kluczy, planów, pobranych
providerów ani `rozwiazanie_ukryte`. Workflow zakończy się czytelnym błędem,
jeśli w repozytorium brakuje źródeł ucznia.

## 9. Przygotuj workflow i współbieżność

Teraz otwórz plik
[.github/workflows/terraform-cwiczenie02.yaml](../../.github/workflows/terraform-cwiczenie02.yaml).
Aktywny plik stanowi wzorzec pipeline do analizy; kod Terraform przygotowujesz
samodzielnie. Przygotuj `workflow_dispatch` z inputem `operation` typu
`choice`, o wartościach `apply` i `destroy`. Ustaw `permissions: contents: read`.

Na poziomie całego workflow ustaw grupę `concurrency` wspólną dla
repozytorium, z `cancel-in-progress: false`. Nie różnicuj jej według gałęzi
ani operacji: apply i destroy dotyczą tego samego state i nie mogą działać
jednocześnie.

Teraz zdefiniuj dwa joby:

```text
provision → check-ssh
```

Oba używają `[self-hosted, linux]`. `check-ssh` wymaga sukcesu `provision`
i uruchamia się tylko dla `apply`.

## 10. Przygotuj środowisko joba provision

Teraz dodaj `actions/checkout@v7` z `persist-credentials: false` oraz
`hashicorp/setup-terraform@v4` z `terraform_version: '1.17.2'`
i `terraform_wrapper: false`. Dodaj kontrolę obecności źródeł w publicznym
katalogu `cwiczenie02/terraform`.

Teraz wylicz trwały katalog state, utwórz go z prywatnymi prawami i wyznacz
ścieżkę klucza `keys/id_ed25519`. Sprawdź bezwzględne ścieżki oraz położenie
poza checkoutem i katalogiem tymczasowym.

Wartości Terraform przekaż przez środowisko procesu:

| Zmienna procesu | Źródło |
| --- | --- |
| `TF_VAR_vm_name` | `vars.VM_NAME` |
| `TF_VAR_vpc_name` | `vars.VPC_NAME` |
| `TF_VAR_firewall_name` | `vars.FIREWALL_NAME` |
| `TF_VAR_vpc_cidr` | `vars.VPC_CIDR` |
| `TF_VAR_ssh_allowed_cidr` | `vars.SSH_ALLOWED_CIDR` |
| `TF_VAR_region` | `vars.DO_REGION` lub `fra1` |
| `TF_VAR_vm_image` | `vars.DO_VM_IMAGE` lub `ubuntu-24-04-x64` |
| `TF_VAR_vm_size` | `vars.DO_VM_SIZE` lub `s-1vcpu-1gb` |
| `TF_VAR_ssh_private_key_path` | Wyliczona ścieżka pliku na trwałym dysku |
| `DIGITALOCEAN_TOKEN` | `secrets.DIGITALOCEAN_TOKEN` |

Dane z GitHub przekazuj przez `env`, nie wklejaj ich bezpośrednio do `run`.
Sprawdź brak wymaganych wartości i poprawność CIDR przed planowaniem zmian.

## 11. Wykonaj plan i apply albo destroy

Teraz dodaj osobne kroki:

1. `terraform fmt -check`.
2. `terraform init` z `-backend-config` wskazującym bezwzględny plik
   `terraform.tfstate` w trwałym katalogu.
3. `terraform validate`.
4. Plan zapisany poza checkoutem, obok state.
5. `terraform apply` wskazujące zapisany plan.

Polecenia wykonuj dla katalogu źródeł przez `-chdir`, zgodnie ze zmiennymi
przygotowanymi w workflow. Dla operacji `apply` są to:

```bash
terraform -chdir="$TF_SOURCE_DIR" fmt -check
terraform -chdir="$TF_SOURCE_DIR" init -input=false -reconfigure -backend-config="path=$STATE_FILE"
terraform -chdir="$TF_SOURCE_DIR" validate
terraform -chdir="$TF_SOURCE_DIR" plan -input=false -out="$PLAN_FILE"
terraform -chdir="$TF_SOURCE_DIR" apply -input=false "$PLAN_FILE"
```

Dla `apply` przygotuj zwykły plan, a dla `destroy` plan z `-destroy`.
Zastosowanie planu w pipeline wykonuje rzeczywiste zmiany w DigitalOcean;
utworzenie VM wiąże się z opłatami.

Plan zapisz w podkatalogu `plans` przy state, z nazwą opartą na ID przebiegu
i próby, z prawami `0600`. Końcowy krok `if: always()` ma usunąć tylko plan
tego przebiegu, zachowując state oraz klucz.

Po apply odczytaj **wyłącznie potrzebne** outputy: `public_ip` i
`private_key_path`, używając `terraform output -raw <nazwa>`. Do job outputs
przekaż:

| Job output | Zawartość |
| --- | --- |
| `public_ip` | Publiczny IPv4 utworzonej VM |
| `private_key_path` | Ścieżka pliku prywatnego klucza |
| `state_directory` | Ścieżka trwałego katalogu state |
| `runner_name` | Nazwa runnera wykonującego provision |

Zawartość klucza pozostaje na dysku hosta.

Nie wypisuj wszystkich outputs przez `terraform output -json` i nie
publikuj state ani planu jako artefaktu. Takie pliki mogą zawierać wrażliwe
dane, nawet jeśli zwykły log Terraform je maskuje.

## 12. Dodaj osobny job check-ssh

Teraz dodaj `needs: provision` i warunek pomijający job dla `destroy`.
Porównaj aktualne `runner.name` z nazwą przekazaną przez `provision`.
Niezgodność ma zakończyć job błędem; nie szukaj klucza na innym hoście.

Teraz sprawdź istnienie pliku klucza w przekazanej ścieżce i jego prawa
`0600`. Zaloguj się jako `root` na publiczny IP z outputu `provision`.
Użyj:

- `BatchMode=yes`, aby brak klucza nie wywołał pytania o hasło;
- `IdentitiesOnly=yes`, aby użyć wskazanego klucza;
- `StrictHostKeyChecking=accept-new`;
- trwałego `known_hosts` obok state;
- do 30 prób z odstępami pięciu sekund i timeoutem połączenia pięć sekund,
  ponieważ nowa VM może jeszcze uruchamiać SSH.

Wykonaj zdalne polecenie potwierdzające użytkownika i host i oznacz sukces
w logu jako `SSH_OK`. Otwarty port `22` nie zastępuje poprawnego logowania kluczem.

`accept-new` oznacza zaufanie przy pierwszym połączeniu: pierwszy klucz
hosta zostaje zapamiętany, a zmiana znanego klucza blokuje logowanie.
Nie jest to niezależne wcześniejsze sprawdzenie tożsamości VM. Przy zmianie
klucza wyjaśnij sytuację z prowadzącym zamiast czyścić `known_hosts` na ślepo.

## 13. Uruchom tworzenie i sprawdź rezultat

Teraz zapisz workflow i źródła Terraform w repozytorium. Udostępnij workflow
również na domyślnej gałęzi, aby pojawił się formularz. W **Actions** wybierz
workflow ćwiczenia 02, kliknij **Run workflow** i ustaw `operation: apply`.

Teraz sprawdź:

1. `provision` zakończył plan i apply bez błędu.
2. State i klucz powstały w trwałym katalogu konta agenta.
3. `check-ssh` potwierdził realne SSH na tym samym runnerze.
4. W DigitalOcean VM należy do wybranej VPC i ma przypisany firewall.
5. SSH dopuszcza tylko `/32` agenta, a publiczne reguły obejmują TCP
   `80`, `443` i `18000-18999`.

Teraz uruchom ponownie `apply` bez zmiany kodu i Variables. Plan ma używać
tego samego state, zachować nazwy z sufiksem i nie tworzyć drugiej kopii
zasobów. Test SSH ma ponownie przejść.

## 14. Usuń zasoby przez ten sam workflow

Teraz wybierz **Run workflow → operation: destroy**. Job `provision`
przygotuje i zastosuje plan usuwania, a `check-ssh` zostanie pominięty.
Sprawdź w DigitalOcean usunięcie zasobów zarządzanych przez ten state.

Nie usuwaj katalogu state przed udanym destroy. Jeśli DigitalOcean odmawia
usunięcia VPC, bo stała się domyślną w regionie, uzgodnij z prowadzącym
wskazanie innej istniejącej VPC jako domyślnej i ponów destroy. Nie usuwaj
ani nie modyfikuj samodzielnie cudzych sieci.

Po sprzątaniu chroń state i jego kopie; wcześniejsze wersje mogą nadal
zawierać klucz prywatny. Usunięcie pliku state nie usuwa infrastruktury.

Zadanie jest ukończone, gdy oba joby działają na jednym self-hosted,
Terraform używa trwałego lokalnego state, SSH przechodzi wygenerowanym
kluczem, a kolejne apply i destroy korzystają z tych samych danych.
Sama poprawność YAML i `terraform validate` nie potwierdza SSH ani VM.

Dokumentacja:
[dodawanie self-hosted runnera](https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/add-runners),
[lokalny backend Terraform](https://developer.hashicorp.com/terraform/language/backend/local)
oraz [StrictHostKeyChecking w OpenSSH](https://man.openbsd.org/ssh_config#StrictHostKeyChecking).
