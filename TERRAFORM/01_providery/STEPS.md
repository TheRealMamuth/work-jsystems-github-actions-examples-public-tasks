# 01. STEPS — przygotuj providery

Ta instrukcja prowadzi przez samodzielne zbudowanie rozwiązania. Każdy krok podaje ścieżkę pliku, **pełny kod do wpisania w edytorze**, jego znaczenie oraz późniejszy sposób sprawdzenia wyniku. Wszystkie potrzebne treści są tutaj; katalog `rozwiazanie` służy tylko do opcjonalnego porównania.

Ścieżki plików odnoszą się do jednego katalogu `cloud/digitalocean/Cwiczenia/praca`. Zachowuj stan, lock file, własny `terraform.tfvars` oraz klucze między etapami. Zapisuj pliki jako UTF-8. Kod HCL/YAML/HTML/Jinja wpisuj do wskazanego pliku; polecenia `sh` wykonuj w terminalu. `{{ ... }}` w szablonie pozostaw dosłownie — uzupełni je Ansible.

**Masz mało czasu?** Przejdź numerowane kroki, wklejając treść plików bezpośrednio z tej instrukcji, i wykonaj punkt kontrolny. Część „Dodatkowo” jest opcjonalna. Przed `apply` zawsze przeczytaj plan; po zmianie kodu lub parametrów wygeneruj go ponownie.

**Punkt startowy:** nowy katalog pracy.

## Pliki tego etapu

Każdy plik tworzony lub zmieniany ma osobny krok poniżej. Pełne treści plików zachowanych bez zmian są w rozwijanej sekcji na końcu. Nie trzeba przepisywać ich ponownie.

| Plik względem `praca` | Czynność | Rola pliku |
| --- | --- | --- |
| `versions.tf` | utwórz | Wersje Terraform i źródła providerów |
| `variables.tf` | utwórz | Deklaracje parametrów wejściowych |
| `providers.tf` | utwórz | Konfiguracja providerów |
| `terraform.tfvars.example` | utwórz | Wersjonowany wzór parametrów |
| `terraform.tfvars` | sprawdź i uzupełnij | Lokalne wartości uczestnika; pełny wzór w kroku parametrów |

## Krok 1. Przygotuj katalog

Otwórz terminal w **katalogu głównym repozytorium** i przejdź do swojego miejsca pracy:

```sh
mkdir -p cloud/digitalocean/Cwiczenia/praca
cd cloud/digitalocean/Cwiczenia/praca
terraform version
```

Wynik `terraform version` powinien spełniać zakres `>= 1.7.0, < 2.0.0`. Jeśli program nie jest dostępny, skorzystaj z przygotowania stanowiska w [spisie](../README.md).

## Krok 2. Utwórz versions.tf

Utwórz w edytorze plik **`praca/versions.tf`**. Poniżej jego **pełna zawartość**; zastąp treść istniejącego pliku, nie dopisuj drugiej kopii tych bloków.

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

## Krok 3. Utwórz variables.tf

Utwórz w edytorze plik **`praca/variables.tf`**. Poniżej jego **pełna zawartość**; zastąp treść istniejącego pliku, nie dopisuj drugiej kopii tych bloków.

Na początku deklarujesz tylko parametr tokena: jego typ to `string`, domyślna wartość to `null`, a `sensitive` ogranicza wyświetlanie wartości. Prefiks i walidację dodasz w etapie 03. Samo `sensitive` nie szyfruje danych.

<!-- file: variables.tf -->
```hcl
variable "digitalocean_token" {
  description = "Token API DigitalOcean odczytywany z lokalnego, ignorowanego pliku terraform.tfvars."
  type        = string
  sensitive   = true
  default     = null
}
```

## Krok 4. Utwórz providers.tf

Utwórz w edytorze plik **`praca/providers.tf`**. Poniżej jego **pełna zawartość**; zastąp treść istniejącego pliku, nie dopisuj drugiej kopii tych bloków.

`provider "digitalocean"` przekazuje wartość `var.digitalocean_token` do klienta API. Puste bloki pozostałych providerów używają ustawień domyślnych. Definicje zasobów powstaną w kolejnych plikach.

<!-- file: providers.tf -->
```hcl
# Token jest przekazywany przez zmienną sensitive z lokalnego terraform.tfvars.
provider "digitalocean" {
  token = var.digitalocean_token
}

provider "random" {}
```

## Krok 5. Utwórz terraform.tfvars.example

Utwórz w edytorze plik **`praca/terraform.tfvars.example`**. Poniżej jego **pełna zawartość**; zastąp treść istniejącego pliku, nie dopisuj drugiej kopii tych bloków.

To pełny przykład bez sekretów. Terraform nie wczytuje automatycznie pliku z końcówką `.example`. Rzeczywiste wartości uczestnika są w osobnym lokalnym `terraform.tfvars`.

<!-- file: terraform.tfvars.example -->
```hcl
# Wpisz token wyłącznie w lokalnym terraform.tfvars (plik ignorowany przez Git).
# W etapach 01-04 token nie jest potrzebny do operacji lokalnych.
digitalocean_token = null
```

## Krok 6. Utwórz terraform.tfvars

Otwórz **`praca/terraform.tfvars`** albo utwórz go, jeżeli jeszcze nie istnieje. To pełny wzór lokalnych ustawień. Przy aktualizacji zachowaj swoje wartości; nie zastępuj istniejącego tokena przykładowym tekstem.

Terraform automatycznie odczytuje ten plik z katalogu pracy. Jeśli już istnieje, zachowaj swój token, prefiks, region i inne uzgodnione wartości; uzupełniaj tylko brakujące parametry. Poniżej pokazano pełny układ pliku. Nie wpisuj tego samego klucza dwukrotnie.

<!-- file: terraform.tfvars -->
```hcl
# Wpisz token wyłącznie w lokalnym terraform.tfvars (plik ignorowany przez Git).
# W etapach 01-04 token nie jest potrzebny do operacji lokalnych.
digitalocean_token = null
```

W etapach 01–04 token może pozostać `null`. Ten plik jest lokalny i nie trafia do Git.

```sh
chmod 600 terraform.tfvars
git check-ignore terraform.tfvars
```

Ostatnie polecenie powinno wypisać nazwę ignorowanego pliku.

## Krok 7. Pobierz zależności i sprawdź konfigurację

```sh
terraform init
terraform fmt
terraform validate
terraform providers
```

`init` pobiera providery i tworzy `.terraform.lock.hcl`. `validate` powinno zgłosić poprawną konfigurację, a `providers` pokazać DigitalOcean i Random. Lock file zachowuje wybrane wersje; `init` nie tworzy Dropleta.

## Punkt kontrolny

Masz trzy pliki `.tf`, własny `terraform.tfvars` i lock file. Walidacja przechodzi. Nie wykonujesz jeszcze `apply` i nie masz zasobów w chmurze.

## Dodatkowo — gdy masz więcej czasu

Otwórz `.terraform.lock.hcl` i znajdź wersję wybraną dla każdego providera. Porównaj konkretną wersję z ograniczeniem w `versions.tf`.

## Pliki generowane — nie wpisujesz ich ręcznie

- `.terraform/` i `.terraform.lock.hcl` powstają przez `terraform init`; lock file zachowuje wybrane wersje providerów.
- `terraform.tfstate` i kopie stanu powstają przy pracy Terraform; nie zastępuj ich przykładami. Plan `terraform.tfplan` jest wynikiem `plan -out`.

[Treść zadania i pytania](README.md) · [Spis ćwiczeń](../README.md) · [Następny etap krok po kroku](../02_pierwszy_zasob/STEPS.md)
