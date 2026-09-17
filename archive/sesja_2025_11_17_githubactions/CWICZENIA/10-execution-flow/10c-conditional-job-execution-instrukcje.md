# 10C Conditional Job Execution — Instrukcje (PL/EN)

> Przewodnik krok po kroku wyjaśniający **każdą linię** i co należy przygotować, aby uzyskać działający plik workflow GitHub Actions na podstawie podanego fragmentu.

---

## 🇵🇱 Część I — Co należy przygotować (krok po kroku)

1. **Repozytorium z kodem na GitHubie**
   - Upewnij się, że masz repozytorium na GitHubie (publiczne lub prywatne).

2. **Włączone GitHub Actions**
   - Wejdź w: `Settings` → `Actions` → `General` i pozostaw domyślne ustawienia `Allow all actions and reusable workflows`.

3. **Utwórz strukturę katalogów na workflow**
   - W repozytorium utwórz katalog: `.github/workflows/` (jeśli nie istnieje).

4. **Utwórz plik workflow**
   - Nazwij plik np.: `10c-conditional-job-execution.yml` i umieść go w `.github/workflows/`.

5. **Wklej zawartość workflow** (omówioną w Części II) do pliku i zapisz.

6. **Commit i push**
   - Zrób commit zmian i wypchnij je do gałęzi domyślnej (np. `main`).

7. **Ręczne uruchomienie workflow**
   - Przejdź do zakładki `Actions` → wybierz workflow „10C Conditional Job Execution” → kliknij **Run workflow**.

> Uwaga: Ten workflow nie wymaga żadnych sekretów ani dodatkowych uprawnień — używa jedynie poleceń `echo` i mechanizmu `outputs`.

---

## 🇵🇱 Część II — Omówienie *linii po linii* i instrukcje

Poniżej znajdują się linie z pliku i objaśnienia, co robią oraz co trzeba przygotować.

1. ```yaml
   name: 10C Conditional Job Execution
   ```
   - **Co to robi:** Ustawia nazwę workflow, która będzie widoczna w zakładce GitHub **Actions**.
   - **Co przygotować:** Nic dodatkowego — to tylko etykieta.

2. ```yaml
   on:
     workflow_dispatch:
   ```
   - **Co to robi:** Definiuje zdarzenie wyzwalające – `workflow_dispatch` pozwala uruchomić workflow **ręcznie** z UI GitHuba lub przez API.
   - **Co przygotować:** Upewnij się, że masz dostęp do zakładki **Actions** w repozytorium, aby kliknąć „Run workflow”.

3. ```yaml
   jobs:
   ```
   - **Co to robi:** Sekcja zbiorcza definiująca wszystkie zadania (jobs) w workflow.
   - **Co przygotować:** Nic — to nagłówek dla kolejnych definicji.

4. ```yaml
     a:
       name: a
       runs-on: ubuntu-latest
   ```
   - **Co to robi:** Definiuje job `a`, nadaje mu nazwę wyświetlaną jako `a` i wskazuje, że ma działać na wirtualnym środowisku `ubuntu-latest`.
   - **Co przygotować:** Nie potrzeba runnera własnego — GitHub zapewni hostowanego runnera Ubuntu.

5. ```yaml
       steps:
         - run: echo "A"
   ```
   - **Co to robi:** Pierwszy krok w jobie `a` — wypisuje literę „A” do logów.
   - **Co przygotować:** Nic — to proste polecenie powłoki.

6. ```yaml
         # nadajemy ID, by móc odczytać outputs
         - id: set
           run: |
             # USTAWIANIE OUTPUTU STEPU zgodnie z nowym API:
             # zapis w formacie klucz=wartość do pliku wskazanego przez $GITHUB_OUTPUT
             echo "run_job_b=yes" >> "$GITHUB_OUTPUT"
   ```
   - **Co to robi:**
     - `id: set` nadaje krokowi identyfikator `set`, dzięki czemu jego **outputs** możemy referencjonować dalej w jobie.
     - Polecenie `echo "run_job_b=yes" >> "$GITHUB_OUTPUT"` ustawia **output kroku** o nazwie `run_job_b` na wartość `yes` zgodnie z **nowym API** (zapisywanie do pliku wskazanego przez zmienną środowiskową `$GITHUB_OUTPUT`).  
   - **Co przygotować:** Nic — `$GITHUB_OUTPUT` jest udostępniane automatycznie przez środowisko GitHub Actions.

7. ```yaml
       outputs:
         run_job_b: ${{ steps.set.outputs.run_job_b }}
   ```
   - **Co to robi:** Definiuje **output joba `a`** o nazwie `run_job_b`, przypisując mu wartość pochodzącą z **outputu kroku** `set` (`steps.set.outputs.run_job_b`).
   - **Co przygotować:** Nic — to wiązanie wartości, które stanie się dostępne dla innych jobów przez `needs.a.outputs.run_job_b`.

8. ```yaml
     b:
       name: b
       runs-on: ubuntu-latest
       needs:
         - a
       if: needs.a.outputs.run_job_b == 'yes'
       steps:
         - run: echo "B"
   ```
   - **Co to robi:**
     - Definiuje job `b`, uruchamiany na `ubuntu-latest`.
     - `needs: - a` — wymusza, że `b` czeka na zakończenie `a` i ma dostęp do jego **outputs** i **result**.
     - `if: needs.a.outputs.run_job_b == 'yes'` — warunek uruchomienia joba `b`: wystartuje **tylko jeśli** job `a` wystawił output `run_job_b` równy `yes`.
     - Krok wypisuje „B” do logów.
   - **Co przygotować:** Nic — logika kontrolna opiera się na outputach i warunkach. Zadziała bez dodatkowych zasobów.

9. ```yaml
     c:
       name: c
       runs-on: ubuntu-latest
       needs:
         - a
         - b
       if: needs.b.result == 'success' || needs.b.result == 'skipped'
       steps:
         - run: echo "C"
   ```
   - **Co to robi:**
     - Definiuje job `c`, który zależy od `a` i `b` (oba muszą się rozstrzygnąć — ukończyć, nawet jeśli `b` zostanie **skipped**).
     - `if: needs.b.result == 'success' || needs.b.result == 'skipped'` — `c` uruchomi się, gdy `b` **skończy się sukcesem** albo zostanie **pominięty** (np. gdy warunek `if` w `b` nie został spełniony).
     - Krok wypisuje „C” do logów.
   - **Co przygotować:** Nic — to kontrola przepływu: `c` ruszy w przypadku działania `b` lub jego pominięcia.

---

## 🇬🇧 Part I — What to prepare (step by step)

1. **A GitHub repository**
   - Ensure you have a repository on GitHub (public or private).

2. **GitHub Actions enabled**
   - Go to `Settings` → `Actions` → `General` and keep `Allow all actions and reusable workflows` enabled.

3. **Create the workflows folder**
   - In your repo, create `.github/workflows/` (if it doesn’t exist).

4. **Create the workflow file**
   - Name it e.g. `10c-conditional-job-execution.yml` and place it under `.github/workflows/`.

5. **Paste the workflow content** (covered in Part II) into the file and save it.

6. **Commit and push**
   - Commit the changes and push to your default branch (e.g. `main`).

7. **Manually run the workflow**
   - Go to the **Actions** tab → select “10C Conditional Job Execution” → click **Run workflow**.

> Note: This workflow needs no secrets or extra permissions — it only uses `echo` and the `outputs` mechanism.

---

## 🇬🇧 Part II — Line‑by‑line explanation and instructions

Below are the file lines with explanations of what they do and what you need to prepare.

1. ```yaml
   name: 10C Conditional Job Execution
   ```
   - **What it does:** Sets the workflow’s display name in the GitHub **Actions** UI.
   - **Prepare:** Nothing — label only.

2. ```yaml
   on:
     workflow_dispatch:
   ```
   - **What it does:** Defines the trigger — `workflow_dispatch` allows a **manual** run from GitHub UI or via API.
   - **Prepare:** Ensure you can access the **Actions** tab to press “Run workflow”.

3. ```yaml
   jobs:
   ```
   - **What it does:** Top-level section to define all workflow jobs.
   - **Prepare:** Nothing — header for the following definitions.

4. ```yaml
     a:
       name: a
       runs-on: ubuntu-latest
   ```
   - **What it does:** Declares job `a`, sets its display name, and specifies the hosted runner image `ubuntu-latest`.
   - **Prepare:** No self-hosted runner needed — GitHub provides the Ubuntu runner.

5. ```yaml
       steps:
         - run: echo "A"
   ```
   - **What it does:** First step in job `a` — prints “A” to logs.
   - **Prepare:** Nothing — a simple shell command.

6. ```yaml
         # nadajemy ID, by móc odczytać outputs
         - id: set
           run: |
             # USTAWIANIE OUTPUTU STEPU zgodnie z nowym API:
             # zapis w formacie klucz=wartość do pliku wskazanego przez $GITHUB_OUTPUT
             echo "run_job_b=yes" >> "$GITHUB_OUTPUT"
   ```
   - **What it does:**
     - `id: set` assigns step identifier `set` so its **outputs** can be referenced later within the job.
     - `echo "run_job_b=yes" >> "$GITHUB_OUTPUT"` sets a **step output** named `run_job_b` to `yes` via the **new API** (append `key=value` to the file exposed in `$GITHUB_OUTPUT`).  
   - **Prepare:** Nothing — `$GITHUB_OUTPUT` is provided automatically by GitHub Actions runtime.

7. ```yaml
       outputs:
         run_job_b: ${{ steps.set.outputs.run_job_b }}
   ```
   - **What it does:** Exposes **job `a` output** named `run_job_b`, mapped from the **step output** `set` (`steps.set.outputs.run_job_b`).
   - **Prepare:** Nothing — this makes the value available to other jobs via `needs.a.outputs.run_job_b`.

8. ```yaml
     b:
       name: b
       runs-on: ubuntu-latest
       needs:
         - a
       if: needs.a.outputs.run_job_b == 'yes'
       steps:
         - run: echo "B"
   ```
   - **What it does:**
     - Declares job `b`, running on `ubuntu-latest`.
     - `needs: - a` — enforces that `b` waits for `a` and can read its **outputs** and **result**.
     - `if: needs.a.outputs.run_job_b == 'yes'` — job `b` runs **only if** job `a` exposed output `run_job_b` equal to `yes`.
     - The step prints “B” to logs.
   - **Prepare:** Nothing — control logic is based on outputs and conditions; no extra resources needed.

9. ```yaml
     c:
       name: c
       runs-on: ubuntu-latest
       needs:
         - a
         - b
       if: needs.b.result == 'success' || needs.b.result == 'skipped'
       steps:
         - run: echo "C"
   ```
   - **What it does:**
     - Declares job `c`, which depends on both `a` and `b` (both must resolve — complete — even if `b` is **skipped**).
     - `if: needs.b.result == 'success' || needs.b.result == 'skipped'` — `c` runs when `b` **succeeds** or is **skipped** (e.g., its `if` condition evaluated to false).
     - The step prints “C” to logs.
   - **Prepare:** Nothing — this is flow control: `c` proceeds when `b` succeeded or was skipped.

---

## ✅ Szybka weryfikacja działania / Quick verification

- **Scenariusz 1 (domyślny):** `run_job_b=yes` → `b` uruchamia się, `c` uruchamia się (bo `b` = `success`).  
- **Scenariusz 2 (test warunku):** zmień w kroku `echo "run_job_b=yes"` na `echo "run_job_b=no"` → `b` zostanie **skipped**, a `c` i tak się uruchomi (warunek dopuszcza `skipped`).

---

## 📁 Pełna zawartość pliku (do umieszczenia w `.github/workflows/10c-conditional-job-execution.yml`)

```yaml
name: 10C Conditional Job Execution
on:
  workflow_dispatch:
jobs:
  a:
    name: a
    runs-on: ubuntu-latest
    steps:
      - run: echo "A"
      # nadajemy ID, by móc odczytać outputs
      - id: set
        run: |
          # USTAWIANIE OUTPUTU STEPU zgodnie z nowym API:
          # zapis w formacie klucz=wartość do pliku wskazanego przez $GITHUB_OUTPUT
          echo "run_job_b=yes" >> "$GITHUB_OUTPUT"
    outputs:
      run_job_b: ${{ steps.set.outputs.run_job_b }}
  b:
    name: b
    runs-on: ubuntu-latest
    needs:
      - a
    if: needs.a.outputs.run_job_b == 'yes'
    steps:
      - run: echo "B"
  c:
    name: c
    runs-on: ubuntu-latest
    needs:
      - a
      - b
    if: needs.b.result == 'success' || needs.b.result == 'skipped'
    steps:
      - run: echo "C"
```
