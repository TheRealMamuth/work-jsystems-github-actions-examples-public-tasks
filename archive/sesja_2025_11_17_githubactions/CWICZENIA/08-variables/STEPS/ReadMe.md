# Rozwiązanie ćwiczenia 08 – Zmienne środowiskowe (krok po kroku)

---

## 1️⃣ Utworzenie pliku workflow i nazwy

1. W katalogu `.github/workflows` utwórz plik:
   ```bash
   08-variables.yaml
   ```
2. Nadaj nazwę workflow:
   ```yaml
   name: "08 — Using Variables"
   ```

---

## 2️⃣ Dodanie wyzwalaczy

Dodaj dwa triggery: `push` oraz `workflow_dispatch`:

```yaml
on:
  push:
  workflow_dispatch:
```

---

## 3️⃣ Zmienne środowiskowe na poziomie workflow

Zdefiniuj zmienne na najwyższym poziomie:

```yaml
env:
  WORKFLOW_VAR: "I am a workflow env var"
  OVERWRITTEN: "I will be overwritten"
```

---

## 4️⃣ Definicja joba `echo` + zmienne joba

Utwórz pojedynczy job działający na `ubuntu-latest` i zdefiniuj jego zmienne:

```yaml
jobs:
  echo:
    runs-on: ubuntu-latest
    env:
      JOB_VAR: "I am a job env var"
      OVERWRITTEN: "I have been overwritten at the job level"
    steps:
```

---

## 5️⃣ Krok: `Print Env Variables` (zmienne kroku + wypisywanie)

Dodaj krok z dwiema zmiennymi kroku i wypisz wymagane wartości.  
Możesz używać zarówno składni kontekstu `${{ env.* }}`, jak i bezpośredniego `$NAZWA`:

```yaml
      - name: Print Env Variables
        env:
          STEP_VAR: "I am a step env var"
          step_var2: "I am another step var"
        run: |
          echo "Step env var: ${{ env.STEP_VAR }}"
          echo "Step env var 2: $step_var2"
          echo "Job env var: ${{ env.JOB_VAR }}"
          echo "Workflow env var: ${{ env.WORKFLOW_VAR }}"
          echo "Overwritten: ${{ env.OVERWRITTEN }}"
```

---

## 6️⃣ Krok: `Overwrite Job Variable` (nadpisanie na poziomie kroku)

Dodaj kolejny krok, który nadpisze zmienną `OVERWRITTEN` tylko w tym kroku:

```yaml
      - name: Overwrite Job Variable
        env:
          OVERWRITTEN: "I have been overwritten at the step level"
        run: echo "Step env var: $OVERWRITTEN"
```

---

## 7️⃣ Commit, push i obserwacje

1. Zatwierdź i wypchnij zmiany:
   ```bash
   git add .
   git commit -m "Add 08 — Using Variables workflow"
   git push
   ```
2. W zakładce **Actions** sprawdź, jak warstwy `env` wpływają na wartości:
   - `WORKFLOW_VAR` pochodzi z poziomu **workflow**,
   - `JOB_VAR` z poziomu **job**,
   - `OVERWRITTEN` przyjmuje kolejno: workflow → **job** (nadpisanie) → **step** (ponowne nadpisanie tylko w danym kroku),
   - zmienne kroku (`STEP_VAR`, `step_var2`) są dostępne wyłącznie w danym kroku.

---

## 8️⃣ Ograniczenie wyzwalaczy do `workflow_dispatch`

Po testach zmień `on:` tak, aby workflow uruchamiał się tylko ręcznie:

```yaml
on:
  workflow_dispatch:
```

---

## 9️⃣ Finalna wersja pliku `08-variables.yaml`

```yaml
name: "08 — Using Variables"

on:
  workflow_dispatch:

env:
  WORKFLOW_VAR: "I am a workflow env var"
  OVERWRITTEN: "I will be overwritten"

jobs:
  echo:
    runs-on: ubuntu-latest
    env:
      JOB_VAR: "I am a job env var"
      OVERWRITTEN: "I have been overwritten at the job level"
    steps:
      - name: Print Env Variables
        env:
          STEP_VAR: "I am a step env var"
          step_var2: "I am another step var"
        run: |
          echo "Step env var: ${{ env.STEP_VAR }}"
          echo "Step env var 2: $step_var2"
          echo "Job env var: ${{ env.JOB_VAR }}"
          echo "Workflow env var: ${{ env.WORKFLOW_VAR }}"
          echo "Overwritten: ${{ env.OVERWRITTEN }}"

      - name: Overwrite Job Variable
        env:
          OVERWRITTEN: "I have been overwritten at the step level"
        run: echo "Step env var: $OVERWRITTEN"
```

---

## 🔎 Notatki

- Hierarchia nadpisywania: **workflow** → **job** → **step** (najniższy poziom wygrywa w swoim zakresie).
- Dostęp do zmiennych w Bashu: przez `${{ env.VAR }}` (kontekst Actions) lub `$VAR` (składnia powłoki).
- Używanie `workflow_dispatch` po zakończeniu testów ogranicza niepotrzebne uruchomienia.
