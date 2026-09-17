# Task: GitHub Actions CI for Docker Static Web App

## Goal

You are given a small static web application that is served from an Nginx container.  
The application is located in:

```text
CWICZENIA/04-praca-z-zewnetrzymi-akcjami/docker-app-02
```

This directory contains, among others:

- `Dockerfile` – builds the Nginx-based image that serves the static site.
- `docker-compose.yml` – defines how to run the container locally using Docker Compose (service `webapp`, port mapping `8080:80`). 
- `index.html` – the main HTML page of the application, which must contain the text `cw04 github actions` in its content.

Your goal is to create a **GitHub Actions workflow** (YAML file) that:

1. Automatically builds and tests the Docker image of this web app on specific branches and pull requests.
2. Uses Docker Compose to start the container on the GitHub runner.
3. Performs automated HTTP checks against the running web app:
   - Verify that the homepage (`/`) is reachable and contains the expected text.
   - Verify that an image (`/assets/wall.jpg`) is served with HTTP status 200 and a valid image-like content type.
4. Always prints the container logs and shuts down the Docker Compose stack at the end of the job.

The final deliverable is a **single GitHub Actions workflow YAML file** stored as:

```text
.github/workflows/04-03-docker-with-actions.yaml
```

---

## Part 1 – Understand the provided project files

1. Open the repository in your editor (e.g. VS Code).
2. Navigate to:

   ```text
   CWICZENIA/04-praca-z-zewnetrzymi-akcjami/docker-app-02
   ```

3. Inspect the provided files:

   - **`Dockerfile`** – defines how to build an Nginx image that serves the static content from this directory.
   - **`docker-compose.yml`** – defines a single service:
     - Service name: `webapp`
     - Container name: `webapp`
     - Build context: current directory (`.`)
     - Port mapping: host `8080` → container `80`  
   - **`index.html`** – a static HTML page that, when served by Nginx, displays content including the phrase `cw04 github actions`. The test in the workflow will assert that this phrase is present in the response body.

You do not need to modify these files as part of this task. You only need to **create and configure the CI workflow YAML**.

---

## Part 2 – Create the workflow file

4. Ensure the following directory exists in the repository root:

   ```text
   .github/workflows
   ```

   If it does not exist, create it.
5. Inside `.github/workflows`, create a new file:

   ```text
   04-03-docker-with-actions.yaml
   ```

   This file will contain the complete definition of your CI pipeline.

---

## Part 3 – Configure workflow triggers and concurrency

6. At the top of the YAML file, define a descriptive workflow name, for example:

   ```yaml
   name: 04 - Docker Web CI - with actions
   ```

7. Configure the workflow to be triggered:

   - On `push` to branch:
     - `docker`
   - On `pull_request` targeting branch:
     - `docker`
   - Manually using `workflow_dispatch`.

   The `on:` section should therefore include `push`, `pull_request`, and `workflow_dispatch` blocks.

8. Add a `concurrency` section to avoid overlapping runs for the same branch:

   - Use `group: ${{ github.workflow }}-${{ github.ref }}` so that runs of the same workflow on the same ref are grouped together.
   - Set `cancel-in-progress: true` so that a new run cancels the previous one for that group.

---

## Part 4 – Define the job, defaults and environment variables

9. Under `jobs`, create a single job named `build-test`:

   ```yaml
   jobs:
     build-test:
       runs-on: ubuntu-latest
   ```

10. Configure `defaults.run` for the job so that:

    - `shell` is set to `bash`
    - `working-directory` is set to the application directory:

      ```text
      CWICZENIA/04-praca-z-zewnetrzymi-akcjami/docker-app-02
      ```

    This ensures all `run` commands execute in the correct directory.

11. Define the following environment variables under `env` for the job:

    - `IMAGE_NAME`: short name for the Docker image, e.g. `webapp`.
    - `TAG`: image tag set to the current commit SHA: `${{ github.sha }}`.
    - `HOST_PORT`: `8080` (the port exposed by Docker Compose on the host).
    - `CONTAINER_PORT`: `80` (the port used inside the container).

    These variables will be reused in later steps.

---

## Part 5 – Steps: checkout and Docker build setup

12. In the `build-test` job, add a `steps` section.

13. **Step – Checkout code**

    - Use `actions/checkout@v4`.
    - Name the step `Checkout`.

    This gives the runner access to the `Dockerfile`, `docker-compose.yml`, and `index.html`.

14. **Step – Setup Buildx**

    - Use the `docker/setup-buildx-action@v3` action.
    - Name the step `Setup Buildx`.

    This prepares Docker Buildx on the runner, which will be used by the build-and-push action.

15. **Step – Docker metadata**

    - Use `docker/metadata-action@v5`.
    - Give the step an `id`, e.g. `meta`.
    - Configure:
      - `images`: `${{ env.IMAGE_NAME }}`
      - `tags`: raw tag based on `${{ env.TAG }}`

    Even if you do not push to a registry in this task, this step establishes a pattern for consistent tagging.

---

## Part 6 – Build the image and start the container via Docker Compose

16. **Step – Build image (local)**

    - Use `docker/build-push-action@v6`.
    - Configure:
      - `context`: `${{ github.workspace }}/CWICZENIA/04-praca-z-zewnetrzymi-akcjami/docker-app-02`
      - `push`: `false` (no registry push in this exercise).
      - `load`: `true` (load the built image into the local Docker daemon on the runner).
      - `tags`: `${{ env.IMAGE_NAME }}:${{ env.TAG }}`

    This step builds the image defined in `Dockerfile` and makes it available for Docker Compose to run.

17. **Step – Compose up**

    - Use `isbang/compose-action@v2`.
    - Configure:
      - `compose-file`: `${{ github.workspace }}/CWICZENIA/04-praca-z-zewnetrzymi-akcjami/docker-app-02/docker-compose.yml`
      - `down-flags`: `--volumes --remove-orphans`
    - Do not specify `commands` explicitly, so the default `up -d` is used.

    With `docker-compose.yml` configured to build and run the `webapp` service mapping `8080:80`, this step will start your container in the background, exposing the static site on `http://localhost:8080/`.

---

## Part 7 – HTTP health checks and assertions

18. **Step – URL Health Check**

    - Use `jtalk/url-health-check-action@v3`.
    - Configure:
      - `url`: `http://localhost:${{ env.HOST_PORT }}/`
      - `max-attempts`: `30`
      - `retry-delay`: `1s`
      - `follow-redirect`: `false`

    This step waits until the homepage is responding with a 2xx status code, retrying up to 30 times with a 1 second delay between attempts.

19. **Step – GET /**

    - Use `Satak/webrequest-action@v1.2.4`.
    - Give the step an `id` such as `page`.
    - Configure:
      - `url`: `http://localhost:${{ env.HOST_PORT }}/`
      - `method`: `GET`

    The response body will be available via `steps.page.outputs.output`.

20. **Step – Assert page contains expected text**

    - Use `actions/github-script@v7`.
    - In the `script` field:
      - Read the page body from `` `${{ steps.page.outputs.output }}` ``.
      - Check that it includes the text `cw04 github actions`.
      - If not, call `core.setFailed` with a clear error message (for example: `"Strona nie zawiera oczekiwanego napisu: "cw04 github actions"."`).

    This step validates that `index.html` was served correctly by Nginx and that the expected label is present in the HTML.

21. **Step – GET /assets/wall.jpg**

    - Use `fjogeleit/http-request-action@v1`.
    - Give the step an `id`, e.g. `img`.
    - Configure:
      - `url`: `http://localhost:${{ env.HOST_PORT }}/assets/wall.jpg`
      - `method`: `GET`
      - `timeout`: `30000` (30 seconds)

    The action exposes outputs such as `status` and `headers` for the response.

22. **Step – Assert image 200**

    - Use `actions/github-script@v7`.
    - In the `script`:
      - Convert the `status` output to a number.
      - Fail the step (`core.setFailed`) if the status code is not `200`.
      - Read the `headers` output, convert to lowercase, and check that it contains one of:
        - `image`
        - `jpeg`
        - `jpg`
      - If none of these substrings are present, issue a warning using `core.warning` (but do not fail the job only because of this).

    This verifies that the image file is accessible and looks like an actual JPEG image based on HTTP headers.

---

## Part 8 – Logs and cleanup (always)

23. **Step – Docker logs (always)**

    - Use `actions/github-script@v7`.
    - Add `if: always()` to ensure the step runs even if previous steps failed.
    - In the `script`:
      - Use Node’s `child_process.execSync` to run `docker logs webapp`.
      - Print the logs to the GitHub Actions log using `core.info`.
      - Wrap the call in a `try/catch` and use `core.warning` if logs cannot be retrieved.

    This step gives you container logs in the run output for easier debugging.

24. **Step – Compose down (always)**

    - Use `isbang/compose-action@v2`.
    - Add `if: always()`.
    - Configure:
      - `compose-file`: the same path as in the `Compose up` step.
      - `commands`: `down --volumes --remove-orphans`

    This step ensures Docker Compose stops the service, removes containers and associated volumes, and cleans up orphaned resources regardless of success or failure in previous steps.

---

## Deliverable

Your final answer should be the completed workflow file:

```text
.github/workflows/04-03-docker-with-actions.yaml
```

It must implement all of the following:

- Correct `on:` triggers for `push`, `pull_request`, and `workflow_dispatch`.
- Concurrency settings to cancel in-progress runs on the same branch.
- A `build-test` job running on `ubuntu-latest` with proper `defaults.run`.
- Environment variables for image name, tag, host and container ports.
- Steps to:
  - Checkout the code.
  - Setup Docker Buildx.
  - Generate Docker metadata.
  - Build and load the Docker image using `docker/build-push-action`.
  - Start the container using `isbang/compose-action`.
  - Perform health checks and assertions on:
    - The homepage HTML content.
    - The image file.
  - Always print Docker logs and bring the Compose stack down.

---

# Zadanie: GitHub Actions CI dla statycznej aplikacji webowej w Dockerze

## Cel

Otrzymujesz prostą statyczną aplikację webową, serwowaną z kontenera Nginx.  
Aplikacja znajduje się w katalogu:

```text
CWICZENIA/04-praca-z-zewnetrzymi-akcjami/docker-app-02
```

W tym katalogu znajdują się m.in.:

- `Dockerfile` – buduje obraz Nginx, który serwuje stronę.
- `docker-compose.yml` – definiuje uruchomienie kontenera za pomocą Docker Compose (serwis `webapp`, mapowanie portów `8080:80`).
- `index.html` – główna strona HTML aplikacji, która musi zawierać w treści napis `cw04 github actions`.

Twoim zadaniem jest utworzenie **workflow GitHub Actions** (pliku YAML), który:

1. Automatycznie buduje i testuje obraz Dockera dla tej aplikacji przy zmianach w określonych gałęziach oraz dla pull requestów.
2. Używa Docker Compose do uruchomienia kontenera na runnerze GitHuba.
3. Wykonuje automatyczne testy HTTP względem działającej aplikacji:
   - Sprawdza, czy strona główna (`/`) odpowiada i zawiera oczekiwany tekst.
   - Sprawdza, czy obraz (`/assets/wall.jpg`) jest dostępny (HTTP 200) i ma nagłówek wskazujący na typ obrazkowy.
4. Zawsze wypisuje logi kontenera oraz zatrzymuje i usuwa stack Dockera na końcu joba.

Końcowym rezultatem jest **jeden plik YAML workflow** zapisany jako:

```text
.github/workflows/04-03-docker-with-actions.yaml
```

---

## Część 1 – Zrozumienie dostarczonych plików

1. Otwórz repozytorium w edytorze (np. VS Code).
2. Przejdź do katalogu:

   ```text
   CWICZENIA/04-praca-z-zewnetrzymi-akcjami/docker-app-02
   ```

3. Przejrzyj dostarczone pliki:

   - **`Dockerfile`** – definiuje, jak zbudować obraz Nginx, który serwuje statyczne pliki z tego katalogu.
   - **`docker-compose.yml`** – zawiera pojedynczą usługę:
     - Nazwa serwisu: `webapp`
     - Nazwa kontenera: `webapp`
     - Kontekst build: bieżący katalog (`.`)
     - Mapowanie portów: host `8080` → kontener `80`
   - **`index.html`** – statyczna strona HTML, która po wystawieniu przez Nginx powinna zawierać napis `cw04 github actions`. Test w workflow sprawdzi obecność tego napisu w odpowiedzi.

W ramach zadania nie musisz zmieniać tych plików – Twoim celem jest **konfiguracja CI w postaci pliku YAML**.

---

## Część 2 – Utworzenie pliku workflow

4. Upewnij się, że w katalogu głównym repozytorium istnieje struktura:

   ```text
   .github/workflows
   ```

   Jeśli jej nie ma – utwórz ją.
5. Wewnątrz `.github/workflows` utwórz nowy plik:

   ```text
   04-03-docker-with-actions.yaml
   ```

   Ten plik będzie zawierał pełną definicję pipeline’u CI.

---

## Część 3 – Konfiguracja wyzwalaczy i concurrency

6. Na początku pliku YAML zdefiniuj czytelną nazwę workflow, np.:

   ```yaml
   name: 04 - Docker Web CI - with actions
   ```

7. Skonfiguruj workflow tak, aby uruchamiał się:

   - przy `push` na gałąź:
     - `docker`
   - przy `pull_request` kierowanym na gałąź:
     - `docker`
   - ręcznie, za pomocą `workflow_dispatch`.

   Sekcja `on:` powinna więc zawierać bloki `push`, `pull_request` oraz `workflow_dispatch`.

8. Dodaj sekcję `concurrency`, aby uniknąć nachodzących na siebie uruchomień dla tej samej gałęzi:

   - Użyj `group: ${{ github.workflow }}-${{ github.ref }}`, aby grupować runy dla tego samego workflow i refa.
   - Ustaw `cancel-in-progress: true`, aby nowe uruchomienie anulowało poprzednie w tej grupie.

---

## Część 4 – Definicja joba, defaults i zmiennych środowiskowych

9. W sekcji `jobs` zdefiniuj pojedynczy job `build-test`:

   ```yaml
   jobs:
     build-test:
       runs-on: ubuntu-latest
   ```

10. Skonfiguruj `defaults.run` dla tego joba, aby:

    - `shell` ustawiony był na `bash`,
    - `working-directory` wskazywał katalog aplikacji:

      ```text
      CWICZENIA/04-praca-z-zewnetrzymi-akcjami/docker-app-02
      ```

    Dzięki temu wszystkie polecenia `run` będą wykonane w poprawnym katalogu.

11. Zdefiniuj w `env` następujące zmienne środowiskowe:

    - `IMAGE_NAME` – krótka nazwa obrazu Dockera, np. `webapp`.
    - `TAG` – tag obrazu ustawiony na SHA commita: `${{ github.sha }}`.
    - `HOST_PORT` – `8080` (port wystawiony na hoście przez Docker Compose).
    - `CONTAINER_PORT` – `80` (port używany wewnątrz kontenera).

---

## Część 5 – Kroki: checkout i konfiguracja builda Dockera

12. W jobie `build-test` dodaj sekcję `steps`.

13. **Krok – Checkout**

    - Użyj akcji `actions/checkout@v4`.
    - Nazwij krok np. `Checkout`.

    Dzięki temu runner otrzyma dostęp do `Dockerfile`, `docker-compose.yml` i `index.html`.

14. **Krok – Setup Buildx**

    - Użyj akcji `docker/setup-buildx-action@v3`.
    - Nazwij krok np. `Setup Buildx`.

    Przygotuje to środowisko Docker Buildx na runnerze.

15. **Krok – Docker metadata**

    - Użyj akcji `docker/metadata-action@v5`.
    - Nadaj krokowi `id`, np. `meta`.
    - Skonfiguruj:
      - `images`: `${{ env.IMAGE_NAME }}`
      - `tags`: tag typu `raw` oparty o `${{ env.TAG }}`

    Nawet jeśli w tym zadaniu nie wypychasz obrazu do rejestru, ten krok buduje poprawny schemat tagowania.

---

## Część 6 – Budowa obrazu i start kontenera przez Docker Compose

16. **Krok – Build image (local)**

    - Użyj akcji `docker/build-push-action@v6`.
    - Skonfiguruj:
      - `context`: `${{ github.workspace }}/CWICZENIA/04-praca-z-zewnetrzymi-akcjami/docker-app-02`
      - `push`: `false` (brak wypchnięcia do rejestru w tym ćwiczeniu),
      - `load`: `true` (załadowanie obrazu do lokalnego demona Dockera),
      - `tags`: `${{ env.IMAGE_NAME }}:${{ env.TAG }}`.

    Ten krok zbuduje obraz z `Dockerfile` i udostępni go do uruchomienia przez Docker Compose.

17. **Krok – Compose up**

    - Użyj akcji `isbang/compose-action@v2`.
    - Skonfiguruj:
      - `compose-file`: `${{ github.workspace }}/CWICZENIA/04-praca-z-zewnetrzymi-akcjami/docker-app-02/docker-compose.yml`
      - `down-flags`: `--volumes --remove-orphans`
    - Nie podawaj jawnie `commands`, tak aby domyślnie wykonało się `up -d`.

    Ponieważ `docker-compose.yml` buduje i uruchamia serwis `webapp` z mapowaniem portu `8080:80`, ten krok wystawi stronę pod adresem `http://localhost:8080/`.

---

## Część 7 – Testy HTTP i asercje

18. **Krok – URL Health Check**

    - Użyj akcji `jtalk/url-health-check-action@v3`.
    - Skonfiguruj:
      - `url`: `http://localhost:${{ env.HOST_PORT }}/`
      - `max-attempts`: `30`
      - `retry-delay`: `1s`
      - `follow-redirect`: `false`

    Krok ten będzie ponawiał zapytania aż do momentu, gdy strona zacznie odpowiadać kodem 2xx (lub do wyczerpania prób).

19. **Krok – GET /**

    - Użyj akcji `Satak/webrequest-action@v1.2.4`.
    - Nadaj krokowi `id`, np. `page`.
    - Skonfiguruj:
      - `url`: `http://localhost:${{ env.HOST_PORT }}/`
      - `method`: `GET`

    Treść odpowiedzi będzie dostępna w `steps.page.outputs.output`.

20. **Krok – Assert page contains expected text**

    - Użyj akcji `actions/github-script@v7`.
    - W polu `script`:
      - Pobierz body strony z `` `${{ steps.page.outputs.output }}` ``.
      - Sprawdź, czy zawiera napis `cw04 github actions`.
      - Jeśli nie – wywołaj `core.setFailed` z czytelnym komunikatem (np. `"Strona nie zawiera oczekiwanego napisu: "cw04 github actions"."`).

    Ten krok weryfikuje, że `index.html` został poprawnie wystawiony przez Nginx i zawiera oczekiwany napis.

21. **Krok – GET /assets/wall.jpg**

    - Użyj akcji `fjogeleit/http-request-action@v1`.
    - Nadaj krokowi `id`, np. `img`.
    - Skonfiguruj:
      - `url`: `http://localhost:${{ env.HOST_PORT }}/assets/wall.jpg`
      - `method`: `GET`
      - `timeout`: `30000` (30 sekund)

    Akcja udostępni m.in. `status` oraz `headers` odpowiedzi.

22. **Krok – Assert image 200**

    - Użyj akcji `actions/github-script@v7`.
    - W skrypcie:
      - Zamień `status` na liczbę.
      - Jeśli status jest różny od `200`, wywołaj `core.setFailed`.
      - Odczytaj nagłówki z `steps.img.outputs.headers`, zamień na małe litery i sprawdź, czy zawierają jedną z fraz:
        - `image`
        - `jpeg`
        - `jpg`
      - Jeśli żadna z nich nie występuje – zgłoś ostrzeżenie (`core.warning`), ale nie przerywaj joba tylko z tego powodu.

    Ten krok weryfikuje, że plik obrazka jest dostępny i wygląda na obraz JPEG po nagłówkach HTTP.

---

## Część 8 – Logi i sprzątanie (zawsze)

23. **Krok – Docker logs (always)**

    - Użyj akcji `actions/github-script@v7`.
    - Dodaj `if: always()`, aby krok wykonał się nawet przy błędach we wcześniejszych krokach.
    - W `script`:
      - Użyj `child_process.execSync`, aby wykonać `docker logs webapp`.
      - Wypisz logi do logów workflow za pomocą `core.info`.
      - Obsłuż błędy w `try/catch` i przy problemach użyj `core.warning`.

    Dzięki temu w logach runu zobaczysz logi kontenera, co ułatwia debugowanie.

24. **Krok – Compose down (always)**

    - Użyj akcji `isbang/compose-action@v2`.
    - Dodaj `if: always()`.
    - Skonfiguruj:
      - `compose-file`: tę samą ścieżkę co w kroku `Compose up`,
      - `commands`: `down --volumes --remove-orphans`.

    Ten krok zatrzymuje serwis, usuwa kontenery oraz powiązane wolumeny i sprząta „osierocone” zasoby, niezależnie od sukcesu lub porażki poprzednich kroków.

---

## Rezultat

Twoim ostatecznym rezultatem jest **plik YAML workflow**:

```text
.github/workflows/04-03-docker-with-actions.yaml
```

Plik musi zawierać:

- poprawnie skonfigurowane wyzwalacze (`push`, `pull_request`, `workflow_dispatch`),
- sekcję `concurrency` anulującą poprzednie runy dla tej samej gałęzi,
- job `build-test` na `ubuntu-latest` z odpowiednim `defaults.run`,
- zmienne środowiskowe dla nazwy obrazu, tagu oraz portów,
- kroki:
  - checkout kodu,
  - konfiguracja Docker Buildx,
  - generowanie metadanych Dockera,
  - build i załadowanie obrazu przy użyciu `docker/build-push-action`,
  - start kontenera przez `isbang/compose-action`,
  - health check i asercje dla strony HTML oraz obrazka,
  - zawsze wykonywane: logi kontenera i zamknięcie stacka Compose.

Dostarczony plik YAML powinien umożliwiać pełne zautomatyzowanie testu statycznej aplikacji webowej w Dockerze w opisany powyżej sposób.
