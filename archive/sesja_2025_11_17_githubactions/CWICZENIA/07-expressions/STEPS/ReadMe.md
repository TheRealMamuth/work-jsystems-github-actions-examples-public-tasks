# Rozwiązanie ćwiczenia 07 – Praca z wyrażeniami (Expressions)

---

## 1️⃣ Utworzenie pliku workflow

1. W katalogu `.github/workflows` utwórz nowy plik o nazwie:
   ```bash
   07-expressions.yaml
   ```

2. Dodaj nazwę workflow:
   ```yaml
   name: "07 – Using Expressions"
   ```

---

## 2️⃣ Dodanie wyzwalaczy (triggers)

Dodaj dwa wyzwalacze: `push` i `workflow_dispatch`.  
Dla `workflow_dispatch` zdefiniuj wejście o nazwie `debug`, typu `boolean`, z domyślną wartością `false`:

```yaml
on:
  push:
  workflow_dispatch:
    inputs:
      debug:
        type: boolean
        default: false
```

---

## 3️⃣ Utworzenie joba `echo` z trzema krokami

Dodaj sekcję `jobs` i utwórz joba `echo`, który działa na `ubuntu-latest`:

```yaml
jobs:
  echo:
    runs-on: ubuntu-latest
    steps:
```

### 🧩 Krok 1 — `[debug] Print start-up data`

Ten krok ma wykonać się **tylko wtedy**, gdy `inputs.debug` = `true`:

```yaml
      - name: "[debug] Print start-up data"
        if: ${{ inputs.debug == true }}
        run: |
          echo "Triggered by: ${{ github.event_name }}"
          echo "Branch: ${{ github.ref }}"
          echo "Commit SHA: ${{ github.sha }}"
          echo "Runner OS: ${{ runner.os }}"
```

### 🧩 Krok 2 — `[debug] Print when triggered from main`

Krok wykonuje się tylko, jeśli `inputs.debug == true` **i** workflow został wywołany z gałęzi `main`:

```yaml
      - name: "[debug] Print when triggered from main"
        if: ${{ inputs.debug == true && github.ref == 'refs/heads/main' }}
        run: echo "I was triggered from main"
```

### 🧩 Krok 3 — `Greeting`

Ten krok wykonuje się zawsze i wyświetla prosty komunikat:

```yaml
      - name: "Greeting"
        run: echo "Hello, world"
```

---

## 4️⃣ Testowanie pierwszej wersji workflow

1. Zatwierdź i wypchnij zmiany:
   ```bash
   git add .
   git commit -m "Add initial version of 07 – Using Expressions workflow"
   git push
   ```
2. Sprawdź w zakładce **Actions**, czy workflow uruchomił się po zdarzeniu `push`.
3. Następnie uruchom workflow ręcznie z interfejsu GitHub (`Run workflow`) i zmień wartość `debug` (true/false), aby zaobserwować różnice w wynikach.

---

## 5️⃣ Dodanie `run-name` z wykorzystaniem wyrażeń

Dodaj właściwość `run-name` na początku pliku.  
Wartość powinna dynamicznie zmieniać się w zależności od wejścia `debug`:

```yaml
run-name: "07 – Using Expressions | DEBUG – ${{ inputs.debug && 'ON' || 'OFF' }}"
```

💡 To wykorzystuje tzw. operator logiczny trójargumentowy (ternary):
- Jeśli `inputs.debug` = `true`, wynik to `'ON'`
- W przeciwnym wypadku wynik to `'OFF'`

---

## 6️⃣ Pełna wersja pliku przed ograniczeniem wyzwalaczy

```yaml
name: "07 – Using Expressions"
run-name: "07 – Using Expressions | DEBUG – ${{ inputs.debug && 'ON' || 'OFF' }}"

on:
  push:
  workflow_dispatch:
    inputs:
      debug:
        type: boolean
        default: false

jobs:
  echo:
    runs-on: ubuntu-latest
    steps:
      - name: "[debug] Print start-up data"
        if: ${{ inputs.debug == true }}
        run: |
          echo "Triggered by: ${{ github.event_name }}"
          echo "Branch: ${{ github.ref }}"
          echo "Commit SHA: ${{ github.sha }}"
          echo "Runner OS: ${{ runner.os }}"

      - name: "[debug] Print when triggered from main"
        if: ${{ inputs.debug == true && github.ref == 'refs/heads/main' }}
        run: echo "I was triggered from main"

      - name: "Greeting"
        run: echo "Hello, world"
```

---

## 7️⃣ Ograniczenie wyzwalaczy do `workflow_dispatch`

Aby uniknąć uruchamiania przy każdym `push`, zmień sekcję `on` na:

```yaml
on:
  workflow_dispatch:
    inputs:
      debug:
        type: boolean
        default: false
```

---

## 8️⃣ Finalna wersja pliku `07-expressions.yaml`

```yaml
name: "07 – Using Expressions"
run-name: "07 – Using Expressions | DEBUG – ${{ inputs.debug && 'ON' || 'OFF' }}"

on:
  workflow_dispatch:
    inputs:
      debug:
        type: boolean
        default: false

jobs:
  echo:
    runs-on: ubuntu-latest
    steps:
      - name: "[debug] Print start-up data"
        if: ${{ inputs.debug == true }}
        run: |
          echo "Triggered by: ${{ github.event_name }}"
          echo "Branch: ${{ github.ref }}"
          echo "Commit SHA: ${{ github.sha }}"
          echo "Runner OS: ${{ runner.os }}"

      - name: "[debug] Print when triggered from main"
        if: ${{ inputs.debug == true && github.ref == 'refs/heads/main' }}
        run: echo "I was triggered from main"

      - name: "Greeting"
        run: echo "Hello, world"
```

---

## 9️⃣ Podsumowanie

- **Wyrażenia** (`${{ ... }}`) pozwalają warunkowo wykonywać kroki i ustawiać dynamiczne wartości.  
- **`if:`** decyduje o wykonaniu kroku lub joba.  
- **Operatory logiczne `&&` i `||`** umożliwiają tworzenie warunków typu ternary.  
- **`workflow_dispatch`** z wejściem `debug` pozwala łatwo testować różne warianty działania workflow.  
- Wartość `run-name` pomaga w czytelnym oznaczaniu uruchomień w zakładce **Actions**.

