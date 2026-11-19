# Ćwiczenie 16A — kontrola bezpieczeństwa przed publikacją i deployem

## 1. Najpierw ustaw wymagane vars i secrets

W swoim repozytorium GitHub otwórz **Settings → Secrets and variables → Actions**.
W zakładce **Variables** dodaj przez **New repository variable**:

| Nazwa | Wartość |
| --- | --- |
| `DOCKERHUB_USERNAME` | Twój login Docker Hub; przykład: `piotrskoska` |
| `DOCKER_IMAGE_NAME` | `python_pogoda` |

W zakładce **Secrets** dodaj przez **New repository secret**:

| Nazwa | Jaką wartość wpisać |
| --- | --- |
| `DOCKERHUB_TOKEN` | Twój token Docker Hub z prawem publikowania i pobierania obrazu |
| `OPENWEATHER_API_KEY` | Twój rzeczywisty, aktywny klucz OpenWeatherMap |

Przygotuj repozytorium obrazu `python_pogoda` na swoim koncie Docker Hub.
Token i klucz API wklej wyłącznie do GitHub Secrets, nie do YAML, Dockerfile,
inputs, outputs ani artefaktów.

Skanery nie wymagają dodatkowego tokenu SaaS ani GitHub Advanced Security.
Automatyczny `GITHUB_TOKEN` dostarcza GitHub Actions; w tym workflow wystarcza
`permissions: contents: read`. Raporty są artefaktami Actions, bez obowiązku
publikowania SARIF lub nadawania `security-events: write`.

## 2. Sprawdź gotową aplikację i przygotuj runner

Aplikacja wraz z Dockerfile, Nginxem i testami znajduje się w
[pogoda_python_flusk](./pogoda_python_flusk/). Pracujesz nad pipeline;
nie musisz pisać aplikacji ani zmieniać jej istniejących plików.

Kontener udostępnia WWW pod `/`, gotowość pod `/healthz` oraz API
`/api/weather?city=Warsaw`. Klucz pogodowy jest potrzebny podczas działania
kontenera, a nie podczas budowania obrazu.

Przygotuj dostępny dla repozytorium runner Linux z etykietami `self-hosted`
i `linux`. Konto runnera musi mieć dostęp do Dockera, Python 3 oraz `curl`.
Host musi łączyć się z Docker Hub i OpenWeatherMap. Dla każdego uczestnika
na wspólnym hoście wybierz inny wolny port HTTP.

Wszystkie kontrole i publikacja działają na runnerach GitHuba. Własny runner
służy tylko do trwałego deploya; nie potrzebuje dodatkowej własnej etykiety
ani lokalnej instalacji Trivy, Bandita lub `jq`.

## 3. Przygotuj workflow i graf zależności

Pracuj w pliku
[.github/workflows/16A-pogoda-security.yaml](../../.github/workflows/16A-pogoda-security.yaml).
Włącz wyłącznie ręczne zdarzenie `workflow_dispatch`.

Zdefiniuj osiem jobów:

```text
                 ┌─ source-security ─┐
prepare ─────────┤                   ├─ build ─ test ─ image-security ─ publish ─ deploy
                 └─ python-security ─┘
```

| Job | Zadanie |
| --- | --- |
| `prepare` | Walidacja inputs, przygotowanie nazw i outputs |
| `source-security` | Trivy: zależności, konfiguracja i sekrety w plikach aplikacji |
| `python-security` | Bandit: analiza bezpieczeństwa kodu Python |
| `build` | Jednorazowe zbudowanie obrazu po sukcesie kontroli źródeł |
| `test` | Test utwardzonego kontenera z prawdziwym kluczem pogodowym |
| `image-security` | Trivy: podatności i sekrety w dokładnie zbudowanym obrazie |
| `publish` | Publikacja tego samego obrazu po sukcesie wszystkich kontroli |
| `deploy` | Uruchomienie opublikowanego digestu na self-hosted i ponowne testy |

Kontrole źródeł wykonują się równolegle. Nieudana kontrola zatrzymuje dalszą
część pipeline; publikacja ani deploy nie mogą omijać tego wyniku.
W krokach checkout ustaw `persist-credentials: false`, ponieważ dalsze
polecenia nie potrzebują zapisanych poświadczeń Git.

## 4. Dodaj inputs i outputs konfiguracji

Formularz **Run workflow** ma przyjmować:

| Input | Typ | Wartość lub ograniczenie |
| --- | --- | --- |
| `first_name` | `string` | Wymagane imię, do 30 znaków; litery ASCII, opcjonalne człony połączone myślnikami |
| `last_name` | `string` | Wymagane nazwisko, do 30 znaków; takie same ograniczenia |
| `city` | `string` | Domyślnie `Warsaw`, 1–100 znaków, bez znaków sterujących |
| `app_port` | `number` | Domyślnie `18816`; liczba całkowita od `1024` do `65535` |

Wpisz np. `Jan` i `Kowalski`; slug ma wynosić `jan-kowalski`. Surowe inputs
przekaż do kroku przez `env`, a następnie zwaliduj. Nie wklejaj ich
bezpośrednio do poleceń powłoki.

Job `prepare` ma wyliczyć konfigurację i wystawić job outputs potrzebne
następnym jobom. W szczególności:

- tag uczestnika: `jan-kowalski-<pełny GITHUB_SHA>`;
- drugi tag: sam pełny `GITHUB_SHA`;
- lokalny obraz CI: `cw16a-weather:ci-<pełny GITHUB_SHA>`;
- stałą nazwę kontenera: `cw16a-<REPO_ID>-jan-kowalski-prod`;
- zwalidowane miasto i port.

Output kroku zapisz do `$GITHUB_OUTPUT`, wystaw przez `jobs.<job>.outputs`,
a w odbiorcy odczytaj przez `needs.<job>.outputs`. Job korzystający
z konfiguracji musi jawnie uwzględniać `prepare` w `needs`.

## 5. Skanuj pliki aplikacji przez oficjalną akcję Trivy

W jobie `source-security` wykonaj checkout i przeskanuj tylko katalog
`CWICZENIA/16A-Cwiczenia-pipeline-gha/pogoda_python_flusk`.
Nie ustawiaj skanowania całego repozytorium: pozostałe ćwiczenia nie należą
do tej aplikacji.

Przed skanowaniem sprawdź obecność `app.py`, `requirements.txt` i `Dockerfile`
w kroku z `id: scan_scope`.

Użyj gotowej akcji przypiętej do konkretnego commita:

```yaml
uses: aquasecurity/trivy-action@ed142fd0673e97e23eac54620cfb913e5ce36c25 # v0.36.0
```

W pierwszym skanowaniu ustaw:

| Opcja | Wartość |
| --- | --- |
| `version` | `v0.70.0` |
| `scan-type` | `fs` |
| `scan-ref` | Katalog aplikacji tego ćwiczenia |
| `scanners` | `vuln,misconfig` |
| `severity` | `HIGH,CRITICAL` |
| `ignore-unfixed` | `false` |
| `exit-code` | `1` |
| `format` | `json` |

Zapisz wynik jako `trivy-source-dependencies.json` przez `output`. Kontrola ma zatrzymać
job przy podatnościach lub błędach konfiguracji o poziomie HIGH/CRITICAL.
`ignore-unfixed: false` obejmuje także znane podatności bez dostępnej poprawki.

## 6. Dodaj oddzielne skanowanie sekretów

Drugi krok Trivy w tym samym jobie ma skanować ten sam katalog, ale używać
`scanners: secret`. Ustaw wszystkie poziomy:

```yaml
severity: UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL
exit-code: '1'
```

To osobna kontrola, ponieważ ograniczenie wspólnego skanowania do
HIGH/CRITICAL przepuściłoby wykryty sekret sklasyfikowany np. jako MEDIUM.

Dla drugiego skanowania ustaw
`if: ${{ !cancelled() && steps.scan_scope.outcome == 'success' }}`.
Raport powstanie także po znaleziskach pierwszego skanera, ale dopiero po
poprawnym sprawdzeniu katalogu. Nie zmienia to wyniku pierwszego kroku ani
całego joba na sukces.

Wynik sekretów zapisz jako `trivy-source-secrets.json`. Na końcu, przez
`actions/upload-artifact@v4` z `if: always()`, opublikuj
raporty jako `source-trivy-reports`, z retencją pięciu dni. Raport musi być
dostępny również wtedy, gdy skaner wykryje problem.

Jeśli oba skanowania zakończyły się sukcesem, sprawdź wcześniej każdy raport:
plik musi być niepusty, zawierać poprawny JSON i `SchemaVersion: 2`.
Brak jednego raportu nie może oznaczać zaliczenia kontroli.

Nie dodawaj `continue-on-error`, `exit-code: 0` ani `|| true` do kontroli
bezpieczeństwa. Nie rozwiązuj problemu przez wyłączenie skanera lub ukrycie
podatności plikiem wyjątków.

## 7. Sprawdź kod Python przez gotową akcję Bandit

W równoległym jobie `python-security` wykonaj checkout i użyj:

```yaml
uses: jpetrucciani/bandit-check@0dd659afc3190589090165b7295d17bbf5b67db4
with:
  path: CWICZENIA/16A-Cwiczenia-pipeline-gha/pogoda_python_flusk
  bandit_flags: '-ll -i -f json -o bandit-report.json'
```

Ta wersja akcji korzysta z Bandita `1.9.4`. Flaga `-ll` ustawia minimalną
wagę problemu na MEDIUM, a `-i` dopuszcza ustalenia z pewnością LOW i wyższą.
Wynik MEDIUM lub HIGH spełniający ten warunek ma zatrzymać job.

Bandit analizuje konstrukcje kodu Python, a Trivy sprawdza m.in. zależności
i konfigurację. Jedno narzędzie nie zastępuje drugiego.

Dodaj kontrolę raportu przez `jq`: tablica `errors` musi być pusta,
a `metrics._totals.loc` większe od zera. Dzięki temu pominięte pliki,
błąd parsowania lub brak faktycznie przeskanowanego kodu nie dadzą pozornego
sukcesu. Brak albo niepoprawny JSON także musi zakończyć się błędem.

Wyślij `bandit-report.json` jako artefakt `python-bandit-report`, z
`if: always()` i retencją pięciu dni. Nie ignoruj kodu zakończenia Bandita
i nie stosuj `--exit-zero`.

## 8. Zbuduj obraz tylko po udanych kontrolach źródeł

Job `build` ma zależeć od `prepare`, `source-security` i `python-security`.

1. Pobierz kod repozytorium i przygotuj Buildx.
2. Zbuduj aplikację bez klucza OpenWeatherMap i bez tokenu rejestru.
3. Odczytaj ID obrazu przez `docker image inspect` i wystaw job output
   `image_id`.
4. Sprawdź, że konfiguracja obrazu nie zawiera `OPENWEATHER_API_KEY=`.
5. Zapisz obraz jako `image.tar`.
6. Wyślij artefakt `cw16a-weather-image`, z retencją jednego dnia
   i `overwrite: true`.

W kolejnych jobach korzystaj z tego samego artefaktu. Nie buduj obrazu drugi
raz podczas skanowania, publikacji ani deploya. ID obrazu jest outputem
tekstowym, a jego zawartość przekazujesz artefaktem.

## 9. Uruchom test z ograniczonymi uprawnieniami kontenera

W jobie `test` pobierz `image.tar`, wykonaj `docker load` i sprawdź zgodność
ID z `needs.build.outputs.image_id`. Kontener testowy uruchom z rzeczywistym
sekretem pogodowym i następującymi ograniczeniami:

```text
--cap-drop ALL
--security-opt no-new-privileges:true
--read-only
--tmpfs /tmp:rw,noexec,nosuid,size=64m
```

Gotowy obraz deklaruje `USER 10001:10001`. Nie nadpisuj tego ustawienia
przez `--user root`. Aplikacja i Nginx zapisują pliki robocze pod `/tmp`,
więc mogą działać z systemem plików obrazu dostępnym tylko do odczytu.

Po uruchomieniu sprawdź:

1. `docker exec <kontener> id -u` nie zwraca `0`.
2. `docker inspect` potwierdza `ReadonlyRootfs`, usunięcie wszystkich
   capabilities oraz `no-new-privileges`.
3. `/healthz` odpowiada po ponowieniach `curl`.
4. Istniejący [tests/smoke_test.py](./pogoda_python_flusk/tests/smoke_test.py)
   sprawdza WWW, zasoby statyczne i API z prawdziwą pogodą dla wybranego miasta.

Kontener testowy usuń w kroku z `if: always()`. Udane skanowanie nie zastępuje
testu działania aplikacji z tymi ograniczeniami.

## 10. Przeskanuj dokładnie przetestowany obraz

Job `image-security` uruchamia się po udanym `test`. Pobierz artefakt,
załaduj obraz i ponownie sprawdź jego ID względem outputu joba `build`.

Użyj tej samej przypiętej akcji Trivy i wersji narzędzia, ale ustaw
skanowanie obrazu z archiwum `input: image.tar`. Nie skanuj innego tagu
z Docker Hub, który mógł już wskazywać na odmienny obraz.

Wykonaj dwie kontrole:

| Kontrola | Parametry bramki |
| --- | --- |
| Podatności pakietów systemowych i bibliotek | `scanners: vuln`, `vuln-type: os,library`, HIGH/CRITICAL, `ignore-unfixed: false`, `exit-code: 1` |
| Sekrety w obrazie | `scanners: secret`, wszystkie poziomy ważności, `exit-code: 1` |

Zapisz wyniki odpowiednio jako `trivy-image-vulnerabilities.json` oraz
`trivy-image-secrets.json`. Raporty wyślij jako `image-trivy-reports`, z retencją pięciu dni oraz
`if: always()`. Tak jak w źródłach, drugie skanowanie może wykonać się po
błędzie pierwszego; publikacja pozostaje zablokowana.

Krok porównujący ID archiwum z obrazem `build` ma `id: verified_image`.
Skan sekretów wymaga jego sukcesu przez
`if: ${{ !cancelled() && steps.verified_image.outcome == 'success' }}`.
Po udanych skanach sprawdź obecność i poprawność obu raportów w kroku
`id: security_gate`, a następnie zapisz sprawdzone ID jako output `image_id`.
Wystaw je jako job output `scanned_image_id` przez
`steps.security_gate.outputs.image_id`.

## 11. Uzależnij publikację od wszystkich kontroli

Job `publish` musi wymagać sukcesu testu i obu kontroli źródeł oraz kontroli
obrazu. Dodaj też bezpośrednie zależności od jobów, których outputs odczytuje.
Nie uruchamiaj publikacji przez `always()` po nieudanym skanowaniu.

Załaduj ten sam obraz z artefaktu i porównaj jego ID z outputem `build`
oraz `needs.image-security.outputs.scanned_image_id`. Wszystkie trzy
identyfikatory muszą być zgodne przed pierwszym `docker push`.
Zaloguj się do Docker Hub przez sekret tokenu i opublikuj dwa tagi:

```text
<DOCKERHUB_USERNAME>/python_pogoda:jan-kowalski-<pełny GITHUB_SHA>
<DOCKERHUB_USERNAME>/python_pogoda:<pełny GITHUB_SHA>
```

Zapisz digest udanej publikacji jako job output `image_digest`, wyprowadzony
z `steps.release.outputs.image_digest`. W deployu odczytaj
`needs.publish.outputs.image_digest`. Przekazuj sam `sha256:...`;
nazwę repozytorium składaj z jawnych `vars`.

## 12. Wdróż obraz na self-hosted z tymi samymi ograniczeniami

Job `deploy` ma używać `runs-on: [self-hosted, linux]` i zależeć od sukcesu
publikacji. Ustaw współbieżność według docelowej nazwy kontenera oraz
`cancel-in-progress: false`.

1. Utwórz prywatny, tymczasowy `DOCKER_CONFIG` i zaloguj się do Docker Hub.
2. Pobierz `<login>/<obraz>@<digest_z_publish>` przed usuwaniem starego
   kontenera. Nie wdrażaj zmiennego tagu `latest`.
3. Znajdź dokładnie `cw16a-<REPO_ID>-<student_slug>-prod`, uwzględniając
   zatrzymane kontenery. Usuń tylko ten kontener, jeśli istnieje.
4. Uruchom nowy kontener z `--restart unless-stopped`, mapowaniem
   `<app_port>:8080` i wszystkimi ograniczeniami z kroku 9.
5. Klucz OpenWeatherMap dostarcz wyłącznie podczas `docker run -e`.
6. Sprawdź niezerowe UID, ustawienia bezpieczeństwa, stan działania,
   `/healthz` oraz smoke test WWW i rzeczywistego API.
7. Zapisz wynik oraz adres w podsumowaniu workflow.

Końcowy krok z `if: always()` wylogowuje Docker Hub i usuwa wyłącznie
tymczasowe dane logowania tego joba. Kontener docelowy pozostaje na hoście
także przy błędzie testu, aby umożliwić diagnostykę. Nie ma automatycznego
rollbacku.

Po udanym uruchomieniu otwórz:

```text
http://<adres-hosta-self-hosted>:18816/
http://<adres-hosta-self-hosted>:18816/api/weather?city=Warsaw
```

Zastąp port wartością inputu. Host i reguły sieciowe muszą umożliwiać ten
dostęp; adres `127.0.0.1` widoczny w testach pipeline jest lokalny dla runnera.

## 13. Uruchom workflow i odczytaj raporty

1. Udostępnij workflow na GitHubie, także na domyślnej gałęzi repozytorium,
   aby można go było uruchomić z interfejsu Actions.
2. Otwórz **Actions**, wybierz workflow 16A i kliknij **Run workflow**.
3. Podaj imię i nazwisko bez polskich znaków, miasto oraz własny wolny port.
4. Obserwuj, czy nieudana kontrola zatrzymuje zależne joby.
5. W podsumowaniu przebiegu, w sekcji **Artifacts**, pobierz raporty:

| Artefakt | Co zawiera |
| --- | --- |
| `source-trivy-reports` | Wyniki kontroli zależności, konfiguracji i sekretów w źródłach aplikacji |
| `python-bandit-report` | Analiza kodu Python oraz informacje o faktycznie przeskanowanych plikach |
| `image-trivy-reports` | Wyniki podatności i sekretów w zbudowanym obrazie |

To raporty Actions, nie wpisy wymagające zakładki **Security → Code scanning**.
Jeśli wcześniejszy etap zatrzymał pipeline, raport późniejszego joba nie
powstanie. Błąd uruchomienia skanera lub pobrania bazy także jest błędem joba,
a nie potwierdzeniem braku problemów.

## 14. Popraw wykryte problemy i powtórz przebieg

Odczytaj w JSON identyfikator podatności lub reguły, pakiet, wykrytą wersję,
lokalizację problemu i dostępną wersję poprawioną. Dla Bandita sprawdź
`test_id`, `filename`, `line_number`, `issue_severity` oraz `issue_confidence`.

Napraw przyczynę: zaktualizuj właściwą zależność lub obraz bazowy, popraw
konfigurację albo usuń niebezpieczny fragment kodu. Jeśli prawdziwy sekret
znalazł się w pliku, usuń go i zastąp ujawnione dane nowym sekretem w GitHubie.
Nie wklejaj wartości wykrytych sekretów do logów ani zgłoszeń. Trivy domyślnie
maskuje ich wartości, ale raporty nadal traktuj jako materiały projektu.

Ponów pełny pipeline po poprawkach. Baza CVE jest aktualizowana, dlatego
dzisiejszy sukces nie gwarantuje identycznego wyniku następnego uruchomienia.
Pierwszy rzeczywisty przebieg może wykryć HIGH/CRITICAL również w gotowym
obrazie bazowym i zatrzymać publikację. Nie obniżaj progów ani nie wyłączaj
kontroli tylko po to, aby uzyskać zielony wynik.

Sukces oznacza spełnienie opisanych reguł dla faktycznie sprawdzonego zakresu
i użytej bazy. Nie jest gwarancją wykrycia wszystkich możliwych zagrożeń.

## 15. Sprawdź działanie blokady przed wdrożeniem

Opcjonalnie wykonaj kontrolowany eksperyment na osobnej gałęzi:

1. W ćwiczeniowej kopii Dockerfile zmień `USER 10001:10001` na `USER root`.
2. Uruchom workflow dla tej gałęzi z tymi samymi danymi uczestnika.
3. Potwierdź, że problem zostaje wykryty przed publikacją i deployem.
   Dotychczasowy kontener na self-hosted powinien pozostać uruchomiony.
4. Wycofaj demonstracyjną zmianę i ponów sprawdzenie.

Nie przeprowadzaj demonstracji przez dodawanie prawdziwych tokenów do plików.
Zadanie jest ukończone, kiedy wszystkie kontrole rzeczywiście wykonują swoją
pracę, raporty są dostępne, błędy blokują publikację i deploy, a utwardzony
kontener przechodzi test prawdziwego WWW/API.

Dokumentacja:
[oficjalna akcja Trivy](https://github.com/aquasecurity/trivy-action),
[skanowanie sekretów Trivy](https://trivy.dev/docs/latest/scanner/secret/),
[akcja Bandit](https://github.com/jpetrucciani/bandit-check),
[opcje Bandita](https://bandit.readthedocs.io/en/latest/man/bandit.html)
oraz [parametry uruchamiania kontenerów Docker](https://docs.docker.com/engine/containers/run/).
