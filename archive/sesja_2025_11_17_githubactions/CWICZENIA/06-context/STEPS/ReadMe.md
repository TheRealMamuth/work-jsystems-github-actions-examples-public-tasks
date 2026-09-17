# Rozwiązanie ćwiczenia 06 – Praca z różnymi kontekstami (krok po kroku)

---

## 1) Pierwsza wersja workflow

1. Utwórz plik `.github/workflows/06-contexts.yaml` i nadaj mu nazwę workflow:
   ```yaml
   name: "06 – Contexts"
   ```

2. Dodaj wyzwalacze `push` i `workflow_dispatch`:
   ```yaml
   on:
     push:
     workflow_dispatch:
   ```

3. Zdefiniuj jedno zadanie `echo-data` na `ubuntu-latest` z dwoma krokami:
   ```yaml
   jobs:
     echo-data:
       runs-on: ubuntu-latest
       steps:
         - name: Display Information
           run: |
             echo "Event name: ${{ github.event_name }}"
             echo "Ref: ${{ github.ref }}"
             echo "SHA: ${{ github.sha }}"
             echo "Actor: ${{ github.actor }}"
             echo "Workflow: ${{ github.workflow }}"
             echo "Run ID: ${{ github.run_id }}"
             echo "Run number: ${{ github.run_number }}"

         - name: Retrieve Variable
           run: echo "${{ vars.MY_VAR }}"
   ```

4. W repozytorium utwórz **zmienną repozytorium** `MY_VAR` o wartości `hello world` (Ustawienia → *Secrets and variables* → *Actions* → zakładka *Variables* → **New repository variable**).

5. Zatwierdź i wypchnij zmiany, uruchomiony workflow powinien wypisać wartości z kontekstu `github` oraz `MY_VAR`.

---

## 2) Dodanie błędnego kontekstu do `run-name` (celowe)

1. Na najwyższym poziomie dodaj klucz `run-name` z użyciem **niedozwolonego** w tym miejscu kontekstu `runner`:
   ```yaml
   run-name: "My custom workflow run name – ${{ runner.os }}"
   ```

2. Zatwierdź i wypchnij zmiany. Uruchomienie zakończy się błędem walidacji (przykładowy komunikat):
   > *Unrecognized named-value: 'runner'. Located at run-name expression.*

   To ćwiczenie pokazuje, że **nie każdy kontekst jest dostępny** w `run-name`.

---

## 3) Naprawa `run-name` i dodanie wejścia (inputs) do `workflow_dispatch`

1. Zastąp `run-name` wersją używającą wejścia z `workflow_dispatch`:
   ```yaml
   run-name: "06 – Contexts | DEBUG – ${{ inputs.debug }}"
   ```

2. Dodaj definicję wejścia `debug` (typ `boolean`, domyślnie `false`):
   ```yaml
   on:
     push:
     workflow_dispatch:
       inputs:
         debug:
           type: boolean
           default: false
   ```

3. Zatwierdź i wypchnij zmiany.  
   - Dla uruchomienia przez `push` pole `inputs.debug` przyjmie wartość domyślną `false`.  
   - Uruchamiając z UI możesz zaznaczać/odznaczać checkbox i obserwować zmianę nazwy uruchomienia (`run-name`).

---

## 4) Kontekst `env` na poziomie workflow, job i step + nadpisywanie

1. Dodaj **zmienne środowiskowe** na poziomie workflow:
   ```yaml
   env:
     MY_WORKFLOW_VAR: "workflow"
     MY_OVERWRITTEN_VAR: "workflow"
   ```

2. W jobie `echo-data` dodaj **env** specyficzne dla joba:
   ```yaml
   jobs:
     echo-data:
       runs-on: ubuntu-latest
       env:
         MY_JOB_VAR: "job"
         MY_OVERWRITTEN_VAR: "job"
       steps:
         # ... istniejące kroki
   ```

3. Dodaj krok, który **nadpisze** zmienną tylko na poziomie kroku i wypisze wartości:
   ```yaml
   - name: Print Env Variables (with step override)
     env:
       MY_OVERWRITTEN_VAR: "step"
     run: |
       echo "Workflow env: ${{ env.MY_WORKFLOW_VAR }}"
       echo "Overwritten env: ${{ env.MY_OVERWRITTEN_VAR }}"
   ```

4. Dodaj drugi krok bez własnego `env`, aby zobaczyć efekt „cofnięcia” nadpisania do poziomu joba:
   ```yaml
   - name: Print Env Variables (job level)
     run: |
       echo "Workflow env: ${{ env.MY_WORKFLOW_VAR }}"
       echo "Overwritten env: ${{ env.MY_OVERWRITTEN_VAR }}"
   ```

5. Zatwierdź i wypchnij zmiany. W logach zobaczysz, że:
   - w pierwszym z dwóch kroków „Print Env Variables” `MY_OVERWRITTEN_VAR` = `step` (nadpisanie na poziomie kroku),  
   - w kolejnym kroku `MY_OVERWRITTEN_VAR` = `job` (obowiązuje wartość z poziomu joba),  
   - `MY_WORKFLOW_VAR` zawsze = `workflow` (poziom workflow).

---

## 5) Ograniczenie wyzwalaczy tylko do `workflow_dispatch`

Po zakończeniu eksperymentów pozostaw wyłącznie ręczne uruchamianie z UI, aby nie „zaśmiecać” listy uruchomień:

```yaml
on:
  workflow_dispatch:
    inputs:
      debug:
        type: boolean
        default: false
```

---

## Finalna, uporządkowana wersja `06-contexts.yaml` (po wszystkich zmianach)

```yaml
name: "06 – Contexts"
run-name: "06 – Contexts | DEBUG – ${{ inputs.debug }}"

on:
  workflow_dispatch:
    inputs:
      debug:
        type: boolean
        default: false

env:
  MY_WORKFLOW_VAR: "workflow"
  MY_OVERWRITTEN_VAR: "workflow"

jobs:
  echo-data:
    runs-on: ubuntu-latest
    env:
      MY_JOB_VAR: "job"
      MY_OVERWRITTEN_VAR: "job"
    steps:
      - name: Display Information
        run: |
          echo "Event name: ${{ github.event_name }}"
          echo "Ref: ${{ github.ref }}"
          echo "SHA: ${{ github.sha }}"
          echo "Actor: ${{ github.actor }}"
          echo "Workflow: ${{ github.workflow }}"
          echo "Run ID: ${{ github.run_id }}"
          echo "Run number: ${{ github.run_number }}"

      - name: Retrieve Variable
        run: echo "${{ vars.MY_VAR }}"

      - name: Print Env Variables (with step override)
        env:
          MY_OVERWRITTEN_VAR: "step"
        run: |
          echo "Workflow env: ${{ env.MY_WORKFLOW_VAR }}"
          echo "Overwritten env: ${{ env.MY_OVERWRITTEN_VAR }}"

      - name: Print Env Variables (job level)
        run: |
          echo "Workflow env: ${{ env.MY_WORKFLOW_VAR }}"
          echo "Overwritten env: ${{ env.MY_OVERWRITTEN_VAR }}"
```

---

## Notatki
- `run-name` przyjmuje wyrażenia, ale **nie wszystkie konteksty** są dostępne w tym miejscu — użyj `inputs`, `github` lub `vars`, zamiast `runner`.
- `vars.MY_VAR` odczytuje **zmienne repozytorium** (nie tajne sekrety).
- Priorytet `env`: **step** ⟶ **job** ⟶ **workflow** (wartości z niższego poziomu nadpisują wyższe).
