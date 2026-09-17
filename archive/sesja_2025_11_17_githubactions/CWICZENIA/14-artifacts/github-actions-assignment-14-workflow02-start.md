# Assignment: GitHub Actions – Triggered Workflow Downloading Artifacts (EN)

## Goal

Create a GitHub Actions workflow that is triggered **after another workflow finishes**, downloads an artifact produced by that first workflow, and prints the artifact’s contents in the logs.  
The final result must be functionally equivalent to the provided `14-workflow02-start.yaml` file.

---

## Context

In the repository there is already a workflow named **`14-01-start-build`** which:

- can be triggered manually or on push,
- creates a file `output.txt`,
- uploads it as an artifact named **`build-output`**.

In this assignment you will create a **second** workflow that:

1. Does **not** run directly on `push` or `workflow_dispatch`.
2. Is triggered **only when `14-01-start-build` completes**.
3. Downloads the artifact `build-output` from that run.
4. Prints the contents of `output.txt` in the job logs.

This simulates a simple “deploy” or “post-processing” pipeline that depends on the result of another workflow.

---

## Requirements – step by step

### 1. Create the workflow file

1. Create a new workflow file in the repository, e.g.:
   - `.github/workflows/14-workflow02-start.yml`
2. Set the workflow name so that it clearly describes that it copies/uses the output of another workflow, for example:
   - `14 Copy from other workflow - deploy`

This is the name that should appear in the **Actions** tab for this second workflow.

---

### 2. Configure the trigger: workflow_run

Instead of using `push` or `workflow_dispatch`, configure the workflow to be triggered by the completion of another workflow using the `workflow_run` event.

Requirements:

1. Use the `on.workflow_run.workflows` field to specify the **name of the upstream workflow**:
   - `workflows: ["14-01-start-build"]`
2. Limit the trigger to **completed runs** of that workflow:
   - `types: [completed]`

Result:

- This workflow will start automatically **every time** the workflow named `14-01-start-build` finishes (successfully or not).
- It will **not** run directly on `push` or `workflow_dispatch` itself; it is a downstream workflow.

Example structure (conceptual):

```yaml
on:
  workflow_run:
    workflows: ["14-01-start-build"]
    types:
      - completed
```

---

### 3. Define a single job

Create a single job named, for example, `deploy`.

Requirements:

- The job must run on an Ubuntu machine:
  - `runs-on: ubuntu-latest`

No matrix or additional configuration is required.

Skeleton:

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      # steps go here
```

All following steps will be placed inside this `deploy` job.

---

### 4. Step 1 – Download the artifact from another workflow run

Add the first step in the `deploy` job that downloads the artifact produced by the **previous workflow run** (`14-01-start-build`).

1. Use the official action to download artifacts:
   - `actions/download-artifact@v4`
2. Give the step a clear name, e.g.:
   - `Download artifact`

Configure the action using the `with:` block:

- `name`: the **artifact name** created by the first workflow:
  - `build-output`
- `run-id`: ID of the workflow run from which to download the artifact. For `workflow_run`-triggered workflows, GitHub provides this in the event payload:
  - `run-id: ${{ github.event.workflow_run.id }}`
- `github-token`: a token that allows the workflow to access artifacts from that run. Use the automatically provided token:
  - `github-token: ${{ secrets.GITHUB_TOKEN }}`

Conceptually:

```yaml
- name: Download artifact
  uses: actions/download-artifact@v4
  with:
    name: build-output
    run-id: ${{ github.event.workflow_run.id }}
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

Explanation:

- `name` must exactly match the artifact name used in the first workflow.
- `run-id` tells GitHub **which specific run** of `14-01-start-build` to use.
- `GITHUB_TOKEN` (exposed via `secrets.GITHUB_TOKEN`) authorizes downloading artifacts from another run.

After this step completes, the artifact `build-output` should be downloaded and extracted into the current working directory, exposing the file `output.txt`.

---

### 5. Step 2 – Display the contents of the file

Add a second step that simply prints the contents of `output.txt` to the job logs.  
This will confirm that the artifact was downloaded and extracted correctly.

1. Name the step in a descriptive way, for example:
   - `Show file`
2. Use a simple shell command in `run:` to output the file contents:
   - `cat output.txt`

Example step:

```yaml
- name: Show file
  run: cat output.txt
```

When the workflow runs, this step should display the text that was originally written into `output.txt` by the `14-01-start-build` workflow.

---

## Acceptance criteria

Your workflow will be considered correct if all of the following conditions are met:

1. The workflow file is located in `.github/workflows` and has a clear name (e.g. `14-workflow02-start.yml`).
2. The workflow has the name `14 Copy from other workflow - deploy` (or an equivalent name explicitly given in the assignment).
3. The `on:` section:
   - uses `workflow_run`,
   - lists `workflows: ["14-01-start-build"]`,
   - sets `types: [completed]`.
4. There is a single job `deploy` that runs on `ubuntu-latest`.
5. The job contains **two steps**:
   - **Download artifact** – uses `actions/download-artifact@v4` with:
     - `name: build-output`,
     - `run-id: ${{ github.event.workflow_run.id }}`,
     - `github-token: ${{ secrets.GITHUB_TOKEN }}`.
   - **Show file** – runs `cat output.txt`.
6. When you trigger `14-01-start-build` and it completes, this second workflow is automatically started and:
   - successfully downloads the artifact,
   - prints the contents of `output.txt` in the logs of the `Show file` step.

---

# Zadanie: Workflow GitHub Actions wyzwalany przez inny workflow – pobieranie artefaktów (PL)

## Cel

Stwórz workflow GitHub Actions, który jest uruchamiany **po zakończeniu innego workflow**, pobiera artefakt wygenerowany przez ten pierwszy workflow i wypisuje jego zawartość w logach.  
Końcowy wynik ma być funkcjonalnie zgodny z plikiem `14-workflow02-start.yaml`.

---

## Kontekst

W repozytorium istnieje już workflow o nazwie **`14-01-start-build`**, który:

- może być uruchamiany ręcznie lub przy pushu,
- tworzy plik `output.txt`,
- wysyła ten plik jako artefakt o nazwie **`build-output`**.

W tym zadaniu utworzysz **drugi** workflow, który:

1. **Nie** uruchamia się bezpośrednio na `push` ani `workflow_dispatch`.
2. Jest wyzwalany **dopiero po zakończeniu** workflow `14-01-start-build`.
3. Pobiera artefakt `build-output` z tamtego uruchomienia.
4. Wypisuje zawartość pliku `output.txt` w logach joba.

Symuluje to prosty „deploy” lub etap „post-processing”, który zależy od rezultatu innego workflow.

---

## Wymagania – krok po kroku

### 1. Utworzenie pliku workflow

1. Utwórz nowy plik workflow w repozytorium, np.:
   - `.github/workflows/14-workflow02-start.yml`
2. Ustaw nazwę workflow tak, aby jasno wskazywała, że korzysta z wyników innego workflow, np.:
   - `14 Copy from other workflow - deploy`

Taka nazwa powinna być widoczna w zakładce **Actions** dla tego drugiego workflow.

---

### 2. Konfiguracja wyzwalacza: workflow_run

Zamiast `push` czy `workflow_dispatch`, skonfiguruj workflow tak, aby był wyzwalany po zakończeniu innego workflow przy użyciu eventu `workflow_run`.

Wymagania:

1. Użyj pola `on.workflow_run.workflows`, aby wskazać **nazwę workflow nadrzędnego**:
   - `workflows: ["14-01-start-build"]`
2. Ogranicz wyzwalanie do **zakończonych uruchomień** tego workflow:
   - `types: [completed]`

Efekt:

- Ten workflow będzie startował automatycznie **za każdym razem**, gdy workflow o nazwie `14-01-start-build` zakończy działanie (niezależnie od statusu sukces/porażka).
- Nie będzie uruchamiany bezpośrednio przez `push` czy `workflow_dispatch` – jest to workflow „następczy”.

Przykładowa struktura (koncepcyjnie):

```yaml
on:
  workflow_run:
    workflows: ["14-01-start-build"]
    types:
      - completed
```

---

### 3. Definicja pojedynczego joba

Zdefiniuj pojedynczy job, np. o nazwie `deploy`.

Wymagania:

- Job musi być wykonywany na maszynie Ubuntu:
  - `runs-on: ubuntu-latest`

Nie ma potrzeby tworzenia macierzy systemów.

Szkielet:

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      # kroki joba
```

Wszystkie kolejne kroki umieść w tym jobie `deploy`.

---

### 4. Krok 1 – Pobranie artefaktu z innego uruchomienia workflow

Dodaj pierwszy krok w jobie `deploy`, który pobierze artefakt wytworzony przez **poprzedni workflow** (`14-01-start-build`).

1. Użyj oficjalnej akcji do pobierania artefaktów:
   - `actions/download-artifact@v4`
2. Nazwij krok w czytelny sposób, np.:
   - `Download artifact`

Skonfiguruj akcję w sekcji `with`:

- `name`: **nazwa artefaktu** utworzonego przez pierwszy workflow:
  - `build-output`
- `run-id`: identyfikator uruchomienia workflow, z którego chcesz pobrać artefakt. W przypadku workflow wyzwalanego przez `workflow_run` GitHub udostępnia to w danych zdarzenia:
  - `run-id: ${{ github.event.workflow_run.id }}`
- `github-token`: token umożliwiający pobranie artefaktów z tamtego uruchomienia. Użyj automatycznie dostarczanego tokena:
  - `github-token: ${{ secrets.GITHUB_TOKEN }}`

Koncepcyjnie:

```yaml
- name: Download artifact
  uses: actions/download-artifact@v4
  with:
    name: build-output
    run-id: ${{ github.event.workflow_run.id }}
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

Wyjaśnienie:

- `name` musi dokładnie odpowiadać nazwie artefaktu użytej w pierwszym workflow.
- `run-id` określa, **z którego konkretnego uruchomienia** `14-01-start-build` chcesz pobrać artefakt.
- `GITHUB_TOKEN` (udostępniany jako `secrets.GITHUB_TOKEN`) pozwala na autoryzowany dostęp do artefaktów.

Po wykonaniu tego kroku artefakt `build-output` powinien zostać pobrany i rozpakowany do bieżącego katalogu roboczego, tworząc plik `output.txt`.

---

### 5. Krok 2 – Wyświetlenie zawartości pliku

Dodaj drugi krok, który wypisze zawartość `output.txt` w logach joba.  
Pozwoli to zweryfikować, że artefakt został prawidłowo pobrany i rozpakowany.

1. Nazwij krok opisowo, np.:
   - `Show file`
2. Użyj prostego polecenia powłoki w `run:`, które wypisze zawartość pliku:
   - `cat output.txt`

Przykład kroku:

```yaml
- name: Show file
  run: cat output.txt
```

Podczas uruchomienia workflow ten krok powinien wyświetlić w logach tekst, który pierwotnie został zapisany do `output.txt` przez workflow `14-01-start-build`.

---

## Kryteria akceptacji

Rozwiązanie będzie uznane za poprawne, jeśli wszystkie poniższe warunki zostaną spełnione:

1. Plik workflow znajduje się w katalogu `.github/workflows` i ma czytelną nazwę (np. `14-workflow02-start.yml`).
2. Workflow ma nazwę `14 Copy from other workflow - deploy` (lub inną, jednoznacznie ustaloną w treści zadania).
3. Sekcja `on:`:
   - używa eventu `workflow_run`,
   - zawiera `workflows: ["14-01-start-build"]`,
   - ustawia `types: [completed]`.
4. Zdefiniowany jest pojedynczy job `deploy`, działający na `ubuntu-latest`.
5. Job zawiera **dwa kroki**:
   - **Download artifact** – używa `actions/download-artifact@v4` z ustawieniami:
     - `name: build-output`,
     - `run-id: ${{ github.event.workflow_run.id }}`,
     - `github-token: ${{ secrets.GITHUB_TOKEN }}`,
   - **Show file** – wykonuje `cat output.txt`.
6. Po uruchomieniu workflow `14-01-start-build` i jego zakończeniu, drugi workflow jest automatycznie wyzwalany i:
   - poprawnie pobiera artefakt,
   - wypisuje zawartość `output.txt` w logach kroku `Show file`.
