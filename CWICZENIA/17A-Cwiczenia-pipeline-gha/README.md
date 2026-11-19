# Ćwiczenie 17A — pipeline z reusable workflows

## 1. Najpierw ustaw vars i secrets repozytorium

Otwórz **Settings → Secrets and variables → Actions** w swoim repozytorium.
W zakładce **Variables** dodaj:

| Nazwa | Wartość |
| --- | --- |
| `DOCKERHUB_USERNAME` | Twój login Docker Hub, np. `piotrskoska` |
| `DOCKER_IMAGE_NAME` | `python_pogoda` |

W zakładce **Secrets** dodaj:

| Nazwa | Wartość do wpisania |
| --- | --- |
| `DOCKERHUB_TOKEN` | Twój token Docker Hub z uprawnieniem publikowania i pobierania obrazu |
| `OPENWEATHER_API_KEY` | Twój prawdziwy, aktywny klucz OpenWeatherMap |

Przygotuj repozytorium obrazu `python_pogoda` na swoim koncie Docker Hub.
Wartości tokenu i klucza API przechowuj wyłącznie w Secrets. Nie zapisuj ich
w YAML, Dockerfile, inputs, outputs ani artefaktach.

## 2. Sprawdź gotową aplikację i własny runner

Kod WWW/API, Dockerfile, Nginx i test
[tests/smoke_test.py](./pogoda_python_flusk/tests/smoke_test.py) są już w
[pogoda_python_flusk](./pogoda_python_flusk/). W ćwiczeniu przygotowujesz
GitHub Actions; nie musisz zmieniać aplikacji.

Kontener udostępnia HTTP na porcie `8080`: `/` z formularzem miasta,
`/healthz` z gotowością oraz `/api/weather?city=Warsaw` z pogodą.

Repozytorium musi mieć dostępny runner Linux z etykietami `self-hosted`
i `linux`. Konto runnera potrzebuje dostępu do Dockera, Python 3 oraz `curl`.
Host musi łączyć się z Docker Hub i OpenWeatherMap. Wybierz wolny port,
domyślnie `18817`; uczestnicy na wspólnym hoście muszą używać różnych portów.

## 3. Rozdziel pipeline na trzy pliki

Wszystkie pliki YAML umieść bezpośrednio w `.github/workflows`:

| Plik | Rola | Zdarzenie |
| --- | --- | --- |
| [17A-pogoda-reusable.yaml](../../.github/workflows/17A-pogoda-reusable.yaml) | Workflow uruchamiany przez uczestnika; przekazuje parametry i łączy części pipeline | `workflow_dispatch` |
| [17A-reusable-docker-ci.yaml](../../.github/workflows/17A-reusable-docker-ci.yaml) | Budowanie, test i publikacja obrazu | `workflow_call` |
| [17A-reusable-docker-deploy.yaml](../../.github/workflows/17A-reusable-docker-deploy.yaml) | Trwały deploy na własnym runnerze | `workflow_call` |

Nie twórz podkatalogów wewnątrz `.github/workflows`. Katalog aplikacji może
pozostać w `CWICZENIA`; lokalizacja aplikacji nie zmienia lokalizacji workflow.

```text
17A-pogoda-reusable.yaml
  ├─ ci     → 17A-reusable-docker-ci.yaml
  │            prepare → build → test → publish
  ├─ deploy → 17A-reusable-docker-deploy.yaml
  │            deploy na self-hosted, po sukcesie ci
  └─ result → podsumowanie outputs obu wywołań, po sukcesie ci i deploy
```

Workflow wywołujący, dalej nazywany callerem, ma tylko połączyć gotowe
procesy. Logika budowania i deploya znajduje się w dwóch wywoływanych plikach.

## 4. Zdefiniuj interfejs reusable workflow CI

W `17A-reusable-docker-ci.yaml` dodaj `on: workflow_call` z inputs:

| Input | Typ | Wymaganie |
| --- | --- | --- |
| `app_dir` | `string` | Domyślnie `./CWICZENIA/17A-Cwiczenia-pipeline-gha/pogoda_python_flusk` |
| `first_name` | `string` | Wymagane imię, litery ASCII i opcjonalne człony z myślnikami, maksymalnie 30 znaków |
| `last_name` | `string` | Wymagane nazwisko z takimi samymi ograniczeniami |
| `dockerhub_username` | `string` | Wymagany login przekazany z repozytorium |
| `docker_image_name` | `string` | Wymagana nazwa obrazu przekazana z repozytorium |
| `weather_city` | `string` | Miasto testu, domyślnie `Warsaw` |

W `on.workflow_call.secrets` zadeklaruj wymagane sekrety
`DOCKERHUB_TOKEN` oraz `OPENWEATHER_API_KEY` przez `required: true`.
Same deklaracje nie tworzą sekretów; caller musi przekazać je w `secrets`.

Inputs mają jawne typy. `required` oznacza parametr obowiązkowy, a `default`
pozwala pominąć parametr z wartością domyślną. W krokach waliduj także
rzeczywistą zawartość: np. pusty sekret albo nieprawidłowy login mają dać błąd.

## 5. Zaimplementuj cztery joby CI

Wszystkie joby CI uruchamiaj na `ubuntu-latest`:

1. `prepare`: zwaliduj inputs, utwórz slug `jan-kowalski` z imienia i nazwiska,
   wylicz nazwy i przekaż konfigurację przez outputs.
2. `build`: zbuduj obraz dokładnie raz, bez sekretów aplikacji. Odczytaj
   `image_id`, zapisz obraz do `image.tar` i wyślij go jako artefakt z retencją
   jednego dnia. Nazwa artefaktu uwzględnia przebieg, próbę i slug uczestnika.
3. `test`: pobierz ten artefakt, wykonaj `docker load`, sprawdź zgodność ID
   i uruchom kontener z prawdziwym `OPENWEATHER_API_KEY`. Poczekaj na
   `/healthz`, a następnie wykonaj dostarczony smoke test WWW i rzeczywistego
   API dla `weather_city`. Kontener testowy usuń także po błędzie.
4. `publish`: po sukcesie testów pobierz ten sam obraz, sprawdź jego ID
   i opublikuj go w Docker Hub bez ponownego budowania.

Dla uczestnika Jan Kowalski opublikuj dwa tagi:

```text
<login>/python_pogoda:jan-kowalski-<pełny GITHUB_SHA>
<login>/python_pogoda:<pełny GITHUB_SHA>
```

Pełne SHA nie jest skróconym identyfikatorem commita. Klucz API przekazuj
tylko do `docker run -e OPENWEATHER_API_KEY`. Błąd buildu zatrzymuje dalsze
joby, a błąd prawdziwego API zatrzymuje publikację i późniejszy deploy.

## 6. Wystaw outputs całego reusable workflow CI

Caller potrzebuje danych wyjściowych CI:

| Workflow output | Co zawiera |
| --- | --- |
| `image_reference` | `<login>/<obraz>@sha256:<digest>` — referencja opublikowanego obrazu |
| `image_digest` | Sam digest `sha256:...` |
| `image_tag` | Tag z imieniem, nazwiskiem i pełnym SHA |
| `student_slug` | Np. `jan-kowalski` |

Przekazywanie odbywa się przez trzy poziomy:

```text
krok: $GITHUB_OUTPUT
  → job: outputs
    → workflow: on.workflow_call.outputs
      → caller: needs.ci.outputs.<nazwa>
```

W sekcji `on.workflow_call.outputs` mapuj `value` na output joba,
np. `${{ jobs.publish.outputs.image_digest }}`. Job wcześniej mapuje wynik
kroku, np. `${{ steps.release.outputs.image_digest }}`. Sam zapis do
`$GITHUB_OUTPUT` nie udostępnia wyniku callerowi.

Plik `image.tar` pozostaje artefaktem pomiędzy jobami CI. Outputs zawierają
tekstowe metadane, nie zawartość obrazu ani wartości sekretów.

## 7. Zdefiniuj interfejs reusable workflow deploya

W `17A-reusable-docker-deploy.yaml` także użyj `workflow_call`. Przygotuj:

| Input | Typ | Znaczenie |
| --- | --- | --- |
| `app_dir` | `string` | Katalog gotowego smoke testu; domyślnie katalog aplikacji 17A |
| `image_reference` | `string` | Wymagana referencja obrazu przypięta digestem |
| `container_name` | `string` | Wymagana nazwa kontenera obliczona przez callera |
| `app_port` | `number` | Port hosta, domyślnie `18817`; dozwolone całkowite `1024`–`65535` |
| `weather_city` | `string` | Miasto testu, domyślnie `Warsaw` |
| `dockerhub_username` | `string` | Wymagany login Docker Hub |

Zadeklaruj te same dwa wymagane sekrety. Nie zakładaj, że sekret przekazany
do workflow CI automatycznie trafia do osobnego workflow deploya.

Własny job tego reusable workflow ma `runs-on: [self-hosted, linux]`.
To wywoływany plik określa runner swoich jobów.

## 8. Wdróż opublikowany obraz i sprawdź działanie

Job deploya ma:

1. Sprawdzić konfigurację, zwłaszcza digest obrazu, nazwę kontenera i port.
2. Utworzyć prywatny, tymczasowy `DOCKER_CONFIG`, a następnie zalogować się
   do Docker Hub przez token.
3. Wykonać `docker pull` obrazu przypiętego digestem przed usuwaniem
   poprzedniego kontenera.
4. Sprawdzić dokładną nazwę kontenera, także wśród zatrzymanych, i usunąć
   tylko ten kontener, jeśli istnieje.
5. Uruchomić nowy kontener z `--restart unless-stopped`, portem
   `<app_port>:8080` i kluczem API przekazanym tylko podczas startu.
6. Potwierdzić działający kontener, gotowość `/healthz` i wynik smoke testu
   WWW/API z prawdziwymi danymi pogodowymi.
7. Zawsze wylogować Docker Hub i usunąć tymczasowe poświadczenia tego joba.

Dodaj współbieżność według nazwy kontenera z `cancel-in-progress: false`.
Docelowy kontener pozostaje na hoście po jobie; nie usuwaj go w końcowym
sprzątaniu logowania. Konfiguracja nie wykonuje automatycznego rollbacku.

Po udanym smoke teście krok `verify` zapisuje `app_url`. Wystaw go przez
`steps.verify.outputs.app_url` jako output joba `deploy`, a następnie przez
`jobs.deploy.outputs.app_url` jako output `on.workflow_call.outputs.app_url`.
Wartością jest adres testowany na runnerze, np. `http://127.0.0.1:18817`.
Nie jest to publiczny adres hosta.

## 9. Połącz oba reusable workflows w callerze

W `17A-pogoda-reusable.yaml` dodaj `workflow_dispatch` z formularzem:

| Input | Typ | Przykład lub wartość domyślna |
| --- | --- | --- |
| `first_name` | `string`, wymagany | `Jan` |
| `last_name` | `string`, wymagany | `Kowalski` |
| `city` | `string` | `Warsaw` |
| `app_port` | `number` | `18817` |

Job `ci` wywołuje reusable CI, a job `deploy` z `needs: ci` wywołuje reusable
deploy. Nazwę kontenera złóż jako
`cw17a-<REPO_ID>-<student_slug_z_CI>-prod`. Dodaj zwykły job `result` z
`needs: [ci, deploy]` i `runs-on: ubuntu-latest`. Ma odczytać outputs obu
workflow i zapisać podsumowanie, w tym `needs.deploy.outputs.app_url`.

Reusable workflow wywołuj przez `uses` na poziomie **joba**, nie kroku.
Lokalne ścieżki `./.github/workflows/...` nie mają sufiksu `@main` ani
`@SHA`; wskazują plik z tego samego commita co caller.

Do joba zawierającego takie `uses` nie dodawaj `runs-on` ani `steps`.
Jeśli potrzebujesz nowych poleceń, umieść je wewnątrz odpowiedniego
wywoływanego workflow.

Kompletny caller z rozwiązania:

```yaml
name: 17A Pogoda — reusable workflows
run-name: 17A Reuse — ${{ inputs.first_name }} ${{ inputs.last_name }}

on:
  workflow_dispatch:
    inputs:
      first_name:
        description: Imię bez polskich znaków, np. Jan
        required: true
        type: string
      last_name:
        description: Nazwisko bez polskich znaków, np. Kowalski
        required: true
        type: string
      city:
        description: Miasto do rzeczywistego testu API
        required: true
        type: string
        default: Warsaw
      app_port:
        description: Wolny port HTTP na self-hosted, osobny dla uczestnika
        required: true
        type: number
        default: 18817

permissions:
  contents: read

jobs:
  ci:
    # Reusable workflow wywołujemy na poziomie JOBA, bez runs-on i steps.
    # Lokalna ścieżka oznacza plik z tego samego commita; nie dodawaj @main.
    uses: ./.github/workflows/17A-reusable-docker-ci.yaml
    with:
      app_dir: ./CWICZENIA/17A-Cwiczenia-pipeline-gha/pogoda_python_flusk
      first_name: ${{ inputs.first_name }}
      last_name: ${{ inputs.last_name }}
      dockerhub_username: ${{ vars.DOCKERHUB_USERNAME }}
      docker_image_name: ${{ vars.DOCKER_IMAGE_NAME }}
      weather_city: ${{ inputs.city }}
    secrets:
      DOCKERHUB_TOKEN: ${{ secrets.DOCKERHUB_TOKEN }}
      OPENWEATHER_API_KEY: ${{ secrets.OPENWEATHER_API_KEY }}

  deploy:
    needs: ci
    uses: ./.github/workflows/17A-reusable-docker-deploy.yaml
    with:
      app_dir: ./CWICZENIA/17A-Cwiczenia-pipeline-gha/pogoda_python_flusk
      # Output CI jest inputem drugiego reusable workflow.
      image_reference: ${{ needs.ci.outputs.image_reference }}
      container_name: ${{ format('cw17a-{0}-{1}-prod', github.repository_id, needs.ci.outputs.student_slug) }}
      app_port: ${{ inputs.app_port }}
      weather_city: ${{ inputs.city }}
      dockerhub_username: ${{ vars.DOCKERHUB_USERNAME }}
    secrets:
      DOCKERHUB_TOKEN: ${{ secrets.DOCKERHUB_TOKEN }}
      OPENWEATHER_API_KEY: ${{ secrets.OPENWEATHER_API_KEY }}

  result:
    needs: [ci, deploy]
    runs-on: ubuntu-latest
    steps:
      - name: Read the reusable workflows outputs
        env:
          IMAGE_REFERENCE: ${{ needs.ci.outputs.image_reference }}
          IMAGE_TAG: ${{ needs.ci.outputs.image_tag }}
          APP_URL: ${{ needs.deploy.outputs.app_url }}
          APP_PORT: ${{ inputs.app_port }}
        run: |
          {
            echo "### CW17A — outputs reużywanych workflow"
            echo ""
            echo "- Opublikowany obraz: $IMAGE_REFERENCE"
            echo "- Tag uczestnika: $IMAGE_TAG"
            echo "- Sprawdzony adres lokalny na self-hosted: $APP_URL"
            echo "- WWW z komputera uczestnika: http://ADRES_TWOJEGO_RUNNERA:${APP_PORT}/"
          } >> "$GITHUB_STEP_SUMMARY"
```

## 10. Przekazuj konfigurację i sekrety jawnie

Zwykłe wartości przekazuj w `with`, np. login z
`${{ vars.DOCKERHUB_USERNAME }}`. W wywoływanym workflow odczytuj je przez
`inputs.dockerhub_username`. Nie zakładaj dziedziczenia `env` callera;
potrzebne parametry stanowią część interfejsu `workflow_call`.

Do obu wywołań dodaj jawne mapowanie:

```yaml
secrets:
  DOCKERHUB_TOKEN: ${{ secrets.DOCKERHUB_TOKEN }}
  OPENWEATHER_API_KEY: ${{ secrets.OPENWEATHER_API_KEY }}
```

W tym ćwiczeniu nie stosuj `secrets: inherit`: lista przy wywołaniu pokazuje,
których sekretów dany workflow potrzebuje.

Ustaw `permissions: contents: read`. Checkout oraz potrzebne akcje
wykonują joby wywoływanych workflow; caller nie przygotowuje im wspólnego
katalogu roboczego.

## 11. Uruchom pipeline i odczytaj rezultat

1. Udostępnij wszystkie trzy pliki w repozytorium, w tym na domyślnej gałęzi,
   aby dostępny był formularz ręcznego uruchamiania callera.
2. Otwórz **Actions** i wybierz **17A Pogoda — reusable workflows**
   (`17A-pogoda-reusable.yaml`).
3. Kliknij **Run workflow**, podaj imię i nazwisko bez polskich znaków,
   miasto oraz własny wolny port.
4. Obserwuj joby reusable CI: `prepare`, `build`, `test`, `publish`.
5. Sprawdź, że deploy rusza dopiero po sukcesie CI i używa outputu
   `image_reference`, a nie zmiennego tagu.
6. W Docker Hub sprawdź oba tagi z pełnym SHA.
7. Odczytaj podsumowanie i otwórz aplikację przez adres hosta runnera:

```text
http://<adres-IP-lub-nazwa-hosta-runnera>:18817/
http://<adres-IP-lub-nazwa-hosta-runnera>:18817/api/weather?city=Warsaw
```

Podstaw wybrany port. Dostęp z komputera uczestnika wymaga otwartego portu
w odpowiednich regułach sieciowych. `127.0.0.1` z outputu `app_url` odnosi
się do runnera i nie zastępuje adresu jego hosta.

Tylko caller ma ręczne `workflow_dispatch`. Dwa pliki z `workflow_call`
uruchamiają się przez wywołanie, nie jako osobne formularze tego ćwiczenia.

## 12. Sprawdź ponowne użycie i obsługę błędów

Uruchom caller ponownie dla tego samego uczestnika i portu, zmieniając
jedynie `city`, np. na `Gdansk`. Kontener ma zostać zastąpiony pod tą samą
nazwą, a testy wykonane dla nowego miasta. Nie kopiuj logiki builda lub
deploya do callera.

Prześledź dwa przykłady przepływu:

- `city` z formularza → `with.weather_city` → `inputs.weather_city`
  w obu reusable workflows;
- referencja z digestem z publikacji → output joba → output reusable CI →
  `needs.ci.outputs.image_reference` → input deploya.

Błąd budowania, brak sekretu, odrzucony token, nieprawidłowy klucz API
lub nieudany test muszą dać niepowodzenie odpowiedniego joba. Dalsza
publikacja i deploy zależą od sukcesu wcześniejszych etapów.

Zadanie jest ukończone, gdy caller zawiera wywołania i parametry, CI buduje
i testuje jeden obraz, deploy otrzymuje opublikowany digest przez output,
a aplikacja działa na self-hosted i przechodzi test prawdziwego API.

Dokumentacja:
[reusable workflows, inputs, secrets i outputs](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows)
oraz [przekazywanie outputs pomiędzy jobami](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/pass-job-outputs).
