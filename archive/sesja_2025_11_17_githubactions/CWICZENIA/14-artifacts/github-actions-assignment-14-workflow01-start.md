# Assignment: Simple GitHub Actions Workflow – Start Build & Artifact (EN)

## Goal

Create a very simple GitHub Actions workflow that:
1. Can be triggered manually and on pushes to a specific branch.
2. Creates a text file as a build output.
3. Uploads this file as a build artifact.

The final solution should be functionally equivalent to the provided **GitHub Actions YAML workflow file**.

---

## Context

You are working in an existing GitHub repository.  
You want to introduce a first, minimal CI workflow that:
- proves GitHub Actions is correctly configured,
- runs a trivial “build” step,
- persists the result as an artifact that can be downloaded from the workflow run page.

No tests, Docker builds or external services are involved – this is intentionally a very small starter workflow.

---

## Requirements – step by step

### 1. Workflow location and name

1. Create a new workflow file under:
   - `.github/workflows/14-workflow01-start.yml` (or a very similar name indicated by your instructor).
2. Set the workflow `name` so that it clearly describes what it does, for example:
   - `14-01-start-build`

This name should appear in the “Actions” tab in GitHub.

---

### 2. Triggers (on: …)

Configure the workflow so that it can be executed in two ways:

1. **Manual trigger**:
   - Add support for `workflow_dispatch` so that the workflow can be started manually from the GitHub UI.

2. **Push trigger for a specific branch**:
   - The workflow must also run automatically on each `push` to the branch:
     - `CW14`

The `on:` section should therefore:
- include `workflow_dispatch`,
- and a `push` trigger limited to the `CW14` branch.

This ensures that:
- you can test the workflow at any time (manual run),
- and it will automatically run when you push code to the designated branch.

---

### 3. Define the job

Create a single job named, for example, `build`.

Requirements for the job:

- It must run on an Ubuntu virtual machine:
  - `runs-on: ubuntu-latest`

You do not need any matrix or special environment – one Linux runner is enough.

All steps in the next sections will be part of this `build` job.

---

### 4. Step 1 – Checkout the repository

Add the first step in the `build` job to download the repository contents into the runner.

- Use the official checkout action:
  - `actions/checkout@v4`
- Give the step a clear name, e.g.:
  - `Checkout`

This step is mandatory in almost every workflow, as it gives subsequent steps access to the code and allows them to create or modify files in the working directory of the repo.

---

### 5. Step 2 – Perform a simple “build” (create a file)

Add a second step that simulates a build process by creating a small text file.  
Instead of running a real build tool, this assignment uses a simple shell command.

Requirements:

1. Name the step in a meaningful way, for example:
   - `Build`
2. Use a `run:` command that:
   - creates a file named `output.txt`,
   - writes a short message into it, e.g. `Say Hello to my little friend`.

Example command idea (you don’t have to copy this literally, the effect is what matters):
- `echo "Say Hello to my little friend" > output.txt`

After this step completes, there should be a file `output.txt` in the repository workspace on the runner.

---

### 6. Step 3 – Upload the artifact

Add a final step that uploads `output.txt` as an artifact.

Requirements:

1. Use the official artifact upload action:
   - `actions/upload-artifact@v4`
2. Give the step a descriptive name, e.g.:
   - `Upload artifact`
3. In the `with:` configuration:
   - Set `name` to the artifact name that will be visible in the Actions UI, for example:
     - `build-output`
   - Set `path` to:
     - `output.txt`

After this step, the workflow run should expose an artifact named `build-output` which contains the `output.txt` file with the message created in the previous step.

---

## Acceptance criteria

Your solution will be considered correct if all of the following conditions are met:

1. The workflow file is stored in the `.github/workflows` directory and has a clear, descriptive name.
2. The workflow has the name `14-01-start-build` (or an agreed equivalent).
3. The `on:` section:
   - includes `workflow_dispatch`,
   - and includes a `push` trigger limited to the `CW14` branch.
4. There is a single job `build` that runs on `ubuntu-latest`.
5. The job contains **exactly three logical steps**:
   - **Checkout** – uses `actions/checkout@v4`.
   - **Build** – creates an `output.txt` file with a non-empty message (e.g. “Say Hello to my little friend”).
   - **Upload artifact** – uses `actions/upload-artifact@v4` to upload `output.txt` as an artifact named `build-output`.
6. After a successful run:
   - The Actions run shows an artifact named `build-output`.
   - Downloading this artifact reveals a file `output.txt` with the expected message inside.

---

# Zadanie: Prosty workflow GitHub Actions – Start Build & Artifact (PL)

## Cel

Stwórz bardzo prosty workflow GitHub Actions, który:
1. Może być uruchamiany ręcznie oraz przy pushu na wybraną gałąź.
2. Tworzy plik tekstowy jako wynik „builda”.
3. Wysyła ten plik jako artefakt builda.

Końcowe rozwiązanie powinno być funkcjonalnie równoważne dostarczonemu **plikowi workflow YAML GitHub Actions**.

---

## Kontekst

Pracujesz w istniejącym repozytorium na GitHubie.  
Chcesz dodać pierwszy, minimalny workflow CI, który:
- potwierdzi, że GitHub Actions działa poprawnie,
- wykona prościutki krok „build”,
- zapisze wynik jako artefakt możliwy do pobrania z widoku uruchomienia workflow.

Nie ma tu testów, buildów Dockera ani zewnętrznych usług – to celowo mały, startowy workflow.

---

## Wymagania – krok po kroku

### 1. Lokalizacja pliku workflow i nazwa

1. Utwórz nowy plik workflow w katalogu:
   - `.github/workflows/14-workflow01-start.yml` (lub bardzo podobnej nazwie wskazanej przez prowadzącego).
2. Ustaw pole `name` workflow w taki sposób, aby jasno opisywało jego działanie, na przykład:
   - `14-01-start-build`

Taka nazwa będzie widoczna w zakładce „Actions” w GitHubie.

---

### 2. Wyzwalacze (on: …)

Skonfiguruj workflow tak, aby mógł zostać uruchomiony na dwa sposoby:

1. **Ręczne uruchomienie**:
   - Dodaj obsługę `workflow_dispatch`, aby można było wystartować workflow ręcznie z interfejsu GitHuba.

2. **Push na konkretną gałąź**:
   - Workflow musi uruchamiać się automatycznie przy każdym `push` na gałąź:
     - `CW14`

Sekcja `on:` powinna więc:
- zawierać `workflow_dispatch`,
- oraz wyzwalacz `push` ograniczony do gałęzi `CW14`.

Dzięki temu:
- możesz przetestować workflow w dowolnym momencie (ręczny run),
- a także będzie on uruchamiany automatycznie przy pushu na wskazaną gałąź.

---

### 3. Definicja joba

Utwórz pojedynczy job, np. o nazwie `build`.

Wymagania dla joba:

- Ma być wykonywany na maszynie Ubuntu:
  - `runs-on: ubuntu-latest`

Nie potrzebujesz żadnej macierzy czy specjalnego środowiska – wystarczy jeden runner Linux.

Wszystkie kolejne kroki będą częścią tego joba `build`.

---

### 4. Krok 1 – Checkout repozytorium

Dodaj pierwszy krok w jobie `build`, który pobierze zawartość repozytorium na runnera.

- Użyj oficjalnej akcji do checkoutu:
  - `actions/checkout@v4`
- Nazwij krok w czytelny sposób, np.:
  - `Checkout`

Krok ten jest wymagany w praktycznie każdym workflow – dzięki niemu kolejne kroki mają dostęp do kodu i mogą tworzyć/zmieniać pliki w katalogu roboczym repozytorium.

---

### 5. Krok 2 – Prosty „build” (utworzenie pliku)

Dodaj drugi krok, który zasymuluje proces builda poprzez utworzenie prostego pliku tekstowego.  
Zamiast faktycznego narzędzia buildowego używamy tu prostego polecenia powłoki.

Wymagania:

1. Nazwij krok w sposób opisowy, np.:
   - `Build`
2. Użyj polecenia w sekcji `run:`, które:
   - utworzy plik `output.txt`,
   - zapisze w nim krótki komunikat, np. `Say Hello to my little friend`.

Przykładowe polecenie (nie musisz go kopiować literalnie, ważny jest efekt):
- `echo "Say Hello to my little friend" > output.txt`

Po wykonaniu tego kroku na runnerze powinien istnieć plik `output.txt` w katalogu roboczym repozytorium.

---

### 6. Krok 3 – Wysłanie artefaktu

Dodaj ostatni krok, który wyśle plik `output.txt` jako artefakt.

Wymagania:

1. Użyj oficjalnej akcji do wysyłania artefaktów:
   - `actions/upload-artifact@v4`
2. Nazwij krok w sposób jednoznaczny, np.:
   - `Upload artifact`
3. W sekcji `with:`:
   - ustaw `name` na nazwę artefaktu widoczną w Actions, na przykład:
     - `build-output`
   - ustaw `path` na:
     - `output.txt`

Po tym kroku w wynikach uruchomienia workflow powinien być dostępny artefakt o nazwie `build-output`, zawierający plik `output.txt` z komunikatem utworzonym w poprzednim kroku.

---

## Kryteria akceptacji

Rozwiązanie będzie uznane za poprawne, jeśli spełnione zostaną wszystkie poniższe warunki:

1. Plik workflow znajduje się w katalogu `.github/workflows` i ma czytelną, opisową nazwę.
2. Workflow ma nazwę `14-01-start-build` (lub uzgodniony odpowiednik).
3. Sekcja `on:`:
   - zawiera `workflow_dispatch`,
   - zawiera wyzwalacz `push` ograniczony do gałęzi `CW14`.
4. Zdefiniowany jest pojedynczy job `build`, działający na `ubuntu-latest`.
5. Job zawiera **dokładnie trzy logiczne kroki**:
   - **Checkout** – korzysta z `actions/checkout@v4`,
   - **Build** – tworzy plik `output.txt` z niepustym komunikatem (np. „Say Hello to my little friend”),
   - **Upload artifact** – korzysta z `actions/upload-artifact@v4`, aby wysłać `output.txt` jako artefakt o nazwie `build-output`.
6. Po pomyślnym uruchomieniu workflow:
   - w wynikach Actions widoczny jest artefakt o nazwie `build-output`,
   - pobranie tego artefaktu daje plik `output.txt` z oczekiwanym komunikatem w środku.
