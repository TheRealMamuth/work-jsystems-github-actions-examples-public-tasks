# 03. Zmienne wejściowe i outputs

**Potrzebujesz prowadzenia? [STEPS — rozwiązanie krok po kroku](STEPS.md)** zawiera pełną zawartość wszystkich plików, kolejność ich tworzenia, objaśnienia i polecenia weryfikacji.

Czas: około 30 minut.

## Efekt

Oddzielisz parametry od kodu i udostępnisz wynik konfiguracji przez `output`.
Ten sam kod będzie można wykorzystać z różnymi nazwami środowisk.

## Punkt startowy

Zasób `random_id.suffix` z etapu 02 znajduje się już w stanie. Zachowaj `main.tf`.

## Zadania

1. W `variables.tf` zadeklaruj zmienną `name_prefix`: `type = string`,
   `default = "jsystems-dev"`, `nullable = false` i opis jej zastosowania.
2. Dodaj walidację. Prefiks ma mieć 1–32 znaki, zaczynać się małą literą
   oraz zawierać tylko małe litery, cyfry i myślniki. Użyj wyrażenia
   `can(regex("^[a-z][a-z0-9-]{0,31}$", var.name_prefix))` i czytelnego komunikatu.
3. W `outputs.tf` zadeklaruj output `resource_name_prefix`, którego wartość
   łączy `var.name_prefix`, myślnik i `random_id.suffix.hex`.
4. Rozszerz `terraform.tfvars.example` o `name_prefix = "jsystems-lab-anna"`.
   Dopisz swój prefiks do istniejącego `terraform.tfvars`, zachowując token
   `digitalocean_token`. Nie nadpisuj uzupełnionego pliku przykładem.
   W `variables.tf` zachowaj wcześniejszą deklarację zmiennej tokena.
5. Sformatuj kod, sprawdź plan i zastosuj zmianę outputs.

```sh
terraform fmt
terraform validate
terraform plan -out=terraform.tfplan
terraform apply terraform.tfplan
terraform output resource_name_prefix
terraform output -raw resource_name_prefix
```

Output ma dać np. `jsystems-lab-anna-a1b2c3`; sufiks będzie Twój. Definicja
zmiennej znajduje się w `.tf`, a jej wartość dla tego uruchomienia w `.tfvars`.
Plik `.example` nie jest automatycznie wczytywany. Terraform wczytuje
`terraform.tfvars`, jeśli taki plik istnieje w katalogu roboczym.

## Eksperymenty — wykonaj tylko plan

```sh
terraform plan -var='name_prefix=jsystems-lab-test'
terraform plan -var='name_prefix=Niepoprawny prefiks!'
```

Pierwsze polecenie nadpisuje wartość z tfvars dla tego wywołania. Drugie ma
zakończyć się błędem walidacji. Nie zapisuj niepoprawnej wartości w konfiguracji.

## Kryterium ukończenia

- W stanie pozostaje jeden zasób; pojawił się output, bez ponownego losowania.
- Własny prefiks z tfvars jest widoczny w wyniku `terraform output`.
- Niepoprawny prefiks jest odrzucany przez `plan`.

## Sprawdź zrozumienie

1. Co oznacza `var.name_prefix`, a co `random_id.suffix.hex`?
2. Po co osobny plik `.example`, skoro Terraform go nie wczytuje?
3. Kiedy warto użyć outputu, zamiast odczytywać cały plik stanu?

Dokumentacja: [zmienne wejściowe](https://developer.hashicorp.com/terraform/language/values/variables).

## Parametry lokalne

Rozwiązanie tego etapu zawiera `terraform.tfvars.example` bez sekretu.
Lokalny `terraform.tfvars` przechowuje parametry tego etapu i `digitalocean_token`;
jest ignorowany przez Git i ma uprawnienia `0600`. W swoim `praca` dopisuj
nowe parametry do istniejącego pliku, zachowując token. Nie przenoś stanu
do katalogów rozwiązań. Po świeżym klonowaniu uzupełnij token we własnym tfvars.

## Rozwiązanie i dalsza praca

[Kompletny kod po tym etapie](rozwiazanie/) — porównaj go z własną pracą.
Rozwiązania nie zawierają Twojego stanu ani danych dostępowych.

[Poprzedni etap](../02_pierwszy_zasob/README.md) · [Następny etap](../04_locals_i_podzial_plikow/README.md)
