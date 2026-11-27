# Ćwiczenie 01 — maszyna DigitalOcean we własnej sieci VPC

Napisz konfigurację Terraform tworzącą jedną maszynę Ubuntu, sieć VPC,
firewall oraz parę kluczy SSH. Wartości nazw i adresacji mają pochodzić
ze zmiennych. Do nazw zasobów dodaj losowy sufiks, aby odróżnić zasoby
uczestników korzystających ze wspólnego konta.

Pliki `.tf` napisz samodzielnie bezpośrednio w tym katalogu. Lokalny katalog
instruktora `rozwiazanie_ukryte/` jest wyłączony z Gita i nie trafia do klonów
repozytorium uczestników; nie jest katalogiem roboczym tego zadania.

## 1. Przygotuj narzędzia i dostęp

Teraz sprawdź, czy masz Terraform co najmniej `1.6.0`, terminal Bash,
klienta OpenSSH oraz dostęp do konta DigitalOcean:

```bash
terraform version
ssh -V
```

Token DigitalOcean musi pozwalać odczytywać i zarządzać Dropletami, sieciami
VPC, firewallami oraz kluczami SSH, także usuwać zasoby podczas sprzątania.
Sprawdź dostępny limit maszyn i dostępność regionu oraz rozmiaru VM na koncie.
Utworzona maszyna będzie zasobem płatnym do czasu jej usunięcia; samo
przeczytanie instrukcji ani lokalne formatowanie plików jej nie tworzy.

Teraz przejdź w terminalu do `CWICZENIA_TERRAFORM/cwiczenie01` w swoim klonie.
Wszystkie dalsze polecenia Terraform wykonuj z tego katalogu.

## 2. Ustal adresację i nazwy dla swojego ćwiczenia

Teraz uzgodnij z prowadzącym wolną sieć VPC. Wymagana domyślna wartość
zmiennej `vpc_cidr` to `10.33.34.0/24`. Na wspólnym koncie nie możesz
utworzyć kolejnej sieci z zakresem nachodzącym na istniejącą VPC.

Losowy sufiks rozwiązuje kolizje **nazw**, a nie kolizje zakresów IP.
Jeśli domyślna sieć jest zajęta, uzyskaj przydział innego wolnego `/24`,
np. `10.33.35.0/24`, i podaj go jako wartość `vpc_cidr`. Nie wybieraj zakresu
na podstawie samej zmiany nazwy sieci.

Teraz ustal swój publiczny adres IPv4, z którego będziesz łączyć się przez
SSH. W firewallu podaj go z maską `/32`. Adres `203.0.113.10/32` w przykładach
jest adresem dokumentacyjnym — musisz zastąpić go swoim rzeczywistym adresem.

## 3. Utwórz plik `versions.tf`

Teraz utwórz `versions.tf`. Dodaj blok `terraform`, określ minimalną wersję
Terraform i zadeklaruj providery:

| Nazwa lokalna | Źródło | Ograniczenie wersji |
| --- | --- | --- |
| `digitalocean` | `digitalocean/digitalocean` | `~> 2.109.0` |
| `random` | `hashicorp/random` | `~> 3.9.1` |
| `tls` | `hashicorp/tls` | `~> 4.4.2` |
| `local` | `hashicorp/local` | `~> 2.9.1` |

Dodaj pustą konfigurację `provider "digitalocean" {}`. Provider odczyta
token ze zmiennej środowiskowej `DIGITALOCEAN_TOKEN`; nie twórz zmiennej
Terraform zawierającej token i nie zapisuj go w `terraform.tfvars`.

Pozostaw domyślny lokalny state w pliku `terraform.tfstate`.
W tym ćwiczeniu nie dodawaj bloku `backend`.

## 4. Utwórz plik `variables.tf`

Teraz utwórz deklaracje poniższych zmiennych typu `string`. Do każdej dodaj
opis. Nazwy zasobów traktuj jako podstawę nazwy, do której później dołączysz
losowy sufiks.

| Zmienna | Wartość domyślna lub przeznaczenie |
| --- | --- |
| `vm_name` | Wymagana podstawa nazwy VM, np. `vm-jan-kowalski` |
| `firewall_name` | Wymagana podstawa nazwy firewalla, np. `fw-jan-kowalski` |
| `vpc_name` | Wymagana podstawa nazwy VPC, np. `vpc-jan-kowalski` |
| `vpc_cidr` | Domyślnie `10.33.34.0/24` |
| `region` | Domyślnie `fra1` |
| `vm_image` | Domyślnie `ubuntu-24-04-x64` |
| `vm_size` | Domyślnie `s-1vcpu-1gb` |
| `ssh_allowed_cidr` | Wymagany rzeczywisty publiczny IPv4 uczestnika z maską `/32`, bez wartości domyślnej |

Dodaj walidację nazw: 3–50 znaków, małe litery, cyfry i myślniki;
początek to litera, koniec to litera lub cyfra. Dla `ssh_allowed_cidr` odrzuć błędny CIDR,
IPv6 i maski inne niż `/32`; nie otwieraj SSH dla `0.0.0.0/0`.
Dla `vpc_cidr` sprawdź poprawność prywatnej sieci IPv4 o masce `/24`.

## 5. Utwórz `main.tf` i losowy sufiks

Teraz utwórz `main.tf` i zasób `random_string` z długością sześciu znaków.
Włącz małe litery i cyfry, wyłącz wielkie litery i znaki specjalne.
Do nazw użyj atrybutu `result`, np. `a1b2c3`.

Wylicz nazwy VM, firewalla, VPC i zarejestrowanego klucza SSH, łącząc
odpowiednią zmienną z tym samym sufiksem. Nazwa maszyny może wyglądać tak:

```text
vm-jan-kowalski-a1b2c3
```

Nie wpisuj losowej wartości ręcznie. Nie używaj `timestamp()` do nazw
zasobów. Sufiks ma pozostać stały w zapisanym state przy kolejnych planach;
samo odświeżenie nie powinno go zmieniać.

## 6. Dodaj sieć VPC

Teraz dodaj zasób `digitalocean_vpc`. Ustaw:

- nazwę z `var.vpc_name` i losowego sufiksu;
- `region` ze zmiennej `region`;
- `ip_range` ze zmiennej `vpc_cidr`.

Nie wpisuj `10.33.34.0/24` bezpośrednio w zasobie. Zmiana wartości
`vpc_cidr` ma rzeczywiście zmieniać planowany zakres sieci.

## 7. Wygeneruj i zarejestruj parę kluczy SSH

Teraz dodaj `tls_private_key` z algorytmem `ED25519`. Publiczną część tej
pary przekaż do `digitalocean_ssh_key` przez atrybut `public_key_openssh`.
Nadaj kluczowi nazwę opartą na nazwie VM, oznaczeniu SSH i losowym sufiksie.

Teraz dodaj `local_sensitive_file`, który zapisze `private_key_openssh`
do `${path.module}/.keys/id_ed25519`. Ustaw `file_permission = "0600"`
i prawa katalogu `directory_permission = "0700"`.

Wygenerujesz jedną parę: część publiczna trafia do DigitalOcean, a prywatna
pozostaje na Twoim komputerze oraz w lokalnym state Terraform. W kroku 10
udostępnij obie części jako outputs; prywatną oznacz jako `sensitive`.

Oznaczenie `sensitive` ogranicza wyświetlanie danych, ale nie szyfruje state.
Chroń zarówno plik klucza, jak i `terraform.tfstate` oraz jego kopie.

## 8. Dodaj maszynę w utworzonej sieci

Teraz dodaj `digitalocean_droplet`:

1. Nazwę zbuduj z `var.vm_name` i sufiksu.
2. Pola `region`, `image` i `size` pobierz odpowiednio ze zmiennych
   `region`, `vm_image` i `vm_size`.
3. Do `vpc_uuid` przekaż ID VPC utworzonej w kroku 6.
4. Do listy `ssh_keys` przekaż ID albo fingerprint zarejestrowanego
   `digitalocean_ssh_key`.

Używaj odwołań do atrybutów zasobów, zamiast wklejać ID z panelu.
Terraform na ich podstawie ustali zależności między siecią, kluczem i VM.

## 9. Dodaj firewall i przypisz go do VM

Teraz dodaj `digitalocean_firewall`. Nazwa ma pochodzić z `var.firewall_name`
i sufiksu. W `droplet_ids` umieść ID właśnie utworzonego Dropleta.

Zdefiniuj następujące reguły:

| Kierunek | Protokół | Porty | Źródło lub cel |
| --- | --- | --- | --- |
| Przychodzący | TCP | `22` | Wyłącznie `var.ssh_allowed_cidr` |
| Wychodzący | TCP | `1-65535` | `0.0.0.0/0` i `::/0` |
| Wychodzący | UDP | `1-65535` | `0.0.0.0/0` i `::/0` |
| Wychodzący | ICMP | Bez `port_range` | `0.0.0.0/0` i `::/0` |

Teraz sprawdź, że firewall jest przypisany przez `droplet_ids`; samo
utworzenie go bez tego powiązania nie chroni VM.

## 10. Dodaj outputs i swoje wartości wejściowe

Teraz utwórz `outputs.tf` i zadeklaruj wyniki:

| Output | Wartość |
| --- | --- |
| `vm_id` | ID utworzonego Dropleta |
| `vm_name` | Pełna nazwa VM z sufiksem |
| `public_ip` | Publiczny IPv4 VM |
| `private_ip` | Prywatny IPv4 VM w VPC |
| `vpc_id` | ID utworzonej VPC |
| `vpc_cidr` | Faktyczny `ip_range` utworzonej VPC |
| `firewall_name` | Pełna nazwa przypisanego firewalla |
| `private_key_path` | Ścieżka pliku klucza, bez jego zawartości |
| `ssh_public_key` | `tls_private_key.ssh.public_key_openssh` — klucz publiczny w formacie OpenSSH |
| `ssh_private_key` | `tls_private_key.ssh.private_key_openssh` — klucz prywatny z `sensitive = true` |
| `ssh_command` | Polecenie SSH z właściwą ścieżką klucza i publicznym IP |

Każdy output ma korzystać z odpowiednich atrybutów zasobów. Dla
`ssh_private_key` ustaw `sensitive = true`, aby zwykłe `terraform output`
oraz podsumowanie `apply` ukrywały jego wartość. Nie wystawiaj tokenu API.

Teraz utwórz lokalny plik `terraform.tfvars`. Ustaw w nim własne wartości
`vm_name`, `firewall_name`, `vpc_name` i `ssh_allowed_cidr`. Jeśli prowadzący
przydzielił inną sieć, ustaw również `vpc_cidr`.

Teraz sprawdź, że Git ignoruje `.terraform/`, `.keys/`, state wraz z kopiami,
pliki `.tfvars` i zapisane plany. Plik `.terraform.lock.hcl` standardowo
wersjonuje się razem z konfiguracją; nie jest plikiem state ani sekretem.
Cały lokalny wzorzec instruktora `rozwiazanie_ukryte/` pozostaje ignorowany.

## 11. Udostępnij token tylko bieżącej sesji terminala

Teraz wykonaj poniższe polecenia w Bash. Jeśli korzystasz z innej powłoki,
najpierw uruchom `bash`. Wklej token przy ukrytym odczycie, bez wpisywania
jego wartości do polecenia:

```bash
read -rsp "Token DigitalOcean: " DIGITALOCEAN_TOKEN
echo
export DIGITALOCEAN_TOKEN
```

Nie wykonuj `echo "$DIGITALOCEAN_TOKEN"` i nie zapisuj tokenu w plikach
projektu. Provider odczyta go ze środowiska procesu Terraform.

## 12. Sformatuj i sprawdź napisaną konfigurację

Teraz wykonaj:

```bash
terraform fmt
terraform init
terraform validate
```

`fmt` porządkuje zapis HCL, `init` pobiera wymagane providery i tworzy lockfile,
a `validate` sprawdza konfigurację. Usuń zgłoszone błędy, zanim przejdziesz
dalej. Te polecenia nie tworzą Dropleta.

## 13. Przygotuj plan i przeczytaj go

Teraz wykonaj:

```bash
terraform plan -out=tfplan
terraform show tfplan
```

Teraz sprawdź w planie:

- czy ma powstać jedna maszyna we wskazanym regionie;
- czy nazwy używają Twoich zmiennych i sześciu znaków sufiksu;
- czy VPC otrzymała właściwy, uzgodniony `ip_range`;
- czy VM korzysta z utworzonej VPC i publicznego klucza SSH;
- czy firewall dopuszcza przychodzący TCP `22` tylko z Twojego `/32`;
- czy output `ssh_private_key` ma `sensitive = true`, a token nie jest outputem.

Zapisany plan jest plikiem lokalnym, którego nie publikujesz w Git.
Odczyt planu nie oznacza jeszcze utworzenia ani sprawdzenia maszyny w chmurze.

## 14. Utwórz zasoby i odczytaj wynik

Teraz wykonaj zatwierdzony przez siebie zapisany plan:

```bash
terraform apply tfplan
terraform output
```

To polecenie wykonuje rzeczywiste operacje w DigitalOcean i tworzy płatną
VM. Wskazanie pliku planu oznacza zastosowanie przeczytanego planu, bez
dodatkowego pytania o potwierdzenie w `apply`.

Teraz odczytaj klucz publiczny:

```bash
terraform output -raw ssh_public_key
```

Jeżeli potrzebujesz odczytać treść klucza prywatnego, wykonaj lokalnie:

```bash
terraform output -raw ssh_private_key
```

To polecenie ujawnia klucz mimo `sensitive = true`. Jawny odczyt konkretnego
outputu oraz `terraform output -json` także mogą ujawnić jego wartość.
Nie dodawaj takiego odczytu do logów pipeline ani materiałów publikowanych
w repozytorium. Do logowania SSH użyj pliku `.keys/id_ed25519` utworzonego
przez konfigurację.

Teraz sprawdź w panelu DigitalOcean, czy VM ma oczekiwaną nazwę, region,
prywatny adres z wybranej sieci i przypisany firewall. Otwórz szczegóły VPC
oraz firewalla i porównaj CIDR, powiązanie z VM i źródło reguły SSH z kodem.

## 15. Połącz się przez SSH i sprawdź sieć

Teraz odczytaj publiczny IP z outputs i sprawdź prawa klucza:

```bash
ls -l .keys/id_ed25519
terraform output -raw ssh_command
ssh -i .keys/id_ed25519 root@PUBLICZNY_IP_Z_OUTPUT
```

Zastąp placeholder rzeczywistym IP. Przy pierwszym połączeniu zweryfikuj
klucz hosta według ustaleń prowadzącego. Po zalogowaniu wykonaj:

```bash
hostname
ip -4 address
```

Teraz sprawdź, czy jeden z adresów prywatnych należy do zadeklarowanego
`vpc_cidr`. Następnie zakończ sesję poleceniem `exit`.

Jeśli SSH nie działa, sprawdź kolejno: aktualny publiczny IP uczestnika,
wartość `ssh_allowed_cidr`, przypisanie firewalla, IP Dropleta i właściwy
plik prywatnego klucza. Nie naprawiaj dostępu przez otwarcie SSH dla całego
Internetu.

## 16. Sprawdź stałość konfiguracji i działanie zmiennych

Teraz ponownie wykonaj `terraform plan`. Po udanym apply i bez zmian kodu
oczekuj braku zmian. Losowy sufiks ma być taki sam jak przy pierwszym apply.

Teraz zmień w `terraform.tfvars` wartość `vm_name` i ponownie wykonaj plan.
Sprawdź, jakie zmiany wynikają z tej jednej zmiennej. Nie zakładaj z góry,
że zmiana jest bezpieczna: przeczytaj, czy plan aktualizuje zasób, czy go
zastępuje. Nie musisz stosować tej demonstracyjnej zmiany; możesz przywrócić
poprzednią wartość.

Nie usuwaj state, aby wymusić ponowne tworzenie zasobów. To nie odtwarza
kontroli nad już istniejącą infrastrukturą i może zostawić zasoby poza
zarządzaniem Terraform.

## 17. Usuń zasoby po ćwiczeniu

Teraz przygotuj i przeczytaj plan usuwania:

```bash
terraform plan -destroy -out=destroy.tfplan
terraform show destroy.tfplan
```

Po upewnieniu się, że plan dotyczy wyłącznie zasobów Twojego ćwiczenia,
teraz wykonaj:

```bash
terraform apply destroy.tfplan
```

Jeśli DigitalOcean nie pozwala usunąć VPC, bo jest ona domyślna w regionie,
zgłoś to prowadzącemu. Pierwsza sieć w regionie może zostać domyślną.
Prowadzący musi uzgodnić inną istniejącą VPC jako domyślną w tym regionie;
nie usuwaj ani nie modyfikuj samodzielnie cudzych sieci. Po rozwiązaniu
problemu przygotuj nowy plan usuwania i ponów operację. Wymaganie opisuje
[dokumentacja VPC DigitalOcean](https://docs.digitalocean.com/products/networking/vpc/reference/api/vpcs/).

Po udanym usunięciu teraz wykonaj:

```bash
terraform state list
unset DIGITALOCEAN_TOKEN
```

Teraz potwierdź w panelu DigitalOcean usunięcie VM, firewalla, VPC i klucza
SSH utworzonych w tym ćwiczeniu. Klucz prywatny zapisany przez zasób lokalny
także powinien zostać usunięty. Nie usuwaj plików state ręcznie przed
zakończeniem sprzątania; mogą być potrzebne do ponowienia nieudanej operacji.

Zadanie jest ukończone, gdy samodzielnie napisana konfiguracja korzysta
ze zmiennych, VM działa w wybranej VPC, firewall ogranicza SSH do Twojego
adresu, logowanie wygenerowanym kluczem działa, kolejny plan nie proponuje
zmian, a zasoby zostały posprzątane. Samo `fmt` lub `validate` potwierdza
lokalną poprawność konfiguracji, a nie rzeczywiste działanie w DigitalOcean.

Dokumentacja:
[plan](https://developer.hashicorp.com/terraform/cli/commands/plan),
[apply zapisanego planu](https://developer.hashicorp.com/terraform/cli/commands/apply),
[VPC DigitalOcean](https://docs.digitalocean.com/products/networking/vpc/how-to/create/)
oraz [provider DigitalOcean](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs).
