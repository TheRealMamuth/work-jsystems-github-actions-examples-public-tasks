# FAZA-3 — Matrix i GitHub Environments: test, dev, prod

## Cel ćwiczenia

Rozszerz pipeline z [FAZY-2](../FAZA-2/README.md), aby jeden zbudowany
i przetestowany obraz opublikować oraz wdrożyć dla GitHub Environments
`test`, `dev` i `prod`. Użyj strategii `matrix` w publikacji i deployu.

Nowy plik workflow: `.github/workflows/15A-FAZA3-pogoda.yaml`.
W YAML pozostają **cztery definicje jobów**, ale GitHub wykona **osiem uruchomień**:

| Definicja joba | Liczba uruchomień | Runner | GitHub Environment |
| --- | --- | --- | --- |
| `build` | 1 | `ubuntu-latest` | brak |
| `test` | 1 | `ubuntu-latest` | brak |
| `build-and-push` | 3, przez matrix | `ubuntu-latest` | `test`, `dev`, `prod` |
| `deploy` | 3, przez matrix | `[self-hosted, linux]` | `test`, `dev`, `prod` |

Build i test są wspólne. Każdy wariant publikacji dostaje ten sam przetestowany
obraz i własny tag. Wszystkie publikacje muszą się udać, zanim ruszą deploye.
Trzy kontenery mają działać na jednym hoście, z oddzielnymi nazwami i portami.

## Krok 1. Przygotuj nową fazę

1. Skopiuj `.github/workflows/15A-FAZA2-pogoda.yaml` do
   `.github/workflows/15A-FAZA3-pogoda.yaml`.
2. Nadaj workflow nazwę `15A FAZA-3 — Matrix i Environments`.
3. Zachowaj `workflow_dispatch` i `push` na `main`; w `paths` wskaż katalog
   aplikacji i nowy plik YAML.
4. Nadal korzystaj z aplikacji
   `CWICZENIA/15A-Cwiczenia-pipeline-gha/pogoda_python_flusk`.
5. Nie zmieniaj aplikacji, wcześniejszych workflow ani ustawień portów FAZ 1 i 2.
6. Sprawdź dostępność runnera self-hosted oraz wolnych portów `18093`, `18094`,
   `18095`. Dostęp z Twojego urządzenia musi dopuszczać sieć i zapora hosta.

W tej fazie wdrożenia wykonują joby GitHub Actions przez Docker CLI na runnerze.
HTTP pozostaje domyślnym protokołem, z Nginxem na `8080` wewnątrz kontenera.

## Krok 2. Ustaw wspólne Repository variables

Otwórz **Settings → Secrets and variables → Actions → Variables**.
Dodaj lub sprawdź wspólne wartości:

| Repository variable | Wartość początkowa | Zastosowanie |
| --- | --- | --- |
| `DOCKERHUB_USERNAME` | `piotrskoska` albo Twój login | Konto publikujące obrazy |
| `DOCKER_IMAGE_NAME` | `python_pogoda` | Repozytorium obrazu na Docker Hub |
| `FAZA3_DEPLOY_BRANCH` | `main` | Gałąź dopuszczona do publikacji i deploya |
| `FAZA3_WEATHER_CITY` | `Warsaw` | Miasto wspólnego testu CI |

Wpisuj same wartości, bez dodatkowych cudzysłowów. Katalog aplikacji, nazwy
artefaktów, `CI_IMAGE` i scope cache ustawia workflow; nie twórz dla nich
dodatkowych Repository variables.

## Krok 3. Zachowaj Repository secrets

W **Settings → Secrets and variables → Actions → Secrets** pozostają:

| Repository secret | Wartość |
| --- | --- |
| `DOCKERHUB_TOKEN` | Twój prawdziwy token Docker Hub z prawem publikacji |
| `OPENWEATHER_API_KEY` | Twój prawdziwy, aktywny klucz API OpenWeatherMap |

Wspólny job `test` nie ma przypisanego Environment. Potrzebuje więc klucza
API na poziomie repozytorium, również wtedy, gdy później ustawisz osobne
klucze środowiskowe.

Klucz pogody nadal przekazuj wyłącznie przy `docker run`.
Nie umieszczaj go w obrazie, `build-args`, cache, pliku metadanych publikacji,
JavaScripcie ani URL zapytania API.

## Krok 4. Utwórz lub wykorzystaj GitHub Environments

1. Przejdź do **Settings → Environments**.
2. Utwórz `test`, `dev` i `prod` przez **New environment**.
3. Jeżeli te środowiska istnieją po poprzednich ćwiczeniach, wykorzystaj je.
4. Dodawaj nowe zmienne z prefiksem `FAZA3_`, zachowując ustawienia wcześniejszych
   ćwiczeń.

Jeśli Environment ogranicza dozwolone gałęzie, dopuść gałąź wskazaną przez
`FAZA3_DEPLOY_BRANCH`. Istniejące reguły zatwierdzania dotyczą zarówno publikacji,
jak i deploya; oczekiwanie na zatwierdzenie publikacji wstrzymuje start deployów.

Job powiąż ze środowiskiem przez pole `environment`. Zmienna powłoki
`TARGET_ENVIRONMENT` sama nie tworzy tego powiązania. Zobacz
[konfigurację GitHub Environments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments).

## Krok 5. Dodaj te same nazwy zmiennych w każdym Environment

W **Settings → Environments → test/dev/prod → Environment variables**
utwórz wartości z odpowiedniej kolumny:

| Environment variable | `test` | `dev` | `prod` |
| --- | --- | --- | --- |
| `FAZA3_IMAGE_TAG` | `faza3-test` | `faza3-dev` | `faza3-prod` |
| `FAZA3_APP_PORT` | `18093` | `18094` | `18095` |
| `FAZA3_CONTAINER_NAME` | `pogoda_api_faza3_test` | `pogoda_api_faza3_dev` | `pogoda_api_faza3_prod` |
| `FAZA3_WEATHER_CITY` | `Warsaw` | `Warsaw` | `Warsaw` |

Tagi, porty oraz nazwy kontenerów mają być rozdzielone między środowiskami.
`FAZA3_IMAGE_TAG`, `FAZA3_APP_PORT` i `FAZA3_CONTAINER_NAME` ustaw w samych
Environments. Nowy workflow nie pobiera ich z dawnych zmiennych ćwiczeń 08.

`FAZA3_WEATHER_CITY` na poziomie repozytorium służy wspólnemu CI.
Wariant deploya odczyta wartość tego samego klucza z własnego Environment.

## Krok 6. Opcjonalnie rozdziel sekrety środowisk

W sekcji **Environment secrets** możesz dodać `DOCKERHUB_TOKEN`
i `OPENWEATHER_API_KEY` dla każdego środowiska pod tymi samymi nazwami.
Pozwala to użyć innych danych dostępowych w `test`, `dev` i `prod`.

Jeżeli dane są wspólne, pozostaw sekrety repozytorium. W kodzie odczytuj je
przez `secrets.*`; właściwy zakres wynika z przypisania joba do Environment.
Sekrety środowiska są dostępne jobom korzystającym z tego środowiska.
[Opis zmiennych i sekretów środowiskowych](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments).

## Krok 7. Zachowaj jeden build i cache warstw

1. Job `build` pozostaw bez matrix i bez GitHub Environment.
2. Zachowaj Buildx z `version: latest` i `driver: docker-container`.
3. Buduj obraz z tagiem `ci-faza3-<github.sha>`, z `load: true`, `push: false`.
4. Ustaw cache z nowym, stałym scope:

   ```yaml
   cache-from: type=gha,version=2,scope=15a-pogoda-faza3
   cache-to: type=gha,version=2,scope=15a-pogoda-faza3,mode=max
   ```

5. Sprawdź, czy w metadanych obrazu nie ma ustawionego klucza API.
6. Zapisz obraz do `image.tar` i prześlij artefakt `faza3-weather-image`.
7. W `actions/upload-artifact@v4` zachowaj `overwrite: true`, aby ponowne
   uruchomienie joba mogło zastąpić artefakt tej fazy w tym samym przebiegu.

Cache przyspiesza ponowne budowanie, a artefakt przekazuje konkretny obraz
do następnych jobów. Zasady cache są takie jak w FAZIE-2;
[dokumentacja backendu `gha`](https://docs.docker.com/build/cache/backends/gha/).

## Krok 8. Zachowaj jeden rzeczywisty test CI

1. Job `test` pozostaw bez matrix i bez Environment, z `needs: build`.
2. Pobierz `faza3-weather-image` i wykonaj `docker load`.
3. Uruchom kontener `pogoda_api_faza3_ci` z sekretem API i lokalnym
   mapowaniem `127.0.0.1:18093:8080`.
4. Sprawdź `/healthz`, a następnie uruchom `tests/smoke_test.py` z miastem
   z Repository variable `FAZA3_WEATHER_CITY`.
5. Po błędzie pokaż logi, a tymczasowy kontener usuń w kroku `if: always()`.

Ten test nadal musi odpytać OpenWeatherMap prawdziwym kluczem.
Jest wykonywany raz przed publikacjami dla wszystkich trzech środowisk.

## Krok 9. Zastąp pojedynczą publikację macierzą

W `build-and-push` ustaw `needs: test` i zachowaj warunek gałęzi
`vars.FAZA3_DEPLOY_BRANCH || 'main'`. Dodaj:

```yaml
strategy:
  fail-fast: false
  matrix:
    environment: [test, dev, prod]
environment: ${{ matrix.environment }}
```

Jedna definicja joba wygeneruje trzy warianty. W każdym:

1. Odczytaj `vars.FAZA3_IMAGE_TAG` w `env` kroku po starcie joba.
2. Zapisz zweryfikowany tag do `$GITHUB_ENV` dla kolejnych kroków.
3. Pobierz i załaduj wspólny, przetestowany `image.tar`.
4. Zaloguj się do Docker Hub.
5. Dodaj tag środowiska oraz tag `<tag-środowiska>-<github.sha>`.
6. Wykonaj `docker push` i odczytaj digest z potwierdzenia własnej publikacji.
7. Nie buduj obrazu ponownie w żadnym wariancie.

`fail-fast: false` pozwala pozostałym wariantom dokończyć pracę po błędzie
jednego z nich; błąd nadal pozostaje błędem pipeline.
[Dokumentacja strategii matrix](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations).

## Krok 10. Zapisz metadane publikacji osobno dla każdego środowiska

Po poprawnym push zapisz `release.json` zawierający:

| Pole | Znaczenie |
| --- | --- |
| `environment` | Bieżący wariant `test`, `dev` albo `prod` |
| `image_tag` | Tag odczytany z właściwego Environment |
| `image_digest` | Digest `sha256:...` z potwierdzenia push |
| `commit` | `github.sha` bieżącego przebiegu |
| `run_id` | Identyfikator bieżącego workflow run |

Prześlij plik przez `actions/upload-artifact@v4`, z nazwą
`faza3-release-${{ matrix.environment }}` i `overwrite: true`.
Powstaną `faza3-release-test`, `faza3-release-dev`, `faza3-release-prod`.
Metadane nie mogą zawierać kluczy ani tokenów.

Nie przekazuj trzech digestów przez jeden output o tej samej nazwie w jobie
matrix. Wspólne nazwy outputów mogą być nadpisywane przez inne warianty;
zobacz [zasady outputów jobów matrix](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idoutputs).

## Krok 11. Dodaj macierz deploya i wspólną barierę publikacji

W `deploy` ustaw:

```yaml
needs: build-and-push
runs-on: [self-hosted, linux]
strategy:
  fail-fast: false
  max-parallel: 1
  matrix:
    environment: [test, dev, prod]
environment: ${{ matrix.environment }}
```

`needs: build-and-push` czeka na zakończenie **całej macierzy publikacji**.
Dopiero gdy wszystkie trzy publikacje zakończą się sukcesem, mogą ruszyć deploye.
Jeśli jedna publikacja zawiedzie, pozostałe mogą się zakończyć, ale wszystkie
warianty deploya zostaną pominięte.

`max-parallel: 1` ogranicza deploy do jednego wariantu naraz na wspólnym hoście.
Nie jest to zależność promująca wersję kolejno `test` → `dev` → `prod`.
Ta faza wdraża trzy niezależne konfiguracje wspólnego obrazu.
[Znaczenie `needs` i pomijania zależnych jobów](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idneeds).

## Krok 12. Odczytaj i zweryfikuj konfigurację właściwego środowiska

W każdym wariancie deploya:

1. Pobierz tylko artefakt `faza3-release-${{ matrix.environment }}`
   do katalogu `release-metadata`.
2. W `env` kroku odczytaj `FAZA3_IMAGE_TAG`, `FAZA3_APP_PORT`,
   `FAZA3_CONTAINER_NAME`, `FAZA3_WEATHER_CITY` i sekret pogodowy.
3. Przed zmianą kontenera zweryfikuj, czy `release-metadata/release.json`
   odpowiada bieżącemu środowisku, tagowi, commitowi i `run_id`.
4. Sprawdź format digestu, port z zakresu `1–65535`, nazwę miasta
   i obecność klucza API.
5. Nazwa kontenera musi mieć postać `pogoda_api_faza3_<środowisko>`
   albo tę nazwę z sufiksem zaczynającym się od `_` lub `-`,
   np. `pogoda_api_faza3_dev_v2`. Nie używaj nazwy innej fazy lub środowiska.
6. Zapisz zatwierdzone ustawienia oraz `IMAGE_REFERENCE=<repo>@<digest>`
   do `$GITHUB_ENV` dla kolejnych kroków.

Taka walidacja zapobiega użyciu metadanych innego wariantu i usunięciu kontenera
z innego środowiska. Zmienne Environment odczytuj w krokach joba, po jego
przypisaniu do środowiska. [Kontekst `vars`](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#vars-context).

## Krok 13. Zachowaj wymianę kontenera i sprzątanie poświadczeń

1. Dla wariantu deploya przygotuj prywatny tymczasowy `DOCKER_CONFIG`
   z prefiksem `faza3-<środowisko>-docker-config.`.
2. Zaloguj się do Docker Hub i pobierz obraz po zweryfikowanym digescie.
3. Wyszukaj poprzedni kontener po pełnej, zweryfikowanej nazwie i usuń go,
   jeśli istnieje, również gdy jest zatrzymany.
4. Uruchom nowy z `--restart unless-stopped`, portem `${APP_PORT}:8080`
   oraz sekretem przekazanym wyłącznie przez `-e OPENWEATHER_API_KEY`.
5. Sprawdź gotowość, stan kontenera oraz WWW i prawdziwe API helperem testowym.
6. Po błędzie pokaż logi; po zakończeniu pozostaw kontener uruchomiony.
7. W `if: always()` wykonaj wylogowanie i usuń plik tymczasowych poświadczeń
   tego joba. Ten krok nie usuwa sekretów zapisanych w ustawieniach GitHub.

Grupy `concurrency` uwzględnij osobno dla publikacji i deploya, z nazwą
środowiska, np. `pogoda-faza3-publish-${{ matrix.environment }}` oraz
`pogoda-faza3-deploy-${{ matrix.environment }}`. Zachowaj `cancel-in-progress: false`.

## Krok 14. Uruchom workflow i sprawdź trzy aplikacje

1. Sprawdź tabele Variables i Secrets oraz dostępność wszystkich trzech portów.
2. Udostępnij nowy YAML na GitHub na `main`.
3. W **Actions** wybierz `15A FAZA-3 — Matrix i Environments`.
4. Wybierz **Run workflow** na gałęzi `main`.
5. Potwierdź jeden `build`, jeden `test`, trzy warianty `Publish`
   i trzy warianty `Deploy`.
6. W artefaktach przebiegu sprawdź wspólny obraz i trzy pliki metadanych środowisk.
7. Sprawdź trzy tagi na Docker Hub oraz adresy aplikacji:

| Environment | WWW | API |
| --- | --- | --- |
| `test` | `http://ADRES_RUNNERA:18093/` | `http://ADRES_RUNNERA:18093/api/weather?city=Warsaw` |
| `dev` | `http://ADRES_RUNNERA:18094/` | `http://ADRES_RUNNERA:18094/api/weather?city=Warsaw` |
| `prod` | `http://ADRES_RUNNERA:18095/` | `http://ADRES_RUNNERA:18095/api/weather?city=Warsaw` |

`ADRES_RUNNERA` zastąp adresem lub nazwą hosta self-hosted osiągalną z Twojego
urządzenia. `127.0.0.1` w testach workflow oznacza runner, a nie komputer ucznia.
Sprawdź również, czy wcześniejsze fazy na swoich portach nadal działają.

## Krok 15. Sprawdź ponowienie i zachowanie po błędach

1. Uruchom nowy przebieg bez zmiany kodu i sprawdź użycie cache w jednym wspólnym buildzie.
2. Potwierdź ponowne wykonanie rzeczywistego testu CI.
3. Sprawdź, że trzy deploye zastąpiły tylko swoje kontenery i pozostawiły aplikacje działające.
4. Zmień `FAZA3_WEATHER_CITY` tylko w Environment `dev`, np. na `Gdansk`.
   W kolejnym przebiegu test po deployu `dev` ma użyć nowej wartości.
5. Przeanalizuj w logach zachowanie macierzy i zależności:

| Miejsce błędu | Oczekiwany skutek |
| --- | --- |
| Wspólny `build` | Test, publikacje i deploye nie ruszą |
| Wspólny `test` | Publikacje i deploye nie ruszą |
| Jedna publikacja | Inne publikacje mogą dokończyć pracę; wszystkie deploye są pominięte |
| Jeden deploy | Pozostałe warianty deploya nadal mogą się wykonać; cały workflow pozostaje nieudany |

`fail-fast: false` nie maskuje błędów. Nie dodawaj `continue-on-error`
ani warunków omijających wspólny test lub barierę publikacji.
Kolejność wariantów z `max-parallel: 1` nie zastępuje procesu promocji
ani automatycznego rollbacku.

## Kryteria ukończenia

- Cztery definicje jobów generują osiem uruchomień, z matrix tylko w publikacji i deployu.
- GitHub Environments rozdzielają tagi, porty, kontenery, zmienne i opcjonalne sekrety.
- Build i test są wspólne; cache ma scope `15a-pogoda-faza3`.
- Trzy publikacje używają tego samego przetestowanego obrazu, bez przebudowy.
- Digesty i pozostałe metadane są osobnymi artefaktami wariantów.
- Deploy sprawdza metadane bieżącego przebiegu i namespace kontenera przed jego wymianą.
- Wszystkie publikacje muszą przejść przed deployami; jeden host wykonuje najwyżej jeden wariant deploya tego przebiegu naraz.
- Po zakończeniu działają trzy aplikacje, a tymczasowe poświadczenia Docker są usunięte.

HTTP pozostaje domyślny. Opcjonalne HTTPS korzysta z tego samego mechanizmu
certyfikatu i klucza montowanych tylko do odczytu co w
[FAZIE-1](../FAZA-1/README.md#krok-17-opcjonalnie-uruchom-ten-sam-obraz-z-https).
Dobierz wtedy tag środowiska i osobne, wolne porty.

Przygotowanie plików oraz lokalne sprawdzenie składni nie uruchamiają
GitHub Environments, cache usługi ani deployów. Wynik potwierdź rzeczywistym
przebiegiem GitHub Actions, logami testów i działaniem trzech kontenerów.

Gotowe rozwiązanie: [15A-FAZA3-pogoda.yaml](../../../.github/workflows/15A-FAZA3-pogoda.yaml).
