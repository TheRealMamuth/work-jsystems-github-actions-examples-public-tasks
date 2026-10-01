# 04. STEPS — uporządkuj pliki i locals

Ta instrukcja prowadzi przez samodzielne zbudowanie rozwiązania. Każdy krok podaje ścieżkę pliku, **pełny kod do wpisania w edytorze**, jego znaczenie oraz późniejszy sposób sprawdzenia wyniku. Wszystkie potrzebne treści są tutaj; katalog `rozwiazanie` służy tylko do opcjonalnego porównania.

Ścieżki plików odnoszą się do jednego katalogu `cloud/digitalocean/Cwiczenia/praca`. Zachowuj stan, lock file, własny `terraform.tfvars` oraz klucze między etapami. Zapisuj pliki jako UTF-8. Kod HCL/YAML/HTML/Jinja wpisuj do wskazanego pliku; polecenia `sh` wykonuj w terminalu. `{{ ... }}` w szablonie pozostaw dosłownie — uzupełni je Ansible.

**Masz mało czasu?** Przejdź numerowane kroki, wklejając treść plików bezpośrednio z tej instrukcji, i wykonaj punkt kontrolny. Część „Dodatkowo” jest opcjonalna. Przed `apply` zawsze przeczytaj plan; po zmianie kodu lub parametrów wygeneruj go ponownie.

**Punkt startowy:** ukończony etap 03, w tym samym katalogu i stanie.

## Pliki tego etapu

Każdy plik tworzony lub zmieniany ma osobny krok poniżej. Pełne treści plików zachowanych bez zmian są w rozwijanej sekcji na końcu. Nie trzeba przepisywać ich ponownie.

| Plik względem `praca` | Czynność | Rola pliku |
| --- | --- | --- |
| `versions.tf` | zachowaj | Wersje Terraform i źródła providerów |
| `variables.tf` | zachowaj | Deklaracje parametrów wejściowych |
| `providers.tf` | zachowaj | Konfiguracja providerów |
| `random.tf` | utwórz | Losowy sufiks nazw |
| `locals.tf` | utwórz | Wartości obliczane wewnątrz konfiguracji |
| `outputs.tf` | zaktualizuj | Wyniki dostępne po apply |
| `terraform.tfvars.example` | zachowaj | Wersjonowany wzór parametrów |
| `terraform.tfvars` | sprawdź i uzupełnij | Lokalne wartości uczestnika; pełny wzór w kroku parametrów |

`main.tf` z poprzedniego etapu zmienia nazwę na `random.tf`; nie pozostawiaj deklaracji Random w dwóch plikach.

## Krok 1. Sprawdź punkt wyjścia

Otwórz terminal w **katalogu głównym repozytorium** i przejdź do swojego miejsca pracy:

```sh
cd cloud/digitalocean/Cwiczenia/praca
pwd
```

Kolejne polecenia wykonuj w tym terminalu, po kolei. Jeśli wracasz do przerwanego ćwiczenia, przejdź od razu do wskazanego katalogu i kontynuuj od swojego kroku.

```sh
terraform output resource_name_prefix
```

Zapamiętaj wynik, aby porównać go na końcu.

## Krok 2. Zmień nazwę main.tf na random.tf

W `praca` wykonaj raz:

```sh
mv main.tf random.tf
```

Jeśli już masz oba pliki, połącz je ręcznie tak, aby `random_id.suffix` występował tylko raz w `random.tf`, a `main.tf` nie zawierał tego zasobu. Pełny kod `random.tf` jest w następnym kroku.

## Krok 3. Utwórz random.tf

Utwórz w edytorze plik **`praca/random.tf`**. Poniżej jego **pełna zawartość**; zastąp treść istniejącego pliku, nie dopisuj drugiej kopii tych bloków.

Adres nadal brzmi `random_id.suffix`. Zmiana nazwy pliku z `main.tf` na `random.tf` nie zmienia zasobu. Deklaracja ma występować tylko raz w katalogu.

<!-- file: random.tf -->
```hcl
resource "random_id" "suffix" {
  byte_length = 3
}
```

## Krok 4. Utwórz locals.tf

Utwórz w edytorze plik **`praca/locals.tf`**. Poniżej jego **pełna zawartość**; zastąp treść istniejącego pliku, nie dopisuj drugiej kopii tych bloków.

`local.name` łączy prefiks ze stałym dla tego stanu losowym sufiksem. Lokals upraszczają odwołania i nie są parametrami wpisywanymi do tfvars.

<!-- file: locals.tf -->
```hcl
locals {
  name = "${var.name_prefix}-${random_id.suffix.hex}"
}
```

## Krok 5. Zaktualizuj outputs.tf

Zaktualizuj w edytorze plik **`praca/outputs.tf`**. Poniżej jego **pełna zawartość**; zastąp treść istniejącego pliku, nie dopisuj drugiej kopii tych bloków.

Każdy `output` nadaje nazwę wartości, którą odczytasz przez `terraform output NAZWA`. Output może być tekstem albo obiektem grupującym dane zasobu. Zapisywany jest w stanie podczas apply.

<!-- file: outputs.tf -->
```hcl
output "resource_name_prefix" {
  description = "Prefiks wraz z losowym sufiksem używany w nazwach wszystkich zasobów."
  value       = local.name
}
```

## Krok 6. Zaktualizuj terraform.tfvars

Otwórz **`praca/terraform.tfvars`** albo utwórz go, jeżeli jeszcze nie istnieje. To pełny wzór lokalnych ustawień. Przy aktualizacji zachowaj swoje wartości; nie zastępuj istniejącego tokena przykładowym tekstem.

Terraform automatycznie odczytuje ten plik z katalogu pracy. Jeśli już istnieje, zachowaj swój token, prefiks, region i inne uzgodnione wartości; uzupełniaj tylko brakujące parametry. Poniżej pokazano pełny układ pliku. Nie wpisuj tego samego klucza dwukrotnie.

<!-- file: terraform.tfvars -->
```hcl
# Wpisz token wyłącznie w lokalnym terraform.tfvars (plik ignorowany przez Git).
# W etapach 01-04 token nie jest potrzebny do operacji lokalnych.
digitalocean_token = null

name_prefix = "jsystems-lab-anna"
```

W etapach 01–04 token może pozostać `null`. Dopasuj imię w prefiksie i uzgodnione parametry. Ten plik jest lokalny i nie trafia do Git.

```sh
chmod 600 terraform.tfvars
git check-ignore terraform.tfvars
```

Ostatnie polecenie powinno wypisać nazwę ignorowanego pliku.

## Krok 7. Potwierdź brak zmian zasobu

```sh
terraform fmt
terraform validate
terraform plan
terraform output resource_name_prefix
```

Oczekuj `No changes` oraz identycznego wyniku jak wcześniej. Nie potrzebujesz apply. Terraform czyta wszystkie pliki `.tf` z katalogu; nazwa pliku nie jest adresem zasobu.

## Punkt kontrolny

`main.tf` został zastąpiony przez `random.tf`, zasób nie jest zdublowany i nadal ma ten sam adres oraz wartość.

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
<summary>variables.tf — pełna zawartość, bez zmiany w tym etapie</summary>

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
<summary>terraform.tfvars.example — pełna zawartość, bez zmiany w tym etapie</summary>

To pełny przykład bez sekretów. Terraform nie wczytuje automatycznie pliku z końcówką `.example`. Rzeczywiste wartości uczestnika są w osobnym lokalnym `terraform.tfvars`.

<!-- file: terraform.tfvars.example -->
```hcl
# Wpisz token wyłącznie w lokalnym terraform.tfvars (plik ignorowany przez Git).
# W etapach 01-04 token nie jest potrzebny do operacji lokalnych.
digitalocean_token = null

name_prefix = "jsystems-lab-anna"
```

</details>

## Pliki generowane — nie wpisujesz ich ręcznie

- `.terraform/` i `.terraform.lock.hcl` powstają przez `terraform init`; lock file zachowuje wybrane wersje providerów.
- `terraform.tfstate` i kopie stanu powstają przy pracy Terraform; nie zastępuj ich przykładami. Plan `terraform.tfplan` jest wynikiem `plan -out`.

[Treść zadania i pytania](README.md) · [Spis ćwiczeń](../README.md) · [Następny etap krok po kroku](../05_projekt_digitalocean/STEPS.md)
