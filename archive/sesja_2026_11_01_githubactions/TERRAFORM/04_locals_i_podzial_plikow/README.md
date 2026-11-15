# 04. Locals i podział plików

**Potrzebujesz prowadzenia? [STEPS — rozwiązanie krok po kroku](STEPS.md)** zawiera pełną zawartość wszystkich plików, kolejność ich tworzenia, objaśnienia i polecenia weryfikacji.

Czas: około 20 minut.

## Efekt

Uporządkujesz kod bez zmiany utworzonych zasobów. Poznasz `locals` i zobaczysz,
że Terraform łączy pliki `.tf` z jednego katalogu w jedną konfigurację.

## Punkt startowy

Zachowaj stan i parametry z etapu 03. Nie zmieniaj wartości `name_prefix`.

## Zadania

1. Przenieś cały blok `resource "random_id" "suffix"` z `main.tf` do `random.tf`.
   Usuń pusty `main.tf`; nie zostawiaj drugiej kopii zasobu.
2. Utwórz `locals.tf`. W bloku `locals` dodaj `name` zawierające to samo
   połączenie prefiksu i sufiksu, którego używasz w output.
3. W `outputs.tf` zastąp wyrażenie interpolacji odwołaniem `local.name`.
4. Wykonaj walidację i plan. Porównaj output z wynikiem z etapu 03.

```sh
terraform fmt
terraform validate
terraform plan
terraform output resource_name_prefix
```

Nazwy plików pomagają ludziom czytać projekt; nie określają kolejności
tworzenia zasobów. Adres zasobu nadal brzmi `random_id.suffix`, dlatego samo
przeniesienie bloku nie wymaga importu ani przenoszenia stanu.

## Kryterium ukończenia

- Pliki robocze to `versions.tf`, `providers.tf`, `random.tf`, `variables.tf`,
  `locals.tf`, `outputs.tf` oraz Twoje pliki parametrów i stanu.
- Plan pokazuje `No changes` i nie proponuje zastąpienia zasobu Random.
- Output ma dokładnie tę samą wartość co wcześniej.

## Sprawdź zrozumienie

1. Dlaczego odwołujesz się przez `local.name`, choć deklaracja to `locals`?
2. Czym zmienna wejściowa różni się od wartości lokalnej?
3. Co byłoby inną zmianą: przeniesienie pliku czy zmiana `suffix` na inną nazwę?

## Parametry lokalne

Rozwiązanie tego etapu zawiera `terraform.tfvars.example` bez sekretu.
Lokalny `terraform.tfvars` przechowuje parametry tego etapu i `digitalocean_token`;
jest ignorowany przez Git i ma uprawnienia `0600`. W swoim `praca` dopisuj
nowe parametry do istniejącego pliku, zachowując token. Nie przenoś stanu
do katalogów rozwiązań. Po świeżym klonowaniu uzupełnij token we własnym tfvars.

## Rozwiązanie i dalsza praca

[Kompletny kod po tym etapie](rozwiazanie/) — porównaj go z własną pracą.
Rozwiązania nie zawierają Twojego stanu ani danych dostępowych.

[Poprzedni etap](../03_zmienne_i_outputy/README.md) · [Następny etap](../05_projekt_digitalocean/README.md)
