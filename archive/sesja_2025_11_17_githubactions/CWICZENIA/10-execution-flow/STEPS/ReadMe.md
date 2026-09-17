# Rozwiązanie ćwiczenia 11 – Definiowanie zależności i warunkowe uruchamianie jobów

---

## 1️⃣ Utworzenie pliku workflow

1. W katalogu `.github/workflows` utwórz plik:
   ```bash
   10-execution-flow.yaml
   ```

2. Dodaj nagłówek workflow i nazwę:
   ```yaml
   name: "10 – Controlling the Execution Flow"
   ```

3. Dodaj wyzwalacz `workflow_dispatch` z wejściem logicznym `pass-unit-tests`:
   ```yaml
   on:
     workflow_dispatch:
       inputs:
         pass-unit-tests:
           type: boolean
           default: false
   ```

---

## 2️⃣ Definicja pierwszego joba `lint-build`

Job uruchamia proces lintowania i budowania projektu.

```yaml
jobs:
  lint-build:
    runs-on: ubuntu-latest
    steps:
      - name: Lint and build
        run: echo "Linting and building project"
```

---

## 3️⃣ Definicja drugiego joba `unit-tests`

Ten job symuluje testy jednostkowe. Jeśli `pass-unit-tests` = `false`, testy kończą się błędem.

```yaml
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - name: Running unit tests
        run: echo "Running tests..."

      - name: Failing tests
        if: ${{ inputs.pass-unit-tests == false }}
        run: |
          echo "Tests failed!"
          exit 1
```

---

## 4️⃣ Dodanie joba `deploy-nonprod`

Ten job powinien uruchamiać się **dopiero po pomyślnym zakończeniu** `lint-build` i `unit-tests`.

```yaml
  deploy-nonprod:
    runs-on: ubuntu-latest
    needs: [lint-build, unit-tests]
    steps:
      - name: Deploying to nonprod
        run: echo "Deploying to nonprod..."
```

---

## 5️⃣ Dodanie joba `e2e-tests`

Job uruchamia testy E2E po zakończeniu `deploy-nonprod`.

```yaml
  e2e-tests:
    runs-on: ubuntu-latest
    needs: deploy-nonprod
    steps:
      - name: Running E2E tests
        run: echo "Running E2E tests"
```

---

## 6️⃣ Dodanie joba `load-tests`

Job uruchamia testy obciążeniowe, również po zakończeniu `deploy-nonprod`.

```yaml
  load-tests:
    runs-on: ubuntu-latest
    needs: deploy-nonprod
    steps:
      - name: Running load tests
        run: echo "Running load tests"
```

---

## 7️⃣ Dodanie joba `deploy-prod`

Job wdrażający do produkcji uruchamia się **dopiero po pomyślnym zakończeniu** testów E2E i testów obciążeniowych.

```yaml
  deploy-prod:
    runs-on: ubuntu-latest
    needs: [e2e-tests, load-tests]
    steps:
      - name: Deploying to prod
        run: echo "Deploying to prod..."
```

---

## 8️⃣ Testowanie przepływu pracy

1. Zacommituj i wypchnij plik:
   ```bash
   git add .
   git commit -m "Add execution flow workflow"
   git push
   ```
2. Uruchom workflow ręcznie z zakładki **Actions** i ustaw różne wartości `pass-unit-tests` (true/false).  
   - Gdy `pass-unit-tests` = `true` → wszystkie joby powinny się wykonać.  
   - Gdy `pass-unit-tests` = `false` → `unit-tests` zakończy się błędem, a joby zależne (`deploy-nonprod`, `e2e-tests`, `load-tests`, `deploy-prod`) nie zostaną uruchomione.

---

## 9️⃣ Testowanie opcji `continue-on-error`

Aby workflow kontynuował mimo błędu testów, dodaj do definicji joba `unit-tests`:

```yaml
  unit-tests:
    runs-on: ubuntu-latest
    continue-on-error: true
    steps:
      - name: Running unit tests
        run: echo "Running tests..."

      - name: Failing tests
        if: ${{ inputs.pass-unit-tests == false }}
        run: |
          echo "Tests failed!"
          exit 1
```

➡️ Teraz nawet przy błędzie testów workflow przejdzie dalej do `deploy-nonprod` i pozostałych jobów.

---

## 🔟 Usunięcie `continue-on-error` po testach

Zaleca się usunięcie `continue-on-error`, aby workflow zatrzymywał się przy faktycznych błędach.

---

## ✅ Finalna wersja pliku `10-execution-flow.yaml`

```yaml
name: "10 – Controlling the Execution Flow"

on:
  workflow_dispatch:
    inputs:
      pass-unit-tests:
        type: boolean
        default: false

jobs:
  lint-build:
    runs-on: ubuntu-latest
    steps:
      - name: Lint and build
        run: echo "Linting and building project"

  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - name: Running unit tests
        run: echo "Running tests..."

      - name: Failing tests
        if: ${{ inputs.pass-unit-tests == false }}
        run: |
          echo "Tests failed!"
          exit 1

  deploy-nonprod:
    runs-on: ubuntu-latest
    needs: [lint-build, unit-tests]
    steps:
      - name: Deploying to nonprod
        run: echo "Deploying to nonprod..."

  e2e-tests:
    runs-on: ubuntu-latest
    needs: deploy-nonprod
    steps:
      - name: Running E2E tests
        run: echo "Running E2E tests"

  load-tests:
    runs-on: ubuntu-latest
    needs: deploy-nonprod
    steps:
      - name: Running load tests
        run: echo "Running load tests"

  deploy-prod:
    runs-on: ubuntu-latest
    needs: [e2e-tests, load-tests]
    steps:
      - name: Deploying to prod
        run: echo "Deploying to prod..."
```

---

## 🔍 Podsumowanie

- `needs:` definiuje zależności między jobami.  
- Jeśli jeden job zawiedzie, joby zależne nie uruchomią się (chyba że użyto `continue-on-error`).  
- `continue-on-error: true` pozwala kontynuować workflow mimo błędu, ale należy używać tej opcji tylko w wyjątkowych przypadkach (np. testy eksperymentalne).  
- Wyzwalacz `workflow_dispatch` pozwala ręcznie przekazywać parametry wejściowe (`inputs`), dzięki czemu można łatwo testować różne scenariusze.  
