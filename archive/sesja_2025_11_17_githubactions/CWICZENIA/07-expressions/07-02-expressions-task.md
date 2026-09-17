# Task: GitHub Actions with Expressions – Weather API CI/CD

## Goal

You are given a small **FastAPI-based Weather API** project, Dockerized and prepared to run behind Uvicorn.  
The application lives in the directory:

```text
CWICZENIA/07-expressions/pogoda_python_flusk
```

Key project files:

- `app.py` – FastAPI application exposing a `/weather` endpoint.
- `requirements.txt` – Python dependencies (at least `requests`, `fastapi`, `uvicorn[standard]`).
- `Dockerfile` – builds the Docker image running the API service.
- (Other support files) – used by the API internally.

Your task is to create a **GitHub Actions workflow** (YAML file) that:

1. Builds a Docker image for this API and stores it as an artifact.
2. Runs tests in a separate job that:
   - Load the image from the artifact.
   - Start the container with a secret API key.
   - Call the `/weather` endpoint.
3. For successful runs on the `main` branch:
   - Build and **push** the image to Docker Hub under multiple tags (including one based on branch, SHA and dynamic environment name).
4. Uses **expressions** (`if`, `contains`, ternary-like logic) to control when jobs and steps run.

The final deliverable is a single **workflow YAML file**:

```text
.github/workflows/07-02-expressions.yaml
```

---

## Part 1 – Explore the project

1. Open the repository in your editor (e.g. VS Code).
2. Navigate to:

   ```text
   CWICZENIA/07-expressions/pogoda_python_flusk
   ```

3. Review the key files:

   - `app.py` – exposes the `/weather` endpoint, which expects a `city` and an `api_key` (read from environment variable `OPENWEATHER_API_KEY` passed into the container).
   - `requirements.txt` – lists dependencies such as:
     - `requests`
     - `fastapi`
     - `uvicorn[standard]`
   - `Dockerfile` – builds an image that:
     - Installs dependencies from `requirements.txt`.
     - Starts the FastAPI app on port `8000` (e.g. via `uvicorn app:app --host 0.0.0.0 --port 8000`).

You **do not** need to modify these project files. Your work is to create a GitHub Actions workflow that builds, tests and publishes the image.

---

## Part 2 – Create the workflow file

4. In the repository root, ensure the following directory exists:

   ```text
   .github/workflows
   ```

   Create it if missing.

5. Inside `.github/workflows`, create a new file:

   ```text
   07-02-expressions.yaml
   ```

   The rest of this task describes what must be inside this file.

---

## Part 3 – Top-level configuration: triggers and environment

6. At the top of the workflow, define a readable workflow name, for example:

   ```yaml
   name: 07-02b Pogoda API CI
   ```

7. Configure workflow triggers (`on:`) so that the workflow runs:

   - On `push` to branches:
     - `feature/07-pogoda-api`
     - `main`
   - On `pull_request` targeting branch:
     - `feature/07-pogoda-api`
   - Manually, via `workflow_dispatch` (no extra inputs needed).

   Conceptually:

   ```yaml
   on:
     push:
       branches: [ feature/07-pogoda-api, main ]
     pull_request:
       branches: [ feature/07-pogoda-api ]
     workflow_dispatch:
   ```

8. Add a top-level `env` section that defines shared environment variables:

   - `WORKDIR`: path to the API application directory:

     ```yaml
     WORKDIR: ./CWICZENIA/07-expressions/pogoda_python_flusk
     ```

   - `TEST_IMAGE`: name of the image used only for testing, based on your Docker Hub username and a `:test` tag:

     ```yaml
     TEST_IMAGE: ${{ secrets.DOCKERHUB_USERNAME }}/python_pogoda:test
     ```

   - `HUB_IMAGE_BASE`: base name for the image that will be pushed to Docker Hub:

     ```yaml
     HUB_IMAGE_BASE: ${{ secrets.DOCKERHUB_USERNAME }}/python_pogoda
     ```

   - `DEPLOY_ENV`: environment name derived dynamically from the branch using an **expression**:

     - For `main` branch → `prod07`
     - For all other branches → `dev07`

     Use the short-circuit expression form:

     ```yaml
     DEPLOY_ENV: ${{ github.ref == 'refs/heads/main' && 'prod07' || 'dev07' }}
     ```

   Your top-level `env` block must include all four variables.

---

## Part 4 – Job 1: Build Docker image and upload as artifact

9. Define the first job, e.g. `build`:

   ```yaml
   jobs:
     build:
       runs-on: ubuntu-latest
   ```

10. Add the following steps inside the `build` job:

   ### Step 1 – Checkout repository

   - Use `actions/checkout@v4`.
   - Name it e.g. `Checkout repository`.

   ### Step 2 – Set up Docker Buildx

   - Use `docker/setup-buildx-action@v3`.
   - Name the step `Set up Docker Buildx`.

   ### Step 3 – Build local test image (no push)

   - Use `docker/build-push-action@v6`.
   - Configure:
     - `context`: `${{ env.WORKDIR }}`
     - `tags`: `${{ env.TEST_IMAGE }}`
     - `load`: `true`
     - `push`: `false`
   - This builds the image from the `Dockerfile` in `WORKDIR` and loads it into the local Docker daemon under the `TEST_IMAGE` tag.

   ### Step 4 – Save image to tar

   - Add a `run` step that saves the built image to a tar file:

     ```bash
     docker save "${{ env.TEST_IMAGE }}" -o image.tar
     ```

   ### Step 5 – Upload image artifact

   - Use `actions/upload-artifact@v4` to upload `image.tar` as an artifact.
   - Configure:
     - `name`: `pogoda-image`
     - `path`: `image.tar`

   After this job finishes, the Docker image for your Weather API is stored as a reusable artifact.

---

## Part 5 – Job 2: Test image with expressions and conditions

11. Define a job named `test` that depends on `build`:

   ```yaml
   test:
     runs-on: ubuntu-latest
     needs: build
   ```

12. Configure a job-level `if:` condition using expressions:

   - Tests must run:
     - Always for `pull_request` events.
     - For `push` events **only if** the commit message does **not** contain `[skip tests]`.

   - Use the expression:

     ```yaml
     if: >
       github.event_name == 'pull_request' ||
       (github.event_name == 'push' && !contains(github.event.head_commit.message, '[skip tests]'))
     ```

13. Add a job-level `env` for the secret API key:

   ```yaml
   env:
     OPENWEATHER_API_KEY: ${{ secrets.OPENWEATHER_API_KEY }}
   ```

14. Inside the `test` job, add these steps:

   ### Step 1 – Download image artifact

   - Use `actions/download-artifact@v4`.
   - Configure:
     - `name`: `pogoda-image`
   - This will restore `image.tar`.

   ### Step 2 – Load Docker image

   - Add a `run` step:

     ```bash
     docker load -i image.tar
     ```

   ### Step 3 – Validate presence of OPENWEATHER_API_KEY

   - Add a step with `if: env.OPENWEATHER_API_KEY == ''`.
   - In `run`:
     - Print an error message indicating the missing secret.
     - Exit with non-zero code.

     Example:

     ```bash
     echo "❌ Brak sekretu OPENWEATHER_API_KEY – testy API nie mogą zostać uruchomione."
     exit 1
     ```

   ### Step 4 – Run container (only if secret is present)

   - Add a step with `if: env.OPENWEATHER_API_KEY != ''`.
   - Start the container using `docker run -d`:
     - `--name pogoda_api`
     - `-p 8000:8000`
     - `-e OPENWEATHER_API_KEY="${{ env.OPENWEATHER_API_KEY }}"`
     - Image: `${{ env.TEST_IMAGE }}`

     Example:

     ```bash
     docker run -d        --name pogoda_api        -p 8000:8000        -e OPENWEATHER_API_KEY="${{ env.OPENWEATHER_API_KEY }}"        "${{ env.TEST_IMAGE }}"
     ```

   ### Step 5 – Wait for API to be ready

   - Add a step with `if: env.OPENWEATHER_API_KEY != ''`.
   - Use a small delay:

     ```bash
     echo "Czekam na start API..."
     sleep 10
     ```

   ### Step 6 – Test `/weather` endpoint via curl

   - Add a step with `if: env.OPENWEATHER_API_KEY != ''`.
   - Use `curl` to call the endpoint:

     - URL: `http://localhost:8000/weather?city=Warsaw&api_key=${{ env.OPENWEATHER_API_KEY }}`
     - Use `curl -f` so non-2xx status codes fail the step.
     - Use `set -e` to stop on first error.

     Example:

     ```bash
     set -e
     echo "Testowanie endpointu /weather..."
     curl -f "http://localhost:8000/weather?city=Warsaw&api_key=${{ env.OPENWEATHER_API_KEY }}"
     echo
     echo "OK - endpoint /weather zwrócił odpowiedź 2xx."
     ```

   ### Step 7 – Show container logs on failure

   - Add a step with `if: failure()`.
   - Print logs:

     ```bash
     echo "Logi kontenera:"
     docker logs pogoda_api || true
     ```

   ### Step 8 – Stop and remove container (always)

   - Add a cleanup step with `if: always()`.
   - Stop and remove the container if it exists:

     ```bash
     docker stop pogoda_api || true
     docker rm pogoda_api || true
     ```

This job demonstrates the use of expressions both at **job-level** and **step-level** (`if:`) to control whether tests run and how they behave depending on secrets and previous failures.

---

## Part 6 – Job 3: Build and push to Docker Hub (release job)

15. Define a third job, e.g. `build-and-push`, that depends on `test`:

   ```yaml
   build-and-push:
     runs-on: ubuntu-latest
     needs: test
   ```

16. Add a job-level `if:` so that this job is executed only when:

   - The event is `push`.
   - The branch is `main`.
   - The repository is **not** a fork.

   Use the expression:

   ```yaml
   if: >
     github.event_name == 'push' &&
     github.ref == 'refs/heads/main' &&
     github.event.repository.fork == false
   ```

17. Inside `build-and-push`, add the following steps:

   ### Step 1 – Checkout repository

   - Use `actions/checkout@v4`.

   ### Step 2 – Set up Docker Buildx

   - Use `docker/setup-buildx-action@v3`.

   ### Step 3 – Log in to Docker Hub

   - Use `docker/login-action@v3`.
   - Provide:
     - `username`: `${{ secrets.DOCKERHUB_USERNAME }}`
     - `password`: `${{ secrets.DOCKERHUB_TOKEN }}`

   ### Step 4 – Build & push image to Docker Hub

   - Use `docker/build-push-action@v6`.
   - Configure:
     - `context`: `${{ env.WORKDIR }}`
     - `push`: `true`
     - `tags`: a multi-line list of tags:

       ```yaml
       tags: |
         ${{ env.HUB_IMAGE_BASE }}:latest
         ${{ env.HUB_IMAGE_BASE }}:${{ github.sha }}
         ${{ env.HUB_IMAGE_BASE }}:${{ github.ref_name }}
         ${{ env.HUB_IMAGE_BASE }}:${{ env.DEPLOY_ENV }}
       ```

   This will push four tags for the same image:

   - `latest`
   - Full commit SHA
   - Branch name
   - Dynamic environment name (`prod07` or `dev07`) chosen by expression

---

## Part 7 – Commit, push and verify

18. Save the workflow file at:

   ```text
   .github/workflows/07-02-expressions.yaml
   ```

19. Commit and push your changes:

   ```bash
   git add .github/workflows/07-02-expressions.yaml
   git commit -m "Add expressions-based CI for Weather API"
   git push
   ```

20. Verify behaviour:

   - Push to `feature/07-pogoda-api`:
     - `build` and `test` jobs should run.
     - `build-and-push` should **not** run.
   - Open a pull request to `feature/07-pogoda-api`:
     - `build` and `test` should run (tests cannot be skipped).
   - Push to `main`:
     - If tests pass and the repo is not a fork, `build-and-push` should run and push images to Docker Hub with four tags.

---

## Deliverable

Your final output is the **workflow YAML file**:

```text
.github/workflows/07-02-expressions.yaml
```

It must include:

- The specified triggers.
- Top-level `env` variables with an expression-based `DEPLOY_ENV`.
- Three jobs: `build`, `test`, `build-and-push`.
- Correct `if:` expressions at both job and step levels.
- Docker build, artifact usage, container tests and final Docker Hub push.

---

# Zadanie: GitHub Actions z wyrażeniami – CI/CD dla Pogodowego API

## Cel

Masz przygotowany niewielki projekt pogodowego API opartego na FastAPI, który działa w kontenerze Dockera za pomocą Uvicorna.  
Aplikacja znajduje się w katalogu:

```text
CWICZENIA/07-expressions/pogoda_python_flusk
```

Najważniejsze pliki projektu:

- `app.py` – aplikacja FastAPI wystawiająca endpoint `/weather`.
- `requirements.txt` – lista zależności Pythona (m.in. `requests`, `fastapi`, `uvicorn[standard]`).
- `Dockerfile` – buduje obraz Dockera uruchamiający API.
- (Inne pliki pomocnicze) – wykorzystywane przez aplikację.

Twoim zadaniem jest utworzenie **workflow GitHub Actions** (pliku YAML), który:

1. Buduje obraz Dockera dla tego API i zapisuje go jako artefakt.
2. W osobnym jobie:
   - Ładuje obraz z artefaktu,
   - Uruchamia kontener z sekretnym kluczem API,
   - Wywołuje endpoint `/weather`.
3. Dla udanych uruchomień na gałęzi `main`:
   - Buduje obraz ponownie,
   - Wypycha go do Docker Huba z kilkoma tagami (opartymi o SHA, nazwę gałęzi i dynamiczny „environment name”).
4. Wykorzystuje **wyrażenia** (`if`, `contains`, logikę warunkową) do sterowania wykonywaniem jobów i kroków.

Końcowy wynik to **jeden plik workflow YAML**:

```text
.github/workflows/07-02-expressions.yaml
```

---

## Część 1 – Zapoznanie się z projektem

1. Otwórz repozytorium w edytorze (np. VS Code).
2. Przejdź do katalogu:

   ```text
   CWICZENIA/07-expressions/pogoda_python_flusk
   ```

3. Przejrzyj kluczowe pliki:

   - `app.py` – wystawia endpoint `/weather`, który oczekuje parametrów `city` oraz `api_key`. Klucz API jest odczytywany ze zmiennej środowiskowej `OPENWEATHER_API_KEY`, przekazywanej do kontenera.
   - `requirements.txt` – zawiera zależności, w tym:
     - `requests`
     - `fastapi`
     - `uvicorn[standard]`
   - `Dockerfile` – buduje obraz:
     - instalując zależności z `requirements.txt`,
     - uruchamiając FastAPI przez Uvicorna na porcie `8000`.

Tych plików **nie musisz** modyfikować – w zadaniu chodzi o konfigurację workflow GitHub Actions.

---

## Część 2 – Utworzenie pliku workflow

4. W katalogu głównym repozytorium upewnij się, że istnieje struktura:

   ```text
   .github/workflows
   ```

   Jeśli jej nie ma – utwórz ją.

5. Wewnątrz `.github/workflows` utwórz nowy plik:

   ```text
   07-02-expressions.yaml
   ```

W tym pliku skonfigurujesz cały pipeline.

---

## Część 3 – Konfiguracja globalna: wyzwalacze i zmienne środowiskowe

6. Na górze pliku ustaw czytelną nazwę workflow, np.:

   ```yaml
   name: 07-02b Pogoda API CI
   ```

7. Skonfiguruj wyzwalacze (`on:`), aby workflow uruchamiał się:

   - przy `push` na gałęzie:
     - `feature/07-pogoda-api`
     - `main`
   - przy `pull_request` kierowanych na gałąź:
     - `feature/07-pogoda-api`
   - ręcznie przez `workflow_dispatch`.

   Przykładowo:

   ```yaml
   on:
     push:
       branches: [ feature/07-pogoda-api, main ]
     pull_request:
       branches: [ feature/07-pogoda-api ]
     workflow_dispatch:
   ```

8. Dodaj sekcję `env` na poziomie workflow z następującymi zmiennymi:

   - `WORKDIR` – ścieżka do katalogu aplikacji:

     ```yaml
     WORKDIR: ./CWICZENIA/07-expressions/pogoda_python_flusk
     ```

   - `TEST_IMAGE` – nazwa obrazu testowego, oparta na Twoim loginie w Docker Hubie (sekrety) i tagu `:test`:

     ```yaml
     TEST_IMAGE: ${{ secrets.DOCKERHUB_USERNAME }}/python_pogoda:test
     ```

   - `HUB_IMAGE_BASE` – nazwa bazowa obrazu wypychanego do Docker Huba:

     ```yaml
     HUB_IMAGE_BASE: ${{ secrets.DOCKERHUB_USERNAME }}/python_pogoda
     ```

   - `DEPLOY_ENV` – nazwa środowiska wyliczana dynamicznie z użyciem wyrażenia:

     - dla gałęzi `main` → `prod07`,
     - dla pozostałych → `dev07`.

     Użyj wyrażenia:

     ```yaml
     DEPLOY_ENV: ${{ github.ref == 'refs/heads/main' && 'prod07' || 'dev07' }}
     ```

   Wszystkie powyższe zmienne muszą znaleźć się w top-level `env`.

---

## Część 4 – Job 1: Build obrazu Dockera i upload artefaktu

9. Zdefiniuj pierwszy job, np. `build`:

   ```yaml
   jobs:
     build:
       runs-on: ubuntu-latest
   ```

10. Wewnątrz `build` dodaj następujące kroki:

   ### Krok 1 – Checkout repozytorium

   - Użyj akcji `actions/checkout@v4`.
   - Nazwij krok np. `Checkout repository`.

   ### Krok 2 – Setup Docker Buildx

   - Użyj `docker/setup-buildx-action@v3`.
   - Nazwij krok `Set up Docker Buildx`.

   ### Krok 3 – Build lokalnego obrazu testowego (bez push)

   - Użyj `docker/build-push-action@v6`.
   - Skonfiguruj:
     - `context`: `${{ env.WORKDIR }}`
     - `tags`: `${{ env.TEST_IMAGE }}`
     - `load`: `true`
     - `push`: `false`

   Ten krok buduje obraz z `Dockerfile` w `WORKDIR` i ładuje go do lokalnego demona Dockera pod tagiem `TEST_IMAGE`.

   ### Krok 4 – Zapis obrazu do pliku tar

   - Dodaj krok `run`, który zapisze obraz do pliku:

     ```bash
     docker save "${{ env.TEST_IMAGE }}" -o image.tar
     ```

   ### Krok 5 – Upload artefaktu z obrazem

   - Użyj `actions/upload-artifact@v4`.
   - Skonfiguruj:
     - `name`: `pogoda-image`
     - `path`: `image.tar`

   Po zakończeniu joba Docker image będzie dostępny jako artefakt `pogoda-image`.

---

## Część 5 – Job 2: Test obrazu z wykorzystaniem wyrażeń

11. Zdefiniuj job `test`, zależny od `build`:

   ```yaml
   test:
     runs-on: ubuntu-latest
     needs: build
   ```

12. Dodaj warunek na poziomie joba (`if:`), który określa, kiedy testy mają się wykonać:

   - Zawsze dla `pull_request`.
   - Dla `push` tylko wtedy, gdy message commita **nie** zawiera `[skip tests]`.

   Użyj wyrażenia:

   ```yaml
   if: >
     github.event_name == 'pull_request' ||
     (github.event_name == 'push' && !contains(github.event.head_commit.message, '[skip tests]'))
   ```

13. Dodaj `env` na poziomie joba:

   ```yaml
   env:
     OPENWEATHER_API_KEY: ${{ secrets.OPENWEATHER_API_KEY }}
   ```

14. W jobie `test` dodaj kroki:

   ### Krok 1 – Download artefaktu z obrazem

   - Użyj `actions/download-artifact@v4`.
   - Skonfiguruj:
     - `name`: `pogoda-image`

   ### Krok 2 – Load obrazu Dockera

   - Krok `run`:

     ```bash
     docker load -i image.tar
     ```

   ### Krok 3 – Walidacja obecności OPENWEATHER_API_KEY

   - Krok z `if: env.OPENWEATHER_API_KEY == ''`.
   - W `run`:
     - Wypisz komunikat o braku sekretu.
     - Zakończ krok kodem różnym od zera:

     ```bash
     echo "❌ Brak sekretu OPENWEATHER_API_KEY – testy API nie mogą zostać uruchomione."
     exit 1
     ```

   ### Krok 4 – Uruchomienie kontenera (tylko jeśli sekret jest ustawiony)

   - Krok z `if: env.OPENWEATHER_API_KEY != ''`.
   - Użyj `docker run -d`:

     ```bash
     docker run -d        --name pogoda_api        -p 8000:8000        -e OPENWEATHER_API_KEY="${{ env.OPENWEATHER_API_KEY }}"        "${{ env.TEST_IMAGE }}"
     ```

   ### Krok 5 – Czekanie na start API

   - Krok z `if: env.OPENWEATHER_API_KEY != ''`.
   - Np.:

     ```bash
     echo "Czekam na start API..."
     sleep 10
     ```

   ### Krok 6 – Test endpointu `/weather` za pomocą curl

   - Krok z `if: env.OPENWEATHER_API_KEY != ''`.
   - Skrypt:

     ```bash
     set -e
     echo "Testowanie endpointu /weather..."
     curl -f "http://localhost:8000/weather?city=Warsaw&api_key=${{ env.OPENWEATHER_API_KEY }}"
     echo
     echo "OK - endpoint /weather zwrócił odpowiedź 2xx."
     ```

   ### Krok 7 – Logi kontenera przy błędzie

   - Krok z `if: failure()`.
   - Skrypt:

     ```bash
     echo "Logi kontenera:"
     docker logs pogoda_api || true
     ```

   ### Krok 8 – Zatrzymanie i usunięcie kontenera (zawsze)

   - Krok z `if: always()`.
   - Skrypt:

     ```bash
     docker stop pogoda_api || true
     docker rm pogoda_api || true
     ```

Ten job pokazuje zastosowanie wyrażeń zarówno na poziomie joba (`if` z `contains`), jak i na poziomie kroków (`if: env.OPENWEATHER_API_KEY != ''`, `if: failure()`, `if: always()`).

---

## Część 6 – Job 3: Build & push do Docker Huba (job „release”)

15. Zdefiniuj trzeci job, np. `build-and-push`, zależny od `test`:

   ```yaml
   build-and-push:
     runs-on: ubuntu-latest
     needs: test
   ```

16. Dodaj warunek `if:` na poziomie joba, aby wykonywał się tylko gdy:

   - zdarzenie to `push`,
   - gałąź to `main`,
   - repozytorium nie jest forkiem.

   Użyj:

   ```yaml
   if: >
     github.event_name == 'push' &&
     github.ref == 'refs/heads/main' &&
     github.event.repository.fork == false
   ```

17. Wewnątrz `build-and-push` dodaj kroki:

   ### Krok 1 – Checkout repozytorium

   - `actions/checkout@v4`.

   ### Krok 2 – Setup Docker Buildx

   - `docker/setup-buildx-action@v3`.

   ### Krok 3 – Logowanie do Docker Huba

   - Użyj `docker/login-action@v3`.
   - Skonfiguruj:
     - `username`: `${{ secrets.DOCKERHUB_USERNAME }}`
     - `password`: `${{ secrets.DOCKERHUB_TOKEN }}`

   ### Krok 4 – Build & push obrazu do Docker Huba

   - Użyj `docker/build-push-action@v6`.
   - Skonfiguruj:
     - `context`: `${{ env.WORKDIR }}`
     - `push`: `true`
     - `tags` (wielolinijkowo):

       ```yaml
       tags: |
         ${{ env.HUB_IMAGE_BASE }}:latest
         ${{ env.HUB_IMAGE_BASE }}:${{ github.sha }}
         ${{ env.HUB_IMAGE_BASE }}:${{ github.ref_name }}
         ${{ env.HUB_IMAGE_BASE }}:${{ env.DEPLOY_ENV }}
       ```

   W efekcie obraz zostanie wypchnięty z czterema tagami:

   - `latest`,
   - pełny SHA commita,
   - nazwa gałęzi,
   - dynamiczny `DEPLOY_ENV` (`prod07` lub `dev07`).

---

## Część 7 – Commit, push i weryfikacja

18. Zapisz plik workflow:

   ```text
   .github/workflows/07-02-expressions.yaml
   ```

19. Wykonaj commit i push:

   ```bash
   git add .github/workflows/07-02-expressions.yaml
   git commit -m "Dodaj workflow z expressions dla Pogoda API"
   git push
   ```

20. Zweryfikuj działanie:

   - Push na `feature/07-pogoda-api`:
     - powinny uruchomić się joby `build` i `test`,
     - `build-and-push` nie powinien się wykonać.
   - Pull request do `feature/07-pogoda-api`:
     - `build` i `test` powinny się wykonać (testów nie da się „pominąć” przez `[skip tests]`).
   - Push na `main`:
     - po przejściu testów i jeśli repo nie jest forkiem, powinien wykonać się `build-and-push` i wypchnąć obraz do Docker Huba z czterema tagami.

---

## Rezultat

Rezultatem zadania jest **plik workflow YAML**:

```text
.github/workflows/07-02-expressions.yaml
```

Plik musi zawierać:

- odpowiednie wyzwalacze,
- globalne `env` z wyliczanym `DEPLOY_ENV`,
- trzy joby: `build`, `test`, `build-and-push`,
- poprawnie użyte wyrażenia `if` i funkcję `contains`,
- pełną logikę: build → artefakt → test kontenera → build & push do Docker Huba.

Dostarczając ten plik, słuchacz pokazuje, że potrafi użyć wyrażeń GitHub Actions do sterowania przepływem CI/CD dla pogodowego API w Dockerze.
