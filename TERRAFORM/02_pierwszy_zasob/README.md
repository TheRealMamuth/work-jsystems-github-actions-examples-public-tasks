# 02. Pierwszy zasób i stan Terraform

**Potrzebujesz prowadzenia? [STEPS — rozwiązanie krok po kroku](STEPS.md)** zawiera pełną zawartość wszystkich plików, kolejność ich tworzenia, objaśnienia i polecenia weryfikacji.

Czas: około 25 minut.

## Efekt

Utworzysz pierwszy zasób: losowy identyfikator. Poznasz planowanie, wdrożenie
i stan na przykładzie, który nie wymaga konta w chmurze.

## Punkt startowy

Zachowaj pliki z etapu 01. Nadal pracujesz w tym samym `praca`.

## Zadania

1. Utwórz `main.tf`. Zadeklaruj zasób typu `random_id`, o lokalnej nazwie
   `suffix`, z argumentem `byte_length = 3`.
2. Zanim uruchomisz plan, zapisz: ile zasobów Terraform powinien dodać?
3. Wykonaj poniższą sekwencję. W planie znajdź adres `random_id.suffix`
   i atrybut `hex`, którego wartość przed pierwszym utworzeniem nie jest znana.
4. Po `apply` sprawdź stan, a potem wykonaj drugi plan.

```sh
terraform fmt
terraform validate
terraform plan -out=terraform.tfplan
terraform apply terraform.tfplan
terraform state list
terraform state show random_id.suffix
terraform plan
```

Trzy bajty dają sześć cyfr szesnastkowych w atrybucie `hex`. Odczyt ze stanu
jest tu bezpieczny: pokazujesz wyłącznie zasób Random, nie żaden prywatny klucz.
Zasób `random_id` przechowuje wynik w stanie, więc każdy kolejny plan nie losuje
nowego identyfikatora.

## Eksperyment

Zmień `byte_length` na `4` i uruchom tylko `terraform plan`. Zobacz, że plan
proponuje zastąpienie zasobu. Nie wykonuj tego planu; przywróć `3` i sprawdź,
że zwykły plan ponownie nie zawiera zmian. Kolejne etapy zakładają trzy bajty.

## Kryterium ukończenia

- Pierwszy plan: `1 to add, 0 to change, 0 to destroy`.
- W stanie jest tylko `random_id.suffix` i jego wartość `hex` ma sześć znaków.
- Drugi plan po przywróceniu `byte_length = 3`: `No changes`.
- Plik stanu pozostaje w `praca`; nie dodajesz go do Git.

## Sprawdź zrozumienie

1. Co oznaczają `random_id` i `suffix` w deklaracji zasobu?
2. Czym różni się `plan` od `apply`?
3. Dlaczego usunięcie pliku stanu nie jest sposobem na usunięcie infrastruktury?

Dokumentacja: [planowanie zmian](https://developer.hashicorp.com/terraform/cli/commands/plan).

## Parametry lokalne

Rozwiązanie tego etapu zawiera `terraform.tfvars.example` bez sekretu.
Lokalny `terraform.tfvars` przechowuje parametry tego etapu i `digitalocean_token`;
jest ignorowany przez Git i ma uprawnienia `0600`. W swoim `praca` dopisuj
nowe parametry do istniejącego pliku, zachowując token. Nie przenoś stanu
do katalogów rozwiązań. Po świeżym klonowaniu uzupełnij token we własnym tfvars.

## Rozwiązanie i dalsza praca

[Kompletny kod po tym etapie](rozwiazanie/) — porównaj go z własną pracą.
Rozwiązania nie zawierają Twojego stanu ani danych dostępowych.

[Poprzedni etap](../01_providery/README.md) · [Następny etap](../03_zmienne_i_outputy/README.md)
