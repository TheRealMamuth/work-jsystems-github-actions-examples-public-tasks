# Ćwiczenie 04 — wdrożenie aplikacji przez role Ansible

Przygotuj projekt Ansible wdrażający gotową aplikację pogodową na swojej
**istniejącej maszynie szkoleniowej z agentem**. Każdy uczestnik wskazuje
w inventory własny adres IP. Całą instalację i konfigurację wykonują role
Ansible, a Ty sprawdzasz wynik przez WWW i prawdziwe API.

Docelowy ruch HTTP:

```text
http://IP_TWOJEGO_AGENTA:80 → Nginx na hoście
  → 127.0.0.1:18080 na hoście → kontener aplikacji:8080
```

## 1. Wybierz kontroler i sprawdź adres hosta docelowego

Teraz wybierz komputer, z którego uruchomisz Ansible: własny laptop albo
inną maszynę z dostępem SSH do hosta agenta. Kontrolerem może być także sam
host agenta, ale w tym ćwiczeniu połączysz się do jego jawnego IP przez SSH.

Teraz na swojej maszynie agenta wykonaj:

```bash
ip a
ip -4 addr show dev eth0
```

Odczytaj rzeczywisty publiczny IPv4 z `inet` przy `eth0`, bez maski sieci.
To adres **celu wdrożenia**, a nie adres laptopa. Ustal też konto SSH oraz
istniejący klucz dostępu otrzymane do tej maszyny. Nie twórz nowego klucza
ani nowej VM tylko na potrzeby zadania.

## 2. Przygotuj Ansible na kontrolerze

Teraz przygotuj na kontrolerze Python `3.11` lub nowszy i środowisko
narzędziowe poza katalogiem repozytorium. Poniższy zakres pozwala pip dobrać
wersję ansible-core zgodną z Pythonem kontrolera:

```bash
python3 -m venv ~/.venvs/cw04-ansible
source ~/.venvs/cw04-ansible/bin/activate
python -m pip install 'ansible-core>=2.17,<2.23'
ansible --version
```

Kolekcję `community.docker` zainstalujesz z pliku `requirements.yml`
w następnym kroku. Host docelowy musi być maszyną Ubuntu/Debian z Pythonem
oraz kontem pozwalającym wykonać zadania administracyjne przez `sudo`.
Do testu aplikacji na kontrolerze potrzebujesz także `curl`.

Nie zatrzymuj ani nie instaluj ponownie działającego agenta szkoleniowego.
Docker i Nginx mają zostać sprawdzone i uzupełnione tylko tam, gdzie ich brakuje.

## 3. Utwórz własny projekt ansible

Teraz utwórz publiczny katalog `CWICZENIA_TERRAFORM/cwiczenie04/ansible`.
Pracuj od tego miejsca wewnątrz tego katalogu. Przygotuj pliki:

```text
ansible/
  ansible.cfg
  requirements.yml
  inventory.ini.example
  inventory.ini
  vars.local.yml.example
  vars.local.yml
  site.yml
  roles/
    docker_runtime/tasks/main.yml
    weather_app/defaults/main.yml
    weather_app/tasks/main.yml
    nginx_proxy/tasks/main.yml
    nginx_proxy/handlers/main.yml
    nginx_proxy/templates/cw04-pogoda.conf.j2
```

Pliki `.example`, playbook, konfiguracja i role mają trafić do repozytorium.
`inventory.ini` oraz `vars.local.yml` są Twoimi lokalnymi plikami ignorowanymi
przez Git. Lokalny `rozwiazanie_ukryte/ansible` to wzorzec instruktora,
którego nie otrzymujesz w klonie repozytorium.

Teraz w `requirements.yml` zadeklaruj kolekcję `community.docker` w wersji
`5.4.1`, a następnie wykonaj:

```bash
ansible-galaxy collection install -r requirements.yml
```

W `ansible.cfg` wskaż `inventory.ini` i lokalny katalog `roles`. Zachowaj
weryfikację klucza hosta SSH. Zainstalowane kolekcje i Ansible muszą być
widoczne w tym samym środowisku, z którego uruchomisz playbook.

## 4. Utwórz inventory z jednym własnym hostem

Teraz utwórz niesekretny przykład `inventory.ini.example`, a na jego podstawie
lokalny `inventory.ini` z grupą i aliasem:

```ini
[weather_agents]
agent ansible_host=203.0.113.20 ansible_user=student
```

Adres `203.0.113.20` jest wyłącznie dokumentacyjny — zastąp go własnym IP
odczytanym z `eth0`. `student` także jest przykładem: ustaw konto faktycznie
przydzielone do Twojej maszyny, np. `student` albo `root`.

Teraz wskaż na kontrolerze istniejący prywatny klucz do tego hosta:

```bash
CW04_SSH_KEY="$HOME/.ssh/NAZWA_TWOJEGO_KLUCZA"
test -f "$CW04_SSH_KEY"
```

Zastąp nazwę pliku rzeczywistą. Klucz pozostaje poza repozytorium; podawaj
jego ścieżkę przez `--private-key`. Przy pierwszym kontakcie zweryfikuj
klucz hosta zgodnie z ustaleniami prowadzącego.

## 5. Utwórz jawny plik zmiennych z kluczem API

Teraz utwórz `vars.local.yml.example` z placeholderem:

```yaml
openweather_api_key: "UZUPELNIJ_AKTYWNY_KLUCZ_OPENWEATHER"
```

Teraz wykonaj:

```bash
cp vars.local.yml.example vars.local.yml
chmod 600 vars.local.yml
```

Otwórz `vars.local.yml` w edytorze i zastąp placeholder swoim aktywnym
kluczem API, pozostawiając wartość tekstową w cudzysłowie.
To **jawny, nieszyfrowany plik lokalny**. Prawa `0600`
ograniczają odczyt na kontrolerze, ale nie szyfrują jego zawartości.
Nie dodawaj tego pliku do Gita ani nie wyświetlaj go w logach.

Klucz przekaż później do kontenera przez `env`, wyłącznie podczas jego
uruchamiania. Użytkownik WWW i API będzie podawać tylko miasto.

Pozostałe ustawienia aplikacji możesz zadeklarować jako wartości domyślne
roli i opcjonalnie nadpisać lokalnie:

| Zmienna | Wartość |
| --- | --- |
| `weather_image_reference` | Pełny obraz przypięty digestem z kroku 8 |
| `weather_container_name` | `cw04-pogoda` |
| `weather_city` | `Warsaw` |
| `weather_dockerhub_username` | Domyślnie pusty; opcjonalny login do pobrania obrazu |
| `weather_dockerhub_token` | Domyślnie pusty; opcjonalny token razem z loginem |

Do pobrania publicznego obrazu wystarczy pusty login i token. Jeśli używasz
logowania do rejestru, jego token także pozostaw wyłącznie w lokalnym pliku.

## 6. Przygotuj site.yml i kolejność ról

Teraz utwórz playbook `site.yml`. Ustaw grupę `hosts: weather_agents`,
zbieranie faktów i `become: true`. Wykonuj role w kolejności:

1. `docker_runtime` — sprawdzenie i przygotowanie Dockera.
2. `weather_app` — pobranie obrazu i uruchomienie kontenera.
3. `nginx_proxy` — przygotowanie Nginxa i publicznego proxy HTTP.

Przekazuj własny plik przez `-e @vars.local.yml`. Przed zmianami sprawdź
wymagane zmienne: klucz nie może być pusty ani nadal zawierać placeholdera.
Nie dodawaj zadań wyświetlających wszystkie zmienne, zwłaszcza klucz API.

Jeśli konto ma `sudo` wymagające hasła, dodaj `-K` do polecenia playbooka.
Jeśli przydzielony host używa hasła SSH, użyj `-k` zamiast `--private-key`.
`-K` pyta o hasło podniesienia uprawnień, a `-k` o hasło połączenia SSH.
Podstawowy wariant ćwiczenia korzysta z istniejącego klucza SSH.

## 7. Napisz rolę docker_runtime

Teraz w `roles/docker_runtime/tasks/main.yml` sprawdź dostępność Dockera.
Zadanie odczytu przez `command` ma mieć `changed_when: false`.

Jeśli Docker jest już zainstalowany, wykorzystaj istniejącą instalację.
Nie zastępuj Docker CE pakietem `docker.io` i nie restartuj demona tylko
z powodu ponowienia playbooka. Gdy Dockera nie ma, zainstaluj odpowiedni
pakiet przez moduł `apt` z `state: present`, a nie `latest`.

Teraz zapewnij na hoście pakiet `python3-requests`, wymagany przez używane
moduły kolekcji, oraz uruchomioną i włączoną usługę Docker. Nie usuwaj
innych kontenerów, obrazów, sieci ani wolumenów. Pozostaw działającego agenta.

## 8. Napisz rolę weather_app

Teraz w `roles/weather_app/tasks/main.yml` przygotuj pobranie gotowego obrazu:

```text
piotrskoska/python_pogoda@sha256:ac30d995f5ca10e4c5db5c44d526398c435270ba1194c5987642f7179a224638
```

Nie budujesz aplikacji. Pobierz wskazany obraz z Docker Hub i przez
`community.docker.docker_container` uzgodnij stan własnego kontenera.
Kontener ma pozostawać uruchomiony po playbooku i mieć politykę ponownego
startu `unless-stopped`.

Teraz sprawdź obraz przez `community.docker.docker_image_info`. Gdy go
brakuje, użyj `community.docker.docker_image_pull` z `pull: not_present`.
W zadaniu kontenera ustaw `pull: never`: nie usuwaj działającego kontenera,
zanim upewnisz się, że obraz jest dostępny.

Teraz ustaw mapowanie wyłącznie `127.0.0.1:18080:8080`. Przekaż
`OPENWEATHER_API_KEY` przez `env` z wartości `openweather_api_key`.
Zadania operujące konfiguracją kontenera oznacz `no_log: true`, aby nie
wypisywać klucza w wynikach modułu lub przy błędzie. Nie wymuszaj odtwarzania
albo restartu kontenera przy każdym uruchomieniu; zmieniona konfiguracja
lub klucz mają być rozpoznawane przez moduł.

Teraz dodaj kontrolę `/healthz` lokalnego portu kontenera przez moduł `uri`
z ponowieniami. Brak gotowości ma zatrzymać wykonanie.

## 9. Napisz rolę nginx_proxy

Teraz sprawdź Nginxa. Wykorzystaj obecną instalację albo zainstaluj brakujący
pakiet przez `apt` z `state: present`. Usługa ma być włączona i uruchomiona.

Teraz utwórz własny template vhosta `cw04-pogoda.conf.j2`: nasłuchuj na
porcie `80`, a `server_name` ustaw na dokładny IP z `ansible_host`.
W lokalizacji `/` użyj:

```nginx
proxy_pass http://127.0.0.1:18080;
```

Dodaj konfigurację wyłącznie własnej strony CW04. **Nie ustawiaj
`default_server` i nie usuwaj istniejących stron ani domyślnej konfiguracji.**
Inne domeny, np. panel szkoleniowy, mają nadal korzystać ze swoich vhostów.

Teraz dodaj handler sprawdzający `nginx -t` i przeładowujący Nginxa tylko
po zmianie konfiguracji. Nie wymuszaj restartu całej usługi przy każdym
uruchomieniu. Gdy port `80` zajmuje inna aplikacja albo IP ma już konfliktującą
konfigurację, uzgodnij rozwiązanie z prowadzącym; nie usuwaj cudzych usług.

Teraz zastosuj handlery przez `meta: flush_handlers` przed testem HTTP.
W `post_tasks` playbooka dodaj test formularza WWW oraz zapytanie
`/api/weather?city={{ weather_city | urlencode }}` przez moduł `uri`.
Dla lokalnego adresu `127.0.0.1` ustaw nagłówek `Host` na `ansible_host`,
aby wybrać właściwy vhost. Potwierdź HTTP `200`, formularz `weather-form`,
`source: openweathermap`, `units: metric`, liczbę w `temperature` i niepuste
`city`. Klucza API nie podawaj w URL. Błąd klucza lub dostawcy ma zakończyć
playbook niepowodzeniem, nawet jeśli sam `/healthz` działa.

## 10. Sprawdź zakres i połączenie bez wdrażania

Teraz wyświetl zakres:

```bash
ansible -i inventory.ini weather_agents --list-hosts
ansible-playbook -i inventory.ini site.yml --limit agent -e @vars.local.yml --list-hosts
```

Wynik ma zawierać tylko alias `agent`. Teraz sprawdź w `inventory.ini`,
że przypisany mu adres jest IP Twojej maszyny. Jeśli inventory obejmuje
inne maszyny, popraw je przed dalszym wykonaniem.

Teraz sprawdź połączenie:

```bash
ansible -i inventory.ini agent -m ansible.builtin.ping --private-key "$CW04_SSH_KEY"
```

Oczekuj `pong`. To moduł Ansible sprawdzający połączenie SSH i działający
Python na hoście, nie pakiet ICMP.

## 11. Sprawdź składnię i opcjonalny plan zmian

Teraz wykonaj:

```bash
ansible-playbook -i inventory.ini site.yml --syntax-check -e @vars.local.yml
```

Opcjonalnie obejrzyj przewidywane zmiany:

```bash
ansible-playbook -i inventory.ini site.yml --limit agent -e @vars.local.yml --private-key "$CW04_SSH_KEY" --check
```

To podgląd, a nie wdrożenie przez Ansible. Na pierwszym uruchomieniu brak
pakietów, bibliotek lub działającego Dockera może uniemożliwić sprawdzenie
późniejszych zadań w check mode. Polecenia odczytujące wersje programów
i konfigurację nadal się wykonują; testy HTTP i rzeczywistej pogody są
pomijane. Sama poprawna składnia ani wynik `--check` nie potwierdza
działającej aplikacji.

## 12. Wdróż aplikację przez Ansible na swoim hoście

Teraz wykonaj rzeczywiste wdrożenie **przez Ansible**, wyłącznie na aliasie
`agent` z Twojego inventory:

```bash
ansible-playbook -i inventory.ini site.yml --limit agent -e @vars.local.yml --private-key "$CW04_SSH_KEY"
```

Jeśli potrzebujesz hasła `sudo`, dodaj `-K`. Sprawdź recap: oczekuj
`failed=0` i `unreachable=0`. Pakiety mają być instalowane tylko tam, gdzie
brakowało wymaganej instalacji, a pozostałe aplikacje i agent mają pozostać
uruchomione.

## 13. Sprawdź WWW i rzeczywistą pogodę

Teraz na kontrolerze wykonaj:

```bash
curl --fail --silent --show-error http://TWOJ_PUBLICZNY_IP/healthz
python3 ../tests/smoke_test.py --base-url http://TWOJ_PUBLICZNY_IP --city Warsaw
```

Zastąp placeholder IP z inventory. Dostarczony test
[tests/smoke_test.py](./tests/smoke_test.py) sprawdza formularz, zasoby,
API i rzeczywiste dane OpenWeatherMap. Nie musisz pisać kodu aplikacji
ani przekazywać klucza jako argumentu testu.

Teraz otwórz `http://TWOJ_PUBLICZNY_IP/` w przeglądarce i wpisz miasto.
Użytkownik nie podaje klucza API. Błąd prawdziwego klucza lub dostawcy
ma być błędem testu, bez zastępowania danych przykładową pogodą.
Dostęp HTTP wymaga dopuszczenia portu `80` w regułach hosta i sieci.

## 14. Sprawdź idempotencję i zachowaj właściwy zakres

Teraz uruchom to samo polecenie playbooka drugi raz bez zmiany zmiennych.
Oczekuj `changed=0` oraz działającego WWW/API. Jeśli zadania nadal zmieniają
stan, sprawdź ich przyczynę: nie wymuszaj `restart`, `recreate` ani aktualizacji
`latest` przy każdym wykonaniu. Nie maskuj rzeczywistych zmian jako odczytów.

Teraz sprawdź, że Git obejmuje publiczny projekt i pliki `.example`,
a ignoruje `inventory.ini` oraz jawny `vars.local.yml`. W szczególności
nie publikuj prawdziwego klucza API ani prywatnego klucza SSH.

To istniejąca maszyna z agentem. Nie usuwaj po ćwiczeniu hosta, Dockera,
Nginxa ani cudzych kontenerów i vhostów. Własna aplikacja pozostaje na
przydzielonym hoście zgodnie z ustaleniami prowadzącego.

Zadanie jest ukończone, gdy role przez Ansible przygotowują brakujące
składniki, wdrażają kontener, zachowują pozostałe usługi, a Nginx serwuje
WWW/API pod IP uczestnika i kolejne wykonanie nie wprowadza zmian.
Lokalne sprawdzenie plików nie jest dowodem wykonania na hoście.

Dokumentacja:
[role Ansible](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_roles.html),
[moduł ping](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/ping_module.html)
oraz [opcje ansible-playbook](https://docs.ansible.com/projects/ansible/latest/cli/ansible-playbook.html).
