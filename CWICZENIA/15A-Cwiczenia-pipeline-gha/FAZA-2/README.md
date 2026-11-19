# FAZA-2 — Cache warstw Docker w GitHub Actions

## Cel ćwiczenia

Rozszerz pipeline z [FAZY-1](../FAZA-1/README.md) o cache warstw Docker
przechowywany w GitHub Actions. Rezultatem ma być nowy workflow
`.github/workflows/15A-FAZA2-pogoda.yaml`, który przy kolejnych budowaniach
może ponownie wykorzystać zgodne warstwy, zamiast wykonywać wszystkie instrukcje.

Zachowaj cztery joby: `build` → `test` → `build-and-push` → `deploy`.
Test nadal używa prawdziwego klucza OpenWeatherMap. Publikacja nadal wysyła
dokładnie obraz przetestowany w tym przebiegu, a deploy pobiera go po digescie.

## Krok 1. Przygotuj osobny workflow FAZY-2

1. Skopiuj `.github/workflows/15A-FAZA-1-pogoda.yaml` do
   `.github/workflows/15A-FAZA2-pogoda.yaml`.
2. Nazwij workflow `15A FAZA-2 — Cache warstw Docker`.
3. Pozostaw wyzwalacze `workflow_dispatch` oraz `push` na `main`.
   W filtrze `paths` wskaż katalog aplikacji oraz nowy plik YAML.
4. Nadal buduj aplikację z
   `CWICZENIA/15A-Cwiczenia-pipeline-gha/pogoda_python_flusk`.
5. Nie modyfikuj pipeline FAZY-1 ani plików aplikacji, aby dodać sam cache.

Rozdziel nazwy obu faz:

| Element | Wartość dla FAZY-2 |
| --- | --- |
| Tag obrazu | `faza2` |
| Tymczasowy tag obrazu CI | `ci-faza2-<github.sha>` |
| Artefakt obrazu | `faza2-weather-image` |
| Kontener CI | `pogoda_api_faza2_ci` |
| Kontener na self-hosted | `pogoda_api_faza2` |
| Port HTTP hosta | `18092` → `8080` w kontenerze |
| Grupa `concurrency` deploya | `pogoda-faza2-deploy` |

Port `18092` pozwala pozostawić uruchomioną FAZĘ-1 na `18090`
oraz jej opcjonalny przykład HTTP/HTTPS na `18091`/`18443`.
Przed pierwszym deployem upewnij się, że port `18092` jest wolny na hoście
runnera i dostępny z Twojego urządzenia przez właściwe reguły sieci oraz zapory.

## Krok 2. Ustaw Variables i zachowaj Secrets

W **Settings → Secrets and variables → Actions → Variables** utwórz
lub sprawdź poniższe Repository variables:

| Nazwa | Wartość początkowa |
| --- | --- |
| `DOCKERHUB_USERNAME` | `piotrskoska` albo Twój login Docker Hub |
| `DOCKER_IMAGE_NAME` | `python_pogoda` |
| `FAZA2_IMAGE_TAG` | `faza2` |
| `FAZA2_APP_PORT` | `18092` |
| `FAZA2_CONTAINER_NAME` | `pogoda_api_faza2` |
| `FAZA2_WEATHER_CITY` | `Warsaw` |
| `FAZA2_DEPLOY_BRANCH` | `main` |

W zakładce **Secrets** pozostają te same dwa Repository secrets co w FAZIE-1:

| Sekret | Wartość |
| --- | --- |
| `DOCKERHUB_TOKEN` | Twój token Docker Hub z prawem publikacji obrazu |
| `OPENWEATHER_API_KEY` | Twój prawdziwy, aktywny klucz API OpenWeatherMap |

Nie kopiuj wartości klucza do plików. Nadal przekazuj go wyłącznie
do uruchamianego kontenera przez `docker run -e OPENWEATHER_API_KEY`.
Cache nie wymaga nowego sekretu ani osobnego PAT.

## Krok 3. Przygotuj Buildx do obsługi cache

W jobie `build`, w kroku `docker/setup-buildx-action@v3`, dodaj `with`
z dwoma ustawieniami:

```yaml
- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3
  with:
    version: latest
    driver: docker-container
```

`version: latest` wybiera aktualny Buildx, a `docker-container` uruchamia
builder obsługujący wybrany backend cache. Używamy GitHub Cache API v2;
starsze API v1 zostało wyłączone. Wymagania narzędzi opisuje
[dokumentacja cache w GitHub Actions](https://docs.docker.com/build/ci/github-actions/cache/).

## Krok 4. Dodaj import i eksport warstw

W istniejącym kroku `docker/build-push-action@v6` zachowaj `context`, `tags`,
`load: true` i `push: false`. Dodaj tylko dwie pozycje cache:

```diff
           load: true
           push: false
+          cache-from: type=gha,version=2,scope=15a-pogoda-faza2
+          cache-to: type=gha,version=2,scope=15a-pogoda-faza2,mode=max
```

- `cache-from` odczytuje dostępne warstwy z GitHub Actions.
- `cache-to` zapisuje cache dla kolejnych przebiegów.
- `scope=15a-pogoda-faza2` rozdziela cache tego ćwiczenia od innych obrazów.
- `mode=max` eksportuje także warstwy pośrednie.

Scope ma być identyczny w obu pozycjach i stały między przebiegami.
Nie dopisuj do niego `github.sha`, numeru przebiegu ani daty.
Znaczenie tych parametrów opisuje
[backend GitHub Actions cache](https://docs.docker.com/build/cache/backends/gha/).

## Krok 5. Zachowaj przekazywanie obrazu jako artefaktu

1. Po budowaniu nadal wykonaj `docker save` do `image.tar`.
2. Prześlij artefakt `faza2-weather-image`.
3. W `test` pobierz go, wykonaj `docker load` i uruchom kontener.
4. Po poprawnym teście w `build-and-push` pobierz i załaduj ten sam artefakt.
5. Publikuj go przez `docker tag` i `docker push`, bez kolejnego budowania.

| Mechanizm | Rola w tym ćwiczeniu |
| --- | --- |
| Cache warstw | Przyspiesza kolejne wykonania `build` |
| Artefakt `image.tar` | Przenosi gotowy obraz między jobami bieżącego przebiegu |
| Digest publikacji | Wskazuje dokładny obraz pobierany podczas deploya |

Cache nie zastępuje artefaktu i nie jest potwierdzeniem przejścia testów.
Nie dodawaj warunku pomijającego `test` po trafieniu w cache.

## Krok 6. Zachowaj bezpieczny test, publikację i deploy

1. Wspólny test WWW i API ma za każdym razem pobrać prawdziwą pogodę,
   używając sekretu przekazanego do kontenera podczas uruchomienia.
2. Nie przekazuj sekretu do `build-args`, ustawień cache ani akcji budowania.
3. Publikacja ma działać dopiero po poprawnym teście, dla dopuszczonej gałęzi.
4. Przekazuj sam `image_digest` z publikacji do deploya.
5. Na self-hosted pobierz obraz po digescie przed usunięciem poprzedniego kontenera.
6. Wymieniaj tylko `pogoda_api_faza2`, używając portu `18092:8080`.
7. Zachowaj test po deployu oraz pozostaw działający kontener.
8. Zachowaj prywatny tymczasowy `DOCKER_CONFIG`, jawne `docker logout`
   i usuwanie poświadczeń w kroku `if: always()`. Prefiks katalogu ma dotyczyć FAZY-2.

Do konfiguracji `type=gha` w `docker/build-push-action` nie dodawaj
`actions/cache`, własnych URL usługi ani ręcznie przekazanego tokenu cache.
Akcja uzupełnia dane dostępu do cache podczas wykonania workflow.
[Opis uwierzytelniania backendu](https://docs.docker.com/build/cache/backends/gha/#authentication).

## Krok 7. Wykonaj pierwszy przebieg

1. Udostępnij nowy YAML na GitHub na gałęzi `main`.
2. W **Actions** wybierz `15A FAZA-2 — Cache warstw Docker`.
3. Kliknij **Run workflow**, wybierz `main` i uruchom pipeline.
4. W jobie `build` otwórz krok budowania obrazu.
5. Dla nowego scope obserwuj wykonywanie instrukcji Dockerfile, w tym
   instalację pakietów systemowych i zależności Pythona.
6. Na końcu logu sprawdź eksport cache do GitHub Actions.
7. Potwierdź poprawne zakończenie wszystkich czterech jobów.

Pierwszy przebieg dla nowego scope tworzy cache tej fazy. Nie pomijaj
rzeczywistego testu API, aby szybciej zakończyć napełnianie cache.

## Krok 8. Wykonaj drugi przebieg bez zmian

1. Nie zmieniaj Dockerfile, kodu, zależności ani scope.
2. Ponownie wybierz **Run workflow** na tej samej gałęzi `main`.
3. W logu `build` sprawdź import zapisanych warstw.
4. Porównaj instrukcje instalujące pakiety: zgodne warstwy powinny mieć
   oznaczenie `CACHED`, zamiast ponownego wykonywania `apt-get` i `pip install`.
5. Zanotuj czas kroku budowania w obu przebiegach i wskaż ponownie użyte warstwy.
6. Potwierdź, że pomimo wykorzystania cache ponownie uruchomiono test kontenera,
   publikację i deploy.

Porównuj przede wszystkim krok budowania. Pobieranie obrazu bazowego,
przesyłanie artefaktu, prawdziwe zapytanie pogodowe i publikacja nadal mogą
zajmować czas. Cache nie oznacza budowania w zero sekund.

## Krok 9. Sprawdź wpływ zmiany plików

Po udanych dwóch przebiegach wykonaj osobne eksperymenty szkoleniowe:

| Zmiana | Czego szukać w logu następnego builda |
| --- | --- |
| Tylko `static/styles.css` | Instalacja pakietów może pozostać `CACHED`; zmienia się warstwa kopiująca pliki interfejsu i zależne od niej kroki |
| `requirements.txt` | Ponowne wykonanie instalacji zależności Pythona i kolejnych zależnych warstw |
| Instrukcja w Dockerfile | Ponowne wykonanie zmienionego kroku i zależnych kroków; wcześniejsze zgodne warstwy mogą zostać użyte |
| Inny obraz bazowy lub jego digest | Przebudowa zależnych warstw, nawet gdy kod aplikacji pozostał bez zmian |

Nie zmieniaj scope w tych eksperymentach. Sprawdź, jak BuildKit wybiera warstwy
na podstawie wejść, zamiast oczekiwać ponownego użycia całego obrazu bez analizy.
Po każdym eksperymencie test WWW i rzeczywistego API nadal musi przejść.
Zasady opisuje [dokumentacja unieważniania cache Docker](https://docs.docker.com/build/cache/invalidation/).

## Krok 10. Sprawdź zapisany cache i gotową aplikację

1. W repozytorium otwórz **Actions → Caches** w sekcji **Management**.
2. Sprawdź wpisy utworzone przez BuildKit: daty utworzenia i ostatniego użycia
   oraz rozmiar. Możesz filtrować listę według gałęzi. Klucze BuildKit mogą
   zawierać dodatkowe identyfikatory, więc nie muszą być samą nazwą scope.
3. Pamiętaj, że cache podlega limitom i polityce usuwania GitHub. Usunięty,
   niedostępny dla danej gałęzi lub niezgodny cache może spowodować kolejne
   pełniejsze budowanie. [Zarządzanie cache w GitHub](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manage-caches).
4. Otwórz `http://ADRES_RUNNERA:18092/`, wpisz miasto i sprawdź pogodę.
5. Sprawdź API pod `http://ADRES_RUNNERA:18092/api/weather?city=Warsaw`.
6. Potwierdź, że kontener FAZY-1 na `18090` nadal działa niezależnie.

HTTP pozostaje domyślny. Opcjonalne HTTPS nadal jest możliwe z tego samego
obrazu przez certyfikat i klucz montowane tylko do odczytu; procedurę znajdziesz
w [kroku 17 FAZY-1](../FAZA-1/README.md#krok-17-opcjonalnie-uruchom-ten-sam-obraz-z-https).

## Kryteria ukończenia i sposób potwierdzenia

- Nowy workflow używa cache `type=gha`, API v2, stałego scope i `mode=max`.
- Pierwszy przebieg zapisuje cache, a drugi pokazuje jego import i zgodne warstwy `CACHED`.
- Zachowane są cztery joby, obraz w artefakcie, test z prawdziwym kluczem,
  publikacja bez przebudowy, deploy po digescie i sprzątanie poświadczeń.
- Zmiana UI pozwala zaobserwować ponowne użycie warstw zależności.
- Aplikacje obu faz mają odrębne tagi, kontenery i porty.

Lokalne sprawdzenie YAML i skryptów potwierdza składnię konfiguracji.
Dowodem działania **cache GitHub Actions** są dopiero logi rzeczywistych
przebiegów na GitHub oraz zapisane wpisy cache; samo lokalne budowanie
nie potwierdza działania backendu `gha`.

Gotowe rozwiązanie: [15A-FAZA2-pogoda.yaml](../../../.github/workflows/15A-FAZA2-pogoda.yaml).
