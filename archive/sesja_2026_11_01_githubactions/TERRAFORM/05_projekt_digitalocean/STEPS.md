# 05. STEPS — utwórz projekt DigitalOcean

Ta instrukcja prowadzi przez samodzielne zbudowanie rozwiązania. Każdy krok podaje ścieżkę pliku, **pełny kod do wpisania w edytorze**, jego znaczenie oraz późniejszy sposób sprawdzenia wyniku. Wszystkie potrzebne treści są tutaj; katalog `rozwiazanie` służy tylko do opcjonalnego porównania.

Ścieżki plików odnoszą się do jednego katalogu `cloud/digitalocean/Cwiczenia/praca`. Zachowuj stan, lock file, własny `terraform.tfvars` oraz klucze między etapami. Zapisuj pliki jako UTF-8. Kod HCL/YAML/HTML/Jinja wpisuj do wskazanego pliku; polecenia `sh` wykonuj w terminalu. `{{ ... }}` w szablonie pozostaw dosłownie — uzupełni je Ansible.

**Masz mało czasu?** Przejdź numerowane kroki, wklejając treść plików bezpośrednio z tej instrukcji, i wykonaj punkt kontrolny. Część „Dodatkowo” jest opcjonalna. Przed `apply` zawsze przeczytaj plan; po zmianie kodu lub parametrów wygeneruj go ponownie.

**Punkt startowy:** ukończony etap 04, w tym samym katalogu i stanie.

## Pliki tego etapu

Każdy plik tworzony lub zmieniany ma osobny krok poniżej. Pełne treści plików zachowanych bez zmian są w rozwijanej sekcji na końcu. Nie trzeba przepisywać ich ponownie.

| Plik względem `praca` | Czynność | Rola pliku |
| --- | --- | --- |
| `versions.tf` | zachowaj | Wersje Terraform i źródła providerów |
| `variables.tf` | zaktualizuj | Deklaracje parametrów wejściowych |
| `providers.tf` | zachowaj | Konfiguracja providerów |
| `random.tf` | zachowaj | Losowy sufiks nazw |
| `locals.tf` | zachowaj | Wartości obliczane wewnątrz konfiguracji |
| `project.tf` | utwórz | Projekt DigitalOcean |
| `outputs.tf` | zaktualizuj | Wyniki dostępne po apply |
| `terraform.tfvars.example` | zaktualizuj | Wersjonowany wzór parametrów |
| `terraform.tfvars` | sprawdź i uzupełnij | Lokalne wartości uczestnika; pełny wzór w kroku parametrów |

## Krok 1. Przygotuj dostęp do chmury

Otwórz terminal w **katalogu głównym repozytorium** i przejdź do swojego miejsca pracy:

```sh
cd cloud/digitalocean/Cwiczenia/praca
pwd
```

Kolejne polecenia wykonuj w tym terminalu, po kolei. Jeśli wracasz do przerwanego ćwiczenia, przejdź od razu do wskazanego katalogu i kontynuuj od swojego kroku.

Od tego etapu pracujesz na swoim koncie szkoleniowym DigitalOcean. W edytorze otwórz lokalny `terraform.tfvars` i zastąp `null` przy `digitalocean_token` własnym tokenem jako tekstem w cudzysłowach. Jeśli token jest już wpisany, zachowaj go. Nie kopiuj tokena do `.example`.

```sh
chmod 600 terraform.tfvars
git check-ignore terraform.tfvars
```

## Krok 2. Zaktualizuj variables.tf

Zaktualizuj w edytorze plik **`praca/variables.tf`**. Poniżej jego **pełna zawartość**; zastąp treść istniejącego pliku, nie dopisuj drugiej kopii tych bloków.

`variable` definiuje nazwę, typ, opis i wartość domyślną parametru. `validation` odrzuca niepoprawne wartości. Deklaracja tokena ma `sensitive = true`; rzeczywista wartość będzie tylko w lokalnym `terraform.tfvars`.

<!-- file: variables.tf -->
```hcl
variable "digitalocean_token" {
  description = "Token API DigitalOcean odczytywany z lokalnego, ignorowanego pliku terraform.tfvars."
  type        = string
  sensitive   = true
  default     = null
}

variable "name_prefix" {
  description = "Wspólny prefiks nazw zasobów; losowy sufiks zostanie dodany automatycznie."
  type        = string
  default     = "jsystems-dev"
  nullable    = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,31}$", var.name_prefix))
    error_message = "Prefiks musi mieć 1-32 znaki, zaczynać się małą literą i zawierać tylko małe litery, cyfry oraz myślniki."
  }
}

variable "project_environment" {
  description = "Środowisko projektu DigitalOcean."
  type        = string
  default     = "Development"
  nullable    = false

  validation {
    condition     = contains(["Development", "Staging", "Production"], var.project_environment)
    error_message = "Dozwolone środowiska: Development, Staging, Production."
  }
}
```

## Krok 3. Utwórz project.tf

Utwórz w edytorze plik **`praca/project.tf`**. Poniżej jego **pełna zawartość**; zastąp treść istniejącego pliku, nie dopisuj drugiej kopii tych bloków.

`digitalocean_project.this` organizuje zasoby na koncie. Nazwa wykorzystuje `local.name`, a środowisko pochodzi z `var.project_environment`. `this` jest nazwą lokalnego adresu Terraform, a nie nazwą w panelu.

<!-- file: project.tf -->
```hcl
resource "digitalocean_project" "this" {
  name        = "${local.name}-project"
  description = "Infrastruktura DigitalOcean zarządzana przez Terraform."
  purpose     = "Operational / Developer tooling"
  environment = var.project_environment
}
```

## Krok 4. Zaktualizuj outputs.tf

Zaktualizuj w edytorze plik **`praca/outputs.tf`**. Poniżej jego **pełna zawartość**; zastąp treść istniejącego pliku, nie dopisuj drugiej kopii tych bloków.

Każdy `output` nadaje nazwę wartości, którą odczytasz przez `terraform output NAZWA`. Output może być tekstem albo obiektem grupującym dane zasobu. Zapisywany jest w stanie podczas apply.

<!-- file: outputs.tf -->
```hcl
output "resource_name_prefix" {
  description = "Prefiks wraz z losowym sufiksem używany w nazwach wszystkich zasobów."
  value       = local.name
}

output "project" {
  description = "Utworzony projekt DigitalOcean."
  value = {
    id   = digitalocean_project.this.id
    name = digitalocean_project.this.name
  }
}
```

## Krok 5. Zaktualizuj terraform.tfvars.example

Zaktualizuj w edytorze plik **`praca/terraform.tfvars.example`**. Poniżej jego **pełna zawartość**; zastąp treść istniejącego pliku, nie dopisuj drugiej kopii tych bloków.

To pełny przykład bez sekretów. Terraform nie wczytuje automatycznie pliku z końcówką `.example`. Rzeczywiste wartości uczestnika są w osobnym lokalnym `terraform.tfvars`.

<!-- file: terraform.tfvars.example -->
```hcl
# Wpisz token wyłącznie w lokalnym terraform.tfvars (plik ignorowany przez Git).
# W etapach 01-04 token nie jest potrzebny do operacji lokalnych.
digitalocean_token = null

name_prefix         = "jsystems-lab-anna"
project_environment = "Development"
```

## Krok 6. Zaktualizuj terraform.tfvars

Otwórz **`praca/terraform.tfvars`** albo utwórz go, jeżeli jeszcze nie istnieje. To pełny wzór lokalnych ustawień. Przy aktualizacji zachowaj swoje wartości; nie zastępuj istniejącego tokena przykładowym tekstem.

Terraform automatycznie odczytuje ten plik z katalogu pracy. Jeśli już istnieje, zachowaj swój token, prefiks, region i inne uzgodnione wartości; uzupełniaj tylko brakujące parametry. Poniżej pokazano pełny układ pliku. Nie wpisuj tego samego klucza dwukrotnie.

<!-- file: terraform.tfvars -->
```hcl
# Wpisz token wyłącznie w lokalnym terraform.tfvars (plik ignorowany przez Git).
# W etapach 01-04 token nie jest potrzebny do operacji lokalnych.
digitalocean_token = "UZUPELNIJ_WLASNY_TOKEN"

name_prefix         = "jsystems-lab-anna"
project_environment = "Development"
```

`UZUPELNIJ_WLASNY_TOKEN` zastąp swoim tokenem jako tekstem w cudzysłowach; jeśli token już jest w pliku, zachowaj go. W `.example` token nadal ma być `null`. Dopasuj imię w prefiksie i uzgodnione parametry. Ten plik jest lokalny i nie trafia do Git.

```sh
chmod 600 terraform.tfvars
git check-ignore terraform.tfvars
```

Ostatnie polecenie powinno wypisać nazwę ignorowanego pliku.

## Krok 7. Przeczytaj plan utworzenia

```sh
terraform fmt
terraform validate
terraform plan -out=terraform.tfplan
```

Oczekuj tylko jednego nowego zasobu: `digitalocean_project.this`. Losowy sufiks pozostaje ten sam. Jeśli API odrzuca token, popraw dostęp, a potem wykonaj nowy plan.

## Krok 8. Utwórz i sprawdź projekt

```sh
terraform apply terraform.tfplan
```

```sh
terraform output project
terraform state list
terraform plan
```

W panelu DigitalOcean znajdź projekt po nazwie z outputu. Stan ma dwa wpisy: Random i projekt. Drugi plan powinien nie mieć zmian.

## Punkt kontrolny

Projekt istnieje na koncie, jego ID i nazwa są w output, stan ma dwa zasoby. Samo `validate` nie potwierdza dostępu do API.

## Pełna zawartość plików pozostawionych bez zmian

To dalsza część rozwiązania tego etapu. Pliki już masz z poprzednich ćwiczeń — poniższe treści służą do sprawdzenia lub uzupełnienia braków. Własne CIDR-y, parametry hosta, token i wybrany digest zachowaj.

<details>
<summary>versions.tf — pełna zawartość, bez zmiany w tym etapie</summary>

Blok `terraform` zawiera wymagany zakres wersji programu. `required_providers` wskazuje źródło i dozwolone wersje każdej wtyczki. Dopiero `terraform init` pobierze zależności; zapisanie tego pliku nie tworzy zasobów.

<!-- file: versions.tf -->
```hcl
terraform {
  required_version = ">= 1.7.0, < 2.0.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
```

</details>

<details>
<summary>providers.tf — pełna zawartość, bez zmiany w tym etapie</summary>

`provider "digitalocean"` przekazuje wartość `var.digitalocean_token` do klienta API. Puste bloki pozostałych providerów używają ustawień domyślnych. Definicje zasobów powstaną w kolejnych plikach.

<!-- file: providers.tf -->
```hcl
# Token jest przekazywany przez zmienną sensitive z lokalnego terraform.tfvars.
provider "digitalocean" {
  token = var.digitalocean_token
}

provider "random" {}
```

</details>

<details>
<summary>random.tf — pełna zawartość, bez zmiany w tym etapie</summary>

Adres nadal brzmi `random_id.suffix`. Zmiana nazwy pliku z `main.tf` na `random.tf` nie zmienia zasobu. Deklaracja ma występować tylko raz w katalogu.

<!-- file: random.tf -->
```hcl
resource "random_id" "suffix" {
  byte_length = 3
}
```

</details>

<details>
<summary>locals.tf — pełna zawartość, bez zmiany w tym etapie</summary>

`local.name` łączy prefiks ze stałym dla tego stanu losowym sufiksem. Lokals upraszczają odwołania i nie są parametrami wpisywanymi do tfvars.

<!-- file: locals.tf -->
```hcl
locals {
  name = "${var.name_prefix}-${random_id.suffix.hex}"
}
```

</details>

## Pliki generowane — nie wpisujesz ich ręcznie

- `.terraform/` i `.terraform.lock.hcl` powstają przez `terraform init`; lock file zachowuje wybrane wersje providerów.
- `terraform.tfstate` i kopie stanu powstają przy pracy Terraform; nie zastępuj ich przykładami. Plan `terraform.tfplan` jest wynikiem `plan -out`.

[Treść zadania i pytania](README.md) · [Spis ćwiczeń](../README.md) · [Następny etap krok po kroku](../06_vpc/STEPS.md)
