# Zadanie Github Actions:

## Ad 1.
Twoim zadaniem na poczatek będzie przygotowanie Self-Hosted Gihub actions agenta na maszynie wirtualnej w Twoim środowisku https://uczen-imie-nazwisko-gha.jsystems.cloud:23457
Instalacji dokonaj recznie.

## Ad 2.
Twoim kolejnym zadaniem bedzie przygotowanie w githubactions ENVIRONMENTS konfiguracji dla repozytorium. Strorz następujace Environments:
- development
- production
- testing
- staging

## Ad 3.
Naszym zadaniem będzie konfiguracją EVNIRONMENT testing
Przygotuj odpowiednie VARIABLES środowiskowe w ENVIRONMENT testing do podlaczenia sie za pomoca terraform do DigitalOcean:

1. region        = "nyc1"
2. droplet_size  = "s-2vcpu-2gb"
3. droplet_image = "ubuntu-24-04-x64"
4. name          = "example-droplet"
5. vpc_ip_range  = "10.99.1.0/24"

Przygotuj secrets w ENVIRONMENT testing:
1. do_token - z Twojego konta DigitalOcean
2. TF_API_TOKEN - z Twojego konta Terraform Cloud

## Ad 4.
Przygotuj workflow w Github Actions, który będzie wykonywał następujące kroki:
- Będzie korzystał z ENVIRONMENT zadanie_testing
- Będzie wykonywał następujące kroki:
  1. Checkout kodu
  2. Konfiguracja Terraform CLI z wykorzystaniem akcji oficjalnej HashiCorp
  3. Inicjalizacja Terraform
  4. Plan Terraform
  5. Apply Terraform (z automatycznym zatwierdzeniem)
  6. Na koniec terraform destroy (z automatycznym zatwierdzeniem)
To narazie nasz testowy flow. Zobaczmy Czy nasza konfiguracja wykonuje sie prwidlowo.

## Ad 5.
Rozbudujmy nasz powyszy pipeline o dodatkowe kroki:
1. Dodaj walidacje kodu z wykorzystaniem terraform validate
2. Dodaj krok wykonujący terraform fmt -check

## Ad 6. 
Dodaj dodatkowe infromacje z planu terraform za pomoca tf-summurize:
1. Dodaj krok wykonujący tf-summarize po kroku planu terraform

## Ad 7.
Nasz terraform generuje artefakty w postaci katalogu:
1. ./artefakty
   - zawiera on pliki z kluczami ssh do naszej maszyny wirtualnej
2. ./invantories
   - zawiera plik inventory.ini do wykorzystania z ansible

Twoim zadaniem będzie przekazac je do kolejnego joba w pipeline Github Actions i wykonać w nim proste zadanie zwiazane z ansible:
1. `asnible -i ./inventories/dev/hosts.yaml -m ping all`

## Ad 8.
Poprzednie nasz kroki z terraform rodziel na osobne joby w pipeline Github Actions:
1. Job 1 - init validate
   - checkout
   - terraform init
   - terraform validate
   - terraform fmt -check
2. Job 2 - plan
   - zależny od job 1
   - checkout
   - terraform init
   - terraform plan z zaspisem artefaktu tfplan
   - tf-summarize
3. Job 3 - summarize
   - zależny od job 2
   - checkout
   - terraform init
   - download artefact z joba 2 tfplan
   - tf-summarize
4. Job 4 - apply
   - zależny od joba 3 i 2
   - checkout
   - terraform init
   - download artefact z joba 2 tfplan
   - terraform apply z automatycznym zatwierdzeniem
   - upload artefakty ./artefakty i ./inventories
5. Job 5 - ansible
   - zależny od joba 4
   - checkout
   - download artefakty z joba 4 ./artefakty i ./inventories
   - wykonaj ansible ping do wszystkich hostów z inventory.ini

## Ad 9. 
Wykonaj podobna konfigurację dla innych środowisk:
1. zadanie_development
2. zadanie_staging
3. zadanie_production

Gdzie w każdym środowisku będą inne wartości zmiennych terraform.

## Ad 10.
Krok production niech zawiera element zatwierdzania ręcznego (manual approval) przed wykonaniem apply.

## Ad 11.
Podzielmy teraz nasz workflow na oddzielne srodwiska:
- zadanie_development.yml
- zadanie_staging.yml
- zadanie_production.yml
- zadanie_testing.yml

Gdzie w Testing bedziemy wykonywać pełny cykl init, validate, plan, summarize, apply, destroy
Gdzie w zadanie_development bedziemy wykonywać cykl init, validate, plan, apply - by stworzyć srodowisko rozwojowe
Gdzie w zadanie_staging bedziemy wykonywać cykl init, validate, plan, apply, ansible - by stworzyć srodowisko stagingowe ktore bedzie krokiem przed produkcyjnym
Gdzie w zadanie_production bedziemy wykonywać cykl init, validate, plan, manual approval, apply, ansible - by stworzyć srodowisko produkcyjne pelne.

