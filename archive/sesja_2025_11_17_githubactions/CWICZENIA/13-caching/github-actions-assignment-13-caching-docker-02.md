# Assignment: GitHub Actions – Build Docker Image Using actions/cache for Buildx Layers (EN)

## Goal

Create a GitHub Actions workflow that builds a Docker image for a sample project using **Docker Buildx**, and persists Buildx layer cache between runs using **actions/cache**. The final result of this assignment should be a workflow functionally equivalent to the provided `13-chacing-docker-02.yml` workflow file.

---

## Context and assumptions

- You work in an existing repository with GitHub Actions & Docker exercises.
- There are at least two directories related to caching:
  - `./CWICZENIA/13-caching/docker01` – contains the actual Docker project (Dockerfile, static files like `index.html`, etc.).
  - `./CWICZENIA/13-caching/docker02` – used as the logical working directory for this exercise and for storing the workflow-related files.
- The Docker image is built **only inside CI**; it is **not pushed** to any external registry.
- Build performance is improved by caching the **Buildx layers** in a local directory and then persisting that directory using **actions/cache**.

---

## Requirements – step by step

### 1. Create the workflow file

Create a new workflow file in the repository under:

- `.github/workflows/13-chacing-docker-02.yml` (or an equivalent name provided in the exercise).

Set the workflow name to clearly describe what it does, for example:

- `13-02 Build Docker image with actions/cache 02`

This name should suggest that the workflow builds a Docker image and uses **actions/cache** to store Buildx layers.

---

### 2. Configure workflow triggers

Configure the workflow to be triggered in the following situations:

1. **On pushes to a specific branch**:
   - Only for the branch: `cw13`.
2. **On all pull requests**:
   - Any `pull_request` event, regardless of the source branch.
3. **Manual runs**:
   - Add support for `workflow_dispatch` so that the workflow can be run manually from the GitHub UI.

This ensures that the workflow is useful both for regular development (push/PR) and for ad‑hoc testing (manual trigger).

---

### 3. Global defaults for shell and working directory

Use the `defaults.run` section to define **global defaults** for all `run` steps in the workflow:

- `shell: bash` – all shell commands should use the Bash shell.
- `working-directory: ./CWICZENIA/13-caching/docker02` – the default working directory for shell commands should point to the `docker02` exercise directory.

> Note: Even though the build context for Docker will later point to `docker01`, the logical working directory for script steps in this assignment is `docker02`. This demonstrates that the workflow can operate from one directory while building a Docker image from another.

---

### 4. Define a single job

Create a single job called, for example, `build` with the following configuration:

- The job must run on:
  - `ubuntu-latest`

No matrix builds are required – a single Linux runner is enough for this exercise.

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
```

The rest of the steps will be added under this job.

---

### 5. Checkout repository sources

Add the first step in the `build` job responsible for checking out the repository code, so that the workflow has access to the Docker project and all relevant files.

- Use the official GitHub Action:
  - `actions/checkout@v4`
- Give the step a clear name, such as:
  - `Checkout sources`

This step guarantees that subsequent Docker build commands can see the `CWICZENIA/13-caching/docker01` and `CWICZENIA/13-caching/docker02` folders.

---

### 6. Set up Docker Buildx

Add a step that enables **Docker Buildx**, which is required for advanced Docker build features and layer caching.

- Use the official action:
  - `docker/setup-buildx-action@v3`
- Example step name:
  - `Set up Docker Buildx`

This step prepares the runner to use the `docker/build-push-action` with caching.

---

### 7. Configure actions/cache for Buildx layers

The key requirement of this task is to use **actions/cache** to persist the directory that Buildx uses to store its cached layers.

1. **Add a “Cache Docker layers” step** using:
   - `actions/cache@v4`

2. **Configure the path to the cache directory**:
   - Use a location under `/tmp`, for example:
     - `path: /tmp/.buildx-cache`
   - This directory will store Buildx’s local cache and will be reused between workflow runs if the cache is hit.

3. **Define a cache key** that:
   - Depends on the operating system:
     - `runner.os`
   - Changes whenever relevant build inputs change, for example:
     - the `Dockerfile`
     - a static file such as `index.html`
   - An example approach is to use `hashFiles` on those files:
     - `key: ${{ runner.os }}-docker-buildx-${{ hashFiles('Dockerfile', 'index.html') }}`

4. **Define `restore-keys`** so that older cache entries can still be reused when the exact key is not found:
   - For example, use a prefix per operating system:
     - `restore-keys: ${{ runner.os }}-docker-buildx-`

This configuration ensures that:

- Small changes in the Docker build context create new cache entries.
- If there is no exact match, an older cache for the same OS can still be used as a base.

---

### 8. Build Docker image using cached layers

Add the final build step that actually builds the Docker image using the cached Buildx layers.

1. **Use the Docker build action**:
   - `docker/build-push-action@v6`

2. **Configure the build context and Dockerfile**:
   - `context: ./CWICZENIA/13-caching/docker01`
   - `file: ./CWICZENIA/13-caching/docker01/Dockerfile`

   Even though the working directory is `docker02`, this configuration explicitly points the build to the `docker01` project.

3. **Disable pushing to a registry**:
   - `push: false`
   - This workflow is intended only to build the image in CI, not to publish it.

4. **Set a local image tag** to identify the built image, e.g.:
   - `tags: example-nginx:cache-actions-layers`

5. **Connect Buildx to the cached directory** using a **local cache type**:
   - `cache-from: type=local,src=/tmp/.buildx-cache`
   - `cache-to: type=local,dest=/tmp/.buildx-cache,mode=max`

   This tells Buildx to:
   - Read existing cached layers from `/tmp/.buildx-cache`.
   - Write updated layers back to the same directory (`mode=max`), which is then persisted by `actions/cache` between workflow runs.

Give this step a descriptive name, such as:

- `Build Docker image (with cached layers)`

---

## Acceptance criteria

The solution is considered correct if all of the following are true:

1. The workflow file is located in the `.github/workflows` directory and has a clear name (e.g. `13-chacing-docker-02.yml`).
2. The workflow is triggered:
   - on pushes to the `cw13` branch,
   - on all `pull_request` events,
   - and manually via `workflow_dispatch`.
3. Global defaults are set using `defaults.run`:
   - `shell: bash`
   - `working-directory: ./CWICZENIA/13-caching/docker02`
4. There is a single job named `build` that runs on `ubuntu-latest`.
5. The job contains, in order:
   - A checkout step using `actions/checkout@v4`.
   - A Buildx setup step using `docker/setup-buildx-action@v3`.
   - A cache step using `actions/cache@v4` that:
     - caches `/tmp/.buildx-cache`,
     - uses a key based on `runner.os` and the hash of `Dockerfile` and `index.html`,
     - specifies a suitable `restore-keys` prefix.
   - A Docker build step using `docker/build-push-action@v6` with:
     - `context` and `file` pointing to `./CWICZENIA/13-caching/docker01`,
     - `push: false`,
     - `tags: example-nginx:cache-actions-layers`,
     - `cache-from: type=local,src=/tmp/.buildx-cache`,
     - `cache-to: type=local,dest=/tmp/.buildx-cache,mode=max`.
6. When the workflow runs multiple times with unchanged build inputs, subsequent runs are noticeably faster thanks to the reuse of cached Buildx layers via `actions/cache`.

---

# Zadanie: GitHub Actions – budowanie obrazu Docker z wykorzystaniem actions/cache dla warstw Buildx (PL)

## Cel

Stwórz workflow GitHub Actions, który buduje obraz Dockera dla przykładowego projektu z użyciem **Docker Buildx** oraz utrwala cache warstw Buildx pomiędzy uruchomieniami za pomocą **actions/cache**. Końcowym wynikiem zadania ma być workflow funkcjonalnie zgodny z dostarczonym plikiem `13-chacing-docker-02.yml`.

---

## Kontekst i założenia

- Pracujesz w istniejącym repozytorium z ćwiczeniami z GitHub Actions i Dockera.
- W repozytorium znajdują się co najmniej dwa katalogi związane z cachingiem:
  - `./CWICZENIA/13-caching/docker01` – zawiera właściwy projekt Docker (Dockerfile, pliki statyczne, np. `index.html` itp.).
  - `./CWICZENIA/13-caching/docker02` – wykorzystywany jako katalog roboczy w tym zadaniu oraz miejsce powiązane z workflow.
- Obraz Dockera jest budowany **wyłącznie w CI** i **nie jest** wypychany do zewnętrznego rejestru.
- Przyspieszenie buildów osiągamy poprzez cache’owanie **warstw Buildx** w lokalnym katalogu i utrwalanie tego katalogu między uruchomieniami za pomocą **actions/cache**.

---

## Wymagania – krok po kroku

### 1. Utworzenie pliku workflow

Utwórz nowy plik workflow w repozytorium, w lokalizacji:

- `.github/workflows/13-chacing-docker-02.yml` (lub innej, wskazanej w treści ćwiczenia).

Ustaw nazwę workflow tak, aby jasno opisywała jego cel, np.:

- `13-02 Build Docker image with actions/cache 02`

Nazwa powinna sugerować, że workflow buduje obraz Dockera i wykorzystuje **actions/cache** do przechowywania warstw Buildx.

---

### 2. Konfiguracja wyzwalaczy workflow

Skonfiguruj workflow tak, aby uruchamiał się w następujących sytuacjach:

1. **Dla pushy na konkretną gałąź**:
   - tylko dla gałęzi `cw13`.
2. **Dla wszystkich pull requestów**:
   - każde zdarzenie `pull_request`, niezależnie od gałęzi źródłowej.
3. **Dla ręcznych uruchomień**:
   - dodaj obsługę `workflow_dispatch`, aby można było uruchomić workflow ręcznie z poziomu interfejsu GitHub.

Dzięki temu workflow będzie użyteczny zarówno w standardowym procesie developmentu (push/PR), jak i do testów ad‑hoc (ręczne uruchomienie).

---

### 3. Globalne ustawienia powłoki i katalogu roboczego

Skorzystaj z sekcji `defaults.run`, aby zdefiniować **globalne domyślne ustawienia** dla wszystkich kroków `run` w workflow:

- `shell: bash` – wszystkie polecenia shellowe mają być wykonywane w powłoce Bash.
- `working-directory: ./CWICZENIA/13-caching/docker02` – domyślny katalog roboczy dla kroków `run` ma wskazywać na katalog ćwiczenia `docker02`.

> Uwaga: Mimo że kontekst builda Dockera będzie później wskazywał na `docker01`, w tym zadaniu katalog roboczy dla poleceń skryptowych to `docker02`. Pokazuje to, że workflow może działać z jednego katalogu, a obraz budować z innego.

---

### 4. Definicja pojedynczego joba

Zdefiniuj pojedynczy job o nazwie, np. `build`, z następującą konfiguracją:

- Job musi być wykonywany na maszynie:
  - `ubuntu-latest`

Nie jest wymagana żadna macierz systemów – wystarczy jeden runner Linux.

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
```

W tym jobie dodasz kolejne kroki.

---

### 5. Checkout źródeł repozytorium

Dodaj pierwszy krok w jobie `build`, odpowiedzialny za pobranie kodu z repozytorium, tak aby workflow miał dostęp do projektu Docker oraz wszystkich potrzebnych plików.

- Użyj oficjalnej akcji GitHub:
  - `actions/checkout@v4`
- Nadaj krokowi czytelną nazwę, np.:
  - `Checkout sources`

Krok ten zapewni, że kolejne kroki (w tym build Dockera) będą „widziały” katalogi `CWICZENIA/13-caching/docker01` oraz `CWICZENIA/13-caching/docker02`.

---

### 6. Konfiguracja Docker Buildx

Dodaj krok, który włączy **Docker Buildx**, konieczny do korzystania z zaawansowanych funkcji builda i cache’owania warstw.

- Użyj oficjalnej akcji:
  - `docker/setup-buildx-action@v3`
- Przykładowa nazwa kroku:
  - `Set up Docker Buildx`

Ten krok przygotowuje runner do użycia `docker/build-push-action` z konfiguracją cache.

---

### 7. Konfiguracja actions/cache dla warstw Buildx

Kluczowy element zadania polega na użyciu **actions/cache** do utrwalania katalogu, w którym Buildx przechowuje cache warstw.

1. **Dodaj krok „Cache Docker layers”** wykorzystujący:
   - `actions/cache@v4`

2. **Skonfiguruj ścieżkę do katalogu cache**:
   - Użyj katalogu pod `/tmp`, np.:
     - `path: /tmp/.buildx-cache`
   - Katalog ten będzie przechowywał lokalny cache Buildx i będzie ponownie używany między uruchomieniami workflow, jeśli cache zostanie odnaleziony.

3. **Zdefiniuj klucz cache (`key`)**, który:
   - zależy od systemu operacyjnego:
     - `runner.os`,
   - zmienia się, gdy zmieni się istotny input builda, np.:
     - plik `Dockerfile`,
     - plik statyczny `index.html`,
   - przykładowo możesz użyć `hashFiles` dla tych plików:
     - `key: ${{ runner.os }}-docker-buildx-${{ hashFiles('Dockerfile', 'index.html') }}`

4. **Ustal `restore-keys`**, aby możliwe było wykorzystanie starszego cache, gdy dokładny klucz nie zostanie odnaleziony:
   - np. prefiks per system operacyjny:
     - `restore-keys: ${{ runner.os }}-docker-buildx-`

Dzięki takiej konfiguracji:

- Niewielkie zmiany w kontekście builda powodują utworzenie nowych wpisów cache.
- Jeśli nie ma idealnego dopasowania klucza, workflow może skorzystać ze starszego cache dla tego samego systemu operacyjnego.

---

### 8. Budowanie obrazu Dockera z wykorzystaniem zcache’owanych warstw

Dodaj końcowy krok, który faktycznie zbuduje obraz Dockera z wykorzystaniem zcache’owanych warstw Buildx.

1. **Użyj akcji do builda Dockera**:
   - `docker/build-push-action@v6`

2. **Skonfiguruj kontekst builda oraz Dockerfile**:
   - `context: ./CWICZENIA/13-caching/docker01`
   - `file: ./CWICZENIA/13-caching/docker01/Dockerfile`

   Mimo że katalog roboczy to `docker02`, te ustawienia wprost wskazują, że obraz ma zostać zbudowany z projektu w `docker01`.

3. **Wyłącz wypychanie obrazu do rejestru**:
   - `push: false`
   - Workflow ma jedynie zbudować obraz w środowisku CI, bez jego publikacji.

4. **Ustaw lokalny tag obrazu**, np.:
   - `tags: example-nginx:cache-actions-layers`

5. **Połącz Buildx z katalogiem cache** przy użyciu **lokalnego typu cache**:
   - `cache-from: type=local,src=/tmp/.buildx-cache`
   - `cache-to: type=local,dest=/tmp/.buildx-cache,mode=max`

   Informuje to Buildx, aby:
   - odczytywał istniejący cache warstw z katalogu `/tmp/.buildx-cache`,
   - zapisywał zaktualizowany cache ponownie w tym katalogu (`mode=max`), który następnie jest utrwalany przez `actions/cache` między kolejnymi uruchomieniami workflow.

Nazwij ten krok jednoznacznie, np.:

- `Build Docker image (with cached layers)`

---

## Kryteria akceptacji

Rozwiązanie zostanie uznane za poprawne, jeśli spełnione będą wszystkie poniższe warunki:

1. Plik workflow znajduje się w katalogu `.github/workflows` i ma czytelną nazwę (np. `13-chacing-docker-02.yml`).
2. Workflow jest uruchamiany:
   - dla pushy na gałąź `cw13`,
   - dla wszystkich zdarzeń `pull_request`,
   - ręcznie poprzez `workflow_dispatch`.
3. Sekcja `defaults.run` ustawia globalnie:
   - `shell: bash`,
   - `working-directory: ./CWICZENIA/13-caching/docker02`.
4. Zdefiniowany jest pojedynczy job `build` działający na `ubuntu-latest`.
5. W jobie znajdują się, w podanej kolejności, kroki:
   - checkout repozytorium z użyciem `actions/checkout@v4`,
   - konfiguracja Buildx z użyciem `docker/setup-buildx-action@v3`,
   - konfiguracja cache z użyciem `actions/cache@v4`, który:
     - cache’uje katalog `/tmp/.buildx-cache`,
     - używa klucza opartego o `runner.os` i hash plików `Dockerfile` oraz `index.html`,
     - posiada sensowny prefiks `restore-keys`,
   - build obrazu Dockera z użyciem `docker/build-push-action@v6`, z ustawionymi polami:
     - `context` i `file` wskazującymi na `./CWICZENIA/13-caching/docker01`,
     - `push: false`,
     - `tags: example-nginx:cache-actions-layers`,
     - `cache-from: type=local,src=/tmp/.buildx-cache`,
     - `cache-to: type=local,dest=/tmp/.buildx-cache,mode=max`.
6. Wielokrotne uruchomienie workflow przy niezmienionych inputach builda powoduje zauważalne skrócenie czasu builda dzięki ponownemu wykorzystaniu cache warstw Buildx utrwalanych przez `actions/cache`.
