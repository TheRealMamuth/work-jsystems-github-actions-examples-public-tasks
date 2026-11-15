# 06. VPC i parametry sieci

**Potrzebujesz prowadzenia? [STEPS — rozwiązanie krok po kroku](STEPS.md)** zawiera pełną zawartość wszystkich plików, kolejność ich tworzenia, objaśnienia i polecenia weryfikacji.

Czas: około 25 minut.

## Efekt

Dodasz dedykowaną sieć VPC. Nauczysz się przekazywać parametry regionu
i używać `null`, gdy wartość może dobrać provider.

## Punkt startowy

Projekt oraz zasób Random z etapu 05. Zachowaj token w swoim lokalnym `terraform.tfvars`.

## Zadania

1. Dodaj zmienną `region` typu `string`, z domyślną wartością `"fra1"`
   i `nullable = false`.
2. Dodaj `vpc_ip_range` typu `string`, z domyślną wartością `null`.
   Walidacja ma akceptować `null` albo poprawny CIDR IPv4. Wskazówka:
   `var.vpc_ip_range == null ? true : can(cidrnetmask(var.vpc_ip_range))`.
3. W `vpc.tf` dodaj `digitalocean_vpc.this`: nazwa `"${local.name}-vpc"`,
   `region = var.region`, `ip_range = var.vpc_ip_range` i opis.
4. Dodaj output `vpc`, zawierający `id`, `name`, `region` i `ip_range`.
5. Rozszerz tfvars o region i `vpc_ip_range = null`. Utwórz sieć i odczytaj
   zakres wybrany przez DigitalOcean.

```sh
terraform fmt
terraform validate
terraform plan -out=terraform.tfplan
terraform apply terraform.tfplan
terraform output vpc
terraform state list
terraform plan
```

`null` nie oznacza pustego tekstu ani sieci `0.0.0.0/0`. W tym argumencie
oznacza pominięcie własnego zakresu. Gdy podajesz CIDR samodzielnie, musi być
zgodny z wymaganiami VPC DigitalOcean i nie kolidować z sieciami na koncie.
Walidacja formatu IPv4 nie zastępuje sprawdzeń po stronie API.

Nie dodawaj VPC do `resources` projektu. Ten mechanizm obsługuje m.in. Droplety,
ale nie VPC. Powiązanie sieci z maszyną zrobisz przez `vpc_uuid` w etapie 08.

## Kryterium ukończenia

- Plan dodaje tylko VPC. Stan ma trzy zasoby.
- Output pokazuje rzeczywisty zakres sieci oraz region `fra1`.
- Drugi plan nie proponuje zmian.

## Sprawdź zrozumienie

1. Czym `null` różni się od `"null"` i `""`?
2. Dlaczego sieć oraz późniejszy Droplet powinny mieć wspólny region?
3. Czy poprawny składniowo CIDR gwarantuje, że API przyjmie sieć?

Dokumentacja: [VPC](https://docs.digitalocean.com/reference/terraform/reference/resources/vpc/),
[zasoby obsługiwane przez projekt](https://docs.digitalocean.com/reference/terraform/reference/resources/project/).

## Parametry lokalne

Rozwiązanie tego etapu zawiera `terraform.tfvars.example` bez sekretu.
Lokalny `terraform.tfvars` przechowuje parametry tego etapu i `digitalocean_token`;
jest ignorowany przez Git i ma uprawnienia `0600`. W swoim `praca` dopisuj
nowe parametry do istniejącego pliku, zachowując token. Nie przenoś stanu
do katalogów rozwiązań. Po świeżym klonowaniu uzupełnij token we własnym tfvars.

## Rozwiązanie i dalsza praca

[Kompletny kod po tym etapie](rozwiazanie/) — porównaj go z własną pracą.
Rozwiązania nie zawierają Twojego stanu ani danych dostępowych.

[Poprzedni etap](../05_projekt_digitalocean/README.md) · [Następny etap](../07_klucze_ssh/README.md)
