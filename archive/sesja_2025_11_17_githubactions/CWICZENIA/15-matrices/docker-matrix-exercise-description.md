# Docker Matrix Build Exercise

## Part 1 – English Description

### Goal

The goal of this exercise is to:
- Create a simple Docker image based on `alpine`.
- Use a **build argument** (`APP_ENV`) inside the Dockerfile.
- Configure a **GitHub Actions workflow** that uses a **matrix strategy** to build the image for multiple environments: `dev`, `staging`, and `prod`.
- Verify that each image variant produces output that depends on its environment.

---

## 1. Prerequisites

Before you start, make sure you have:

- A GitHub account.
- Git installed locally.
- Docker installed locally (for optional local testing).
- Basic understanding of:
  - How to create a Git repository.
  - Pushing code to GitHub.

---

## 2. Create a New Project

1. Create a new folder on your machine, for example:

   ```bash
   mkdir docker-matrix-exercise
   cd docker-matrix-exercise
   ```

2. Initialize a new Git repository:

   ```bash
   git init
   ```

3. (Optional) Create a new repository on GitHub (e.g. `docker-matrix-exercise`) and connect it as a remote:

   ```bash
   git remote add origin https://github.com/<your-username>/docker-matrix-exercise.git
   ```

---

## 3. Create the Dockerfile

1. In the project root, create a file named `Dockerfile`.
2. Add the following content:

   ```dockerfile
   FROM alpine:3.20

   ARG APP_ENV=dev

   RUN echo "Hello from environment: ${APP_ENV}" > /message.txt

   CMD ["cat", "/message.txt"]
   ```

### Explanation

- `FROM alpine:3.20` – we use a small Linux distribution as base.
- `ARG APP_ENV=dev` – defines a build-time argument with a default value (`dev`).
- `RUN echo ...` – writes a message containing the environment value to `/message.txt`.
- `CMD ["cat", "/message.txt"]` – at runtime, the container prints the content of `/message.txt` to standard output.

This Dockerfile will behave differently depending on the value of `APP_ENV` passed during build.

---

## 4. (Optional) Test the Dockerfile Locally

You can test the image locally before creating the CI configuration.

### Build for `dev`

```bash
docker build --build-arg APP_ENV=dev -t myapp:dev .
```

Run the container:

```bash
docker run --rm myapp:dev
```

You should see output similar to:

```text
Hello from environment: dev
```

### Build for `staging` and `prod`

```bash
docker build --build-arg APP_ENV=staging -t myapp:staging .
docker build --build-arg APP_ENV=prod -t myapp:prod .

docker run --rm myapp:staging
docker run --rm myapp:prod
```

Each run should print the respective environment name.

---

## 5. Create the GitHub Actions Workflow with a Matrix

Now we will configure a GitHub Actions workflow that:
- Triggers on pushes and pull requests.
- Uses a **matrix** with three environment values.
- Builds and runs the Docker image for each matrix entry.

### 5.1. Create the Workflow Directory

In your project, create the following folder structure:

```bash
mkdir -p .github/workflows
```

### 5.2. Create the Workflow File

Create the file: `.github/workflows/docker-matrix.yml`  
Add the following content:

```yaml
name: Docker matrix build

on:
  push:
    branches:
      - main
      - master
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        env: [dev, staging, prod]

    steps:
      - name: Checkout repo
        uses: actions/checkout@v4

      - name: Show current matrix entry
        run: echo "Building for environment: ${{ matrix.env }}"

      - name: Build Docker image (matrix)
        run: |
          docker build             --build-arg APP_ENV=${{ matrix.env }}             -t myapp:${{ matrix.env }} .

      - name: Run container and print message
        run: |
          docker run --rm myapp:${{ matrix.env }}
```

### 5.3. Workflow Explanation

- `on.push.branches` – the workflow runs on pushes to `main` or `master`.
- `on.pull_request` – the workflow also runs for pull requests.
- `jobs.build.runs-on: ubuntu-latest` – the job uses a hosted Ubuntu runner.
- `strategy.matrix.env: [dev, staging, prod]` – defines the matrix:
  - The `build` job will run three separate times, once for each environment (`env`).
- `actions/checkout@v4` – checks out the source code so Docker can access the `Dockerfile`.
- `docker build ...`:
  - `--build-arg APP_ENV=${{ matrix.env }}` – passes the environment from the matrix into the Dockerfile.
  - `-t myapp:${{ matrix.env }}` – tags images as `myapp:dev`, `myapp:staging`, and `myapp:prod`.
- `docker run --rm myapp:${{ matrix.env }}` – runs the image for each matrix entry and prints the message.

At the end, you will have **three images** built and run in CI, each representing a different environment.

---

## 6. Commit and Push the Changes

1. Add all files:

   ```bash
   git add .
   ```

2. Commit the changes:

   ```bash
   git commit -m "Add Dockerfile and matrix GitHub Actions workflow"
   ```

3. Push to GitHub (replace `main` with your default branch if needed):

   ```bash
   git push -u origin main
   ```

---

## 7. Verify the Workflow on GitHub

1. Go to your repository on GitHub.
2. Open the **Actions** tab.
3. You should see a workflow run named **"Docker matrix build"**.
4. Open the latest run – you should see three jobs (or three matrix entries) for:
   - `env = dev`
   - `env = staging`
   - `env = prod`
5. Click on each job and inspect the logs. At the end of each job, there should be output similar to:

   ```text
   Hello from environment: dev
   ```

   or:

   ```text
   Hello from environment: staging
   Hello from environment: prod
   ```

This confirms that your GitHub Actions workflow correctly uses the matrix to build and run different Docker image variants.

---

## Part 2 – Opis po polsku

### Cel

Celem tego ćwiczenia jest:

- Stworzenie prostego obrazu Dockera opartego na `alpine`.
- Wykorzystanie argumentu budowania (`APP_ENV`) wewnątrz pliku Dockerfile.
- Skonfigurowanie **workflow GitHub Actions** korzystającego z **matrix strategy**, aby budować obraz dla wielu środowisk: `dev`, `staging` i `prod`.
- Sprawdzenie, że każdy wariant obrazu zwraca wynik zależny od środowiska.

---

## 1. Wymagania wstępne

Zanim zaczniesz, upewnij się, że masz:

- Konto na GitHubie.
- Zainstalowany Git.
- Zainstalowanego Dockera (do opcjonalnych testów lokalnych).
- Podstawową wiedzę o:
  - Tworzeniu repozytorium Git.
  - Wysyłaniu zmian do GitHuba (`git push`).

---

## 2. Utworzenie nowego projektu

1. Utwórz nowy folder na swoim komputerze, np.:

   ```bash
   mkdir docker-matrix-exercise
   cd docker-matrix-exercise
   ```

2. Zainicjuj nowe repozytorium Git:

   ```bash
   git init
   ```

3. (Opcjonalnie) Utwórz nowe repozytorium na GitHubie (np. `docker-matrix-exercise`) i dodaj je jako remote:

   ```bash
   git remote add origin https://github.com/<twoj-login>/docker-matrix-exercise.git
   ```

---

## 3. Utworzenie pliku Dockerfile

1. W katalogu głównym projektu utwórz plik `Dockerfile`.
2. Wklej do niego następującą zawartość:

   ```dockerfile
   FROM alpine:3.20

   ARG APP_ENV=dev

   RUN echo "Hello from environment: ${APP_ENV}" > /message.txt

   CMD ["cat", "/message.txt"]
   ```

### Wyjaśnienie

- `FROM alpine:3.20` – korzystamy z lekkiej dystrybucji Linuksa.
- `ARG APP_ENV=dev` – definiuje argument budowania z domyślną wartością (`dev`).
- `RUN echo ...` – zapisuje komunikat zawierający wartość środowiska do pliku `/message.txt`.
- `CMD ["cat", "/message.txt"]` – przy uruchomieniu kontenera wypisuje zawartość pliku `/message.txt` na standardowe wyjście.

Ten Dockerfile będzie zachowywał się inaczej w zależności od wartości `APP_ENV` przekazanej w czasie budowania.

---

## 4. (Opcjonalnie) Przetestuj Dockerfile lokalnie

Możesz przetestować obraz lokalnie, zanim przejdziesz do konfiguracji CI.

### Budowanie dla `dev`

```bash
docker build --build-arg APP_ENV=dev -t myapp:dev .
```

Uruchomienie kontenera:

```bash
docker run --rm myapp:dev
```

Powinieneś zobaczyć coś w stylu:

```text
Hello from environment: dev
```

### Budowanie dla `staging` i `prod`

```bash
docker build --build-arg APP_ENV=staging -t myapp:staging .
docker build --build-arg APP_ENV=prod -t myapp:prod .

docker run --rm myapp:staging
docker run --rm myapp:prod
```

Każde uruchomienie powinno wypisać odpowiednią nazwę środowiska.

---

## 5. Utworzenie workflow GitHub Actions z matrix

Teraz skonfigurujemy workflow GitHub Actions, który:

- Uruchamia się przy pushu i pull requeście.
- Używa **matrix** z trzema wartościami środowiska.
- Buduje i uruchamia obraz Dockera dla każdej pozycji w macierzy.

### 5.1. Utworzenie katalogu na workflow

W projekcie utwórz strukturę katalogów:

```bash
mkdir -p .github/workflows
```

### 5.2. Utworzenie pliku workflow

Utwórz plik: `.github/workflows/docker-matrix.yml`  
i wklej do niego:

```yaml
name: Docker matrix build

on:
  push:
    branches:
      - main
      - master
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        env: [dev, staging, prod]

    steps:
      - name: Checkout repo
        uses: actions/checkout@v4

      - name: Show current matrix entry
        run: echo "Building for environment: ${{ matrix.env }}"

      - name: Build Docker image (matrix)
        run: |
          docker build             --build-arg APP_ENV=${{ matrix.env }}             -t myapp:${{ matrix.env }} .

      - name: Run container and print message
        run: |
          docker run --rm myapp:${{ matrix.env }}
```

### 5.3. Wyjaśnienie workflow

- `on.push.branches` – workflow uruchamia się przy pushu na branch `main` lub `master`.
- `on.pull_request` – workflow uruchamia się także dla pull requestów.
- `jobs.build.runs-on: ubuntu-latest` – job działa na maszynie Ubuntu udostępnianej przez GitHub.
- `strategy.matrix.env: [dev, staging, prod]` – definicja macierzy:
  - Job `build` zostanie uruchomiony trzy razy – dla każdego środowiska (`env`).
- `actions/checkout@v4` – pobiera kod z repozytorium, aby Docker miał dostęp do `Dockerfile`.
- `docker build ...`:
  - `--build-arg APP_ENV=${{ matrix.env }}` – przekazuje wartość środowiska z matrixa do Dockerfile.
  - `-t myapp:${{ matrix.env }}` – nadaje obrazom tagi `myapp:dev`, `myapp:staging`, `myapp:prod`.
- `docker run --rm myapp:${{ matrix.env }}` – uruchamia obraz dla każdej wartości macierzy i wypisuje komunikat.

W efekcie CI zbuduje i uruchomi **trzy obrazy**, każdy dla innego środowiska.

---

## 6. Commit i push zmian

1. Dodaj pliki do commita:

   ```bash
   git add .
   ```

2. Zrób commit:

   ```bash
   git commit -m "Dodaj Dockerfile i workflow GitHub Actions z matrix"
   ```

3. Wypchnij zmiany na GitHuba (w razie potrzeby zamień `main` na domyślny branch):

   ```bash
   git push -u origin main
   ```

---

## 7. Weryfikacja działania workflow na GitHubie

1. Otwórz swoje repozytorium na GitHubie.
2. Przejdź do zakładki **Actions**.
3. Powinieneś zobaczyć uruchomiony workflow o nazwie **"Docker matrix build"**.
4. Wejdź w ostatni run – powinny być widoczne trzy joby (albo trzy wpisy macierzy):
   - `env = dev`
   - `env = staging`
   - `env = prod`
5. Kliknij każdy job i sprawdź logi. Pod koniec logów powinien pojawić się komunikat podobny do:

   ```text
   Hello from environment: dev
   ```

   lub:

   ```text
   Hello from environment: staging
   Hello from environment: prod
   ```

To oznacza, że Twój workflow GitHub Actions poprawnie korzysta z macierzy do budowania i uruchamiania różnych wariantów obrazu Dockera.
