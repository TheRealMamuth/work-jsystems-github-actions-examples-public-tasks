# 05. Pierwszy zasób w chmurze: projekt

**Potrzebujesz prowadzenia? [STEPS — rozwiązanie krok po kroku](STEPS.md)** zawiera pełną zawartość wszystkich plików, kolejność ich tworzenia, objaśnienia i polecenia weryfikacji.

Czas: około 25 minut.

## Efekt

Utworzysz pierwszy zasób w DigitalOcean: pusty projekt. Wykorzystasz istniejący
prefiks i losowy sufiks. Droplet pojawi się dopiero w etapie 08.

## Punkt startowy

Konfiguracja i stan po etapie 04. Od teraz potrzebujesz własnego konta
szkoleniowego oraz tokena API z uprawnieniami do używanych zasobów.

## Zadania

1. Sprawdź lokalny `terraform.tfvars` w swoim `praca`: parametr
   `digitalocean_token` musi zawierać rzeczywisty token jako tekst w cudzysłowach,
   zamiast `null`. Na tym stanowisku lokalne rozwiązania są już uzupełnione.
   Po świeżym klonowaniu uzupełnij własny plik. Nie pokazuj jego zawartości
   w terminalu ani na zrzucie ekranu. Wykonaj `chmod 600 terraform.tfvars`.
   Provider korzysta z `token = var.digitalocean_token`; deklaracja tej zmiennej
   w `variables.tf` ma `sensitive = true`. W pliku `.example` pozostaw `null`.

2. W `variables.tf` dodaj `project_environment` typu `string`, z wartością
   domyślną `"Development"` i `nullable = false`. Walidacja ma dopuszczać
   `Development`, `Staging` i `Production`; użyj `contains`.
3. W `project.tf` dodaj `digitalocean_project.this`. Nazwa ma mieć wartość
   `"${local.name}-project"`, opis ma wskazywać zarządzanie przez Terraform,
   `purpose = "Operational / Developer tooling"`, a `environment` ma pochodzić
   ze zmiennej. Na razie nie ustawiaj `resources` — projekt jest pusty.
4. Dodaj output `project`: obiekt z `id` i `name` nowego projektu.
5. Dodaj `project_environment` do przykładu tfvars. Zaplanuj i utwórz projekt,
   a następnie odszukaj go w panelu DigitalOcean.

```sh
terraform fmt
terraform validate
terraform plan -out=terraform.tfplan
terraform apply terraform.tfplan
terraform output project
terraform state list
terraform plan
```

## Kryterium ukończenia

- Plan względem etapu 04 dodaje jeden projekt i nie zmienia `random_id.suffix`.
- Stan ma dwa zasoby. W panelu widzisz projekt z Twoim prefiksem i sufiksem.
- Ponowny plan nie proponuje zmian. Samo udane `validate` nie potwierdzałoby
  praw tokena; poprawne wykonanie operacji API weryfikuje je dla danego zasobu.

## Sprawdź zrozumienie

1. Jak wartość z `terraform.tfvars` trafia przez `var.digitalocean_token` do providera?
2. Czym lokalny adres `digitalocean_project.this` różni się od nazwy w panelu?
3. Dlaczego identyfikator projektu jest outputem, a token nim nie jest?

Dokumentacja: [projekt DigitalOcean](https://docs.digitalocean.com/reference/terraform/reference/resources/project/).

## Parametry lokalne

Rozwiązanie tego etapu zawiera `terraform.tfvars.example` bez sekretu.
Lokalny `terraform.tfvars` przechowuje parametry tego etapu i `digitalocean_token`;
jest ignorowany przez Git i ma uprawnienia `0600`. W swoim `praca` dopisuj
nowe parametry do istniejącego pliku, zachowując token. Nie przenoś stanu
do katalogów rozwiązań. Po świeżym klonowaniu uzupełnij token we własnym tfvars.

## Rozwiązanie i dalsza praca

[Kompletny kod po tym etapie](rozwiazanie/) — porównaj go z własną pracą.
Rozwiązania nie zawierają Twojego stanu ani danych dostępowych.

[Poprzedni etap](../04_locals_i_podzial_plikow/README.md) · [Następny etap](../06_vpc/README.md)
