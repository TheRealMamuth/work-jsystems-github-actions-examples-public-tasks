# Rozwiązanie ćwiczenia 10 — Używanie Functions w workflowach (krok po kroku)

---

## 1️⃣ Utworzenie pliku i podstawowej definicji

1. W katalogu `.github/workflows` utwórz plik:
   ```bash
   09-functions.yaml
   ```
2. Ustaw nazwę workflow i wyzwalacze `pull_request` oraz `workflow_dispatch`:
   ```yaml
   name: "09 – Using Functions"

   on:
     pull_request:
     workflow_dispatch:
   ```

---

## 2️⃣ Dodanie joba `echo1` z pięcioma krokami sterowanymi funkcjami statusu

Dodaj job działający na Ubuntu:

```yaml
jobs:
  echo1:
    runs-on: ubuntu-latest
    steps:
      # (tymczasowo puste – uzupełnimy w kolejnych punktach)
```
Teraz uzupełnij kroki:

### a) Krok „Failing step” — celowo kończy się błędem
```yaml
      - name: Failing step
        run: |
          echo "About to fail..."
          exit 1
```

### b) Krok „I will be skipped” — wykona się tylko przy pełnym sukcesie poprzednich kroków
```yaml
      - name: I will be skipped
        if: ${{ success() }}
        run: echo "I will print if previous steps succeed."
```

### c) Krok „I will execute” — wykona się, gdy dowolny poprzedni krok upadł
```yaml
      - name: I will execute
        if: ${{ failure() }}
        run: echo "I will print if any previous step fails."
```

### d) Krok „I will execute” — wykona się zawsze, o ile workflow NIE został anulowany
```yaml
      - name: I will execute
        if: ${{ !cancelled() }}
        run: echo "I will always print, except when the workflow is cancelled."
```

### e) Krok „I will execute when cancelled” — wykona się wyłącznie, gdy workflow został anulowany
```yaml
      - name: I will execute when cancelled
        if: ${{ cancelled() }}
        run: echo "This prints only when the workflow is cancelled."
```

Zacommituj i uruchom workflow z UI, sprawdź które kroki się wykonały (przy braku anulowania: b) zostanie pominięty, c) i d) się wykonają).

---

## 3️⃣ Dodanie kroku opóźniającego „Sleep for 20 seconds” (aby móc anulować ręcznie)

Dodaj **na początku joba** (przed „Failing step”) krok:

```yaml
      - name: Sleep for 20 seconds
        run: sleep 20
```

Zacommituj, uruchom z UI i w ciągu ~20 sekund **anuluj** uruchomienie (⋯ → *Cancel workflow*).  
Zweryfikuj w logach: przy anulowaniu powinien wykonać się tylko krok e) (oraz te, które zdążyły wykonać **przed** anulowaniem).

---

## 4️⃣ Dodanie trzech kroków związanych z PR (na samym początku joba)

Wstaw **na samą górę** joba (przed `Sleep for 20 seconds`) trzy kroki:

### a) „Print PR title” — wypisuje tytuł PR
```yaml
      - name: Print PR title
        if: ${{ github.event_name == 'pull_request' }}
        run: echo "PR title: ${{ github.event.pull_request.title }}"
```

### b) „Print PR labels” — wypisuje etykiety PR w formacie JSON (wielowierszowo)
```yaml
      - name: Print PR labels
        if: ${{ github.event_name == 'pull_request' }}
        run: |
          cat << EOF
          ${{ toJSON(github.event.pull_request.labels) }}
          EOF
```

### c) „Bug step” — wykona się, gdy **wcześniejsze kroki zawiodły**, workflow nie jest anulowany **i** tytuł PR zawiera `fix`
```yaml
      - name: Bug step
        if: ${{ failure() && !cancelled() && contains(github.event.pull_request.title, 'fix') }}
        run: echo "I am a bug fix"
```

Zacommituj, otwórz PR (zmiana w `README.md`), obserwuj wynik. Następnie zamknij i ponownie otwórz PR z tytułem zawierającym `fix` i sprawdź zmianę zachowania „Bug step”.

---

## 5️⃣ Ograniczenie wyzwalaczy do `workflow_dispatch` po testach

Aby uniknąć uruchamiania przy każdym PR, pozostaw wyłącznie ręczne uruchamianie:

```yaml
on:
  workflow_dispatch:
```

---

## 6️⃣ Pełna finalna wersja `09-functions.yaml`

```yaml
name: "09 – Using Functions"

on:
  workflow_dispatch:

jobs:
  echo1:
    runs-on: ubuntu-latest
    steps:
      # KROKI ZWIĄZANE Z PR
      - name: Print PR title
        if: ${{ github.event_name == 'pull_request' }}
        run: echo "PR title: ${{ github.event.pull_request.title }}"

      - name: Print PR labels
        if: ${{ github.event_name == 'pull_request' }}
        run: |
          cat << EOF
          ${{ toJSON(github.event.pull_request.labels) }}
          EOF

      - name: Bug step
        if: ${{ failure() && !cancelled() && contains(github.event.pull_request.title, 'fix') }}
        run: echo "I am a bug fix"

      # OPÓŹNIENIE DLA TESTU ANULOWANIA
      - name: Sleep for 20 seconds
        run: sleep 20

      # SCENARIUSZ Z FUNKCJAMI STATUSU
      - name: Failing step
        run: |
          echo "About to fail..."
          exit 1

      - name: I will be skipped
        if: ${{ success() }}
        run: echo "I will print if previous steps succeed."

      - name: I will execute
        if: ${{ failure() }}
        run: echo "I will print if any previous step fails."

      - name: I will execute
        if: ${{ !cancelled() }}
        run: echo "I will always print, except when the workflow is cancelled."

      - name: I will execute when cancelled
        if: ${{ cancelled() }}
        run: echo "This prints only when the workflow is cancelled."
```
