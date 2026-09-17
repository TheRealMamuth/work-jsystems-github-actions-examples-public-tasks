# Assignment: GitHub Actions – Build Docker Image with Cache (EN)

## Goal

Create a GitHub Actions workflow that builds a Docker image for a sample project and uses **GitHub Actions cache for Docker builds** (BuildKit cache stored in GitHub Actions). The final result of this assignment must be a workflow functionally equivalent to the provided file `13-chacing-docker-01.yml`.

---

## Context and assumptions

- You are working in an existing repository that contains exercises for GitHub Actions and Docker.
- The project for this task is located in the directory:  
  `./CWICZENIA/13-caching/docker01`
- Inside this directory there is a `Dockerfile` that builds a simple image (for example a small Nginx-based image or similar demo HTTP service).
- You **do not** push the image to any external registry in this exercise – you only build it locally in the CI environment, while using cache to speed up subsequent builds.

---

## Requirements – step by step

### 1. Workflow triggers

Create a new workflow file in the repository, for example at:  
`.github/workflows/13-caching-docker-01.yml`

Configure the workflow so that it is triggered:

1. On `push` events **only for the branch**:
   - `cw13`
2. On **all** `pull_request` events (for any branch).
3. On manual runs using:
   - `workflow_dispatch`

Give the workflow a descriptive name, e.g.:  
`13-01 Build Docker image with cache 01`

---

### 2. Default shell and working directory

Configure global defaults for all `run` steps in the workflow using the `defaults.run` section so that:

- The default shell is **bash**.
- The default working directory is the project directory for this exercise:
  - `./CWICZENIA/13-caching/docker01`

This ensures that all shell commands in `run:` steps are executed from the correct folder without having to repeat `working-directory` in each step.

---

### 3. Single job definition

Define a single job named, for example, `build`:

- The job must run on the virtual machine:
  - `ubuntu-latest`

You do **not** need any matrix of operating systems or Node versions. One Linux runner is enough.

Example skeleton:

- `jobs.build.runs-on: ubuntu-latest`

---

### 4. Checkout repository sources

Inside the `build` job, the first step must check out the repository sources so that the workflow can access the Dockerfile and project files.

- Use the official GitHub Action:
  - `actions/checkout` in **major version 4** (`actions/checkout@v4`)
- Give the step a clear name, e.g. `Checkout sources`.

This step is required so that subsequent Docker commands can see the `CWICZENIA/13-caching/docker01` directory.

---

### 5. Set up Docker Buildx (optional but recommended)

Add a step that configures **Docker Buildx**, which is required for advanced BuildKit features – including caching.

- Use the official action:
  - `docker/setup-buildx-action@v3`
- Give the step a descriptive name, e.g. `Set up Docker Buildx`.

Even if technically optional for very simple builds, this is considered a good practice when using `docker/build-push-action` with cache settings.

---

### 6. Build Docker image with GitHub Actions cache

Add a key step that builds the Docker image using `docker/build-push-action` and enables Docker-layer caching stored in GitHub Actions.

Requirements:

1. **Action**
   - Use the action:
     - `docker/build-push-action@v6`

2. **Context and Dockerfile**
   - Set the build context (`context`) to the project directory:
     - `./CWICZENIA/13-caching/docker01`
   - Set the Dockerfile path (`file`) to:
     - `./CWICZENIA/13-caching/docker01/Dockerfile`

3. **Image publishing**
   - Do **not** push the image to any registry.
   - Set:
     - `push: false`
   - Assign a local tag for identification, e.g.:
     - `tags: example-nginx:latest`

4. **Build cache configuration**
   - Configure the action to **use GitHub Actions cache** for Docker layers by using the `gha` cache type:
     - `cache-from: type=gha`
     - `cache-to: type=gha,mode=max`
   - This setup ensures that:
     - BuildKit stores intermediate layers in GitHub’s cache.
     - Future runs of the workflow can **reuse** these layers, which accelerates subsequent Docker builds.

Give this step a clear name, e.g.:  
`Build Docker image (with cache)`

---

## Acceptance criteria

Your workflow will be considered correct if:

1. It is stored in the `.github/workflows` directory and has a descriptive name (e.g. `13-caching-docker-01.yml`).
2. It is triggered:
   - on pushes to the `cw13` branch,
   - on all `pull_request` events,
   - and manually via `workflow_dispatch`.
3. It defines a single job `build` that runs on `ubuntu-latest`.
4. It uses `defaults.run` to set:
   - `shell: bash`,
   - `working-directory: ./CWICZENIA/13-caching/docker01`.
5. It contains the following steps, in order:
   - Checkout of the repository with `actions/checkout@v4`.
   - Setup of Docker Buildx with `docker/setup-buildx-action@v3`.
   - Docker image build using `docker/build-push-action@v6` with:
     - `context` and `file` pointing to `./CWICZENIA/13-caching/docker01`,
     - `push: false`,
     - `tags: example-nginx:latest`,
     - `cache-from: type=gha` and `cache-to: type=gha,mode=max`.
6. A successful run of the workflow results in a locally built Docker image (not published to a registry) and visible usage of the GitHub Actions Docker cache between runs.

---

# Zadanie: GitHub Actions – budowanie obrazu Docker z cache (PL)

## Cel

Stwórz workflow GitHub Actions, który buduje obraz Dockera dla przykładowego projektu oraz wykorzystuje **cache BuildKit przechowywany w GitHub Actions**. Końcowym rezultatem zadania ma być workflow funkcjonalnie zgodny z plikiem `13-chacing-docker-01.yml`.

---

## Kontekst i założenia

- Pracujesz w istniejącym repozytorium zawierającym ćwiczenia z GitHub Actions i Dockera.
- Projekt do tego zadania znajduje się w katalogu:  
  `./CWICZENIA/13-caching/docker01`
- W tym katalogu znajduje się plik `Dockerfile`, który buduje prosty obraz (np. bazujący na Nginx albo innym demo serwerze HTTP).
- W tym zadaniu **nie publikujesz** obrazu do zewnętrznego rejestru – obraz ma być jedynie zbudowany lokalnie w środowisku CI, z wykorzystaniem cache w celu przyspieszenia kolejnych buildów.

---

## Wymagania – krok po kroku

### 1. Wyzwalacze workflow

Utwórz nowy plik workflow w repozytorium, np. w lokalizacji:  
`.github/workflows/13-caching-docker-01.yml`

Skonfiguruj workflow tak, aby uruchamiał się:

1. Dla zdarzeń `push` **tylko na gałęzi**:
   - `cw13`
2. Dla **wszystkich** zdarzeń `pull_request` (z dowolnych gałęzi).
3. Dla ręcznych uruchomień za pomocą:
   - `workflow_dispatch`

Nadaj workflowowi opisową nazwę, np.:  
`13-01 Build Docker image with cache 01`

---

### 2. Domyślna powłoka i katalog roboczy

Skonfiguruj globalne domyślne ustawienia dla wszystkich kroków `run` w sekcji `defaults.run` tak, aby:

- Domyślną powłoką była **bash**.
- Domyślnym katalogiem roboczym był katalog projektu używany w tym zadaniu:
  - `./CWICZENIA/13-caching/docker01`

Dzięki temu wszystkie polecenia w `run:` będą domyślnie wykonywane w odpowiednim katalogu, bez konieczności powtarzania `working-directory` w każdym kroku.

---

### 3. Definicja pojedynczego joba

Zdefiniuj pojedynczy job, np. o nazwie `build`:

- Job musi być wykonywany na maszynie wirtualnej:
  - `ubuntu-latest`

Nie potrzebujesz żadnej macierzy systemów ani dodatkowych konfiguracji – wystarczy jeden runner Linux.

Przykładowy szkielet:

- `jobs.build.runs-on: ubuntu-latest`

---

### 4. Checkout źródeł repozytorium

W jobie `build` pierwszym krokiem powinno być pobranie kodu z repozytorium, tak aby workflow miał dostęp do pliku Dockerfile oraz pozostałych plików projektu.

- Użyj oficjalnej akcji GitHub:
  - `actions/checkout` w wersji **major 4** (`actions/checkout@v4`)
- Nadaj krokowi czytelną nazwę, np. `Checkout sources`.

Ten krok jest niezbędny, aby kolejne kroki mogły zbudować obraz z katalogu `CWICZENIA/13-caching/docker01`.

---

### 5. Konfiguracja Docker Buildx (opcjonalnie, ale zalecane)

Dodaj krok konfigurujący **Docker Buildx**, który jest potrzebny do korzystania z zaawansowanych funkcji BuildKit – w tym cache’owania.

- Użyj akcji:
  - `docker/setup-buildx-action@v3`
- Nazwij krok w sposób opisowy, np. `Set up Docker Buildx`.

Choć w prostych przypadkach build mógłby zadziałać bez tego kroku, jest on dobrą praktyką przy korzystaniu z `docker/build-push-action` i konfiguracji cache.

---

### 6. Budowanie obrazu Docker z cache GitHub Actions

Dodaj kluczowy krok, który zbuduje obraz Dockera z użyciem akcji `docker/build-push-action` oraz włączy wykorzystanie cache’a warstw Dockera przechowywanego w GitHub Actions.

Wymagania:

1. **Akcja**
   - Użyj akcji:
     - `docker/build-push-action@v6`

2. **Kontekst i Dockerfile**
   - Ustaw kontekst budowania (`context`) na katalog projektu:
     - `./CWICZENIA/13-caching/docker01`
   - Ustaw ścieżkę do pliku Dockerfile (`file`) na:
     - `./CWICZENIA/13-caching/docker01/Dockerfile`

3. **Publikacja obrazu**
   - **Nie** publikuj obrazu do żadnego rejestru.
   - Ustaw:
     - `push: false`
   - Nadaj obrazowi lokalny tag, np.:
     - `tags: example-nginx:latest`

4. **Konfiguracja cache builda**
   - Skonfiguruj akcję tak, aby korzystała z **cache’a GitHub Actions** dla warstw Dockera, używając typu `gha`:
     - `cache-from: type=gha`
     - `cache-to: type=gha,mode=max`
   - Dzięki temu:
     - BuildKit zapisuje pośrednie warstwy w cache GitHub Actions,
     - kolejne uruchomienia workflow mogą **ponownie wykorzystać** te warstwy, co znacznie przyspiesza czas budowania.

Nazwij ten krok w sposób jednoznaczny, np.:  
`Build Docker image (with cache)`

---

## Kryteria akceptacji

Workflow zostanie uznany za poprawny, jeśli:

1. Znajduje się w katalogu `.github/workflows` i ma opisową nazwę (np. `13-caching-docker-01.yml`).
2. Jest wyzwalany:
   - dla pushy na gałąź `cw13`,
   - dla wszystkich zdarzeń `pull_request`,
   - ręcznie poprzez `workflow_dispatch`.
3. Definiuje pojedynczy job `build` działający na `ubuntu-latest`.
4. Wykorzystuje `defaults.run` do ustawienia:
   - `shell: bash`,
   - `working-directory: ./CWICZENIA/13-caching/docker01`.
5. Zawiera następujące kroki, w podanej kolejności:
   - Checkout repozytorium z użyciem `actions/checkout@v4`,
   - Konfiguracja Docker Buildx za pomocą `docker/setup-buildx-action@v3`,
   - Budowa obrazu Dockera z wykorzystaniem `docker/build-push-action@v6`, z ustawionymi polami:
     - `context` i `file` wskazującymi na `./CWICZENIA/13-caching/docker01`,
     - `push: false`,
     - `tags: example-nginx:latest`,
     - `cache-from: type=gha` i `cache-to: type=gha,mode=max`.
6. Poprawne wykonanie workflow skutkuje lokalnie zbudowanym obrazem Dockera (bez publikacji do rejestru) oraz widocznym wykorzystaniem cache GitHub Actions pomiędzy kolejnymi uruchomieniami builda.
