# 10D Conditional Job Execution — Instrukcje (PL/EN)

> Przewodnik krok po kroku wyjaśniający **każdą linię** i co należy przygotować, aby uzyskać działający plik workflow GitHub Actions na podstawie podanego fragmentu (z `run_job_b=no`, co powoduje pominięcie joba **b**).

---

## 🇵🇱 Część I — Co należy przygotować (krok po kroku)

1. **Repozytorium z kodem na GitHubie**
   - Upewnij się, że masz repozytorium na GitHubie (publiczne lub prywatne).

2. **Włączone GitHub Actions**
   - `Settings` → `Actions` → `General` → pozostaw `Allow all actions and reusable workflows`.

3. **Utwórz katalog na workflow**
   - Utwórz `.github/workflows/` (jeśli nie istnieje).

4. **Utwórz plik workflow**
   - Nazwij go np.: `10d-conditional-job-execution.yml` i umieść w `.github/workflows/`.

5. **Wklej zawartość workflow** (omówioną w Części II) i zapisz plik.

6. **Commit i push**
   - Zrób commit i wypchnij zmiany do gałęzi domyślnej (np. `main`).

7. **Ręczne uruchomienie workflow**
   - Zakładka **Actions** → wybierz „10D Conditional Job Execution” → **Run workflow**.

> Uwaga: Ten workflow nie wymaga sekretów — używa `echo` oraz mechanizmu `outputs` i warunków `if`.

---

## 🇵🇱 Część II — Omówienie *linii po linii* i instrukcje

1. ```yaml
   name: 10D Conditional Job Execution
   ```
   - **Co to robi:** Ustawia nazwę workflow widoczną w UI GitHub **Actions**.
   - **Co przygotować:** Nic — to etykieta.

2. ```yaml
   on:
     workflow_dispatch:
   ```
   - **Co to robi:** Definiuje ręczne uruchomienie workflow z UI lub API.
   - **Co przygotować:** Dostęp do zakładki **Actions**.

3. ```yaml
   jobs:
   ```
   - **Co to robi:** Sekcja definiująca wszystkie joby.

4. ```yaml
     a:
       name: a
       runs-on: ubuntu-latest
   ```
   - **Co to robi:** Deklaruje job `a` i środowisko `ubuntu-latest`.
   - **Co przygotować:** Nic — GitHub zapewnia runnera.

5. ```yaml
       steps:
         - run: echo "A"
   ```
   - **Co to robi:** Pierwszy krok joba `a`, wypisuje „A” do logów.

6. ```yaml
         # nadajemy ID, by móc odczytać outputs
         - id: set
           run: |
             # USTAWIANIE OUTPUTU STEPU zgodnie z nowym API:
             # zapis w formacie klucz=wartość do pliku wskazanego przez $GITHUB_OUTPUT
             echo "run_job_b=no" >> "$GITHUB_OUTPUT"
   ```
   - **Co to robi:**
     - `id: set` nadaje krokowi identyfikator, aby referencjonować jego **outputs**.
     - `echo "run_job_b=no" >> "$GITHUB_OUTPUT"` ustawia **output kroku** `run_job_b` na `no` w nowym API (`$GITHUB_OUTPUT`).  
   - **Efekt:** Job `a` wystawi output `run_job_b=no` dla innych jobów.
   - **Co przygotować:** Nic — zmienna `$GITHUB_OUTPUT` jest dostępna w środowisku actions.

7. ```yaml
       outputs:
         run_job_b: ${{ steps.set.outputs.run_job_b }}
   ```
   - **Co to robi:** Wystawia **output joba `a`** (`run_job_b`) na podstawie **outputu kroku** `set`.
   - **Co przygotować:** Nic — inne joby uzyskają dostęp przez `needs.a.outputs.run_job_b`.

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
     - `b` zależy od `a` (ma dostęp do jego outputs).
     - Warunek `if: needs.a.outputs.run_job_b == 'yes'` sprawi, że **b zostanie pominięty (skipped)**, ponieważ `run_job_b=no`.
     - Gdyby warunek był spełniony, wykonałby krok `echo "B"`.
   - **Co przygotować:** Nic — logika warunkowa działa na podstawie outputu z `a`.

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
     - `c` zależy od `a` i `b`, ale jego warunek dopuszcza uruchomienie także, gdy `b` jest **skipped**.
     - W tym workflow (z `run_job_b=no`) wartość `needs.b.result` będzie `skipped`, więc **`c` uruchomi się** i wypisze „C”.
   - **Co przygotować:** Nic — to kontrola przepływu w oparciu o `result` joba `b`.

---

## 🇬🇧 Part I — What to prepare (step by step)

1. **A GitHub repository**
   - Have a GitHub repo (public or private).

2. **Enable GitHub Actions**
   - `Settings` → `Actions` → `General` → keep `Allow all actions and reusable workflows`.

3. **Create the workflows folder**
   - `.github/workflows/` (create if absent).

4. **Create the workflow file**
   - Name it `10d-conditional-job-execution.yml` and place it under `.github/workflows/`.

5. **Paste the workflow content** (covered in Part II) and save.

6. **Commit and push**
   - Commit and push to the default branch (e.g., `main`).

7. **Manually run the workflow**
   - **Actions** tab → select “10D Conditional Job Execution” → **Run workflow**.

> Note: No secrets required — this uses simple `echo`, job/step outputs, and `if` conditions.

---

## 🇬🇧 Part II — Line-by-line explanation and instructions

1. ```yaml
   name: 10D Conditional Job Execution
   ```
   - **What it does:** Sets the workflow name as shown in **Actions** UI.

2. ```yaml
   on:
     workflow_dispatch:
   ```
   - **What it does:** Allows manual runs from UI or API.

3. ```yaml
   jobs:
   ```
   - **What it does:** Top-level container for all jobs.

4. ```yaml
     a:
       name: a
       runs-on: ubuntu-latest
   ```
   - **What it does:** Declares job `a` running on the hosted `ubuntu-latest` runner.

5. ```yaml
       steps:
         - run: echo "A"
   ```
   - **What it does:** Prints “A” to logs as the first step of job `a`.

6. ```yaml
         # nadajemy ID, by móc odczytać outputs
         - id: set
           run: |
             # USTAWIANIE OUTPUTU STEPU zgodnie z nowym API:
             # zapis w formacie klucz=wartość do pliku wskazanego przez $GITHUB_OUTPUT
             echo "run_job_b=no" >> "$GITHUB_OUTPUT"
   ```
   - **What it does:**
     - Assigns step ID `set` so its outputs can be referenced.
     - Writes `run_job_b=no` to `$GITHUB_OUTPUT` to define a step output via the new API.
   - **Effect:** Job `a` exposes `run_job_b=no` to dependents.
   - **Prepare:** Nothing — `$GITHUB_OUTPUT` is built-in.

7. ```yaml
       outputs:
         run_job_b: ${{ steps.set.outputs.run_job_b }}
   ```
   - **What it does:** Exposes job output `run_job_b` mapped from the step output.

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
     - Depends on `a` and reads its outputs.
     - Because `run_job_b=no`, the condition evaluates to **false** and job **b is skipped**.
     - If true, it would print “B”.

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
     - Depends on `a` and `b`.
     - The condition allows running when `b` is **success** **or** **skipped**.
     - In this case (`run_job_b=no`), `b` is **skipped**, so **`c` runs** and prints “C”.

---

## ✅ Szybka weryfikacja działania / Quick verification

- **Scenariusz (ten workflow):** `run_job_b=no` → **b = skipped**, **c = success** (uruchamia się dzięki warunkowi `success || skipped`).  
- **Test odwrotny:** Zmień `run_job_b=no` na `run_job_b=yes` → **b = success**, **c = success**.

---

## 📁 Pełna zawartość pliku (do umieszczenia w `.github/workflows/10d-conditional-job-execution.yml`)

```yaml
name: 10D Conditional Job Execution
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
          echo "run_job_b=no" >> "$GITHUB_OUTPUT"
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
