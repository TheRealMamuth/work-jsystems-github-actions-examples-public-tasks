# Ćwiczenie 04 — wdrożenie aplikacji przez role Ansible

Przygotuj projekt Ansible wdrażający gotową aplikację pogodową na swojej
**istniejącej maszynie szkoleniowej z agentem**. Wskaż jej IP w inventory.
Całą instalację i konfigurację wykonaj przez role Ansible, a wynik sprawdź
przez WWW i rzeczywiste API pogodowe.

W tym ćwiczeniu nie uruchamiasz GitHub Actions ani Terraform;
nie używasz Vault. Wdrożenie wykonujesz playbookiem Ansible z kontrolera.

Poniżej znajdziesz pełną treść wszystkich 11 plików projektu Ansible oraz
kompletny test `tests/smoke_test.py`. Utwórz je w podanych publicznych
ścieżkach repozytorium. Lokalny katalog `rozwiazanie_ukryte` jest dodatkowym
wzorcem prowadzącego; do wykonania instrukcji wystarczają pliki opisane tutaj.

Docelowy ruch HTTP:

```text
http://IP_TWOJEGO_AGENTA:80 → Nginx na hoście
  → 127.0.0.1:18080 na hoście → kontener aplikacji:8080
```

## 1. Wybierz kontroler i sprawdź adres hosta docelowego

Teraz wybierz komputer, z którego uruchomisz Ansible: własny laptop albo
inną maszynę z dostępem SSH do hosta agenta. Kontrolerem może być także sam
host agenta; w tym ćwiczeniu połączysz się z jego jawnym IP przez Ansible.

Na przydzielonym hoście odczytaj adres interfejsu:

```bash
ip a
ip -4 addr show dev eth0
```

Zapisz rzeczywisty publiczny IPv4 z `inet` przy `eth0`, bez maski sieci.
To adres **celu wdrożenia**, a nie adres laptopa. Ustal konto SSH oraz
istniejący klucz dostępu otrzymane do tej maszyny.

Pracujesz na istniejącym hoście. Pozostaw działającego agenta i jego usługi.
Port `18080` musi być wolny albo należeć do kontenera tego ćwiczenia.
Port `80` może obsługiwać istniejący Nginx z domeną panelu szkoleniowego:
nowy vhost wybierzesz po dokładnym IP. Konflikt z innym serwerem HTTP
lub istniejącym vhostem tego samego IP uzgodnij z prowadzącym.

## 2. Przygotuj Ansible na kontrolerze

Teraz przygotuj Python `3.11` lub nowszy i środowisko narzędziowe poza
repozytorium. Zakres wersji pozwoli pip dobrać ansible-core do Pythona:

```bash
python3 -m venv ~/.venvs/cw04-ansible
source ~/.venvs/cw04-ansible/bin/activate
python -m pip install 'ansible-core>=2.17,<2.23'
ansible --version
```

Host docelowy ma korzystać z Ubuntu lub Debiana, mieć Python oraz konto
z uprawnieniami administracyjnymi przez `sudo`. Do testów na kontrolerze
przygotuj również `curl`. W kolejnym kroku zainstaluj `community.docker`
w wersji zadeklarowanej w pełnym pliku `requirements.yml`.

Docker i Nginx zostaną sprawdzone przez role. Wykorzystasz obecne instalacje,
a brakujące składniki uzupełnisz pakietami `state: present`.

## 3. Utwórz kompletną strukturę projektu

Teraz przejdź w terminalu do katalogu głównego swojego klonu repozytorium.
Utwórz wszystkie katalogi:

```bash
mkdir -p \
  CWICZENIA_TERRAFORM/cwiczenie04/ansible/roles/docker_runtime/tasks \
  CWICZENIA_TERRAFORM/cwiczenie04/ansible/roles/weather_app/defaults \
  CWICZENIA_TERRAFORM/cwiczenie04/ansible/roles/weather_app/tasks \
  CWICZENIA_TERRAFORM/cwiczenie04/ansible/roles/nginx_proxy/tasks \
  CWICZENIA_TERRAFORM/cwiczenie04/ansible/roles/nginx_proxy/handlers \
  CWICZENIA_TERRAFORM/cwiczenie04/ansible/roles/nginx_proxy/templates \
  CWICZENIA_TERRAFORM/cwiczenie04/tests
cd CWICZENIA_TERRAFORM/cwiczenie04/ansible
```

Od tego miejsca wykonuj polecenia z katalogu `ansible`, chyba że instrukcja
wskazuje inaczej. Nagłówki plików podają pełne ścieżki względem głównego
katalogu repozytorium. Wklej do każdego pliku całą zawartość jego bloku.

Docelowa struktura:

```text
CWICZENIA_TERRAFORM/cwiczenie04/
  README.md
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
  tests/
    smoke_test.py
```

Utwórz teraz dwa pierwsze pliki:

### Plik: `CWICZENIA_TERRAFORM/cwiczenie04/ansible/ansible.cfg`

```ini
[defaults]
inventory = inventory.ini
roles_path = roles
host_key_checking = True
retry_files_enabled = False
interpreter_python = auto_silent

[ssh_connection]
pipelining = True
```

### Plik: `CWICZENIA_TERRAFORM/cwiczenie04/ansible/requirements.yml`

```yaml
---
collections:
  - name: community.docker
    version: 5.4.1
```

Teraz zainstaluj wymaganą kolekcję w aktywnym środowisku kontrolera:

```bash
ansible-galaxy collection install -r requirements.yml
ansible-galaxy collection list community.docker
```

### Reguły do dopisania w głównym `.gitignore`

Sprawdź główny plik `.gitignore` repozytorium. Jeśli poniższych reguł jeszcze
nie ma, dopisz je na końcu, zachowując pozostałą zawartość:

```gitignore
/CWICZENIA_TERRAFORM/**/rozwiazanie_ukryte/
/CWICZENIA_TERRAFORM/**/vars.local.yml
/CWICZENIA_TERRAFORM/**/inventory.ini
/CWICZENIA_TERRAFORM/**/.collections/
/CWICZENIA_TERRAFORM/**/*.retry
```

Publiczne role, playbook, test i pliki `.example` mają być wersjonowane.
`inventory.ini` i `vars.local.yml` pozostają lokalne.

## 4. Utwórz inventory z jednym własnym hostem

Teraz utwórz pełny plik przykładowy:

### Plik: `CWICZENIA_TERRAFORM/cwiczenie04/ansible/inventory.ini.example`

```ini
# Zastąp dokumentacyjny IP i użytkownika swoim istniejącym hostem agenta.
# Istniejący klucz SSH podaj przez --private-key /sciezka/do/klucza.
[weather_agents]
agent ansible_host=203.0.113.20 ansible_user=student
```

Skopiuj go do lokalnego inventory:

```bash
cp inventory.ini.example inventory.ini
chmod 600 inventory.ini
```

Otwórz `inventory.ini` w edytorze. Zastąp `203.0.113.20` swoim IP z `eth0`,
a `student` rzeczywistym kontem przydzielonym do maszyny, np. `student`
albo `root`. Zachowaj grupę `weather_agents` i alias `agent`. W grupie ma
znajdować się dokładnie jeden host. Adres z przykładu jest dokumentacyjny.

Teraz wskaż na kontrolerze istniejący prywatny klucz do tego hosta:

```bash
CW04_SSH_KEY="$HOME/.ssh/NAZWA_TWOJEGO_KLUCZA"
test -f "$CW04_SSH_KEY"
```

Zastąp nazwę pliku rzeczywistą. Klucz przechowuj poza repozytorium i podawaj
jego ścieżkę przez `--private-key`. Przy pierwszym kontakcie zweryfikuj
klucz hosta według ustaleń prowadzącego.

## 5. Utwórz jawny plik zmiennych z kluczem API

Teraz utwórz pełny plik przykładowy:

### Plik: `CWICZENIA_TERRAFORM/cwiczenie04/ansible/vars.local.yml.example`

```yaml
---
# Skopiuj do vars.local.yml, ustaw chmod 600 i uzupełnij aktywny klucz.
# To jawny plik lokalny. Nie dodawaj vars.local.yml do Git.
openweather_api_key: UZUPELNIJ_AKTYWNY_KLUCZ_OPENWEATHER

weather_city: Warsaw
weather_container_name: cw04-pogoda
weather_image_reference: piotrskoska/python_pogoda@sha256:ac30d995f5ca10e4c5db5c44d526398c435270ba1194c5987642f7179a224638

# Opcjonalnie: gdy obraz wymaga uwierzytelnienia, uzupełnij OBA pola.
# Token ma mieć jedynie wymagane prawo odczytu obrazu.
weather_dockerhub_username: ""
weather_dockerhub_token: ""
```

Teraz wykonaj:

```bash
cp vars.local.yml.example vars.local.yml
chmod 600 vars.local.yml
```

Otwórz `vars.local.yml` w edytorze i zastąp placeholder swoim aktywnym
kluczem API. Zapisz klucz jako tekst w cudzysłowie. Pozostałe wartości możesz
pozostawić zgodne z przykładem albo dostosować do swojej aplikacji.

To **jawny, nieszyfrowany plik lokalny**. Prawa `0600` ograniczają odczyt
na kontrolerze, ale nie szyfrują zawartości. Nie dodawaj tego pliku do Gita
ani nie wypisuj go w logach. W tym ćwiczeniu wpisujesz klucz bezpośrednio
do zmiennej `openweather_api_key` w lokalnym pliku YAML.

Klucz trafi do kontenera przez `env` podczas jego uruchomienia.
Użytkownik WWW i API będzie podawać tylko miasto.

| Zmienna | Wartość |
| --- | --- |
| `openweather_api_key` | Twój aktywny klucz OpenWeatherMap, wyłącznie w `vars.local.yml` |
| `weather_image_reference` | Pełny obraz przypięty digestem z przykładu |
| `weather_container_name` | `cw04-pogoda` |
| `weather_city` | `Warsaw` |
| `weather_dockerhub_username` | Domyślnie pusty; opcjonalny login do pobrania obrazu |
| `weather_dockerhub_token` | Domyślnie pusty; opcjonalny token odczytu obrazu, razem z loginem |

Domyślny wariant próbuje pobrać obraz bez tworzenia nowego logowania.
Jeśli rejestr wymaga uwierzytelnienia, uzupełnij **oba** pola Docker Hub
w lokalnym pliku. Rola utworzy własną tymczasową konfigurację logowania,
a następnie ją usunie. Zachowa istniejącą konfigurację Dockera na hoście.

## 6. Przygotuj site.yml i kolejność ról

Teraz utwórz kompletny playbook:

### Plik: `CWICZENIA_TERRAFORM/cwiczenie04/ansible/site.yml`

```yaml
---
- name: Przygotuj pogodę na jednym istniejącym hoście agenta
  hosts: weather_agents
  become: true
  gather_facts: true

  # Przykład: ansible-playbook site.yml --private-key ~/.ssh/klucz -e @vars.local.yml
  # Zmienne z pliku pozostają jawne lokalnie; zadania z kluczem ukrywają logi.
  module_defaults:
    group/community.docker.docker:
      docker_host: unix:///var/run/docker.sock

  pre_tasks:
    - name: Wymagaj jednego hosta Ubuntu lub Debian
      ansible.builtin.assert:
        that:
          - ansible_play_hosts_all | length == 1
          - ansible_facts.os_family == 'Debian'
          - ansible_facts.distribution in ['Debian', 'Ubuntu']
        fail_msg: Wskaż dokładnie jeden własny host agenta z Ubuntu lub Debian.

    - name: Wymagaj jawnego IPv4 hosta w inventory
      ansible.builtin.assert:
        that:
          - ansible_host is defined
          - (ansible_host | default('')) is match('^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$')
          - (ansible_host | default('') | split('.') | map('int') | max) <= 255
          - ansible_host not in ['0.0.0.0', '127.0.0.1']
        fail_msg: Ustaw ansible_host na rzeczywisty IPv4 swojego agenta.

    - name: Sprawdź klucz API bez wypisywania jego wartości
      ansible.builtin.assert:
        that:
          - openweather_api_key is defined
          - (openweather_api_key | default('')) is string
          - (openweather_api_key | default('') | trim | length) > 0
          - (openweather_api_key | default('')) != 'UZUPELNIJ_AKTYWNY_KLUCZ_OPENWEATHER'
          - (openweather_api_key | default('')) is not search('[\x00-\x20\x7f]')
        fail_msg: Uzupełnij aktywny klucz OpenWeather w lokalnym vars.local.yml.
      no_log: true

    - name: Sprawdź opcjonalną parę danych Docker Hub
      ansible.builtin.assert:
        that:
          - weather_dockerhub_username is string
          - weather_dockerhub_token is string
          - (weather_dockerhub_username | length > 0) == (weather_dockerhub_token | length > 0)
          - weather_dockerhub_username is not search('[\x00-\x20\x7f]')
          - weather_dockerhub_token is not search('[\x00-\x20\x7f]')
        fail_msg: Dane Docker Hub pozostaw oba puste albo uzupełnij użytkownika i token.
      no_log: true

    - name: Sprawdź niesekretne parametry kontenera
      ansible.builtin.assert:
        that:
          - weather_container_name is match('^[a-zA-Z0-9][a-zA-Z0-9_.-]{0,62}$')
          - weather_image_reference is match('^[a-z0-9][a-z0-9._/-]*@sha256:[a-f0-9]{64}$')
          - weather_city is string
          - weather_city | length > 0
          - weather_city | length <= 100
          - weather_city is not search('[\x00-\x1f\x7f]')
        fail_msg: Sprawdź nazwę kontenera, obraz z digestem sha256 oraz nazwę miasta.

  roles:
    - docker_runtime
    - weather_app
    - nginx_proxy

  post_tasks:
    - name: Odczytaj formularz WWW przez własny vhost
      ansible.builtin.uri:
        url: http://127.0.0.1/
        headers:
          Host: "{{ ansible_host }}"
        return_content: true
        status_code: 200
        use_proxy: false
      register: weather_web_response
      when: not ansible_check_mode

    - name: Potwierdź obecność formularza miasta
      ansible.builtin.assert:
        that:
          - >-
            'id="weather-form"' in weather_web_response.content
        fail_msg: Vhost nie zwrócił formularza aplikacji pogodowej.
      when: not ansible_check_mode

    - name: Odczytaj rzeczywistą pogodę przez API i Nginx
      ansible.builtin.uri:
        url: "http://127.0.0.1/api/weather?city={{ weather_city | urlencode }}"
        headers:
          Host: "{{ ansible_host }}"
        return_content: true
        status_code: 200
        timeout: 20
        use_proxy: false
      register: weather_api_response
      no_log: true
      when: not ansible_check_mode

    - name: Potwierdź dane rzeczywistego dostawcy pogody
      ansible.builtin.assert:
        that:
          - weather_api_response.json.source | default('') == 'openweathermap'
          - weather_api_response.json.units | default('') == 'metric'
          - weather_api_response.json.temperature | default(none) is number
          - weather_api_response.json.city | default('') is string
          - weather_api_response.json.city | default('') | trim | length > 0
        fail_msg: API nie potwierdziło rzeczywistej pogody z OpenWeatherMap. Sprawdź klucz, miasto i dostęp do dostawcy.
      no_log: true
      when: not ansible_check_mode
```

Playbook sprawdza zakres jednego hosta, system, adres i wymagane zmienne.
Wykonuje role `docker_runtime`, `weather_app`, `nginx_proxy`, a na końcu
sprawdza formularz WWW i rzeczywiste API pogodowe przez własny vhost.

W kolejnych poleceniach przekazuj lokalny plik przez
`--extra-vars @vars.local.yml`; zapis `-e @vars.local.yml` jest równoważny.
Przekazujesz ścieżkę pliku, a nie treść klucza w argumentach polecenia.

Jeśli `sudo` wymaga hasła, dodaj `-K` do polecenia playbooka. Jeśli przydzielony
host używa hasła SSH, użyj `-k` zamiast `--private-key`.
`-K` pyta o hasło podniesienia uprawnień, a `-k` o hasło połączenia SSH.
Podstawowy wariant ćwiczenia korzysta z istniejącego klucza SSH.

## 7. Napisz rolę docker_runtime

Teraz utwórz pełny plik zadań:

### Plik: `CWICZENIA_TERRAFORM/cwiczenie04/ansible/roles/docker_runtime/tasks/main.yml`

```yaml
---
- name: Odczytaj zainstalowane pakiety
  ansible.builtin.package_facts:
    manager: auto

- name: Sprawdź istniejący Docker CLI
  ansible.builtin.command:
    argv: [docker, --version]
  register: weather_docker_cli
  check_mode: false
  changed_when: false
  failed_when: false

- name: Nie zastępuj niekompletnej instalacji Docker CE ani Moby
  ansible.builtin.assert:
    that:
      - >-
        not (['docker-ce', 'docker-ce-cli', 'moby-engine', 'moby-cli'] |
        intersect(ansible_facts.packages.keys() | list))
    fail_msg: Istnieje instalacja Docker CE/Moby bez dostępnego CLI. Poproś prowadzącego o naprawę.
  when: weather_docker_cli.rc != 0

- name: Zainstaluj Docker tylko wtedy, gdy go brakuje
  ansible.builtin.apt:
    name: docker.io
    state: present
    update_cache: true
    cache_valid_time: 3600
  when: weather_docker_cli.rc != 0

- name: Zapewnij zależności modułów oraz diagnostyki HTTP
  ansible.builtin.apt:
    name:
      - python3-requests
      - ca-certificates
      - curl
      - iproute2
    state: present
    update_cache: true
    cache_valid_time: 3600

- name: Odczytaj istniejące usługi
  ansible.builtin.service_facts:

- name: Wymagaj systemowej usługi Docker
  ansible.builtin.assert:
    that:
      - "'docker.service' in ansible_facts.services"
    fail_msg: Nie znaleziono docker.service. Nie zastępuj istniejącej nietypowej instalacji bez prowadzącego.

- name: Zapewnij uruchomiony Docker i start po restarcie hosta
  ansible.builtin.systemd_service:
    name: docker
    enabled: true
    state: started
```

Sprawdzenie wersji programu jest odczytem. Rola wykorzystuje istniejącego
Dockera i zapewnia uruchomioną usługę bez wymuszenia jej restartu.
Gdy wykryje niekompletną instalację Docker CE/Moby, zatrzyma wykonanie
zamiast zastępować ją pakietem `docker.io`.

Pakiet `python3-requests` na hoście jest zależnością używanych modułów
kolekcji. Dodatkowe pakiety zapewniają certyfikaty i diagnostykę HTTP.

## 8. Napisz rolę weather_app

Teraz utwórz wartości domyślne roli:

### Plik: `CWICZENIA_TERRAFORM/cwiczenie04/ansible/roles/weather_app/defaults/main.yml`

```yaml
---
weather_image_reference: piotrskoska/python_pogoda@sha256:ac30d995f5ca10e4c5db5c44d526398c435270ba1194c5987642f7179a224638
weather_container_name: cw04-pogoda
weather_city: Warsaw
weather_dockerhub_username: ""
weather_dockerhub_token: ""
```

Następnie utwórz komplet zadań tej roli:

### Plik: `CWICZENIA_TERRAFORM/cwiczenie04/ansible/roles/weather_app/tasks/main.yml`

```yaml
---
- name: Sprawdź obecność dokładnego obrazu z digestem
  community.docker.docker_image_info:
    name: "{{ weather_image_reference }}"
  register: weather_image_info
  no_log: true

- name: Pobierz brakujący obraz bez nowych danych logowania
  community.docker.docker_image_pull:
    name: "{{ weather_image_reference }}"
    pull: not_present
  when:
    - weather_image_info.images | length == 0
    - weather_dockerhub_username | length == 0

- name: Pobierz brakujący obraz z odizolowanym logowaniem Docker Hub
  when:
    - not ansible_check_mode
    - weather_image_info.images | length == 0
    - weather_dockerhub_username | length > 0
  block:
    - name: Utwórz własny tymczasowy katalog konfiguracji Dockera
      ansible.builtin.tempfile:
        state: directory
        path: /root
        prefix: cw04-docker-auth-
      register: weather_docker_auth_directory

    - name: Ogranicz dostęp do własnego katalogu logowania
      ansible.builtin.file:
        path: "{{ weather_docker_auth_directory.path }}"
        state: directory
        owner: root
        group: root
        mode: '0700'

    - name: Utwórz pustą konfigurację bez odczytu cudzych danych logowania
      ansible.builtin.copy:
        dest: "{{ weather_docker_auth_directory.path }}/config.json"
        content: '{"auths":{}}'
        owner: root
        group: root
        mode: '0600'

    - name: Zaloguj do Docker Hub tylko we własnej konfiguracji
      community.docker.docker_login:
        registry_url: https://index.docker.io/v1/
        username: "{{ weather_dockerhub_username }}"
        password: "{{ weather_dockerhub_token }}"
        config_path: "{{ weather_docker_auth_directory.path }}/config.json"
      no_log: true
      diff: false

    - name: Pobierz dokładny obraz z tymczasowymi danymi logowania
      community.docker.docker_image_pull:
        name: "{{ weather_image_reference }}"
        pull: not_present
      environment:
        DOCKER_CONFIG: "{{ weather_docker_auth_directory.path }}"
      no_log: true
      diff: false

  always:
    - name: Usuń wyłącznie własny tymczasowy katalog logowania
      ansible.builtin.file:
        path: "{{ weather_docker_auth_directory.path }}"
        state: absent
      when:
        - weather_docker_auth_directory is defined
        - weather_docker_auth_directory.path is defined
        - weather_docker_auth_directory.path is match('^/root/cw04-docker-auth-[a-zA-Z0-9_]+$')
      no_log: true

- name: Uzgodnij uruchomiony kontener z kluczem API przekazanym podczas startu
  community.docker.docker_container:
    name: "{{ weather_container_name }}"
    image: "{{ weather_image_reference }}"
    pull: never
    state: started
    restart_policy: unless-stopped
    published_ports:
      - 127.0.0.1:18080:8080
    env:
      OPENWEATHER_API_KEY: "{{ openweather_api_key }}"
  no_log: true
  diff: false

- name: Poczekaj na gotowość aplikacji na lokalnym porcie
  ansible.builtin.uri:
    url: http://127.0.0.1:18080/healthz
    status_code: 200
    use_proxy: false
  register: weather_backend_health
  until: weather_backend_health.status | default(0) == 200
  retries: 20
  delay: 3
  when: not ansible_check_mode
```

Rola sprawdza lokalną obecność obrazu przypiętego digestem i pobiera go
przed uzgodnieniem kontenera. Ustawienie `pull: never` w zadaniu kontenera
korzysta z obrazu, którego dostępność została wcześniej potwierdzona.
Błąd pobrania zatrzyma wykonanie przed zmianą działającego kontenera.

`state: started` i `restart_policy: unless-stopped` utrzymują aplikację
po zakończeniu playbooka. Moduł rozpoznaje zmianę obrazu lub klucza API;
ponowne wykonanie z tą samą konfiguracją nie wymusza restartu kontenera.
Mapowanie `127.0.0.1:18080:8080` udostępnia backend lokalnie na hoście.

Zadania z kluczem i danymi logowania mają `no_log: true`, a zadanie
kontenera również `diff: false`. Zachowaj te ustawienia i nie dodawaj
debugowania zarejestrowanej konfiguracji kontenera.

## 9. Napisz rolę nginx_proxy

Teraz utwórz komplet zadań Nginxa:

### Plik: `CWICZENIA_TERRAFORM/cwiczenie04/ansible/roles/nginx_proxy/tasks/main.yml`

```yaml
---
- name: Odczytaj procesy nasłuchujące na porcie HTTP
  ansible.builtin.command:
    argv: [ss, -H, -ltnp, 'sport = :80']
  register: weather_http_listeners
  check_mode: false
  changed_when: false

- name: Nie zastępuj innego serwera HTTP na istniejącym agencie
  ansible.builtin.assert:
    that:
      - item is search('"nginx"')
    fail_msg: Port 80 zajmuje inny proces. Poproś prowadzącego o rozwiązanie konfliktu; playbook go nie zatrzymuje.
  loop: "{{ weather_http_listeners.stdout_lines }}"
  loop_control:
    label: Port HTTP 80

- name: Sprawdź istniejący Nginx bez zmiany jego konfiguracji
  ansible.builtin.command:
    argv: [nginx, -v]
  register: weather_nginx_cli
  check_mode: false
  changed_when: false
  failed_when: false

- name: Nie zastępuj niekompletnej istniejącej instalacji Nginxa
  ansible.builtin.assert:
    that:
      - >-
        not (['nginx', 'nginx-core', 'nginx-full', 'nginx-light', 'nginx-extras'] |
        intersect(ansible_facts.packages.keys() | list))
    fail_msg: Pakiet Nginxa istnieje, ale program nie działa. Poproś prowadzącego o naprawę.
  when: weather_nginx_cli.rc != 0

- name: Zainstaluj Nginx tylko wtedy, gdy go brakuje
  ansible.builtin.apt:
    name: nginx
    state: present
    update_cache: true
    cache_valid_time: 3600
  when: weather_nginx_cli.rc != 0

- name: Odczytaj istniejące usługi po sprawdzeniu Nginxa
  ansible.builtin.service_facts:

- name: Wymagaj systemowej usługi Nginx
  ansible.builtin.assert:
    that:
      - "'nginx.service' in ansible_facts.services"
    fail_msg: Nie znaleziono nginx.service. Uzgodnij nietypową instalację z prowadzącym zamiast ją zastępować.

- name: Sprawdź aktualną konfigurację Nginxa bez jej wyświetlania
  ansible.builtin.command:
    argv: [nginx, -T]
  register: weather_nginx_configuration
  check_mode: false
  changed_when: false
  no_log: true

- name: Rozpocznij sprawdzenie istniejących nazw hostów
  ansible.builtin.set_fact:
    weather_nginx_conflicting_sites: []

- name: Wykryj cudzy vhost z tym samym dokładnym IP
  ansible.builtin.set_fact:
    weather_nginx_conflicting_sites: "{{ weather_nginx_conflicting_sites + [item.0] }}"
  loop: >-
    {{ weather_nginx_configuration.stdout |
    regex_findall('(?ms)^# configuration file ([^\n]+):\n(.*?)(?=^# configuration file |\Z)') }}
  when:
    - item.0 not in ['/etc/nginx/sites-enabled/cw04-pogoda', '/etc/nginx/sites-available/cw04-pogoda']
    - >-
      ansible_host in (item.1 | regex_findall('(?m)(?:^|[;{}])\s*server_name\s+([^;]+);') |
      join(' ') | replace('"', '') | replace("'", '') | regex_findall('\\S+'))
  no_log: true

- name: Nie przejmuj istniejącego vhosta z IP tego agenta
  ansible.builtin.assert:
    that:
      - weather_nginx_conflicting_sites | length == 0
    fail_msg: "Istnieje vhost z tym samym IP: {{ weather_nginx_conflicting_sites | join(', ') }}. Uzgodnij zmianę z prowadzącym."

- name: Sprawdź własną ścieżkę włączanego vhosta
  ansible.builtin.stat:
    path: /etc/nginx/sites-enabled/cw04-pogoda
    follow: false
  register: weather_nginx_enabled_site

- name: Nie zastępuj innego pliku pod własną ścieżką vhosta
  ansible.builtin.assert:
    that:
      - >-
        not weather_nginx_enabled_site.stat.exists or
        (weather_nginx_enabled_site.stat.islnk | default(false) and
        weather_nginx_enabled_site.stat.lnk_source | default('') == '/etc/nginx/sites-available/cw04-pogoda')
    fail_msg: Ścieżka sites-enabled/cw04-pogoda już zawiera inny plik. Uzgodnij konflikt z prowadzącym.

- name: Zapisz wyłącznie własny vhost dla IP agenta
  ansible.builtin.template:
    src: cw04-pogoda.conf.j2
    dest: /etc/nginx/sites-available/cw04-pogoda
    owner: root
    group: root
    mode: '0644'
  notify:
    - Sprawdź składnię Nginxa przed przeładowaniem
    - Przeładuj konfigurację Nginxa

- name: Włącz własny vhost bez usuwania pozostałych stron
  ansible.builtin.file:
    src: /etc/nginx/sites-available/cw04-pogoda
    dest: /etc/nginx/sites-enabled/cw04-pogoda
    state: link
  notify:
    - Sprawdź składnię Nginxa przed przeładowaniem
    - Przeładuj konfigurację Nginxa

- name: Sprawdź składnię także przy ponownym uruchomieniu playbooka
  ansible.builtin.command:
    argv: [nginx, -t]
  check_mode: false
  changed_when: false

- name: Zapewnij uruchomiony Nginx i start po restarcie hosta
  ansible.builtin.systemd_service:
    name: nginx
    enabled: true
    state: started

- name: Zastosuj zmienioną konfigurację przed testem HTTP
  ansible.builtin.meta: flush_handlers

- name: Sprawdź HTTP przez własny vhost Nginxa
  ansible.builtin.uri:
    url: http://127.0.0.1/healthz
    headers:
      Host: "{{ ansible_host }}"
    status_code: 200
    use_proxy: false
  register: weather_proxy_health
  until: weather_proxy_health.status | default(0) == 200
  retries: 10
  delay: 2
  when: not ansible_check_mode
```

Teraz dodaj oba handlery w podanej kolejności:

### Plik: `CWICZENIA_TERRAFORM/cwiczenie04/ansible/roles/nginx_proxy/handlers/main.yml`

```yaml
---
- name: Sprawdź składnię Nginxa przed przeładowaniem
  ansible.builtin.command:
    argv: [nginx, -t]
  changed_when: false

- name: Przeładuj konfigurację Nginxa
  ansible.builtin.systemd_service:
    name: nginx
    state: reloaded
```

Teraz dodaj pełny template własnego vhosta:

### Plik: `CWICZENIA_TERRAFORM/cwiczenie04/ansible/roles/nginx_proxy/templates/cw04-pogoda.conf.j2`

```nginx
# Zarządzane przez rolę nginx_proxy ćwiczenia CW04.
# Dokładny IP wybiera aplikację; domenowe vhosty agenta pozostają osobne.
server {
    listen 80;
    server_name {{ ansible_host }};

    location / {
        proxy_pass http://127.0.0.1:18080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Vhost odpowiada pod dokładnym IP `ansible_host`, zachowując pozostałe
strony i domenowy panel agenta. Nie dodawaj `default_server` ani zadań
usuwających cudze strony. Jeżeli port `80` zajmuje inny serwer HTTP albo
istnieje vhost tego samego IP, uzgodnij konflikt z prowadzącym.

Handler sprawdza `nginx -t` przed przeładowaniem. `flush_handlers`
zastosuje zmianę przed testem HTTP. Dla zapytań do `127.0.0.1` nagłówek
`Host` wskazuje IP agenta i wybiera nowy vhost. Klucz API pozostaje
w konfiguracji uruchomionego kontenera, poza konfiguracją Nginxa.

## 10. Sprawdź zakres i połączenie bez wdrażania

Teraz, z katalogu `ansible`, wyświetl zakres:

```bash
ansible -i inventory.ini weather_agents --list-hosts
ansible-playbook -i inventory.ini site.yml --limit agent --extra-vars @vars.local.yml --list-hosts
```

Wynik ma zawierać tylko alias `agent`. Sprawdź w lokalnym inventory, że
jego IP jest adresem Twojej maszyny. Jeśli grupa obejmuje inne hosty,
popraw inventory przed dalszym wykonaniem.

Teraz wykonaj odczytową kontrolę połączenia przez Ansible:

```bash
ansible -i inventory.ini agent -m ansible.builtin.ping --private-key "$CW04_SSH_KEY"
```

Oczekuj `pong`. To moduł Ansible sprawdzający połączenie SSH i działający
Python na hoście, nie pakiet ICMP. Ta kontrola nie wdraża aplikacji.

## 11. Sprawdź składnię i opcjonalny plan zmian

Teraz sprawdź kompletny projekt:

```bash
ansible-playbook -i inventory.ini site.yml --syntax-check --extra-vars @vars.local.yml
```

Opcjonalnie obejrzyj przewidywane zmiany:

```bash
ansible-playbook -i inventory.ini site.yml --limit agent --extra-vars @vars.local.yml --private-key "$CW04_SSH_KEY" --check
```

To podgląd, a nie wdrożenie przez Ansible. Na pierwszym uruchomieniu brak
pakietów, bibliotek lub działającego Dockera może uniemożliwić sprawdzenie
późniejszych zadań w check mode. Polecenia odczytujące wersje programów
i konfigurację nadal się wykonują; testy HTTP i rzeczywistej pogody są
pomijane. Sama poprawna składnia ani wynik `--check` nie potwierdza
działającej aplikacji.

Zadania z sekretami ukrywają logi. Jeśli preflight odrzuci dane, popraw
lokalny plik zmiennych; nie wyłączaj `no_log` w celu pokazania klucza.

## 12. Wdróż aplikację przez Ansible na swoim hoście

Teraz wykonaj rzeczywiste wdrożenie **przez Ansible**, wyłącznie na aliasie
`agent` z Twojego inventory:

```bash
ansible-playbook -i inventory.ini site.yml --limit agent --extra-vars @vars.local.yml --private-key "$CW04_SSH_KEY"
```

Jeśli potrzebujesz hasła `sudo`, dodaj `-K`. Sprawdź recap: oczekuj
`failed=0` i `unreachable=0`. Playbook ma również potwierdzić formularz WWW
oraz dane `openweathermap` z prawdziwego wywołania API.

Pakiety zostaną uzupełnione tam, gdzie brakowało wymaganych składników.
Dotychczasowy agent i pozostałe aplikacje mają pozostać uruchomione.
Pomyślny test `/healthz` nie zastępuje testu prawdziwej pogody.

## 13. Sprawdź WWW i rzeczywistą pogodę z kontrolera

Teraz utwórz lub sprawdź pełną treść testu w katalogu `tests`, który
przygotowałeś w kroku 3:

### Plik: `CWICZENIA_TERRAFORM/cwiczenie04/tests/smoke_test.py`

```python
#!/usr/bin/env python3
"""Test działającego kontenera: WWW, zasoby, health i prawdziwa pogoda z API.

Nie przyjmuje klucza ani danych przykładowych. Klucz jest wyłącznie w kontenerze.
Każdy błąd dostawcy, w tym zły klucz API, kończy test niepowodzeniem.
"""

from __future__ import annotations

import argparse
import json
import math
import ssl
import sys
import urllib.error
import urllib.parse
import urllib.request


def verify(base_url: str, city: str, ca_file: str | None = None) -> dict:
    context = ssl.create_default_context(cafile=ca_file)
    base = base_url.rstrip("/")
    parsed = urllib.parse.urlsplit(base)
    if parsed.scheme not in ("http", "https") or not parsed.hostname or parsed.username or parsed.password:
        raise ValueError("Podaj poprawny adres HTTP/HTTPS bez danych logowania.")

    def get(path: str, as_json: bool = False):
        request = urllib.request.Request(base + path, headers={"Accept": "application/json" if as_json else "*/*"})
        with urllib.request.urlopen(request, context=context, timeout=30) as response:
            if response.status != 200:
                raise ValueError("Nieoczekiwany status HTTP aplikacji.")
            content = response.read().decode("utf-8")
        return json.loads(content) if as_json else content

    if get("/healthz", True).get("status") != "ok":
        raise ValueError("Kontrola healthz nie potwierdziła gotowości aplikacji.")
    if 'id="weather-form"' not in get("/"):
        raise ValueError("Interfejs WWW nie zawiera formularza miasta.")
    for asset in ("/static/styles.css", "/static/app.js"):
        if not get(asset).strip():
            raise ValueError("Brakuje zasobu interfejsu WWW.")
    schema = get("/openapi.json", True)
    parameters = schema["paths"]["/api/weather"]["get"]["parameters"]
    if {parameter["name"] for parameter in parameters if parameter["in"] == "query"} != {"city"}:
        raise ValueError("API ma przyjmować wyłącznie miasto, bez klucza w URL.")

    weather = get("/api/weather?" + urllib.parse.urlencode({"city": city}), True)
    if weather.get("source") != "openweathermap" or weather.get("units") != "metric":
        raise ValueError("Brak potwierdzonej odpowiedzi pogodowej OpenWeatherMap.")
    if not isinstance(weather.get("city"), str) or not weather["city"].strip():
        raise ValueError("Odpowiedź pogodowa nie zawiera miasta.")
    for name in ("temperature", "feels_like", "humidity", "pressure", "wind_speed"):
        value = weather.get(name)
        if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value):
            raise ValueError("Odpowiedź pogodowa nie zawiera kompletnych pomiarów.")
    if not isinstance(weather.get("observed_at"), int) or weather["observed_at"] <= 0:
        raise ValueError("Brakuje czasu pomiaru pogody.")
    return weather


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-url", required=True)
    parser.add_argument("--city", default="Warsaw")
    parser.add_argument("--ca-file", help="Zaufany certyfikat CA dla opcjonalnego HTTPS")
    args = parser.parse_args()
    try:
        weather = verify(args.base_url, args.city, args.ca_file)
    except urllib.error.HTTPError as error:
        print(f"TEST NIEUDANY: aplikacja zwróciła HTTP {error.code}. Sprawdź konfigurację i dostępność dostawcy.", file=sys.stderr)
        return 1
    except (OSError, ValueError, KeyError, TypeError, AttributeError, ssl.SSLError, urllib.error.URLError):
        print("TEST NIEUDANY: niepoprawna odpowiedź, brak WWW/API albo błąd połączenia.", file=sys.stderr)
        return 1
    print(f"OPENWEATHER_OK: {weather['city']}, {weather['temperature']} °C; WWW i API działają.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

Teraz, nadal z katalogu `ansible`, wykonaj:

```bash
curl --fail --silent --show-error http://TWOJ_PUBLICZNY_IP/healthz
python3 ../tests/smoke_test.py --base-url http://TWOJ_PUBLICZNY_IP --city Warsaw
```

Zastąp placeholder IP z inventory. Test potwierdza formularz, zasoby,
schemat API i rzeczywiste dane OpenWeatherMap. Nie przekazuj klucza
w URL ani w argumentach testu. Oczekuj komunikatu `OPENWEATHER_OK`.

Teraz otwórz `http://TWOJ_PUBLICZNY_IP/` w przeglądarce i wpisz miasto.
Użytkownik podaje tylko miasto. Błąd klucza lub dostawcy ma być błędem
testu, bez zastępowania odpowiedzi przykładową pogodą.
Dostęp HTTP wymaga dopuszczenia portu `80` w regułach hosta i sieci.

## 14. Sprawdź idempotencję i zachowaj właściwy zakres

Teraz uruchom to samo polecenie drugi raz, bez zmiany zmiennych:

```bash
ansible-playbook -i inventory.ini site.yml --limit agent --extra-vars @vars.local.yml --private-key "$CW04_SSH_KEY"
```

Oczekuj `changed=0` oraz działającego WWW/API. Jeżeli zadania nadal
wprowadzają zmiany, sprawdź przyczynę. Nie wymuszaj `restart`, `recreate`
ani pakietów `latest` przy każdym wykonaniu. Nie maskuj rzeczywistych
zmian jako odczytów.

Teraz sprawdź ochronę lokalnych plików:

```bash
git check-ignore inventory.ini vars.local.yml
git status --short
```

Pierwsze polecenie ma wypisać oba lokalne pliki. Publiczny projekt,
`tests/smoke_test.py` i pliki `.example` mają być widoczne dla Gita.
Nie publikuj rzeczywistego klucza API ani prywatnego klucza SSH.

To istniejąca maszyna z agentem. Zachowaj host, Dockera, Nginxa, pozostałe
kontenery i vhosty. Własną aplikację pozostaw na przydzielonym hoście
zgodnie z ustaleniami prowadzącego.

Ćwiczenie jest ukończone, gdy role przez Ansible przygotowują brakujące
składniki, wdrażają kontener, zachowują pozostałe usługi, a Nginx serwuje
WWW/API pod IP uczestnika i kolejne wykonanie nie wprowadza zmian.
Lokalne sprawdzenie plików nie jest dowodem wykonania na hoście.

Dokumentacja:
[role Ansible](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_roles.html),
[moduł ping](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/ping_module.html),
[moduł docker_image_pull](https://docs.ansible.com/projects/ansible/latest/collections/community/docker/docker_image_pull_module.html)
oraz [opcje ansible-playbook](https://docs.ansible.com/projects/ansible/latest/cli/ansible-playbook.html).
