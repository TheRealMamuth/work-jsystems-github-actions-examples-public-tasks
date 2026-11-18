# Ćwiczenie 08 — Zmienne w workflow pogodowego API

## Cel ćwiczenia

Przebuduj workflow [06-06c-app-pogoda.yaml](../../.github/workflows/06-06c-app-pogoda.yaml),
aby konfigurację budowania, testowania i wdrażania aplikacji można było zmieniać
przez **GitHub Actions Variables**, bez edycji YAML przy każdej zmianie wartości.

Wykorzystaj istniejącą aplikację `CWICZENIA/06-context/pogoda_python_flusk`.
Zachowaj cztery joby: `build` → `test` → `build-and-push` → `deploy`.
Ostatni job nadal ma uruchamiać kontener na runnerze self-hosted i sprawdzać
wdrożony endpoint `/weather` przez `curl`.

Rezultatem ćwiczenia ma być własny workflow
`.github/workflows/08-04-zmienne.yaml`. Poniższe fragmenty są
wskazówkami do wykonania zadania, a nie kompletnym rozwiązaniem.

## 1. Przygotuj kopię workflow

1. Skopiuj `.github/workflows/06-06c-app-pogoda.yaml` do
   `.github/workflows/08-04-zmienne.yaml`.
2. Nadaj mu nazwę `08-04 Pogoda API — Variables`.
3. Zachowaj wyzwalacze `push`, `pull_request` i `workflow_dispatch` z pliku bazowego.
4. Pozostaw `ubuntu-latest` dla budowania i testów oraz `[self-hosted, linux]`
   dla `deploy`. Runner wdrożeniowy musi mieć Docker i `curl` oraz dostęp do Docker Hub
   i dostawcy pogody. Jeśli dostępnych jest kilka takich serwerów, dodaj etykietę
   wskazującą konkretny serwer wdrożeniowy.
5. Wykorzystaj dotychczasowy Dockerfile i kod aplikacji.

## 2. Dodaj zmienne w ustawieniach repozytorium

Otwórz **Settings → Secrets and variables → Actions → Variables**.
Przyciskiem **New repository variable** utwórz poniższe zmienne:

| Repository variable | Wartość początkowa | Zastosowanie |
| --- | --- | --- |
| `WORKDIR` | `./CWICZENIA/06-context/pogoda_python_flusk` | Kontekst budowania obrazu |
| `DOCKERHUB_USERNAME` | `TWOJ_LOGIN_DOCKERHUB` — zastąp swoim loginem | Logowanie i prefiks nazwy obrazu |
| `DOCKER_IMAGE_NAME` | `python_pogoda` | Nazwa repozytorium obrazu na Docker Hub |
| `DOCKERHUB_TAG` | `cw08` | Tag obrazu dla tego ćwiczenia |
| `DOCKER_PORT_EXTERNAL` | `18008` | Port aplikacji na hoście wdrożeniowym |
| `DEPLOY_CONTAINER_NAME` | `pogoda_api_variables_deploy` | Nazwa kontenera wdrożeniowego |
| `WEATHER_CITY` | `Warsaw` | Miasto używane w testach `/weather` |
| `DEPLOY_BRANCH` | `feature/06-pogoda-api` | Gałąź dopuszczona do publikacji i wdrożenia |

Komplet wartości początkowych do ustawienia w zakładce **Variables**:

```text
WORKDIR=./CWICZENIA/06-context/pogoda_python_flusk
DOCKERHUB_USERNAME=TWOJ_LOGIN_DOCKERHUB
DOCKER_IMAGE_NAME=python_pogoda
DOCKERHUB_TAG=cw08
DOCKER_PORT_EXTERNAL=18008
DEPLOY_CONTAINER_NAME=pogoda_api_variables_deploy
WEATHER_CITY=Warsaw
DEPLOY_BRANCH=feature/06-pogoda-api
```

Każdą parę dodaj jako osobną **Repository variable**: nazwę wpisz w **Name**,
a tekst po `=` w **Value**, bez dodatkowych cudzysłowów. `TWOJ_LOGIN_DOCKERHUB`
jest miejscem na Twój rzeczywisty login, używany również w ćwiczeniu 06.
Te same wartości podano w komentarzach przy `env` w
[08-04-zmienne.yaml](../../.github/workflows/08-04-zmienne.yaml).
Komentarze w YAML są instrukcją konfiguracji; same nie ustawiają `vars` na GitHub.

Nie twórz Repository variables o nazwach `TEST_IMAGE`, `HUB_IMAGE_BASE`,
`API_BASE_URL`, `IMAGE_DIGEST` ani `CONFIG_SCOPE` — te wartości ustawia workflow.

Użyj loginu i repozytorium Docker Hub, do którego masz prawo publikacji.
Port `18008` musi być wolny na docelowym hoście. Osobny port i nazwa kontenera
pozwalają zachować aplikację z ćwiczenia 06 uruchomioną obok nowej wersji.

### Dane poufne — Repository secrets

Otwórz **Settings → Secrets and variables → Actions → Secrets**.
Dodaj lub zachowaj poniższe sekrety:

| Repository secret | Co wpisać jako wartość | Odczyt w workflow |
| --- | --- | --- |
| `DOCKERHUB_TOKEN` | Twój token dostępu Docker Hub z prawem publikacji obrazu | `${{ secrets.DOCKERHUB_TOKEN }}` |
| `OPENWEATHER_API_KEY` | Twój klucz API OpenWeatherMap | `${{ secrets.OPENWEATHER_API_KEY }}` |

Wartości tokenu i klucza wpisz wyłącznie w ustawieniach **Secrets**.
Nie umieszczaj ich w Repository variables, plikach YAML/Markdown ani logach.
Workflow przekazuje token akcji logowania, a klucz pogody środowisku kontenera.

`DOCKERHUB_USERNAME` to nazwa konta, a nie hasło ani token. Pozostaje w `vars`;
do uwierzytelniania służy osobny sekret `DOCKERHUB_TOKEN`.

### Rozróżnij trzy mechanizmy

| Mechanizm | Do czego służy w ćwiczeniu | Przykład odczytu |
| --- | --- | --- |
| `vars` | Konfiguracja zapisana w ustawieniach repozytorium | `${{ vars.WEATHER_CITY }}` |
| `env` | Zmienne środowiskowe workflow, joba lub kroku | `${{ env.WEATHER_CITY }}` w YAML, `$WEATHER_CITY` w Bashu |
| `secrets` | Token Docker Hub i klucz API pogody | `${{ secrets.OPENWEATHER_API_KEY }}` |

Wartości `vars` nie pojawiają się automatycznie jako zmienne powłoki.
Przekaż je przez `env`, aby odczytywać je w Bashu. Opis tych mechanizmów znajdziesz
w [dokumentacji zmiennych GitHub Actions](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-variables).

## 3. Zastąp stałe wartości odczytami z `vars`

1. W głównym bloku `env` zdefiniuj `WORKDIR`, `DOCKERHUB_TAG`,
   `DOCKER_PORT_EXTERNAL`, `DEPLOY_CONTAINER_NAME` i `WEATHER_CITY`,
   przypisując im wartości odpowiednich Repository variables.
2. Złóż `TEST_IMAGE` oraz `HUB_IMAGE_BASE` z `vars.DOCKERHUB_USERNAME`
   i `vars.DOCKER_IMAGE_NAME`. Obie nazwy mają wskazywać ten sam obraz.
3. W obu krokach logowania do Docker Hub zamień źródło pola `username`
   na `vars.DOCKERHUB_USERNAME`. Pole `password` nadal pobieraj z sekretu
   `DOCKERHUB_TOKEN`.
4. Zastąp stałe miasto `Warsaw` zmienną `WEATHER_CITY` w jobach `test` i `deploy`.
   Do wywołania `/weather` użyj `curl --get --data-urlencode "city=$WEATHER_CITY"`,
   aby poprawnie obsłużyć również miasta ze spacjami w nazwie.
5. W jobie `deploy` zastąp każde wystąpienie nazwy `pogoda_api_deploy`
   zmienną `DEPLOY_CONTAINER_NAME`. Obejmuje to wyszukiwanie starego kontenera,
   jego usunięcie, `docker run`, `docker inspect` i `docker logs`.
   Filtr `name=^/...$` z pliku bazowego jest wyrażeniem regularnym. Jeśli go
   zachowasz, ogranicz nazwę w tym ćwiczeniu do liter, cyfr, `_` i `-`,
   z literą lub cyfrą na początku, i sprawdź ten format w kroku walidacji.
6. W mapowaniu portu oraz obu kontrolach HTTP w jobie `deploy` odczytuj ten sam
   `DOCKER_PORT_EXTERNAL`. Wewnętrzny port aplikacji nadal wynosi `8000`.

Przykład przypisania jednej wartości:

```yaml
env:
  WEATHER_CITY: ${{ vars.WEATHER_CITY }}
```

Zmienne w tym samym bloku `env` nie mogą odwoływać się do siebie.
Przykładowo `HUB_IMAGE_BASE` zbuduj bezpośrednio z `vars`, zamiast odczytywać
sąsiednie wpisy przez `env`:

```yaml
env:
  HUB_IMAGE_BASE: ${{ vars.DOCKERHUB_USERNAME }}/${{ vars.DOCKER_IMAGE_NAME }}
```

W polach akcji, takich jak `with.context` i `with.tags`, używaj kontekstu
`${{ env.NAZWA }}`. W skryptach Bash używaj `"$NAZWA"` lub `"${NAZWA}"`.
Zmienne umieszczaj w cudzysłowach. Zasady zakresów opisuje
[dokumentacja kontekstu `env`](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#env-context).

## 4. Dostosuj warunki publikacji i wdrożenia

W pliku bazowym `build-and-push` dopuszcza wyłącznie `push` na gałąź
`feature/06-pogoda-api`. Samo ręczne uruchomienie nie uruchomi więc całego łańcucha.

1. Zmień warunek `if` joba `build-and-push`, aby publikacja była dozwolona
   dla zdarzenia `push` lub `workflow_dispatch`, gdy `github.ref_name`
   odpowiada `vars.DEPLOY_BRANCH`.
2. Dla `pull_request` wykonuj `build` i `test`, bez publikacji i deploya.
3. Zachowaj zależność `deploy` od `build-and-push` i przekazanie `image_digest`
   przez output joba. Nie zastępuj digestu tagiem `latest`.
4. Zachowaj grupę `concurrency` w jobie `deploy` z `cancel-in-progress: false`,
   nadając jej osobną nazwę `pogoda-api-variables-deploy`.

Gałąź z `DEPLOY_BRANCH` musi być również dopuszczona w filtrze `on.push.branches`.
Filtry zdarzeń nie obsługują kontekstu `vars`; pozostaw w nich jawne nazwy gałęzi.
Sprawdź to w [tabeli dostępności kontekstów](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#context-availability).

## 5. Sprawdź konfigurację przed zmianą kontenera

1. Na początku `deploy`, przed logowaniem, pobieraniem obrazu i usuwaniem kontenera,
   dodaj krok sprawdzający, czy wymagane zmienne konfiguracji oraz `IMAGE_DIGEST`
   mają niepuste wartości. Brak wymaganej zmiennej ma zatrzymać job z czytelnym
   komunikatem, zanim zacznie zmieniać działający kontener.
2. W logu wypisz konfigurację tego ćwiczenia: nazwę obrazu, tag, port,
   nazwę kontenera i miasto. Wyświetl tylko te wskazane wartości konfiguracji.
3. Zachowaj kolejność: pobierz obraz po digescie → sprawdź i usuń poprzedni
   kontener o tej samej nazwie → uruchom nowy → sprawdź gotowość → wywołaj `/weather`.
4. Zachowaj `--restart unless-stopped`, ograniczone ponawianie kontroli gotowości,
   wyświetlenie logów po błędzie oraz pozostawienie kontenera po zakończeniu joba.
5. W obu jobach uruchamiających aplikację przekaż `OPENWEATHER_API_KEY`
   jako zmienną środowiskową kontenera. Test `/weather` ma korzystać z tego klucza
   przez aplikację, bez dodawania go do URL zapytania.

Nieustawiona `vars.NAZWA` zwraca pusty tekst. Dla opcjonalnych ustawień możesz
zastosować wartość domyślną, np. `${{ vars.WEATHER_CITY || 'Warsaw' }}`.
Dla portu, nazwy kontenera i obrazu w tym ćwiczeniu wymagaj jawnej konfiguracji.
Zachowanie pustych wartości opisuje
[dokumentacja kontekstu `vars`](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#vars-context).

## 6. Przećwicz zakresy `env`

Na pomocniczej zmiennej `CONFIG_SCOPE` pokaż nadpisywanie wartości:

1. Ustaw `CONFIG_SCOPE: workflow` w głównym `env`.
2. W `deploy.env` ustaw `CONFIG_SCOPE: job`.
3. Dodaj w `deploy` krok z własnym `env`, ustawiający `CONFIG_SCOPE: step`,
   i wypisz tę wartość.
4. Dodaj kolejny krok bez własnego `env` i ponownie wypisz `CONFIG_SCOPE`.
5. W jednym z jobów bez nadpisania wypisz wartość z poziomu workflow.

Oczekiwane wyniki to odpowiednio `step`, `job` i `workflow`.
Nadpisanie na poziomie kroku obowiązuje tylko w tym kroku. Przećwicz to na
`CONFIG_SCOPE`, zachowując spójną konfigurację portu i nazwy kontenera.

## 7. Uruchom workflow i sprawdź zmianę konfiguracji

1. Udostępnij przygotowany workflow na GitHub i uruchom go przez `push`
   na gałąź zgodną z `DEPLOY_BRANCH`.
2. Zweryfikuj, że wszystkie cztery joby zakończyły się sukcesem, a test `/weather`
   w `deploy` zwrócił poprawną odpowiedź aplikacji z portu `18008`.
3. Zmień w zakładce **Variables** `WEATHER_CITY` na `Gdansk` oraz `DOCKERHUB_TAG`
   na `cw08-v2`. Pozostaw nazwę kontenera i port bez zmian.
4. Uruchom **nowy workflow** przez `workflow_dispatch`, wybierając gałąź zgodną
   z `DEPLOY_BRANCH`. W interfejsie GitHub przycisk **Run workflow** wymaga obecności
   pliku workflow z tym wyzwalaczem na domyślnej gałęzi repozytorium. Jeśli plik
   jeszcze tam nie istnieje, uruchom nowy przebieg przez kolejny `push` na
   dopuszczoną gałąź. Zasady opisuje
   [instrukcja ręcznego uruchamiania workflow](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow).
5. Potwierdź bez edycji YAML, że opublikowano tag `cw08-v2`, test odpytał o `Gdansk`,
   a dotychczasowy kontener został zastąpiony nowym.
6. Sprawdź przypadek brakującej konfiguracji: tymczasowo usuń
   `DEPLOY_CONTAINER_NAME` z **Variables**, uruchom nowy przebieg i potwierdź,
   że walidacja zatrzymała `deploy` przed usunięciem działającego kontenera.
   Następnie przywróć zmienną.

Sama zmiana Repository variable nie uruchamia workflow ani nie zmienia
już działającego kontenera. Nowa konfiguracja zostanie zastosowana przy
następnym poprawnym wykonaniu odpowiednich jobów.

## Zadanie dodatkowe — `$GITHUB_ENV`

W jobie `deploy` dodaj krok, który z `DOCKER_PORT_EXTERNAL` wyliczy
`API_BASE_URL=http://127.0.0.1:<port>` i zapisze tę zmienną do pliku `$GITHUB_ENV`.
W kolejnych krokach użyj `$API_BASE_URL` przy sprawdzaniu gotowości i `/weather`.

Odpowiedz: dlaczego nowa wartość jest dostępna dopiero w następnych krokach
tego joba? Dlaczego zapis w `build` nie udostępni jej automatycznie w `deploy`?
Porównaj to z istniejącym przekazywaniem `image_digest` przez output joba.
Zobacz [ustawianie zmiennych przez `$GITHUB_ENV`](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#setting-an-environment-variable).

## Kryteria ukończenia

- Nowy workflow wykorzystuje `vars`, `env` i `secrets` zgodnie z ich rolą.
- Login, ścieżka aplikacji, nazwa obrazu, tag, port, nazwa kontenera i miasto
  pochodzą z konfiguracji repozytorium.
- Token Docker Hub i klucz pogodowy pozostają w `secrets` i nie są wypisywane.
- Budowanie i testy działają na runnerach GitHub, a `deploy` na self-hosted.
- Publikacja i deploy wykonują się dla właściwej gałęzi i obsługują ręczny start.
- Test `/weather` działa zarówno przed publikacją, jak i po uruchomieniu kontenera.
- Kolejny deploy zastępuje kontener tego ćwiczenia i pozostawia go uruchomionym.
- Brak wymaganej konfiguracji zatrzymuje deploy przed zmianą istniejącego kontenera.
- Logi potwierdzają zakresy `workflow` → `job` → `step` oraz zmianę konfiguracji
  bez edycji YAML.
