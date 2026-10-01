# 02. STEPS — utwórz pierwszy zasób

Ta instrukcja prowadzi przez samodzielne zbudowanie rozwiązania. Każdy krok podaje ścieżkę pliku, **pełny kod do wpisania w edytorze**, jego znaczenie oraz późniejszy sposób sprawdzenia wyniku. Wszystkie potrzebne treści są tutaj; katalog `rozwiazanie` służy tylko do opcjonalnego porównania.

Ścieżki plików odnoszą się do jednego katalogu `cloud/digitalocean/Cwiczenia/praca`. Zachowuj stan, lock file, własny `terraform.tfvars` oraz klucze między etapami. Zapisuj pliki jako UTF-8. Kod HCL/YAML/HTML/Jinja wpisuj do wskazanego pliku; polecenia `sh` wykonuj w terminalu. `{{ ... }}` w szablonie pozostaw dosłownie — uzupełni je Ansible.

**Masz mało czasu?** Przejdź numerowane kroki, wklejając treść plików bezpośrednio z tej instrukcji, i wykonaj punkt kontrolny. Część „Dodatkowo” jest opcjonalna. Przed `apply` zawsze przeczytaj plan; po zmianie kodu lub parametrów wygeneruj go ponownie.

**Punkt startowy:** ukończony etap 01, w tym samym katalogu i stanie.

## Pliki tego etapu

Każdy plik tworzony lub zmieniany ma osobny krok poniżej. Pełne treści plików zachowanych bez zmian są w rozwijanej sekcji na końcu. Nie trzeba przepisywać ich ponownie.

| Plik względem `praca` | Czynność | Rola pliku |
| --- | --- | --- |
| `versions.tf` | zachowaj | Wersje Terraform i źródła providerów |
| `variables.tf` | zachowaj | Deklaracje parametrów wejściowych |
| `providers.tf` | zachowaj | Konfiguracja providerów |
| `main.tf` | utwórz | Pierwszy zasób Random |
| `terraform.tfvars.example` | zachowaj | Wersjonowany wzór parametrów |
| `terraform.tfvars` | sprawdź i uzupełnij | Lokalne wartości uczestnika; pełny wzór w kroku parametrów |

## Krok 1. Wróć do swojej konfiguracji

Otwórz terminal w **katalogu głównym repozytorium** i przejdź do swojego miejsca pracy:

```sh
cd cloud/digitalocean/Cwiczenia/praca
pwd
```

Kolejne polecenia wykonuj w tym terminalu, po kolei. Jeśli wracasz do przerwanego ćwiczenia, przejdź od razu do wskazanego katalogu i kontynuuj od swojego kroku.

## Krok 2. Utwórz main.tf

Utwórz w edytorze plik **`praca/main.tf`**. Poniżej jego **pełna zawartość**; zastąp treść istniejącego pliku, nie dopisuj drugiej kopii tych bloków.

`random_id` to typ zasobu, a `suffix` to jego lokalna nazwa. Trzy bajty dają sześć znaków w atrybucie `hex`. Terraform zachowuje wynik w stanie, więc nie losuje go ponownie przy każdym planie.

<!-- file: main.tf -->
```hcl
resource "random_id" "suffix" {
  byte_length = 3
}
```

## Krok 3. Zaktualizuj terraform.tfvars

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

## Krok 4. Zaplanuj utworzenie

```sh
terraform fmt
terraform validate
terraform plan -out=terraform.tfplan
```

Oczekuj `1 to add, 0 to change, 0 to destroy`. Wartość losowa może być jeszcze opisana jako `known after apply`. Jeśli plan proponuje inne zasoby, sprawdź, czy jesteś w swoim `praca`.

## Krok 5. Zastosuj i odczytaj wynik

```sh
terraform apply terraform.tfplan
```

```sh
terraform state list
terraform state show random_id.suffix
terraform plan
```

Stan ma jeden wpis `random_id.suffix`. Odczytaj jego `hex`. Ostatni plan powinien pokazać `No changes`: wynik losowania pozostaje w stanie, więc kolejne uruchomienie go zachowuje.

## Punkt kontrolny

Jeden zasób w stanie, wygenerowany sufiks i kolejny plan bez zmian.

## Dodatkowo — gdy masz więcej czasu

Zmień `byte_length` na `4`, uruchom tylko `terraform plan` i zobacz propozycję zastąpienia zasobu. Przywróć `3` bez wykonywania apply i ponów plan; ma znów nie mieć zmian.

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
```

</details>

## Pliki generowane — nie wpisujesz ich ręcznie

- `.terraform/` i `.terraform.lock.hcl` powstają przez `terraform init`; lock file zachowuje wybrane wersje providerów.
- `terraform.tfstate` i kopie stanu powstają przy pracy Terraform; nie zastępuj ich przykładami. Plan `terraform.tfplan` jest wynikiem `plan -out`.

[Treść zadania i pytania](README.md) · [Spis ćwiczeń](../README.md) · [Następny etap krok po kroku](../03_zmienne_i_outputy/STEPS.md)
