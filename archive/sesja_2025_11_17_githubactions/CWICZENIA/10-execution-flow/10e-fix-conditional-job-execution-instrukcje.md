# 10E FIX Conditional Job Execution — Instrukcje (PL/EN)

> Szczegółowy przewodnik wyjaśniający **każdą linię** pliku GitHub Actions oraz co należy przygotować, aby go poprawnie uruchomić.  
> Wersja „FIX” zawiera poprawiony warunek `if:` w jobie **c**, dzięki użyciu funkcji `always()`.

---

## 🇵🇱 Część I — Przygotowanie środowiska

1. **Utwórz lub otwórz repozytorium GitHub**
   - Może być publiczne lub prywatne.

2. **Upewnij się, że GitHub Actions są włączone**
   - W repozytorium wejdź w: `Settings` → `Actions` → `General` → wybierz `Allow all actions and reusable workflows`.

3. **Utwórz katalog workflow**
   - Stwórz folder `.github/workflows/`, jeśli jeszcze go nie ma.

4. **Utwórz plik YAML**
   - Utwórz plik o nazwie `10e-fix-conditional-job-execution.yml` w katalogu `.github/workflows/`.

5. **Wklej zawartość pliku (z Części II) i zapisz.**

6. **Commit i push**
   - Zapisz zmiany i wypchnij je do głównej gałęzi (`main`).

7. **Uruchom workflow ręcznie**
   - Przejdź do zakładki **Actions** → wybierz workflow **10E FIX Conditional Job Execution** → kliknij **Run workflow**.

> ⚙️ Nie potrzeba żadnych sekretów, tokenów ani zasobów zewnętrznych.

---

## 🇵🇱 Część II — Omówienie linii YAML (z wyjaśnieniem i przygotowaniem)

### 1. Ustawienie nazwy workflow

```yaml
name: 10E FIX Conditional Job Execution
```
- Określa nazwę workflow w zakładce **Actions**.

### 2. Zdarzenie uruchamiające

```yaml
on:
  workflow_dispatch:
```
- Umożliwia **ręczne uruchamianie** workflow z poziomu GitHub UI lub API.

### 3. Sekcja `jobs`

```yaml
jobs:
```
- Zawiera wszystkie zadania (joby), które będą wykonywane w workflow.

---

### 4. Job `a` — inicjalizacja i ustawienie outputu

```yaml
  a:
    name: a
    runs-on: ubuntu-latest
```
- Uruchamia job `a` na hostowanym runnerze GitHuba z systemem Ubuntu.

```yaml
    steps:
      - run: echo "A"
```
- Pierwszy krok: wypisuje literę „A” w logach.

```yaml
      - id: set
        run: |
          echo "run_job_b=no" >> "$GITHUB_OUTPUT"
```
- Krok o identyfikatorze `set`, ustawiający **output** kroku w pliku `$GITHUB_OUTPUT`.  
- Output `run_job_b` przyjmuje wartość `no`.

```yaml
    outputs:
      run_job_b: ${{ steps.set.outputs.run_job_b }}
```
- Definiuje **output joba `a`**, który może być użyty w kolejnych jobach (`needs.a.outputs.run_job_b`).

---

### 5. Job `b` — warunkowe uruchomienie

```yaml
  b:
    name: b
    runs-on: ubuntu-latest
    needs:
      - a
    if: needs.a.outputs.run_job_b == 'yes'
    steps:
      - run: echo "B"
```
- **Zależność:** `b` czeka na zakończenie `a`.
- **Warunek:** uruchomi się tylko, jeśli `run_job_b` z joba `a` = `yes`.
- W tym przypadku (`run_job_b=no`) job **b zostanie pominięty (skipped)**.
- Krok `echo "B"` nie wykona się.

---

### 6. Job `c` — poprawiony warunek `if:`

```yaml
  c:
    name: c
    runs-on: ubuntu-latest
    needs:
      - a
      - b
    if: |
      always() &&
      needs.a.result == 'success' &&
      (needs.b.result == 'success' || needs.b.result == 'skipped')
    steps:
      - run: echo "C"
```
- **Nowość w wersji FIX:** użycie `always()` zapewnia, że job `c` zostanie **oceniony i uruchomiony niezależnie od statusu poprzednich jobów**.  
- Dodatkowo warunki logiczne sprawdzają:
  - czy `a` zakończył się sukcesem,
  - czy `b` zakończył się sukcesem **lub** został pominięty.
- Dzięki temu `c` uruchomi się nawet wtedy, gdy `b` nie został wykonany, ale został oznaczony jako `skipped`.

> ✅ **Efekt:** `a = success`, `b = skipped`, `c = success` (uruchomiony dzięki `always()` i dopuszczeniu `skipped`).

---

## 🇬🇧 English Version — Step-by-step Breakdown

### 1. Workflow Name

```yaml
name: 10E FIX Conditional Job Execution
```
- Sets the workflow name shown in the **Actions** tab.

### 2. Trigger Event

```yaml
on:
  workflow_dispatch:
```
- Enables **manual workflow execution** via UI or API.

### 3. Jobs Section

```yaml
jobs:
```
- Groups all workflow jobs.

---

### 4. Job `a` — Setup and Output

```yaml
  a:
    name: a
    runs-on: ubuntu-latest
```
- Runs job `a` on GitHub’s hosted Ubuntu runner.

```yaml
    steps:
      - run: echo "A"
```
- Prints “A” to logs.

```yaml
      - id: set
        run: |
          echo "run_job_b=no" >> "$GITHUB_OUTPUT"
```
- Defines step `set`, writing `run_job_b=no` to `$GITHUB_OUTPUT` (defines job output).

```yaml
    outputs:
      run_job_b: ${{ steps.set.outputs.run_job_b }}
```
- Exposes `run_job_b` as job output for dependent jobs.

---

### 5. Job `b` — Conditional Execution

```yaml
  b:
    name: b
    runs-on: ubuntu-latest
    needs:
      - a
    if: needs.a.outputs.run_job_b == 'yes'
    steps:
      - run: echo "B"
```
- **Depends** on job `a`.
- **Condition:** Runs only if `run_job_b=yes`.
- Since `run_job_b=no`, job **b is skipped**.

---

### 6. Job `c` — Fixed Conditional Logic

```yaml
  c:
    name: c
    runs-on: ubuntu-latest
    needs:
      - a
      - b
    if: |
      always() &&
      needs.a.result == 'success' &&
      (needs.b.result == 'success' || needs.b.result == 'skipped')
    steps:
      - run: echo "C"
```
- Uses `always()` to ensure this job is **evaluated even if `b` was skipped**.
- Additional checks confirm:
  - `a` succeeded,
  - `b` either succeeded or was skipped.
- **Outcome:** `c` runs successfully after `a`, regardless of `b` being skipped.

---

## ✅ Quick Verification / Szybki test działania

| Job | Warunek spełniony? | Wynik | Opis |
|-----|--------------------|--------|------|
| a | Zawsze | ✅ success | Uruchamia się zawsze |
| b | `run_job_b=no` | ⚠️ skipped | Pominięty, bo warunek fałszywy |
| c | `always()` + `skipped` dopuszczone | ✅ success | Uruchamia się mimo pominięcia `b` |

---

## 📁 Pełna zawartość pliku `.github/workflows/10e-fix-conditional-job-execution.yml`

```yaml
name: 10E FIX Conditional Job Execution
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
    if: |
      always() &&
      needs.a.result == 'success' &&
      (needs.b.result == 'success' || needs.b.result == 'skipped')
    steps:
      - run: echo "C"
```
