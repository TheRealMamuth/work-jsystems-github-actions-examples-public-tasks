# 01. Providery i inicjalizacja

**Potrzebujesz prowadzenia? [STEPS — rozwiązanie krok po kroku](STEPS.md)** zawiera pełną zawartość wszystkich plików, kolejność ich tworzenia, objaśnienia i polecenia weryfikacji.

Czas: około 20 minut.

## Efekt

Przygotujesz konfigurację, która potrafi zainstalować providery. Jeszcze niczego
nie utworzysz. Provider to wtyczka obsługująca dany system lub rodzaj zasobów.

## Punkt startowy

Pusty katalog `praca` przygotowany zgodnie z [instrukcją główną](../README.md).
Wszystkie poniższe polecenia wykonuj w nim. Token API nie jest jeszcze potrzebny.

## Zadania

1. Utwórz `versions.tf`. Dodaj blok `terraform`, a w nim `required_version`
   ustawione na `">= 1.7.0, < 2.0.0"`.
2. W `required_providers` zadeklaruj dwa providery:
   `digitalocean` ze źródła `digitalocean/digitalocean` i wersją `"~> 2.0"`
   oraz `random` ze źródła `hashicorp/random` i wersją `"~> 3.0"`.
3. Utwórz `variables.tf` z poniższą deklaracją tokena. To gotowy element
   konfiguracji dostępu; własne zmienne i outputs poznasz dokładniej w etapie 03.

   ```hcl
   variable "digitalocean_token" {
     description = "Token z lokalnego terraform.tfvars."
     type        = string
     sensitive   = true
     default     = null
   }
   ```

4. W `providers.tf` dodaj blok `provider "digitalocean"` z argumentem
   `token = var.digitalocean_token` oraz pusty `provider "random" {}`.
   Deklaracja providera nie oznacza jego instalacji; za nią odpowiada `init`.
5. Utwórz `terraform.tfvars.example` z `digitalocean_token = null`.
   Lokalny `terraform.tfvars` przygotowany według instrukcji głównej może już
   zawierać token. Nie jest on potrzebny do ćwiczeń lokalnych 01–04, dlatego
   na świeżym stanowisku możesz na razie pozostawić `null`.
6. Wykonaj polecenia poniżej. Odczytaj wybrane wersje providerów z lock file.
   Porównaj wymaganie wersji z konkretną wersją zapisaną w tym pliku.

```sh
terraform init
terraform fmt
terraform validate
terraform providers
```

`~> 2.0` dopuszcza wersje od 2.0 do wersji poniżej 3.0. Lock file zapisuje
wybraną wersję i jej sumy kontrolne. Katalog `.terraform/` zawiera pobrane
zależności; nie jest Twoim kodem konfiguracji.

## Kryterium ukończenia

- `init` kończy się poprawnie; widzisz providery DigitalOcean i Random.
- `validate` potwierdza poprawność konfiguracji.
- Istnieją `versions.tf`, `providers.tf`, `variables.tf`, lokalny `terraform.tfvars`
  oraz `.terraform.lock.hcl`. Rzeczywisty token nie trafia do pliku `.example`.
- Nie masz jeszcze bloków `resource` i nie powstała infrastruktura.

## Sprawdź zrozumienie

1. Czym różni się `required_providers` od bloku `provider`?
2. Dlaczego wersjonujesz lock file, ale nie cały katalog `.terraform`?
3. Czy uruchomienie `terraform init` tworzy Dropleta?

Dokumentacja: [wymagania providerów](https://developer.hashicorp.com/terraform/language/providers/requirements).

## Parametry lokalne

Rozwiązanie tego etapu zawiera `terraform.tfvars.example` bez sekretu.
Lokalny `terraform.tfvars` przechowuje parametry tego etapu i `digitalocean_token`;
jest ignorowany przez Git i ma uprawnienia `0600`. W swoim `praca` dopisuj
nowe parametry do istniejącego pliku, zachowując token. Nie przenoś stanu
do katalogów rozwiązań. Po świeżym klonowaniu uzupełnij token we własnym tfvars.

## Rozwiązanie i dalsza praca

[Kompletny kod po tym etapie](rozwiazanie/) — porównaj go z własną pracą.
Rozwiązania nie zawierają Twojego stanu ani danych dostępowych.

[Spis ćwiczeń](../README.md) · [Następny etap](../02_pierwszy_zasob/README.md)
