# Exercise: Recreate the GitHub Actions Workflow – Docker Matrix Build / Test / Push

## Part 1 – English Instructions

Your task is to **recreate a complete GitHub Actions workflow** that builds, tests, and pushes Docker images for three environments using a matrix strategy.  
The final result of this exercise should be a workflow file that matches the provided YAML in structure and behavior.

Each point below describes a **step you must perform**. If you follow all the steps, you will end up with the exact workflow configuration.

---

### 1. Create the workflow file and basic header

1. In your repository, create a new workflow file under:
   - `.github/workflows/16_03-docker-matrix.yml` (or a similar name, but keep it consistent).

2. At the very top of the file, define the workflow name by adding:
   ```yaml
   name: 16_03 - Docker matrix build / test / push (only Docker Hub)
   ```

---

### 2. Configure workflow triggers

3. Configure the workflow to run on three types of events:
   - Push events to branch `cw16`.
   - Pull requests targeting branch `cw16`.
   - Manual runs via the GitHub UI (workflow dispatch).

   Add the following block:
   ```yaml
   on:
     push:
       branches:
         - cw16
     pull_request:
       branches:
         - cw16
     workflow_dispatch:
   ```

This ensures the workflow runs automatically on code changes to the `cw16` branch and can also be executed manually.

---

### 3. Set global defaults and environment variables

4. Configure global defaults for all shell commands executed in `run:` steps so that:
   - They use `bash` as the shell.
   - They run inside the directory: `./CWICZENIA/16-environments/docker01` (your Docker exercise folder).

   Add:
   ```yaml
   defaults:
     run:
       shell: bash
       working-directory: ./CWICZENIA/16-environments/docker01
   ```

5. Define global environment variables used across all jobs:
   - `IMAGE_NAME` – base name for the Docker image (`github-action-test`).
   - `DOCKERHUB_REPO` – full Docker Hub repository path (`piotrskoska/github-action-test`).

   Add:
   ```yaml
   env:
     IMAGE_NAME: github-action-test
     DOCKERHUB_REPO: piotrskoska/github-action-test
   ```

These variables will be reused in later steps to reduce repetition.

---

### 4. Define Job 1 – BUILD (development & staging)

6. Start the `jobs:` section and define the first job called `build`:
   - Configure it to run on the `ubuntu-latest` runner.

   ```yaml
   jobs:
     build:
       runs-on: ubuntu-latest
   ```

7. Inside the `build` job, define a **matrix strategy** with two entries:
   - One for the `development` environment.
   - One for the `staging` environment.

   For each matrix entry, define:
   - `environment` – name of the logical environment (`development` or `staging`),
   - `app_env` – value passed to the Docker build argument (`dev` or `staging`),
   - `image_tag` – tag used for the Docker image (`dev` or `staging`).

   Add:
   ```yaml
       strategy:
         matrix:
           include:
             - environment: development
               app_env: dev
               image_tag: dev
             - environment: staging
               app_env: staging
               image_tag: staging
   ```

8. Create the `steps:` section for the `build` job:
   ```yaml
       steps:
   ```

9. Add the first step to **check out the repository** so the workflow runner has access to your code and Dockerfile:
   ```yaml
         - name: Checkout repository
           uses: actions/checkout@v4
   ```

10. Add a diagnostic step to log which matrix entry is being processed:
    - Print `environment`, `app_env`, and `image_tag` for visibility in the workflow logs.

    ```yaml
         - name: Show build matrix entry
           run: |
             echo "BUILD for environment: ${{ matrix.environment }}"
             echo "APP_ENV: ${{ matrix.app_env }}"
             echo "IMAGE_TAG: ${{ matrix.image_tag }}"
    ```

11. Add a step to **log in to Docker Hub**, using a repository secret for authentication:
    - Use `DOCKERHUB_TOKEN` secret to authenticate as the `piotrskoska` user.

    ```yaml
         - name: Login to Docker Hub
           run: |
             echo "${{ secrets.DOCKERHUB_TOKEN }}" | docker login -u "piotrskoska" --password-stdin
    ```

12. Add a step to **build and push the Docker image** for the current matrix entry:
    - Use the matrix variables to set:
      - `TAG` from `matrix.image_tag` (`dev` or `staging`),
      - `APP_ENV` from `matrix.app_env` (`dev` or `staging`),
      - `FULL_IMAGE` as the full Docker Hub image name (`DOCKERHUB_REPO:TAG`).
    - Build the Docker image with `--build-arg APP_ENV`.
    - Tag the image using the full repository name.
    - Push the image to Docker Hub.

    ```yaml
         - name: Build and push Docker image (non-prod)
           run: |
             TAG="${{ matrix.image_tag }}"
             APP_ENV="${{ matrix.app_env }}"
             FULL_IMAGE="${DOCKERHUB_REPO}:${TAG}"

             echo "Building image ${IMAGE_NAME}:${TAG} with APP_ENV=${APP_ENV}"
             docker build                --build-arg APP_ENV="${APP_ENV}"                -t "${IMAGE_NAME}:${TAG}" .

             echo "Tagging ${IMAGE_NAME}:${TAG} -> $FULL_IMAGE"
             docker tag "${IMAGE_NAME}:${TAG}" "$FULL_IMAGE"

             echo "Pushing $FULL_IMAGE"
             docker push "$FULL_IMAGE"
    ```

At this point, the `build` job builds and pushes two images:
- `piotrskoska/github-action-test:dev`
- `piotrskoska/github-action-test:staging`

---

### 5. Define Job 2 – TEST (development & staging)

13. Create a second job named `test`:
    - Run on `ubuntu-latest`.
    - Make it depend on the `build` job so that testing only happens after images are built and pushed.

    ```yaml
   test:
     runs-on: ubuntu-latest
     needs: build
    ```

14. Reuse the same matrix as in the `build` job so tests are executed separately for `development` and `staging`:

    ```yaml
     strategy:
       matrix:
         include:
           - environment: development
             app_env: dev
             image_tag: dev
           - environment: staging
             app_env: staging
             image_tag: staging
    ```

15. Start the `steps:` section for the `test` job:
    ```yaml
     steps:
    ```

16. Add a step to check out the repository again (mainly for consistency and potential future needs):
    ```yaml
       - name: Checkout repository
         uses: actions/checkout@v4
    ```

17. Add a step to log in to Docker Hub (optional but required if the images are private):
    ```yaml
       # opcjonalnie możesz się zalogować, jeśli repo w Docker Hub jest prywatne
       - name: Login to Docker Hub (optional for private repos)
         run: |
           echo "${{ secrets.DOCKERHUB_TOKEN }}" | docker login -u "piotrskoska" --password-stdin
    ```

18. Add a step to **pull and test the Docker image from Docker Hub**:
    - Derive `TAG`, `APP_ENV`, and `FULL_IMAGE` similarly to the build job.
    - Pull the image from Docker Hub.
    - Run a container using `docker run --rm`.
    - Capture the container’s output.
    - Compute the expected output: `Hello from environment: ${APP_ENV}`.
    - Compare actual vs expected output and fail the job if they differ.

    ```yaml
       - name: Pull and test Docker image from Docker Hub
         run: |
           TAG="${{ matrix.image_tag }}"
           APP_ENV="${{ matrix.app_env }}"
           FULL_IMAGE="${DOCKERHUB_REPO}:${TAG}"

           echo "Pulling $FULL_IMAGE"
           docker pull "$FULL_IMAGE"

           echo "Running container for $FULL_IMAGE"
           OUTPUT="$(docker run --rm "$FULL_IMAGE")"
           EXPECTED="Hello from environment: ${APP_ENV}"

           echo "Container output: $OUTPUT"

           if [[ "$OUTPUT" != "$EXPECTED" ]]; then
             echo "❌ TEST FAILED (expected: '$EXPECTED')"
             exit 1
           fi

           echo "✅ TEST PASSED for $FULL_IMAGE"
    ```

Now the `test` job ensures that both non-production images (`dev` and `staging`) behave as expected.

---

### 6. Define Job 3 – PRODUCTION (build, test and push)

19. Create a third job named `production`:
    - Run on `ubuntu-latest`.
    - Make it depend on `test`:
      - This guarantees it only runs when tests for `development` and `staging` passed successfully.

    ```yaml
   production:
     runs-on: ubuntu-latest
     # will start only when ALL matrix entries in 'test' passed
     needs: test
    ```

20. Attach a GitHub Environment to this job for production:
    - Use:
      ```yaml
      environment: production
      ```

21. Define job-specific environment variables for production:
    - `APP_ENV: prod`
    - `IMAGE_TAG: production` (this will be appended to the Docker Hub repo).

    ```yaml
     environment: production

     env:
       APP_ENV: prod
       IMAGE_TAG: production   # tag in Docker Hub: piotrskoska/github-action-test:production
    ```

22. Start the `steps:` section for the `production` job:
    ```yaml
     steps:
    ```

23. Add a step to check out the repository:
    ```yaml
       - name: Checkout repository
         uses: actions/checkout@v4
    ```

24. Add a step to log in to Docker Hub using the same `DOCKERHUB_TOKEN` secret:
    ```yaml
       - name: Login to Docker Hub
         run: |
           echo "${{ secrets.DOCKERHUB_TOKEN }}" | docker login -u "piotrskoska" --password-stdin
    ```

25. Add a step to **build the production Docker image**:
    - Use the job-level `APP_ENV` and `IMAGE_TAG` variables.
    - Build with `--build-arg APP_ENV="${APP_ENV}"`.
    - Tag the built image as `${IMAGE_NAME}:${IMAGE_TAG}`.

    ```yaml
       - name: Build production image
         run: |
           echo "Building production image ${IMAGE_NAME}:${IMAGE_TAG} with APP_ENV=${APP_ENV}"
           docker build              --build-arg APP_ENV="${APP_ENV}"              -t "${IMAGE_NAME}:${IMAGE_TAG}" .
    ```

26. Add a step to **test the production image**:
    - Run the container and compare its output against the expected text.

    ```yaml
       - name: Test production image
         run: |
           echo "Testing production image ${IMAGE_NAME}:${IMAGE_TAG}"

           OUTPUT="$(docker run --rm "${IMAGE_NAME}:${IMAGE_TAG}")"
           EXPECTED="Hello from environment: ${APP_ENV}"

           echo "Container output: $OUTPUT"
           if [[ "$OUTPUT" != "$EXPECTED" ]]; then
             echo "❌ PROD TEST FAILED"
             exit 1
           fi

           echo "✅ PROD TEST PASSED"
    ```

27. Add a step to compute the **full Docker Hub image name** for the production tag:
    - Build `FULL_IMAGE` from `DOCKERHUB_REPO` and `IMAGE_TAG`.
    - Store it in `GITHUB_ENV` for later use.

    ```yaml
       - name: Compute FULL_IMAGE for Docker Hub (prod)
         run: |
           FULL_IMAGE="${DOCKERHUB_REPO}:${IMAGE_TAG}"
           echo "FULL_IMAGE=$FULL_IMAGE" >> "$GITHUB_ENV"
           echo "Prod image: $FULL_IMAGE"
    ```

28. Add the final step to **tag and push the production image**:
    - Tag: from local `${IMAGE_NAME}:${IMAGE_TAG}` to `$FULL_IMAGE`.
    - Push: `docker push $FULL_IMAGE`.

    ```yaml
       - name: Tag and push production image
         run: |
           echo "Tagging ${IMAGE_NAME}:${IMAGE_TAG} -> $FULL_IMAGE"
           docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "$FULL_IMAGE"
           echo "Pushing $FULL_IMAGE"
           docker push "$FULL_IMAGE"
    ```

After completing all steps above, you will have recreated the full workflow that:
- Builds and pushes `dev` and `staging` images,
- Tests them from Docker Hub,
- Builds, tests, and pushes a `production` image only after non-prod tests pass.

---

## Part 2 – Instrukcje po polsku

Twoim zadaniem jest **odtworzenie kompletnego workflow GitHub Actions**, który buduje, testuje i wysyła obrazy Dockera dla trzech środowisk z użyciem macierzy.  
Końcowym efektem ma być plik YAML zachowujący się dokładnie tak, jak przekazany workflow.

Poniżej każdy krok opisuje **konkretne zadanie**, które musisz wykonać, aby ten plik odtworzyć.

---

### 1. Utwórz plik workflow i podstawowy nagłówek

1. W swoim repozytorium utwórz nowy plik workflow:
   - `.github/workflows/16_03-docker-matrix.yml` (lub inną, spójną nazwę).

2. Na samej górze pliku ustaw nazwę workflow:
   ```yaml
   name: 16_03 - Docker matrix build / test / push (only Docker Hub)
   ```

---

### 2. Skonfiguruj wyzwalacze workflow

3. Skonfiguruj workflow tak, aby uruchamiał się w trzech sytuacjach:
   - Przy `push` na branch `cw16`,
   - Przy `pull_request` na branch `cw16`,
   - Przy ręcznym uruchomieniu z UI GitHuba (`workflow_dispatch`).

   Dodaj blok:
   ```yaml
   on:
     push:
       branches:
         - cw16
     pull_request:
       branches:
         - cw16
     workflow_dispatch:
   ```

Dzięki temu workflow reaguje na zmiany w gałęzi ćwiczeniowej oraz może być odpalany ręcznie.

---

### 3. Ustaw domyślne ustawienia globalne i zmienne środowiskowe

4. Dodaj globalne ustawienia `defaults` dla wszystkich kroków `run:`, tak aby:
   - Używały powłoki `bash`,
   - Wykonywały się w katalogu: `./CWICZENIA/16-environments/docker01` (folder z ćwiczeniem Dockera).

   Dodaj:
   ```yaml
   defaults:
     run:
       shell: bash
       working-directory: ./CWICZENIA/16-environments/docker01
   ```

5. Zdefiniuj globalne zmienne środowiskowe używane w jobach:
   - `IMAGE_NAME` – bazowa nazwa obrazu Dockera (`github-action-test`),
   - `DOCKERHUB_REPO` – pełna ścieżka repo w Docker Hub (`piotrskoska/github-action-test`).

   Dodaj:
   ```yaml
   env:
     IMAGE_NAME: github-action-test
     DOCKERHUB_REPO: piotrskoska/github-action-test
   ```

Te zmienne będziesz wykorzystywać później przy budowaniu i pushowaniu obrazów.

---

### 4. Zdefiniuj Job 1 – BUILD (development i staging)

6. Rozpocznij sekcję `jobs:` i dodaj pierwszy job `build`:
   - Ma działać na maszynie `ubuntu-latest`.

   ```yaml
   jobs:
     build:
       runs-on: ubuntu-latest
   ```

7. W jobie `build` skonfiguruj **strategię macierzy** z dwoma wpisami:
   -dla środowiska `development`,
   -dla środowiska `staging`.

   Dla każdego wpisu określ:
   - `environment` – nazwa środowiska logicznego (`development` lub `staging`),
   - `app_env` – wartość przekazywana do argumentu builda (`dev` lub `staging`),
   - `image_tag` – tag obrazu (`dev` lub `staging`).

   Dodaj:
   ```yaml
       strategy:
         matrix:
           include:
             - environment: development
               app_env: dev
               image_tag: dev
             - environment: staging
               app_env: staging
               image_tag: staging
   ```

8. Utwórz sekcję `steps:` w jobie `build`:
   ```yaml
       steps:
   ```

9. Dodaj krok **pobierający kod** repozytorium:
   ```yaml
         - name: Checkout repository
           uses: actions/checkout@v4
   ```

10. Dodaj krok diagnostyczny, który wypisze wartości macierzy dla aktualnego przebiegu:
    ```yaml
         - name: Show build matrix entry
           run: |
             echo "BUILD for environment: ${{ matrix.environment }}"
             echo "APP_ENV: ${{ matrix.app_env }}"
             echo "IMAGE_TAG: ${{ matrix.image_tag }}"
    ```

11. Dodaj krok **logowania do Docker Huba**, wykorzystując sekret `DOCKERHUB_TOKEN`:
    ```yaml
         - name: Login to Docker Hub
           run: |
             echo "${{ secrets.DOCKERHUB_TOKEN }}" | docker login -u "piotrskoska" --password-stdin
    ```

12. Dodaj krok, który **buduje i wysyła obraz Dockera** dla aktualnej pozycji w macierzy:
    - pobiera `TAG` i `APP_ENV` z `matrix`,
    - buduje lokalny obraz `${IMAGE_NAME}:${TAG}`,
    - taguje go jako pełny obraz Docker Hub (`${DOCKERHUB_REPO}:${TAG}`),
    - wykonuje `docker push`.

    ```yaml
         - name: Build and push Docker image (non-prod)
           run: |
             TAG="${{ matrix.image_tag }}"
             APP_ENV="${{ matrix.app_env }}"
             FULL_IMAGE="${DOCKERHUB_REPO}:${TAG}"

             echo "Building image ${IMAGE_NAME}:${TAG} with APP_ENV=${APP_ENV}"
             docker build                --build-arg APP_ENV="${APP_ENV}"                -t "${IMAGE_NAME}:${TAG}" .

             echo "Tagging ${IMAGE_NAME}:${TAG} -> $FULL_IMAGE"
             docker tag "${IMAGE_NAME}:${TAG}" "$FULL_IMAGE"

             echo "Pushing $FULL_IMAGE"
             docker push "$FULL_IMAGE"
    ```

Po tym jobie w Docker Hub powinny istnieć obrazy:
- `piotrskoska/github-action-test:dev`
- `piotrskoska/github-action-test:staging`

---

### 5. Zdefiniuj Job 2 – TEST (development i staging)

13. Dodaj drugi job `test`:
    - wykonuje się na `ubuntu-latest`,
    - ma zależność `needs: build`, aby uruchomić się dopiero po zakończeniu budowania i pushowania obrazów.

    ```yaml
   test:
     runs-on: ubuntu-latest
     needs: build
    ```

14. Ponownie użyj tej samej macierzy co w jobie `build`:
    ```yaml
     strategy:
       matrix:
         include:
           - environment: development
             app_env: dev
             image_tag: dev
           - environment: staging
             app_env: staging
             image_tag: staging
    ```

15. Utwórz sekcję `steps:` dla joba `test`:
    ```yaml
     steps:
    ```

16. Dodaj krok ponownie pobierający repozytorium:
    ```yaml
       - name: Checkout repository
         uses: actions/checkout@v4
    ```

17. Dodaj krok logowania do Docker Huba (potrzebny, jeśli obrazy są prywatne):
    ```yaml
       # opcjonalnie możesz się zalogować, jeśli repo w Docker Hub jest prywatne
       - name: Login to Docker Hub (optional for private repos)
         run: |
           echo "${{ secrets.DOCKERHUB_TOKEN }}" | docker login -u "piotrskoska" --password-stdin
    ```

18. Dodaj krok, który **pobiera i testuje obraz Dockera z Docker Huba**:
    - oblicza `TAG`, `APP_ENV`, `FULL_IMAGE`,
    - wykonuje `docker pull`,
    - uruchamia kontener,
    - porównuje wyjście kontenera z oczekiwanym tekstem,
    - jeśli się nie zgadza – kończy job błędem.

    ```yaml
       - name: Pull and test Docker image from Docker Hub
         run: |
           TAG="${{ matrix.image_tag }}"
           APP_ENV="${{ matrix.app_env }}"
           FULL_IMAGE="${DOCKERHUB_REPO}:${TAG}"

           echo "Pulling $FULL_IMAGE"
           docker pull "$FULL_IMAGE"

           echo "Running container for $FULL_IMAGE"
           OUTPUT="$(docker run --rm "$FULL_IMAGE")"
           EXPECTED="Hello from environment: ${APP_ENV}"

           echo "Container output: $OUTPUT"

           if [[ "$OUTPUT" != "$EXPECTED" ]]; then
             echo "❌ TEST FAILED (expected: '$EXPECTED')"
             exit 1
           fi

           echo "✅ TEST PASSED for $FULL_IMAGE"
    ```

Ten job weryfikuje działanie obrazów `dev` i `staging` po stronie Docker Huba.

---

### 6. Zdefiniuj Job 3 – PRODUCTION (build, test i push)

19. Dodaj trzeci job o nazwie `production`:
    - działa na `ubuntu-latest`,
    - ma zależność `needs: test`, więc uruchomi się tylko, gdy testy `development` i `staging` zakończą się sukcesem.

    ```yaml
   production:
     runs-on: ubuntu-latest
     # wystartuje dopiero, gdy WSZYSTKIE matrixy jobu "test" przejdą (dev + staging)
     needs: test
    ```

20. Podłącz job do środowiska GitHub `production`:
    ```yaml
     environment: production
    ```

21. Dodaj sekcję `env` specyficzną dla produkcji:
    - `APP_ENV: prod`
    - `IMAGE_TAG: production`

    ```yaml
     env:
       APP_ENV: prod
       IMAGE_TAG: production   # tag w Docker Hub: piotrskoska/github-action-test:production
    ```

22. Rozpocznij sekcję `steps:`:
    ```yaml
     steps:
    ```

23. Dodaj krok `Checkout repository`:
    ```yaml
       - name: Checkout repository
         uses: actions/checkout@v4
    ```

24. Dodaj krok logowania do Docker Huba:
    ```yaml
       - name: Login to Docker Hub
         run: |
           echo "${{ secrets.DOCKERHUB_TOKEN }}" | docker login -u "piotrskoska" --password-stdin
    ```

25. Dodaj krok **budujący obraz produkcyjny**:
    ```yaml
       - name: Build production image
         run: |
           echo "Building production image ${IMAGE_NAME}:${IMAGE_TAG} with APP_ENV=${APP_ENV}"
           docker build              --build-arg APP_ENV="${APP_ENV}"              -t "${IMAGE_NAME}:${IMAGE_TAG}" .
    ```

26. Dodaj krok **testujący obraz produkcyjny**:
    ```yaml
       - name: Test production image
         run: |
           echo "Testing production image ${IMAGE_NAME}:${IMAGE_TAG}"

           OUTPUT="$(docker run --rm "${IMAGE_NAME}:${IMAGE_TAG}")"
           EXPECTED="Hello from environment: ${APP_ENV}"

           echo "Container output: $OUTPUT"
           if [[ "$OUTPUT" != "$EXPECTED" ]]; then
             echo "❌ PROD TEST FAILED"
             exit 1
           fi

           echo "✅ PROD TEST PASSED"
    ```

27. Dodaj krok wyliczający pełną nazwę obrazu produkcyjnego:
    ```yaml
       - name: Compute FULL_IMAGE for Docker Hub (prod)
         run: |
           FULL_IMAGE="${DOCKERHUB_REPO}:${IMAGE_TAG}"
           echo "FULL_IMAGE=$FULL_IMAGE" >> "$GITHUB_ENV"
           echo "Prod image: $FULL_IMAGE"
    ```

28. Dodaj końcowy krok tagujący i pushujący obraz produkcyjny do Docker Huba:
    ```yaml
       - name: Tag and push production image
         run: |
           echo "Tagging ${IMAGE_NAME}:${IMAGE_TAG} -> $FULL_IMAGE"
           docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "$FULL_IMAGE"
           echo "Pushing $FULL_IMAGE"
           docker push "$FULL_IMAGE"
    ```

Po wykonaniu wszystkich powyższych zadań odtworzysz kompletny workflow, w którym:
- obrazy `dev` i `staging` są budowane, wysyłane i testowane,
- obraz produkcyjny jest budowany, testowany i pushowany dopiero po przejściu testów dla środowisk nieprodukcyjnych.
