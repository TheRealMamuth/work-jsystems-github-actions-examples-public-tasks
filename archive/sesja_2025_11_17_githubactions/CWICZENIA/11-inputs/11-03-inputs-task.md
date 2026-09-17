# Task: GitHub Actions – Inputs & Conditional Jobs for Weather API

## Goal

You are given a small **FastAPI-based Weather API** project, Dockerized and ready to run behind Uvicorn.  
The application is located in:

```text
CWICZENIA/07-expressions/pogoda_python_flusk
```

Key project files:

- `app.py` – FastAPI application exposing a `/weather` endpoint.
- `requirements.txt` – Python dependencies (at least `requests`, `fastapi`, `uvicorn[standard]`).
- `Dockerfile` – builds the Docker image running the API service.
- `start.py` – helper script used by the application / container start logic.

Your task is to create a **GitHub Actions workflow** (YAML file) that:

1. Builds a Docker image for this API and stores it as an artifact.
2. Runs tests in a separate job, controlled by **inputs** and **conditions**:
   - The test job should run only when specific conditions are met.
   - The city used in tests should be configurable from workflow inputs.
3. Optionally (based on inputs and branch), builds and **pushes** the image to Docker Hub.
4. Uses **workflow_dispatch inputs** and **expressions** (`if`, logical operators, comparisons) to control:
   - When jobs run.
   - Which city is tested.
   - Which environment name (dev/prod) is used for tagging images.

The final deliverable is a single **workflow YAML file**:

```text
.github/workflows/11-03-inputs.yaml
```

---

## Part 1 – Explore the project

1. Open the repository in your editor (e.g. VS Code).
2. Navigate to:

   ```text
   CWICZENIA/07-expressions/pogoda_python_flusk
   ```

3. Review the project files:

   - `app.py` – exposes a `/weather` endpoint which:
     - Accepts at least a `city` and `api_key` parameter.
     - Uses an environment variable `OPENWEATHER_API_KEY` to access the OpenWeather API.
   - `requirements.txt` – contains at least:
     - `requests`
     - `fastapi`
     - `uvicorn[standard]`
   - `Dockerfile` – builds an image that:
     - Installs dependencies from `requirements.txt`.
     - Starts the FastAPI app on port `8000` (e.g. using `uvicorn`).
   - `start.py` – may be used by the container / app startup logic.

You **do not** need to change these files. Your job is to build a GitHub Actions workflow that uses them.

---

## Part 2 – Create the workflow file

4. In the repository root, ensure the following directory exists:

   ```text
   .github/workflows
   ```

   Create it if it does not exist.

5. Inside `.github/workflows`, create a new file:

   ```text
   11-03-inputs.yaml
   ```

All the following steps describe what must be defined inside this workflow file.

---

## Part 3 – Top-level configuration: triggers, inputs and environment

### 3.1 Workflow name

6. At the top of the file, define a descriptive name, for example:

```yaml
name: 11-03 Pogoda API CI
```

### 3.2 Triggers (`on:`)

7. Configure the workflow to run in three ways:

- On `push` to branches:
  - `feature/07-pogoda-api`
  - `main`
- On `pull_request` targeting:
  - `feature/07-pogoda-api`
- Manually via `workflow_dispatch`, with **inputs**.

Conceptually:

```yaml
on:
  push:
    branches: [ feature/07-pogoda-api, main ]
  pull_request:
    branches: [ feature/07-pogoda-api ]
  workflow_dispatch:
    inputs:
      ...
```

### 3.3 `workflow_dispatch` inputs

8. Under `workflow_dispatch`, define the following inputs:

- `city`:
  - `description`: e.g. `"Miasto dla testu endpointu /weather"`
  - `required`: `false`
  - `default`: `"Warsaw"`
  - `type`: `string`

- `run_tests`:
  - `description`: `"Czy uruchomić job TEST?"`
  - `required`: `false`
  - `default`: `true`
  - `type`: `boolean`

- `run_deploy`:
  - `description`: `"Czy uruchomić job BUILD & PUSH (deploy)?"`
  - `required`: `false`
  - `default`: `false`
  - `type`: `boolean`

- `deploy_env`:
  - `description`: `"Środowisko deployu (tylko dla workflow_dispatch)"`
  - `required`: `false`
  - `default`: `"dev07"`
  - `type`: `choice`
  - `options`: `dev07`, `prod07`

These inputs will later be used in `if:` expressions and in environment variables.

### 3.4 Global `env` variables with expressions

9. Add a top-level `env` section with the following variables:

- `WORKDIR` – path to the application directory:

  ```yaml
  WORKDIR: ./CWICZENIA/07-expressions/pogoda_python_flusk
  ```

- `TEST_IMAGE` – name of the Docker image used for tests only, based on Docker Hub username secret:

  ```yaml
  TEST_IMAGE: ${{ secrets.DOCKERHUB_USERNAME }}/python_pogoda:test
  ```

- `HUB_IMAGE_BASE` – base image name for pushing to Docker Hub:

  ```yaml
  HUB_IMAGE_BASE: ${{ secrets.DOCKERHUB_USERNAME }}/python_pogoda
  ```

- `DEPLOY_ENV` – environment name chosen by a dynamic **expression**:

  - If the event is `workflow_dispatch`: use `inputs.deploy_env`.
  - Otherwise:
    - For `main` branch → `prod07`.
    - For all other branches → `dev07`.

  Use a nested conditional expression pattern:

  ```yaml
  DEPLOY_ENV: ${{ github.event_name == 'workflow_dispatch' && inputs.deploy_env || (github.ref == 'refs/heads/main' && 'prod07' || 'dev07') }}
  ```

This expression demonstrates how to use inputs and branch names to compute a dynamic environment value.

---

## Part 4 – Job 1: BUILD (build and upload image)

10. Under `jobs`, define the first job `build`:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
```

11. Add the following steps to `build`:

### Step 1 – Checkout repository

- `uses: actions/checkout@v4`
- Name the step `Checkout repository`.

### Step 2 – Set up Docker Buildx

- `uses: docker/setup-buildx-action@v3`
- Name the step `Set up Docker Buildx`.

### Step 3 – Build local test image (no push)

- Use `docker/build-push-action@v6`.
- Configure the action using `with:`:

  - `context: ${{ env.WORKDIR }}`
  - `tags: ${{ env.TEST_IMAGE }}`
  - `load: true`
  - `push: false`

This builds the image from the `Dockerfile` in `WORKDIR` and loads it into the local Docker daemon as `TEST_IMAGE`.

### Step 4 – Save image to tar

- Add a `run` step:

  ```bash
  docker save "${{ env.TEST_IMAGE }}" -o image.tar
  ```

### Step 5 – Upload image artifact

- Use `actions/upload-artifact@v4`.
- Configure:
  - `name: pogoda-image`
  - `path: image.tar`

This job produces a reusable Docker image artifact called `pogoda-image`.

---

## Part 5 – Job 2: TEST (conditional test job with inputs)

12. Define a second job `test` that depends on `build`:

```yaml
test:
  runs-on: ubuntu-latest
  needs: build
```

### 5.1 Conditional job execution (`if` with inputs)

13. Add a job-level `if:` expression that controls when the `test` job runs:

- `test` **must run**:

  - Always on `pull_request`.
  - On `push` when the commit message does **not** contain `[skip tests]`.
  - On `workflow_dispatch` only when `inputs.run_tests == true`.

Define:

```yaml
if: >
  github.event_name == 'pull_request' ||
  (github.event_name == 'push' &&
   !contains(github.event.head_commit.message, '[skip tests]')) ||
  (github.event_name == 'workflow_dispatch' &&
   inputs.run_tests == true)
```

### 5.2 Job-level `env`

14. Add a job-level `env` block for `test`:

- `OPENWEATHER_API_KEY` – passed from GitHub secret:

  ```yaml
  OPENWEATHER_API_KEY: ${{ secrets.OPENWEATHER_API_KEY }}
  ```

- `TEST_CITY` – city used for the test:

  - For `workflow_dispatch`: taken from `inputs.city`.
  - For other events: default to `"Warsaw"`.

  ```yaml
  TEST_CITY: ${{ github.event_name == 'workflow_dispatch' && inputs.city || 'Warsaw' }}
  ```

### 5.3 Steps in `test` job

15. Add the following steps to `test`:

#### Step 1 – Download image artifact

- Use `actions/download-artifact@v4`.
- Configure:
  - `name: pogoda-image`

This restores the `image.tar` file.

#### Step 2 – Load Docker image

- `run: docker load -i image.tar`

This recreates the `TEST_IMAGE` in the local Docker daemon.

#### Step 3 – Validate `OPENWEATHER_API_KEY` (only if missing)

- Add a step with:

  ```yaml
  if: env.OPENWEATHER_API_KEY == ''
  ```

- In `run`:

  ```bash
  echo "❌ Brak sekretu OPENWEATHER_API_KEY – testy API nie mogą zostać uruchomione."
  exit 1
  ```

If the secret is not configured, the job fails with a clear message.

#### Step 4 – Run container (only if secret is present)

- Step condition:

  ```yaml
  if: env.OPENWEATHER_API_KEY != ''
  ```

- `run`:

  ```bash
  docker run -d     --name pogoda_api     -p 8000:8000     -e OPENWEATHER_API_KEY="${{ env.OPENWEATHER_API_KEY }}"     "${{ env.TEST_IMAGE }}"
  ```

This starts the container in the background, exposing the API on `http://localhost:8000`.

#### Step 5 – Wait for API to be ready

- Condition:

  ```yaml
  if: env.OPENWEATHER_API_KEY != ''
  ```

- `run`:

  ```bash
  echo "Czekam na start API..."
  sleep 10
  ```

#### Step 6 – Test `/weather` endpoint via curl

- Condition:

  ```yaml
  if: env.OPENWEATHER_API_KEY != ''
  ```

- `run`:

  ```bash
  set -e
  echo "Testowanie endpointu /weather dla miasta: '${{ env.TEST_CITY }}'..."
  curl -f "http://localhost:8000/weather?city=${{ env.TEST_CITY }}&api_key=${{ env.OPENWEATHER_API_KEY }}"
  echo
  echo "OK - endpoint /weather zwrócił odpowiedź 2xx."
  ```

This step fails if the HTTP status is not 2xx or if the API is not working.

#### Step 7 – Show container logs on failure

- Condition:

  ```yaml
  if: failure()
  ```

- `run`:

  ```bash
  echo "Logi kontenera:"
  docker logs pogoda_api || true
  ```

This prints container logs to aid debugging when previous steps failed.

#### Step 8 – Stop and remove container (always)

- Condition:

  ```yaml
  if: always()
  ```

- `run`:

  ```bash
  docker stop pogoda_api || true
  docker rm pogoda_api || true
  ```

This ensures the container is cleaned up regardless of success or failure.

---

## Part 6 – Job 3: BUILD & PUSH (optional deploy job)

16. Define a third job `build-and-push` that depends on `test`:

```yaml
build-and-push:
  runs-on: ubuntu-latest
  needs: test
```

### 6.1 Conditional execution based on event and inputs

17. Add a job-level `if:` expression:

- `build-and-push` should run in **two cases**:

  1. `push` to `main` on non-fork repository (standard release case).
  2. `workflow_dispatch` when `inputs.run_deploy == true` (manual deployment trigger).

Use:

```yaml
if: >
  (github.event_name == 'push' &&
   github.ref == 'refs/heads/main' &&
   github.event.repository.fork == false) ||
  (github.event_name == 'workflow_dispatch' &&
   inputs.run_deploy == true)
```

### 6.2 Steps in `build-and-push` job

18. Add the following steps:

#### Step 1 – Checkout repository

- `uses: actions/checkout@v4`
- Name it `Checkout repository`.

#### Step 2 – Set up Docker Buildx

- `uses: docker/setup-buildx-action@v3`
- Name it `Set up Docker Buildx`.

#### Step 3 – Log in to Docker Hub

- `uses: docker/login-action@v3`
- Under `with:`:
  - `username: ${{ secrets.DOCKERHUB_USERNAME }}`
  - `password: ${{ secrets.DOCKERHUB_TOKEN }}`

Make sure `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets are configured in the repository.

#### Step 4 – Build & push image

- Use `docker/build-push-action@v6`.
- Configure:

  ```yaml
  with:
    context: ${{ env.WORKDIR }}
    push: true
    tags: |
      ${{ env.HUB_IMAGE_BASE }}:latest
      ${{ env.HUB_IMAGE_BASE }}:${{ github.sha }}
      ${{ env.HUB_IMAGE_BASE }}:${{ github.ref_name }}
      ${{ env.HUB_IMAGE_BASE }}:${{ env.DEPLOY_ENV }}
  ```

This pushes the same image under four tags:

- `latest`
- Full commit SHA.
- Branch name (`github.ref_name`).
- Dynamic environment name `DEPLOY_ENV` (based on branch or `workflow_dispatch` input).

---

## Part 7 – Commit, push and verify

19. Save the file:

```text
.github/workflows/11-03-inputs.yaml
```

20. Commit and push the workflow:

```bash
git add .github/workflows/11-03-inputs.yaml
git commit -m "Add inputs-based CI/CD workflow for Weather API"
git push
```

21. Verify behaviour:

- **Push to `feature/07-pogoda-api`**:
  - `build` should run.
  - `test` should run unless the commit message contains `[skip tests]`.
  - `build-and-push` should **not** run (unless triggered via `workflow_dispatch` with `run_deploy=true`).

- **Pull request to `feature/07-pogoda-api`**:
  - `build` and `test` should always run.
  - `build-and-push` should **not** run.

- **Push to `main`**:
  - `build` and `test` should run.
  - `build-and-push` should run and push the image to Docker Hub.

- **Manual `workflow_dispatch`**:
  - You can:
    - Change `city` to test a different city.
    - Turn tests on/off with `run_tests`.
    - Turn deploy on/off with `run_deploy`.
    - Choose environment `dev07` or `prod07` with `deploy_env` (affects `DEPLOY_ENV` and image tags).

---

## Deliverable

Your final deliverable is the **GitHub Actions workflow YAML file**:

```text
.github/workflows/11-03-inputs.yaml
```

It must include:

- Triggers for `push`, `pull_request` and `workflow_dispatch` with the described inputs.
- Top-level `env` with dynamic `DEPLOY_ENV`.
- Three jobs: `build`, `test`, `build-and-push`.
- Correct use of `if:` expressions with:
  - `contains(...)`
  - Input-based conditions (`inputs.run_tests`, `inputs.run_deploy`, `inputs.deploy_env`).
- Docker build, artifact upload/download, container tests and optional deployment to Docker Hub.

---

# Zadanie: GitHub Actions – Inputs i warunkowe joby dla Pogodowego API

## Cel

Masz przygotowany mały projekt pogodowego API opartego na FastAPI, działający w kontenerze Dockera za pomocą Uvicorna.  
Aplikacja znajduje się w katalogu:

```text
CWICZENIA/07-expressions/pogoda_python_flusk
```

Najważniejsze pliki projektu:

- `app.py` – aplikacja FastAPI wystawiająca endpoint `/weather`.
- `requirements.txt` – lista zależności Pythona (m.in. `requests`, `fastapi`, `uvicorn[standard]`).
- `Dockerfile` – buduje obraz Dockera z aplikacją.
- `start.py` – plik pomocniczy używany przy starcie aplikacji / kontenera.

Twoim zadaniem jest utworzenie **workflow GitHub Actions** (pliku YAML), który:

1. Buduje obraz Dockera dla tego API i zapisuje go jako artefakt.
2. W osobnym jobie uruchamia testy z wykorzystaniem:
   - obrazu załadowanego z artefaktu,
   - kontenera z sekretnym kluczem API,
   - wywołania endpointu `/weather`.
3. Opcjonalnie (w zależności od inputów i gałęzi) buduje i **wypycha** obraz do Docker Huba.
4. Wykorzystuje **workflow_dispatch inputs** oraz **wyrażenia** (`if`, operatory logiczne, porównania) do sterowania:
   - kiedy joby są wykonywane,
   - jakie miasto jest używane w teście,
   - jakie środowisko (dev/prod) jest używane w tagach obrazu.

Końcowy rezultat to jeden **plik workflow YAML**:

```text
.github/workflows/11-03-inputs.yaml
```

---

## Część 1 – Zapoznanie się z projektem

1. Otwórz repozytorium w edytorze (np. VS Code).
2. Przejdź do katalogu:

   ```text
   CWICZENIA/07-expressions/pogoda_python_flusk
   ```

3. Przejrzyj kluczowe pliki:

   - `app.py` – wystawia endpoint `/weather`, który przyjmuje m.in. parametry `city` i `api_key`.  
     Klucz API odczytywany jest ze zmiennej środowiskowej `OPENWEATHER_API_KEY`.
   - `requirements.txt` – zawiera zależności:
     - `requests`
     - `fastapi`
     - `uvicorn[standard]`
   - `Dockerfile` – buduje obraz:
     - instalując zależności z `requirements.txt`,
     - uruchamiając aplikację FastAPI na porcie `8000`.
   - `start.py` – plik wspierający logikę startową aplikacji / kontenera.

Tych plików **nie musisz** modyfikować – w zadaniu chodzi o przygotowanie workflow w GitHub Actions.

---

## Część 2 – Utworzenie pliku workflow

4. W katalogu głównym repozytorium upewnij się, że istnieje struktura:

   ```text
   .github/workflows
   ```

   Jeśli jej nie ma – utwórz ją.

5. Wewnątrz `.github/workflows` utwórz nowy plik:

   ```text
   11-03-inputs.yaml
   ```

W tym pliku zdefiniujesz cały pipeline.

---

## Część 3 – Konfiguracja globalna: wyzwalacze, inputs i zmienne środowiskowe

### 3.1 Nazwa workflow

6. Na górze pliku ustaw nazwę workflow, np.:

```yaml
name: 11-03 Pogoda API CI
```

### 3.2 Wyzwalacze (`on:`)

7. Skonfiguruj workflow tak, aby uruchamiał się:

- przy `push` na gałęzie:
  - `feature/07-pogoda-api`
  - `main`
- przy `pull_request` kierowanych na gałąź:
  - `feature/07-pogoda-api`
- ręcznie poprzez `workflow_dispatch` (z wejściami).

Przykładowo:

```yaml
on:
  push:
    branches: [ feature/07-pogoda-api, main ]
  pull_request:
    branches: [ feature/07-pogoda-api ]
  workflow_dispatch:
    inputs:
      ...
```

### 3.3 Inputs dla `workflow_dispatch`

8. W sekcji `workflow_dispatch.inputs` zdefiniuj:

- `city`:
  - `description`: `"Miasto dla testu endpointu /weather"`
  - `required`: `false`
  - `default`: `"Warsaw"`
  - `type`: `string`

- `run_tests`:
  - `description`: `"Czy uruchomić job TEST?"`
  - `required`: `false`
  - `default`: `true`
  - `type`: `boolean`

- `run_deploy`:
  - `description`: `"Czy uruchomić job BUILD & PUSH (deploy)?"`
  - `required`: `false`
  - `default`: `false`
  - `type`: `boolean`

- `deploy_env`:
  - `description`: `"Środowisko deployu (tylko dla workflow_dispatch)"`
  - `required`: `false`
  - `default`: `"dev07"`
  - `type`: `choice`
  - `options`:
    - `dev07`
    - `prod07`

Inputs będą później wykorzystywane w warunkach `if:` oraz w zmiennych środowiskowych.

### 3.4 Globalne `env` z wyrażeniem dla `DEPLOY_ENV`

9. Dodaj sekcję `env` na poziomie workflow z następującymi zmiennymi:

- `WORKDIR` – ścieżka do katalogu aplikacji:

  ```yaml
  WORKDIR: ./CWICZENIA/07-expressions/pogoda_python_flusk
  ```

- `TEST_IMAGE` – nazwa obrazu używanego do testów (bazująca na loginie z Docker Huba):

  ```yaml
  TEST_IMAGE: ${{ secrets.DOCKERHUB_USERNAME }}/python_pogoda:test
  ```

- `HUB_IMAGE_BASE` – baza dla obrazów wypychanych do Docker Huba:

  ```yaml
  HUB_IMAGE_BASE: ${{ secrets.DOCKERHUB_USERNAME }}/python_pogoda
  ```

- `DEPLOY_ENV` – nazwa środowiska wyliczana warunkowo:

  - jeśli `github.event_name == 'workflow_dispatch'` → `inputs.deploy_env`,
  - w przeciwnym wypadku:
    - dla gałęzi `main` → `prod07`,
    - dla innych gałęzi → `dev07`.

  Użyj:

  ```yaml
  DEPLOY_ENV: ${{ github.event_name == 'workflow_dispatch' && inputs.deploy_env || (github.ref == 'refs/heads/main' && 'prod07' || 'dev07') }}
  ```

---

## Część 4 – Job 1: BUILD (build + artefakt obrazu)

10. W sekcji `jobs` utwórz job `build`:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
```

11. Dodaj kroki:

### Krok 1 – Checkout repozytorium

- `uses: actions/checkout@v4`
- nazwa: `Checkout repository`.

### Krok 2 – Setup Docker Buildx

- `uses: docker/setup-buildx-action@v3`
- nazwa: `Set up Docker Buildx`.

### Krok 3 – Build lokalnego obrazu testowego (bez push)

- `uses: docker/build-push-action@v6`
- `with`:
  - `context: ${{ env.WORKDIR }}`
  - `tags: ${{ env.TEST_IMAGE }}`
  - `load: true`
  - `push: false`

### Krok 4 – Zapis obrazu do pliku tar

- `run`:

  ```bash
  docker save "${{ env.TEST_IMAGE }}" -o image.tar
  ```

### Krok 5 – Upload artefaktu

- `uses: actions/upload-artifact@v4`
- `with`:
  - `name: pogoda-image`
  - `path: image.tar`

Po tym jobie masz artefakt `pogoda-image` zawierający obraz Dockera.

---

## Część 5 – Job 2: TEST (warunkowy job z inputs)

12. Utwórz job `test` zależny od `build`:

```yaml
test:
  runs-on: ubuntu-latest
  needs: build
```

### 5.1 Warunek na poziomie joba (`if`)

13. Job `test` powinien uruchamiać się:

- zawsze dla `pull_request`,
- dla `push` tylko gdy message commita **nie** zawiera `[skip tests]`,
- dla `workflow_dispatch` tylko jeśli `inputs.run_tests == true`.

Użyj:

```yaml
if: >
  github.event_name == 'pull_request' ||
  (github.event_name == 'push' &&
   !contains(github.event.head_commit.message, '[skip tests]')) ||
  (github.event_name == 'workflow_dispatch' &&
   inputs.run_tests == true)
```

### 5.2 Zmienne środowiskowe joba

14. W `env` joba:

- `OPENWEATHER_API_KEY` – z sekretu:

  ```yaml
  OPENWEATHER_API_KEY: ${{ secrets.OPENWEATHER_API_KEY }}
  ```

- `TEST_CITY` – miasto do testu:

  - przy `workflow_dispatch` → `inputs.city`,
  - w pozostałych przypadkach → `"Warsaw"`.

  ```yaml
  TEST_CITY: ${{ github.event_name == 'workflow_dispatch' && inputs.city || 'Warsaw' }}
  ```

### 5.3 Kroki w jobie `test`

15. Dodaj kroki:

#### Krok 1 – Download artefaktu

- `uses: actions/download-artifact@v4`
- `with`:
  - `name: pogoda-image`

#### Krok 2 – Load obrazu Dockera

- `run: docker load -i image.tar`

#### Krok 3 – Walidacja `OPENWEATHER_API_KEY`

- `if: env.OPENWEATHER_API_KEY == ''`
- `run`:

  ```bash
  echo "❌ Brak sekretu OPENWEATHER_API_KEY – testy API nie mogą zostać uruchomione."
  exit 1
  ```

#### Krok 4 – Uruchomienie kontenera (tylko przy obecnym sekrecie)

- `if: env.OPENWEATHER_API_KEY != ''`
- `run`:

  ```bash
  docker run -d     --name pogoda_api     -p 8000:8000     -e OPENWEATHER_API_KEY="${{ env.OPENWEATHER_API_KEY }}"     "${{ env.TEST_IMAGE }}"
  ```

#### Krok 5 – Czekanie na start API

- `if: env.OPENWEATHER_API_KEY != ''`
- `run`:

  ```bash
  echo "Czekam na start API..."
  sleep 10
  ```

#### Krok 6 – Test endpointu `/weather` przez curl

- `if: env.OPENWEATHER_API_KEY != ''`
- `run`:

  ```bash
  set -e
  echo "Testowanie endpointu /weather dla miasta: '${{ env.TEST_CITY }}'..."
  curl -f "http://localhost:8000/weather?city=${{ env.TEST_CITY }}&api_key=${{ env.OPENWEATHER_API_KEY }}"
  echo
  echo "OK - endpoint /weather zwrócił odpowiedź 2xx."
  ```

#### Krok 7 – Logi kontenera przy błędzie

- `if: failure()`
- `run`:

  ```bash
  echo "Logi kontenera:"
  docker logs pogoda_api || true
  ```

#### Krok 8 – Zatrzymanie i usunięcie kontenera (zawsze)

- `if: always()`
- `run`:

  ```bash
  docker stop pogoda_api || true
  docker rm pogoda_api || true
  ```

---

## Część 6 – Job 3: BUILD & PUSH (opcjonalny „deploy”)

16. Utwórz job `build-and-push`, zależny od `test`:

```yaml
build-and-push:
  runs-on: ubuntu-latest
  needs: test
```

### 6.1 Warunek na poziomie joba

17. Job `build-and-push` powinien działać tylko gdy:

- zdarzenie to `push` **na** `main` i repozytorium nie jest forkiem  
  **lub**
- zdarzenie to `workflow_dispatch` **i** `inputs.run_deploy == true`.

Użyj:

```yaml
if: >
  (github.event_name == 'push' &&
   github.ref == 'refs/heads/main' &&
   github.event.repository.fork == false) ||
  (github.event_name == 'workflow_dispatch' &&
   inputs.run_deploy == true)
```

### 6.2 Kroki w jobie `build-and-push`

18. Dodaj kroki:

#### Krok 1 – Checkout repozytorium

- `uses: actions/checkout@v4`.

#### Krok 2 – Setup Docker Buildx

- `uses: docker/setup-buildx-action@v3`.

#### Krok 3 – Logowanie do Docker Huba

- `uses: docker/login-action@v3`
- `with`:
  - `username: ${{ secrets.DOCKERHUB_USERNAME }}`
  - `password: ${{ secrets.DOCKERHUB_TOKEN }}`

#### Krok 4 – Build & push obrazu

- `uses: docker/build-push-action@v6`
- `with`:
  - `context: ${{ env.WORKDIR }}`
  - `push: true`
  - `tags`:

    ```yaml
    tags: |
      ${{ env.HUB_IMAGE_BASE }}:latest
      ${{ env.HUB_IMAGE_BASE }}:${{ github.sha }}
      ${{ env.HUB_IMAGE_BASE }}:${{ github.ref_name }}
      ${{ env.HUB_IMAGE_BASE }}:${{ env.DEPLOY_ENV }}
    ```

---

## Część 7 – Commit, push i weryfikacja

19. Zapisz plik:

```text
.github/workflows/11-03-inputs.yaml
```

20. Wykonaj commit i push:

```bash
git add .github/workflows/11-03-inputs.yaml
git commit -m "Dodaj workflow z inputs dla Pogoda API"
git push
```

21. Przetestuj różne scenariusze:

- **Push na `feature/07-pogoda-api`**:
  - `build` i `test` powinny się wykonać (chyba że commit zawiera `[skip tests]`).
  - `build-and-push` nie powinien się uruchomić.

- **Pull request do `feature/07-pogoda-api`**:
  - `build` i `test` powinny uruchamiać się zawsze.
  - `build-and-push` nie powinien się uruchomić.

- **Push na `main`**:
  - po przejściu jobów `build` i `test` powinien uruchomić się `build-and-push` i wypchnąć obraz na Docker Huba.

- **Ręczne uruchomienie (`workflow_dispatch`)**:
  - możesz ustawić:
    - `city` – miasto do testu endpointu `/weather`,
    - `run_tests` – czy uruchamiamy job `test`,
    - `run_deploy` – czy uruchamiamy job `build-and-push`,
    - `deploy_env` – środowisko (`dev07` / `prod07`) wykorzystywane w `DEPLOY_ENV` i tagach obrazu.

---

## Rezultat

Końcowym wynikiem zadania jest **workflow GitHub Actions** w pliku:

```text
.github/workflows/11-03-inputs.yaml
```

Plik musi zawierać:

- wyzwalacze `push`, `pull_request` i `workflow_dispatch` z opisanymi inputs,
- globalne `env` z wyliczanym `DEPLOY_ENV`,
- trzy joby: `build`, `test`, `build-and-push`,
- poprawnie użyte warunki `if:` na poziomie jobów i kroków,
- pełną logikę: build → artefakt → test z użyciem inputs → opcjonalny deploy do Docker Huba.
