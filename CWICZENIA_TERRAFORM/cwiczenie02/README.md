# Ćwiczenie 02 — Terraform w GitHub Actions i osobny test SSH

Przygotuj od początku konfigurację Terraform oraz workflow GitHub Actions,
który utworzy VM DigitalOcean, VPC, firewall i parę kluczy SSH. Uruchom
Terraform na istniejącym agencie self-hosted, a następnie w osobnym jobie
sprawdź rzeczywiste logowanie do nowej VM. Wszystkie pliki do utworzenia
podano poniżej w pełnej postaci.

Docelowa kolejność:

```text
Run workflow: apply
  → provision: init → validate → plan → apply
  → check-ssh: logowanie wygenerowanym kluczem i polecenia na VM

Run workflow: destroy
  → provision: init → validate → plan -destroy → apply planu usuwania
  → check-ssh: pominięty
```

State i klucz prywatny pozostają na trwałym dysku jednego agenta. Nie są
przesyłane przez artefakty ani job outputs. To ćwiczenie przygotowuje VM
i sprawdza SSH; instalację aplikacji wykonasz w osobnym ćwiczeniu.

## 1. Przygotuj jeden host self-hosted

Teraz otwórz **Settings → Actions → Runners → New self-hosted runner**
w swoim repozytorium. Wybierz Linux oraz architekturę maszyny szkoleniowej
i wykonaj na niej instrukcje rejestracji pokazane przez GitHub.

Teraz uruchom agenta i sprawdź jego dostępność z etykietami `self-hosted`
i `linux`. Użyj runnera co najmniej `2.327.1`, obsługującego akcje Node.js 24.
Na koncie agenta zapewnij Bash, klienta OpenSSH, `ip` z pakietu iproute2
oraz GNU coreutils, w tym `realpath` i `stat`. Terraform w jobie przygotuje
akcja `hashicorp/setup-terraform`.

Pozostaw **jednego aktywnego runnera** pasującego do `[self-hosted, linux]`.
Oba joby i kolejne przebiegi mają trafiać na ten sam fizyczny host: state
oraz plik klucza znajdują się na jego lokalnym dysku. Sprawdzenie nazwy
runnera w drugim jobie zatrzyma wykonanie, jeśli joby trafią na różne agenty.

## 2. Odczytaj publiczny IPv4 interfejsu eth0 agenta

Teraz na maszynie szkoleniowej z agentem wykonaj:

```bash
ip a
ip -4 addr show dev eth0
```

Znajdź adres z wiersza `inet` interfejsu `eth0`. W tym środowisku szkoleniowym
jest to publiczny IPv4 maszyny agenta. Skopiuj sam adres, **bez maski
interfejsu**, i dopisz `/32`.

Przykład dokumentacyjny:

```text
Wynik ip:          inet 203.0.113.20/20 ... eth0
SSH_ALLOWED_CIDR:   203.0.113.20/32
```

Ustaw rzeczywisty adres swojego agenta. Przykładowy `203.0.113.20` i maska
interfejsu `/20` nie są wartościami do przepisania. Połączenie SSH wykona
job na agencie, dlatego dopuszczasz publiczny IPv4 agenta `/32`, a nie laptopa.

## 3. Zadeklaruj Repository variables oraz secret

Teraz otwórz **Settings → Secrets and variables → Actions → Variables**
i dodaj wymagane Repository variables:

| Nazwa | Wartość |
| --- | --- |
| `VM_NAME` | Własna nazwa bazowa VM, np. `jan-kowalski-cw02-vm` |
| `VPC_NAME` | Własna nazwa bazowa VPC, np. `jan-kowalski-cw02-vpc` |
| `FIREWALL_NAME` | Własna nazwa bazowa firewalla, np. `jan-kowalski-cw02-firewall` |
| `VPC_CIDR` | Wolna prywatna sieć `/24` uzgodniona z prowadzącym, np. `10.33.35.0/24` |
| `SSH_ALLOWED_CIDR` | Publiczny IPv4 z `eth0` Twojego agenta z dopisanym `/32` |

Nazwy mają mieć 3–50 znaków: małe litery, cyfry i myślniki, początek literą,
a koniec literą lub cyfrą. Terraform dopisze do nazw stały losowy sufiks
sześciu znaków. Sufiks jest zachowywany w state między kolejnymi przebiegami.

Zmienne opcjonalne mają następujące wartości domyślne w workflow:

| Nazwa | Domyślnie |
| --- | --- |
| `DO_REGION` | `fra1` |
| `DO_VM_IMAGE` | `ubuntu-24-04-x64` |
| `DO_VM_SIZE` | `s-1vcpu-1gb` |
| `TF_STATE_ROOT` | `$HOME/terraform-state` konta usługi runnera |

Jeżeli ustawiasz `TF_STATE_ROOT`, wpisz bezwzględną ścieżkę do trwałego
katalogu poza checkoutem i katalogiem tymczasowym joba, np.
`/home/student/terraform-state`. Zachowaj tę samą wartość w kolejnych
uruchomieniach. Pipeline dołączy `cwiczenie02/<GITHUB_REPOSITORY_ID>`.

Teraz w zakładce **Secrets** dodaj Repository secret:

| Nazwa | Wartość |
| --- | --- |
| `DIGITALOCEAN_TOKEN` | Twój token DigitalOcean z prawami tworzenia, odczytu, aktualizacji i usuwania VM, VPC, firewalli oraz kluczy SSH |

Token przekazuj wyłącznie przez `secrets.DIGITALOCEAN_TOKEN`. Parę ED25519
utworzy Terraform: prywatnego klucza nie dodajesz do GitHub Secrets ani Gita.
Uzgodnij wolną sieć `/24`; losowy sufiks nazw nie zapobiega nakładaniu się
zakresów VPC. Każde ćwiczenie ma korzystać ze swojego state.

## 4. Utwórz katalogi i komplet plików

Teraz otwórz główny katalog swojego repozytorium i wykonaj:

```bash
mkdir -p CWICZENIA_TERRAFORM/cwiczenie02/terraform
mkdir -p .github/workflows
```

Utwórz w edytorze każdy plik podany w krokach 5–10 i wklej jego pełną treść.
Wszystkie ścieżki w instrukcji są względne wobec głównego katalogu repozytorium.
Docelowa struktura:

```text
.gitignore
.github/
  workflows/
    terraform-cwiczenie02.yaml
CWICZENIA_TERRAFORM/
  cwiczenie02/
    README.md
    terraform/
      versions.tf
      variables.tf
      main.tf
      outputs.tf
      terraform.tfvars.example
      .terraform.lock.hcl        # wygenerowany przez terraform init
```

Nie przepisuj ręcznie `.terraform.lock.hcl`; wygenerujesz go w kroku 11.
Poniższy kod jest kompletny i nie wymaga plików z poprzednich ćwiczeń.

## 5. Ustaw wersje providerów i lokalny backend

Teraz utwórz `versions.tf` z poniższą treścią. Provider pobierze token ze
zmiennej procesu `DIGITALOCEAN_TOKEN`. Lokalny backend otrzyma ścieżkę state
podczas `terraform init` w workflow.

### Plik: `CWICZENIA_TERRAFORM/cwiczenie02/terraform/versions.tf`

```hcl
terraform {
  required_version = ">= 1.6.0, < 2.0.0"

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
```

## 6. Zadeklaruj wejścia konfiguracji

Teraz utwórz `variables.tf`. Walidacje sprawdzają nazwy, prywatną sieć
IPv4 `/24`, pojedynczy adres SSH `/32` oraz niepustą ścieżkę pliku klucza.
W pipeline wartości przekażesz przez `TF_VAR_*`; lokalne wartości domyślne
nie zastępują wymaganych Repository variables.

### Plik: `CWICZENIA_TERRAFORM/cwiczenie02/terraform/variables.tf`

```hcl
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
```

## 7. Utwórz zasoby, klucz SSH i firewall

Teraz utwórz `main.tf`. Przeczytaj zależności: VPC i publiczny klucz są
używane przez VM, a firewall jest przypisany przez jej `droplet_ids`.
`local_sensitive_file` zapisze prywatny klucz z prawami `0600` w katalogu
`0700`; pipeline wskaże ścieżkę poza checkoutem.

Reguła SSH dopuszcza wyłącznie `/32` agenta. TCP `80`, `443` i `18000-18999`
są publiczne. Sama reguła firewalla nie uruchamia aplikacji na tych portach.
Konfiguracja VM wyłącza IPv6, a publiczne reguły firewalla zachowują oba
zakresy adresów. Ruch wychodzący TCP, UDP i ICMP pozostaje dozwolony.

### Plik: `CWICZENIA_TERRAFORM/cwiczenie02/terraform/main.tf`

```hcl
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
```

## 8. Dodaj outputy do weryfikacji

Teraz utwórz `outputs.tf`. Workflow odczyta tylko `public_ip` oraz
`private_key_path`, a do drugiego joba przekaże IP i ścieżkę pliku.
Output `ssh_private_key` jest oznaczony jako sensitive i nie jest
odczytywany przez pipeline. Sam state nadal zawiera prywatny klucz.

### Plik: `CWICZENIA_TERRAFORM/cwiczenie02/terraform/outputs.tf`

```hcl
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
```

## 9. Zapisz przykład danych i reguły ignorowania plików lokalnych

Teraz utwórz `terraform.tfvars.example`. To niesekretny przykład do Gita.
Dla uruchomienia w GitHub Actions ustaw wartości w Repository variables,
jak w kroku 3; **nie twórz rzeczywistego `terraform.tfvars` w katalogu źródeł
pipeline**. Taki plik służy jedynie osobnemu uruchomieniu lokalnemu i jego
wartości miałyby pierwszeństwo przed zmiennymi `TF_VAR_*`.

### Plik: `CWICZENIA_TERRAFORM/cwiczenie02/terraform/terraform.tfvars.example`

```hcl
# Skopiuj do terraform.tfvars i wpisz własne imię/nazwisko w nazwach zasobów.
vm_name       = "jan-kowalski-cw02-vm"
vpc_name      = "jan-kowalski-cw02-vpc"
firewall_name = "jan-kowalski-cw02-firewall"

region   = "fra1"
vm_image = "ubuntu-24-04-x64"
vm_size  = "s-1vcpu-1gb"

# Wybierz sieć niepokrywającą się z CW01 i innymi VPC na wspólnym koncie.
vpc_cidr = "10.33.35.0/24"

# To adres dokumentacyjny. ZASTĄP go publicznym IPv4 SELF-HOSTED RUNNERA /32.
# SSH będzie wykonywane z runnera w osobnym jobie, a nie z laptopa ucznia.
ssh_allowed_cidr = "203.0.113.10/32"

# W pipeline nie wpisuj tutaj ścieżki: workflow przekaże ssh_private_key_path
# do trwałego katalogu stanu poza checkoutem. Lokalny domyślny plik:
# ssh_private_key_path = ".keys/id_ed25519"

# Token API ustaw tylko przez zmienną środowiskową DIGITALOCEAN_TOKEN.
# Nie dopisuj tokenu do tego pliku.
```

Teraz otwórz główny `.gitignore` i dopisz brakujące reguły z poniższego
bloku. Zachowaj wszystkie istniejące wpisy w swoim repozytorium.
Jeśli pliku jeszcze nie ma, utwórz go z tymi regułami.

### Reguły do dopisania w `.gitignore`

```gitignore
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
```

## 10. Utwórz kompletny workflow GitHub Actions

Teraz utwórz `.github/workflows/terraform-cwiczenie02.yaml` z pełną treścią
poniżej. Zwróć uwagę na:

- ręczne wejście `operation` z wartościami `apply` i `destroy`;
- grupę `concurrency` wspólną dla obu operacji i wszystkich gałęzi repozytorium;
- dwa joby na `[self-hosted, linux]`, z `check-ssh` uruchamianym tylko po udanym `apply`;
- przekazywanie Variables i Secrets przez `env`;
- osobne kroki `fmt`, `init`, `validate`, `plan` i zastosowania zapisanego planu;
- trwały state i klucz poza checkoutem oraz usuwanie wyłącznie planu danego przebiegu;
- prawdziwe logowanie SSH w drugim jobie, z trwałym plikiem `known_hosts`.

### Plik: `.github/workflows/terraform-cwiczenie02.yaml`

```yaml
# Ćwiczenie 02 — najpierw przygotuj i dodaj do Gita własne pliki .tf w:
# CWICZENIA_TERRAFORM/cwiczenie02/terraform (instrukcja w cwiczenie02/README.md).
# Nie odwołuj się do rozwiazanie_ukryte: ten katalog nie trafia do GitHub.
# Settings → Secrets and variables → Actions:
# Secret: DIGITALOCEAN_TOKEN — token zarządzający VM, VPC, firewallem i kluczami SSH.
# Variables wymagane:
#   VM_NAME = jan-kowalski-cw02-vm
#   VPC_NAME = jan-kowalski-cw02-vpc
#   FIREWALL_NAME = jan-kowalski-cw02-firewall
#   VPC_CIDR = 10.33.35.0/24 — wolny zakres, niepokrywający się z innymi VPC.
#   SSH_ALLOWED_CIDR = PUBLICZNY_IP_RUNNERA/32 (odczytaj ip a → eth0 na maszynie ćwiczeniowej).
# Variables opcjonalne: DO_REGION=fra1, DO_VM_IMAGE=ubuntu-24-04-x64,
#   DO_VM_SIZE=s-1vcpu-1gb, TF_STATE_ROOT=/home/student/terraform-state.
# Bez TF_STATE_ROOT używamy $HOME/terraform-state konta usługi runnera.
# Oba joby i kolejne uruchomienia MUSZĄ trafić na ten sam host z trwałym dyskiem.
# W tym ćwiczeniu repozytorium ma jednego aktywnego runnera self-hosted Linux.
# Akcje Node.js 24 wymagają runnera >= 2.327.1; zainstaluj aktualny runner.

name: Terraform — ćwiczenie 02
run-name: CW02 Terraform — ${{ inputs.operation }}

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
  group: terraform-cwiczenie02-${{ github.repository_id }}
  cancel-in-progress: false

defaults:
  run:
    shell: bash

env:
  TF_SOURCE_DIR: ./CWICZENIA_TERRAFORM/cwiczenie02/terraform
  TERRAFORM_VERSION: '1.17.2'
  TF_IN_AUTOMATION: 'true'
  TF_INPUT: 'false'
  TF_WORKSPACE: default

jobs:
  provision:
    name: Terraform init, validate, plan i apply
    runs-on: [self-hosted, linux]
    timeout-minutes: 25
    outputs:
      public_ip: ${{ steps.metadata.outputs.public_ip }}
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
        run: |
          set -euo pipefail
          umask 077
          case "$OPERATION" in
            apply|destroy) ;;
            *) echo "::error::Dozwolone operacje to apply i destroy."; exit 1 ;;
          esac
          for file in versions.tf variables.tf main.tf outputs.tf; do
            if [ ! -f "${TF_SOURCE_DIR}/${file}" ]; then
              echo "::error::Przygotuj i dodaj do Gita ${TF_SOURCE_DIR}/${file} zgodnie z instrukcją CW02."
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
          state_root="${REQUESTED_STATE_ROOT:-${HOME}/terraform-state}"
          if [[ "$state_root" != /* || "$state_root" =~ [[:cntrl:]] ]]; then
            echo "::error::TF_STATE_ROOT musi być bezwzględną ścieżką na trwałym dysku runnera, bez znaków sterujących."
            exit 1
          fi
          state_root="$(realpath -m -- "$state_root")"
          workspace="$(realpath -e -- "$GITHUB_WORKSPACE")"
          runner_temporary="$(realpath -m -- "$RUNNER_TEMP")"
          state_directory="$(realpath -m -- "${state_root}/cwiczenie02/${GITHUB_REPOSITORY_ID}")"
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
          echo "Stan CW02 pozostaje na hoście runnera, poza checkoutem: $state_file"

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
        run: |
          umask 077
          terraform -chdir="$TF_SOURCE_DIR" apply -input=false "$PLAN_FILE"
          test -s "$STATE_FILE"
          for file in "$STATE_FILE" "${STATE_FILE}.backup"; do
            if [ -f "$file" ]; then
              chmod 600 "$file"
            fi
          done
          printf '%s\n' 'cwiczenie02' > "${STATE_DIRECTORY}/.initialized"

      - name: Udostępnij IP i ścieżkę klucza, bez jego zawartości
        id: metadata
        if: ${{ inputs.operation == 'apply' }}
        run: |
          public_ip="$(terraform -chdir="$TF_SOURCE_DIR" output -raw public_ip)"
          private_key_path="$(terraform -chdir="$TF_SOURCE_DIR" output -raw private_key_path)"
          [[ "$public_ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]
          test "$private_key_path" = "${STATE_DIRECTORY}/keys/id_ed25519"
          test -s "$private_key_path"
          {
            echo "public_ip=$public_ip"
            echo "private_key_path=$private_key_path"
          } >> "$GITHUB_OUTPUT"

      - name: Podsumuj wynik Terraform
        env:
          OPERATION: ${{ inputs.operation }}
          PUBLIC_IP: ${{ steps.metadata.outputs.public_ip }}
        run: |
          {
            echo "### CW02 — Terraform $OPERATION"
            echo ""
            echo "- Runner: $RUNNER_NAME"
            echo "- Lokalny state: $STATE_FILE"
            if [ "$OPERATION" = apply ]; then
              echo "- Publiczny IPv4 nowej VM: $PUBLIC_IP"
              echo "- Porty publiczne TCP: 80, 443, 18000–18999"
              echo "- SSH: 22 wyłącznie z adresu runnera; osobny job sprawdzi logowanie."
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

  check-ssh:
    name: Sprawdź rzeczywiste logowanie SSH kluczem TLS
    needs: provision
    if: ${{ inputs.operation == 'apply' }}
    runs-on: [self-hosted, linux]
    timeout-minutes: 10
    env:
      PUBLIC_IP: ${{ needs.provision.outputs.public_ip }}
      PRIVATE_KEY_PATH: ${{ needs.provision.outputs.private_key_path }}
      STATE_DIRECTORY: ${{ needs.provision.outputs.state_directory }}
      PROVISION_RUNNER_NAME: ${{ needs.provision.outputs.runner_name }}
    steps:
      - name: Sprawdź host oraz trwały plik klucza
        run: |
          set -euo pipefail
          umask 077
          if [ "$RUNNER_NAME" != "$PROVISION_RUNNER_NAME" ]; then
            echo "::error::Oba joby wymagają tego samego runnera i dysku. Pozostaw jednego pasującego runnera albo skonfiguruj wspólną unikalną etykietę."
            exit 1
          fi
          [[ "$PUBLIC_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]
          test "$PRIVATE_KEY_PATH" = "${STATE_DIRECTORY}/keys/id_ed25519"
          test -s "$PRIVATE_KEY_PATH"
          test ! -L "$PRIVATE_KEY_PATH"
          test "$(stat -c '%u' "$PRIVATE_KEY_PATH")" = "$(id -u)"
          test "$(stat -c '%a' "$PRIVATE_KEY_PATH")" = 600
          command -v ssh

      - name: Poczekaj na SSH i wykonaj polecenia na nowej VM
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
              'set -eu; test "$(id -u)" -eq 0; hostname; id; ip -4 address'; then
              echo "SSH_OK — logowanie wygenerowanym kluczem i polecenia zdalne działają."
              {
                echo "### CW02 — test SSH zakończony sukcesem"
                echo ""
                echo "- VM: $PUBLIC_IP"
                echo "- Użytkownik: root"
                echo "- Uwierzytelnianie: klucz wygenerowany przez tls_private_key"
                echo "- Runner: $RUNNER_NAME"
              } >> "$GITHUB_STEP_SUMMARY"
              exit 0
            fi
            if [ "$attempt" -lt 30 ]; then
              sleep 5
            fi
          done
          echo "::error::Nie udało się zalogować kluczem SSH. Sprawdź SSH_ALLOWED_CIDR, host runnera, firewall, klucz i known_hosts."
          exit 1
```

## 11. Sprawdź pliki i wygeneruj lockfile

Teraz na komputerze przygotowującym repozytorium użyj Terraform `1.17.2`,
tak jak w workflow. W głównym katalogu repozytorium wykonaj:

```bash
terraform -chdir=CWICZENIA_TERRAFORM/cwiczenie02/terraform fmt -check
terraform -chdir=CWICZENIA_TERRAFORM/cwiczenie02/terraform init -backend=false -input=false
terraform -chdir=CWICZENIA_TERRAFORM/cwiczenie02/terraform validate
git diff --check
git status --short
```

`init -backend=false` pobierze providery i wygeneruje `.terraform.lock.hcl`,
bez inicjalizowania lokalnego backendu. Nie tworzy VM. Plik lock określa
wybrane wersje providerów i sumy kontrolne: dodaj go do Gita, a `.terraform/`
pozostaw ignorowany. `validate` sprawdza konfigurację; nie potwierdza
uprawnień tokenu, wolnej sieci VPC ani udanego logowania SSH.

Teraz dodaj do repozytorium `.gitignore`, pięć plików źródłowych z kroków
5–9, wygenerowany `.terraform.lock.hcl` i workflow. Sprawdź, że nie dodajesz
state, planów, pobranych providerów, rzeczywistych `.tfvars` ani kluczy.
Zapisz commit i wyślij pliki do własnego repozytorium. Umieść workflow także
na gałęzi domyślnej, aby formularz **Run workflow** był dostępny.

## 12. Uruchom apply i sprawdź oba joby

Teraz w **Actions** wybierz **Terraform — ćwiczenie 02 → Run workflow**.
Wskaż gałąź zawierającą pełny kod i ustaw `operation: apply`.

Job `provision` wykona kolejno:

1. Sprawdzenie wymaganych plików, Variables i sekretu.
2. Przygotowanie trwałego katalogu state i pliku klucza poza checkoutem.
3. `terraform fmt -check`, `init` oraz `validate`.
4. Zapisanie planu i zastosowanie dokładnie tego planu.
5. Odczyt IP oraz ścieżki pliku klucza i przekazanie metadanych drugiemu jobowi.
6. Usunięcie planu tego przebiegu w kroku `if: always()`.

Domyślne ścieżki na dysku konta usługi runnera:

```text
$HOME/terraform-state/cwiczenie02/<GITHUB_REPOSITORY_ID>/
  terraform.tfstate
  terraform.tfstate.backup       # jeżeli Terraform utworzył kopię
  .initialized
  keys/id_ed25519
  plans/<GITHUB_RUN_ID>-<GITHUB_RUN_ATTEMPT>.tfplan  # usuwany na końcu joba
  known_hosts                   # zapisywany przez job check-ssh
```

Katalogi state, keys i plans mają prawa `0700`, a klucz, plan i pliki state
`0600`. State i jego kopie zawierają klucz prywatny. Zachowaj je na tym samym
trwałym dysku między uruchomieniami; usunięcie state nie usuwa zasobów.
Znacznik `.initialized` blokuje kolejne operacje po zniknięciu używanego
state. Wtedy przywróć właściwy state i ustal przyczynę; nie omijaj ochrony
przez zmianę `TF_STATE_ROOT` lub usunięcie znacznika.

Przepływ job outputs:

| Output joba `provision` | Zawartość i wykorzystanie w `check-ssh` |
| --- | --- |
| `public_ip` | Publiczny IPv4 VM do połączenia SSH |
| `private_key_path` | Ścieżka istniejącego pliku klucza na dysku agenta |
| `state_directory` | Trwały katalog i położenie `known_hosts` |
| `runner_name` | Kontrola, że oba joby używają tego samego runnera |

Teraz sprawdź, że `check-ssh` zakończył się sukcesem i wypisał `SSH_OK`.
Job rzeczywiście loguje się jako `root`, sprawdza jego UID oraz wykonuje
`hostname`, `id` i `ip -4 address` na nowej VM. Otwarty port 22 nie wystarcza:
ma zadziałać uwierzytelnienie wygenerowanym kluczem.

`StrictHostKeyChecking=accept-new` zapisuje klucz przy pierwszym kontakcie
i odrzuca późniejszą zmianę znanego klucza. To zaufanie przy pierwszym
połączeniu, a nie niezależne wcześniejsze potwierdzenie tożsamości VM.
Przy konflikcie `known_hosts` wyjaśnij go z prowadzącym; nie czyść pliku
w ciemno. Job podejmuje do 30 prób SSH z odstępami pięciu sekund.

Teraz w panelu DigitalOcean potwierdź nazwę VM z sufiksem, przypisanie do
własnej VPC oraz firewall: SSH tylko z `/32` agenta, publiczne TCP `80`,
`443` i `18000-18999`. Na tych portach nie jest jeszcze instalowany serwer WWW.
W tym ćwiczeniu nie oczekujesz odpowiedzi aplikacji po HTTP ani HTTPS.

## 13. Powtórz apply bez tworzenia drugiego kompletu zasobów

Teraz ponów `operation: apply` bez zmiany kodu i Repository variables.
Sprawdź, że pipeline odczytał ten sam state, zachował sufiks nazw i nie
tworzy drugiej kopii VM/VPC/firewalla. `check-ssh` ma ponownie przejść.

Jeżeli job nie znajduje state lub klucza, sprawdź nazwę runnera, konto
uruchamiające usługę agenta i `TF_STATE_ROOT`. Jeżeli SSH odmawia dostępu,
sprawdź rzeczywisty IPv4 `eth0` agenta, `SSH_ALLOWED_CIDR`, firewall,
prawa pliku klucza i komunikat `known_hosts`. Zmiana publicznego IP agenta
wymaga aktualizacji jego `/32` w Repository variables.

## 14. Usuń zasoby przez ten sam workflow

Teraz wybierz **Run workflow → operation: destroy** z tego samego repozytorium,
na tym samym agencie i z niezmienioną lokalizacją state. `provision` zapisze
plan z `-destroy` i zastosuje go przez `terraform apply`; `check-ssh`
zostanie pominięty. Sprawdź w DigitalOcean usunięcie zasobów tego ćwiczenia.

Nie usuwaj katalogu state przed udanym sprzątaniem. Gdy DigitalOcean odmawia
usunięcia VPC będącej domyślną w regionie, uzgodnij z prowadzącym wskazanie
innej istniejącej VPC jako domyślnej, a potem ponów operację. Pozostaw cudze
sieci i zasoby bez zmian. Po destroy chroń również kopie state, które mogą
nadal zawierać prywatny klucz.

Ćwiczenie jest ukończone po udanym tworzeniu zasobów, prawdziwym teście SSH,
ponownym apply z tym samym state oraz potwierdzonym usunięciu zasobów.
Tworzenie VM przez pipeline wykonuje rzeczywiste operacje w DigitalOcean
i wiąże się z opłatami za istniejącą infrastrukturę.

Dokumentacja:
[dodawanie self-hosted runnera](https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/add-runners),
[lokalny backend Terraform](https://developer.hashicorp.com/terraform/language/backend/local),
[dependency lockfile](https://developer.hashicorp.com/terraform/language/files/dependency-lock)
i [StrictHostKeyChecking w OpenSSH](https://man.openbsd.org/ssh_config#StrictHostKeyChecking).
