# Exercise: Recreate the GitHub Actions Workflow for Docker Matrix Build / Test / Push

## Part 1 – English Instructions

Your goal in this exercise is to **build a complete GitHub Actions workflow** that automates building, testing and publishing Docker images for multiple environments (`development`, `staging`, `production`).  
The final result of all tasks below should be a workflow file identical in behavior and structure to the YAML you were given.

Follow the steps in order. Each step corresponds to one or more lines in the final workflow.

---

### 1. Define the workflow header

1. Create a new file in your repository under:
   - `.github/workflows/16_02-docker-matrix.yml` (or any name you prefer, but keep it consistent).

2. At the top of the file, set the workflow name:
   - Configure the line:
     - `name: 16_02 - Docker matrix build / test / push (only Docker Hub)`

3. Configure workflow triggers so that it runs on:
   - Push to branch:
     - `cw16`
   - Pull requests targeting branch:
     - `cw16`
   - Manual run from GitHub UI (`workflow_dispatch`).  
   Add the block:
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

---

### 2. Configure global defaults and environment variables

4. Add global defaults for all `run:` steps so they:
   - Use `bash` as the shell.
   - Execute commands in the directory: `./CWICZENIA/16-environments/docker01`.

   Add:
   ```yaml
   defaults:
     run:
       shell: bash
       working-directory: ./CWICZENIA/16-environments/docker01
   ```

5. Define global environment variables for the workflow:
   - `IMAGE_NAME` = `github-action-test`
   - `DOCKERHUB_REPO` = `piotrskoska/github-action-test`

   Add:
   ```yaml
   env:
     IMAGE_NAME: github-action-test
     DOCKERHUB_REPO: piotrskoska/github-action-test
   ```

These values will be reused by all jobs and steps.

---

### 3. Create Job 1 – BUILD (development & staging)

6. Start the `jobs:` section and define the first job named `build`:
   - The job should run on `ubuntu-latest`.

   ```yaml
   jobs:
     build:
       runs-on: ubuntu-latest
   ```

7. Configure a **matrix strategy** to build for two environments:
   - `development` with:
     - `app_env: dev`
     - `image_tag: dev`
   - `staging` with:
     - `app_env: staging`
     - `image_tag: staging`

   Add inside `build`:
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

8. Create the `steps:` section for the `build` job.

9. Add a step to checkout the repository code:
   - Name: `Checkout repository`
   - Use action: `actions/checkout@v4`

   ```yaml
       steps:
         - name: Checkout repository
           uses: actions/checkout@v4
   ```

10. Add a diagnostic step to display the current matrix configuration:
    - Use `echo` to print:
      - Current `environment`
      - `app_env`
      - `image_tag`

    ```yaml
         - name: Show build matrix entry
           run: |
             echo "BUILD for environment: ${{ matrix.environment }}"
             echo "APP_ENV: ${{ matrix.app_env }}"
             echo "IMAGE_TAG: ${{ matrix.image_tag }}"
    ```

11. Add a step to **build the Docker image** using the matrix values:
    - Use `docker build` with `--build-arg APP_ENV` based on `matrix.app_env`.
    - Tag the image as `${IMAGE_NAME}:${{ matrix.image_tag }}`.

    ```yaml
         - name: Build Docker image
           run: |
             docker build                --build-arg APP_ENV="${{ matrix.app_env }}"                -t "${IMAGE_NAME}:${{ matrix.image_tag }}" .
    ```

12. Add a step to **save the built image** into a `tar` archive:
    - Use `docker save` to export the image to `image.tar`.

    ```yaml
         - name: Save image as tar (artifact)
           run: |
             docker save "${IMAGE_NAME}:${{ matrix.image_tag }}" -o image.tar
    ```

13. Add a step to **upload the image tarball as an artifact**:
    - Use `actions/upload-artifact@v4`.
    - Set the artifact name to `docker-image-${{ matrix.environment }}`.
    - Set the path to the full path of `image.tar` in the working directory.

    ```yaml
         - name: Upload image artifact
           uses: actions/upload-artifact@v4
           with:
             name: docker-image-${{ matrix.environment }}
             path: ./CWICZENIA/16-environments/docker01/image.tar
    ```

At this point, the `build` job creates two artifacts: one for `development`, one for `staging`.

---

### 4. Create Job 2 – TEST (development & staging)

14. Define a second job named `test`:
    - It should run on `ubuntu-latest`.
    - It must depend on `build`:
      - Use `needs: build` so it only executes after a successful build.

    ```yaml
  test:
    runs-on: ubuntu-latest
    needs: build
    ```

15. Use the same matrix configuration as in `build`:
    - `development` (`app_env: dev`, `image_tag: dev`)
    - `staging` (`app_env: staging`, `image_tag: staging`)

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

16. Start the `steps:` for the `test` job.

17. Add a step to checkout the repository again (for context):
    ```yaml
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
    ```

18. Add a step to download the image artifact created in the `build` job:
    - Use `actions/download-artifact@v4`.
    - Use the same artifact name pattern as in `build`:
      - `docker-image-${{ matrix.environment }}`.
    - Download into the working directory path.

    ```yaml
      - name: Download image artifact
        uses: actions/download-artifact@v4
        with:
          name: docker-image-${{ matrix.environment }}
          path: ./CWICZENIA/16-environments/docker01
    ```

19. Add a step to **load the Docker image** from `image.tar`:
    - Optionally list the files for debugging.
    - Use `docker load -i image.tar`.

    ```yaml
      - name: Load Docker image from artifact
        run: |
          ls -l
          docker load -i image.tar
    ```

20. Add a step to **test the Docker image**:
    - Run the image with `docker run --rm`.
    - Capture its output into a variable.
    - Compute the expected text using `matrix.app_env`:
      - `"Hello from environment: <app_env>"`
    - Compare actual vs expected and fail the job if they differ.

    ```yaml
      - name: Test Docker image
        run: |
          echo "Testing image ${IMAGE_NAME}:${{ matrix.image_tag }} for env ${{ matrix.environment }}"

          OUTPUT="$(docker run --rm "${IMAGE_NAME}:${{ matrix.image_tag }}")"
          EXPECTED="Hello from environment: ${{ matrix.app_env }}"

          echo "Container output: $OUTPUT"
          if [[ "$OUTPUT" != "$EXPECTED" ]]; then
            echo "❌ TEST FAILED"
            exit 1
          fi

          echo "✅ TEST PASSED"
    ```

Now each matrix entry (`development`, `staging`) is built and tested separately.

---

### 5. Create Job 3 – PUSH non-production images to Docker Hub

21. Create a third job named `push-nonprod`:
    - It should run on `ubuntu-latest`.
    - It must depend on the `test` job:
      - Use `needs: test`.

    ```yaml
  push-nonprod:
    runs-on: ubuntu-latest
    needs: test
    ```

22. Reuse the same matrix for `development` and `staging` as in the previous jobs.

23. Attach GitHub Environments to each matrix entry using:
    - `environment: ${{ matrix.environment }}`

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

    environment: ${{ matrix.environment }}
    ```

24. Start the steps for the `push-nonprod` job.

25. Add a step to checkout the repository again:
    ```yaml
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
    ```

26. Add a step to download the image artifact for the current environment:
    - Use `actions/download-artifact@v4`.
    - Use the same artifact name and path as earlier.

    ```yaml
      - name: Download image artifact
        uses: actions/download-artifact@v4
        with:
          name: docker-image-${{ matrix.environment }}
          path: ./CWICZENIA/16-environments/docker01
    ```

27. Add a step to load the Docker image from `image.tar`:
    ```yaml
      - name: Load Docker image from artifact
        run: |
          docker load -i image.tar
    ```

28. Add a step to compute the **full image name** for Docker Hub:
    - Construct it as `${DOCKERHUB_REPO}:${{ matrix.image_tag }}`.
    - Store it in the environment variable `FULL_IMAGE` using `GITHUB_ENV`.

    ```yaml
      - name: Compute FULL_IMAGE for Docker Hub (non-prod)
        run: |
          FULL_IMAGE="${DOCKERHUB_REPO}:${{ matrix.image_tag }}"
          echo "FULL_IMAGE=$FULL_IMAGE" >> "$GITHUB_ENV"
          echo "Non-prod image: $FULL_IMAGE"
    ```

29. Add a step to **log in to Docker Hub**:
    - Use `docker login -u "piotrskoska"`.
    - Read the password/token from `${{ secrets.DOCKERHUB_TOKEN }}` via `--password-stdin`.

    ```yaml
      - name: Login to Docker Hub
        run: |
          echo "${{ secrets.DOCKERHUB_TOKEN }}" | docker login -u "piotrskoska" --password-stdin
    ```

30. Add a step to tag and push the non-production image:
    - Tag: from local `${IMAGE_NAME}:${{ matrix.image_tag }}` to `$FULL_IMAGE`.
    - Push: `docker push $FULL_IMAGE`.

    ```yaml
      - name: Tag and push image (non-prod)
        run: |
          echo "Tagging ${IMAGE_NAME}:${{ matrix.image_tag }} -> $FULL_IMAGE"
          docker tag "${IMAGE_NAME}:${{ matrix.image_tag }}" "$FULL_IMAGE"
          echo "Pushing $FULL_IMAGE"
          docker push "$FULL_IMAGE"
    ```

This job publishes the `development` and `staging` images to Docker Hub.

---

### 6. Create Job 4 – PRODUCTION (build, test, push after dev+staging)

31. Define the `production` job:
    - Runs on `ubuntu-latest`.
    - Uses `needs: test` so it only runs if both `development` and `staging` tests have passed.
    - Uses GitHub environment `production`.

    ```yaml
  production:
    runs-on: ubuntu-latest
    needs: test
    environment: production
    ```

32. Define production-specific environment variables for this job:
    - `APP_ENV: prod`
    - `IMAGE_TAG: production`

    ```yaml
    env:
      APP_ENV: prod
      IMAGE_TAG: production   # tag in Docker Hub
    ```

33. Start the `steps:` list for the `production` job.

34. Add a step to checkout the repository:
    ```yaml
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
    ```

35. Add a step to **build the production image**:
    - Use `APP_ENV` and `IMAGE_TAG` defined in `env`.
    - Build with `--build-arg APP_ENV="${APP_ENV}"`.
    - Tag image as `${IMAGE_NAME}:${IMAGE_TAG}`.

    ```yaml
      - name: Build production image
        run: |
          docker build             --build-arg APP_ENV="${APP_ENV}"             -t "${IMAGE_NAME}:${IMAGE_TAG}" .
    ```

36. Add a step to **test the production image**:
    - Run the container, capture output.
    - Compare against the expected string `"Hello from environment: ${APP_ENV}"`.

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

37. Add a step to log in to Docker Hub using the same secret token:
    ```yaml
      - name: Login to Docker Hub
        run: |
          echo "${{ secrets.DOCKERHUB_TOKEN }}" | docker login -u "piotrskoska" --password-stdin
    ```

38. Add a step to compute the full Docker Hub image name for production:
    - `FULL_IMAGE="${DOCKERHUB_REPO}:${IMAGE_TAG}"`
    - Store it in `GITHUB_ENV`.

    ```yaml
      - name: Compute FULL_IMAGE for Docker Hub (prod)
        run: |
          FULL_IMAGE="${DOCKERHUB_REPO}:${IMAGE_TAG}"
          echo "FULL_IMAGE=$FULL_IMAGE" >> "$GITHUB_ENV"
          echo "Prod image: $FULL_IMAGE"
    ```

39. Add the final step to tag and push the production image:
    ```yaml
      - name: Tag and push production image
        run: |
          echo "Tagging ${IMAGE_NAME}:${IMAGE_TAG} -> $FULL_IMAGE"
          docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "$FULL_IMAGE"
          echo "Pushing $FULL_IMAGE"
          docker push "$FULL_IMAGE"
    ```

After completing all these steps, you will have recreated the provided GitHub Actions workflow exactly.

---

## Part 2 – Instrukcje po polsku

Twoim celem w tym ćwiczeniu jest **odtworzenie kompletnego workflow GitHub Actions**, który automatyzuje budowanie, testowanie i publikowanie obrazów Dockera dla środowisk: `development`, `staging` oraz `production`.  
Wynikiem wykonania wszystkich poniższych zadań powinien być plik YAML identyczny funkcjonalnie z tym, który otrzymałeś.

Każdy krok opisuje konkretną zmianę lub fragment konfiguracji, który musisz dodać.

---

### 1. Zdefiniuj nagłówek workflow

1. Utwórz nowy plik w repozytorium:
   - `.github/workflows/16_02-docker-matrix.yml` (lub inna spójna nazwa).

2. Na początku pliku ustaw nazwę workflow:
   - Ustaw linię:
     - `name: 16_02 - Docker matrix build / test / push (only Docker Hub)`

3. Skonfiguruj wyzwalacze workflow tak, aby uruchamiał się gdy:
   - Następuje push na branch:
     - `cw16`
   - Tworzony jest pull request do brancha:
     - `cw16`
   - Użytkownik ręcznie wywoła workflow z poziomu interfejsu GitHuba (`workflow_dispatch`).  
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

---

### 2. Ustaw globalne domyślne ustawienia i zmienne środowiskowe

4. Dodaj globalne ustawienia `defaults` dla wszystkich kroków `run:` tak, aby:
   - Używały powłoki `bash`.
   - Wykonywały się w katalogu: `./CWICZENIA/16-environments/docker01`.

   Dodaj:
   ```yaml
   defaults:
     run:
       shell: bash
       working-directory: ./CWICZENIA/16-environments/docker01
   ```

5. Zdefiniuj globalne zmienne środowiskowe dla workflow:
   - `IMAGE_NAME` = `github-action-test`
   - `DOCKERHUB_REPO` = `piotrskoska/github-action-test`

   Dodaj:
   ```yaml
   env:
     IMAGE_NAME: github-action-test
     DOCKERHUB_REPO: piotrskoska/github-action-test
   ```

Te wartości będą używane we wszystkich jobach i krokach.

---

### 3. Utwórz Job 1 – BUILD (development i staging)

6. Rozpocznij sekcję `jobs:` i zdefiniuj pierwszy job o nazwie `build`:
    - Job ma działać na maszynie `ubuntu-latest`.

   ```yaml
   jobs:
     build:
       runs-on: ubuntu-latest
   ```

7. Skonfiguruj **strategię macierzy (matrix)** dla dwóch środowisk:
   - `development` z:
     - `app_env: dev`
     - `image_tag: dev`
   - `staging` z:
     - `app_env: staging`
     - `image_tag: staging`

   Dodaj wewnątrz `build`:
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

8. Utwórz sekcję `steps:` dla joba `build`.

9. Dodaj krok pobierający kod repozytorium:
   - Nazwa: `Checkout repository`
   - Akcja: `actions/checkout@v4`

   ```yaml
       steps:
         - name: Checkout repository
           uses: actions/checkout@v4
   ```

10. Dodaj krok diagnostyczny wyświetlający aktualne wartości macierzy:
    - Użyj `echo`, aby wypisać:
      - `environment`
      - `app_env`
      - `image_tag`

    ```yaml
         - name: Show build matrix entry
           run: |
             echo "BUILD for environment: ${{ matrix.environment }}"
             echo "APP_ENV: ${{ matrix.app_env }}"
             echo "IMAGE_TAG: ${{ matrix.image_tag }}"
    ```

11. Dodaj krok budujący obraz Dockera z użyciem wartości z macierzy:
    - Użyj `docker build` z argumentem `--build-arg APP_ENV` na podstawie `matrix.app_env`.
    - Nadaj tag `${IMAGE_NAME}:${{ matrix.image_tag }}`.

    ```yaml
         - name: Build Docker image
           run: |
             docker build                --build-arg APP_ENV="${{ matrix.app_env }}"                -t "${IMAGE_NAME}:${{ matrix.image_tag }}" .
    ```

12. Dodaj krok **zapisujący obraz Dockera do pliku tar**:
    - Użyj `docker save`, aby zapisać obraz do `image.tar`.

    ```yaml
         - name: Save image as tar (artifact)
           run: |
             docker save "${IMAGE_NAME}:${{ matrix.image_tag }}" -o image.tar
    ```

13. Dodaj krok **wysyłający plik tar jako artefakt**:
    - Użyj `actions/upload-artifact@v4`.
    - Ustaw nazwę artefaktu na `docker-image-${{ matrix.environment }}`.
    - Ustaw ścieżkę na pełną ścieżkę do `image.tar` w katalogu roboczym.

    ```yaml
         - name: Upload image artifact
           uses: actions/upload-artifact@v4
           with:
             name: docker-image-${{ matrix.environment }}
             path: ./CWICZENIA/16-environments/docker01/image.tar
    ```

Po tym kroku job `build` tworzy dwa artefakty: dla `development` i `staging`.

---

### 4. Utwórz Job 2 – TEST (development i staging)

14. Zdefiniuj drugi job o nazwie `test`:
    - Ma działać na `ubuntu-latest`.
    - Ma zależeć od `build`:
      - Użyj `needs: build`, aby job uruchomił się dopiero po poprawnym buildzie.

    ```yaml
  test:
    runs-on: ubuntu-latest
    needs: build
    ```

15. Użyj tej samej konfiguracji macierzy co w `build`:
    - `development` (`app_env: dev`, `image_tag: dev`)
    - `staging` (`app_env: staging`, `image_tag: staging`)

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

16. Rozpocznij sekcję `steps:` dla joba `test`.

17. Dodaj krok ponownie pobierający repozytorium:
    ```yaml
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
    ```

18. Dodaj krok pobierający artefakt z joba `build`:
    - Użyj `actions/download-artifact@v4`.
    - Ustaw nazwę artefaktu: `docker-image-${{ matrix.environment }}`.
    - Ustaw `path` na katalog roboczy.

    ```yaml
      - name: Download image artifact
        uses: actions/download-artifact@v4
        with:
          name: docker-image-${{ matrix.environment }}
          path: ./CWICZENIA/16-environments/docker01
    ```

19. Dodaj krok wczytujący obraz z pliku `image.tar`:
    - Opcjonalnie wypisz listę plików (`ls -l`).
    - Użyj `docker load -i image.tar`.

    ```yaml
      - name: Load Docker image from artifact
        run: |
          ls -l
          docker load -i image.tar
    ```

20. Dodaj krok testujący obraz Dockera:
    - Uruchom kontener przy pomocy `docker run --rm`.
    - Zapisz wyjście do zmiennej.
    - Zbuduj oczekiwany tekst: `"Hello from environment: <app_env>"`.
    - Porównaj wyjście z oczekiwaniem; jeśli są różne – zakończ job błędem.

    ```yaml
      - name: Test Docker image
        run: |
          echo "Testing image ${IMAGE_NAME}:${{ matrix.image_tag }} for env ${{ matrix.environment }}"

          OUTPUT="$(docker run --rm "${IMAGE_NAME}:${{ matrix.image_tag }}")"
          EXPECTED="Hello from environment: ${{ matrix.app_env }}"

          echo "Container output: $OUTPUT"
          if [[ "$OUTPUT" != "$EXPECTED" ]]; then
            echo "❌ TEST FAILED"
            exit 1
          fi

          echo "✅ TEST PASSED"
    ```

---

### 5. Utwórz Job 3 – PUSH dla dev i staging (Docker Hub)

21. Utwórz trzeci job o nazwie `push-nonprod`:
    - Ma działać na `ubuntu-latest`.
    - Ma zależeć od joba `test` (`needs: test`).

    ```yaml
  push-nonprod:
    runs-on: ubuntu-latest
    needs: test
    ```

22. Użyj tej samej macierzy dla `development` i `staging` co poprzednio.

23. Dodaj przypisanie **GitHub Environment** na podstawie macierzy:
    - `environment: ${{ matrix.environment }}`

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

    environment: ${{ matrix.environment }}
    ```

24. Rozpocznij sekcję `steps:` dla joba `push-nonprod`.

25. Dodaj krok `Checkout repository` jak poprzednio:
    ```yaml
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
    ```

26. Dodaj krok pobierający artefakt z obrazem:
    ```yaml
      - name: Download image artifact
        uses: actions/download-artifact@v4
        with:
          name: docker-image-${{ matrix.environment }}
          path: ./CWICZENIA/16-environments/docker01
    ```

27. Dodaj krok wczytujący obraz do Dockera:
    ```yaml
      - name: Load Docker image from artifact
        run: |
          docker load -i image.tar
    ```

28. Dodaj krok wyliczający pełną nazwę obrazu dla Docker Huba:
    - Ustaw `FULL_IMAGE="${DOCKERHUB_REPO}:${{ matrix.image_tag }}"`.
    - Zapisz do `GITHUB_ENV`.

    ```yaml
      - name: Compute FULL_IMAGE for Docker Hub (non-prod)
        run: |
          FULL_IMAGE="${DOCKERHUB_REPO}:${{ matrix.image_tag }}"
          echo "FULL_IMAGE=$FULL_IMAGE" >> "$GITHUB_ENV"
          echo "Non-prod image: $FULL_IMAGE"
    ```

29. Dodaj krok logowania do Docker Huba, używając sekretu `DOCKERHUB_TOKEN`:
    ```yaml
      - name: Login to Docker Hub
        run: |
          echo "${{ secrets.DOCKERHUB_TOKEN }}" | docker login -u "piotrskoska" --password-stdin
    ```

30. Dodaj krok tagujący i wysyłający obraz do Docker Huba:
    ```yaml
      - name: Tag and push image (non-prod)
        run: |
          echo "Tagging ${IMAGE_NAME}:${{ matrix.image_tag }} -> $FULL_IMAGE"
          docker tag "${IMAGE_NAME}:${{ matrix.image_tag }}" "$FULL_IMAGE"
          echo "Pushing $FULL_IMAGE"
          docker push "$FULL_IMAGE"
    ```

---

### 6. Utwórz Job 4 – PRODUKCJA (build, test, push po przejściu dev+staging)

31. Zdefiniuj job `production`:
    - Działa na `ubuntu-latest`.
    - Ma zależeć od `test`:
      - `needs: test` – job odpala się dopiero po przejściu testów dla dev i staging.
    - Powiązany z environmentem `production`.

    ```yaml
  production:
    runs-on: ubuntu-latest
    needs: test
    environment: production
    ```

32. Dodaj sekcję `env` specyficzną dla produkcji:
    - `APP_ENV: prod`
    - `IMAGE_TAG: production`

    ```yaml
    env:
      APP_ENV: prod
      IMAGE_TAG: production   # tag w Docker Hub: piotrskoska/github-action-test:production
    ```

33. Rozpocznij sekcję `steps:` dla joba `production`.

34. Dodaj krok `Checkout repository`:
    ```yaml
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
    ```

35. Dodaj krok budujący obraz produkcyjny:
    - Użyj `APP_ENV` i `IMAGE_TAG`.
    - Buduj z `--build-arg APP_ENV="${APP_ENV}"`.
    - Taguj jako `${IMAGE_NAME}:${IMAGE_TAG}`.

    ```yaml
      - name: Build production image
        run: |
          docker build             --build-arg APP_ENV="${APP_ENV}"             -t "${IMAGE_NAME}:${IMAGE_TAG}" .
    ```

36. Dodaj krok testujący obraz produkcyjny:
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

37. Dodaj krok logowania do Docker Huba używając `DOCKERHUB_TOKEN`:
    ```yaml
      - name: Login to Docker Hub
        run: |
          echo "${{ secrets.DOCKERHUB_TOKEN }}" | docker login -u "piotrskoska" --password-stdin
    ```

38. Dodaj krok wyliczający pełną nazwę obrazu produkcyjnego:
    ```yaml
      - name: Compute FULL_IMAGE for Docker Hub (prod)
        run: |
          FULL_IMAGE="${DOCKERHUB_REPO}:${IMAGE_TAG}"
          echo "FULL_IMAGE=$FULL_IMAGE" >> "$GITHUB_ENV"
          echo "Prod image: $FULL_IMAGE"
    ```

39. Dodaj końcowy krok tagujący i pushujący obraz produkcyjny:
    ```yaml
      - name: Tag and push production image
        run: |
          echo "Tagging ${IMAGE_NAME}:${IMAGE_TAG} -> $FULL_IMAGE"
          docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "$FULL_IMAGE"
          echo "Pushing $FULL_IMAGE"
          docker push "$FULL_IMAGE"
    ```

Po wykonaniu wszystkich powyższych kroków uzyskasz workflow identyczny z dostarczonym plikiem YAML, realizujący pełny proces: build → test → push dla środowisk `development`, `staging` oraz `production`.
