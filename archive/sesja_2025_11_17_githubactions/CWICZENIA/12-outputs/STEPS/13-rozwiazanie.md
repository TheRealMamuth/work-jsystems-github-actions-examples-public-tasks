# Rozwiązanie ćwiczenia 13 – Praca z danymi wyjściowymi (Outputs)

---

## 1️⃣ Utworzenie pliku i wstępna konfiguracja

1. W katalogu `.github/workflows` utwórz plik:
   ```bash
   12-outputs.yaml
   ```
2. Ustaw nazwę workflow oraz wyzwalacz `workflow_dispatch` z wejściem `build-status`:
   ```yaml
   name: "12 – Working with Outputs"

   on:
     workflow_dispatch:
       inputs:
         build-status:
           type: choice
           options: [success, failure]
           default: success
   ```

---

## 2️⃣ Job `build` – zapisanie wartości wyjściowej `status`

1. Dodaj job `build` uruchamiany na `ubuntu-latest`.
2. W pierwszym kroku wypisz ścieżkę do pliku `GITHUB_OUTPUT`.
3. W drugim kroku (z identyfikatorem `build`) dopisz do pliku `GITHUB_OUTPUT` linię z parą klucz=wartość: `status=<wartość wejścia build-status>`.
4. Wystaw output joba `build` o nazwie `build-status`, który pobiera `steps.build.outputs.status`.

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      build-status: ${{ steps.build.outputs.status }}
    steps:
      - name: Print GITHUB_OUTPUT path
        run: echo "$GITHUB_OUTPUT"

      - name: Build
        id: build
        run: echo "status=${{ inputs['build-status'] }}" >> "$GITHUB_OUTPUT"
```

> 🔎 **Wyjaśnienie**: dopisywanie do pliku `GITHUB_OUTPUT` w formacie `klucz=wartość` tworzy wyjście kroku o nazwie `klucz`. Później można je odczytać przez `steps.<id>.outputs.<klucz>`.

---

## 3️⃣ Job `deploy` – uruchamianie warunkowe na podstawie outputu z `build`

1. Dodaj job `deploy` zależny od `build` za pomocą `needs`.
2. Uruchamiaj go **tylko** gdy `needs.build.outputs.build-status == 'success'`.
3. W kroku **Deploy** wypisz komunikat „Deploying”.

```yaml
  deploy:
    runs-on: ubuntu-latest
    needs: build
    if: ${{ needs.build.outputs.build-status == 'success' }}
    steps:
      - name: Deploy
        run: echo "Deploying"
```

---

## 4️⃣ Testy działania

1. Zacommituj i wypchnij zmiany:
   ```bash
   git add .
   git commit -m "Add outputs-based workflow"
   git push
   ```
2. Uruchom workflow z UI **Actions → Run workflow** i sprawdź różne warianty:
   - `build-status = success` → job `deploy` **uruchomi się**.
   - `build-status = failure` → job `deploy` **zostanie pominięty**.

---

## 5️⃣ Finalna wersja pliku `12-outputs.yaml`

```yaml
name: "12 – Working with Outputs"

on:
  workflow_dispatch:
    inputs:
      build-status:
        type: choice
        options: [success, failure]
        default: success

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      build-status: ${{ steps.build.outputs.status }}
    steps:
      - name: Print GITHUB_OUTPUT path
        run: echo "$GITHUB_OUTPUT"

      - name: Build
        id: build
        run: echo "status=${{ inputs['build-status'] }}" >> "$GITHUB_OUTPUT"

  deploy:
    runs-on: ubuntu-latest
    needs: build
    if: ${{ needs.build.outputs.build-status == 'success' }}
    steps:
      - name: Deploy
        run: echo "Deploying"
```

---

## ✅ Podsumowanie

- `GITHUB_OUTPUT` służy do przekazywania danych wyjściowych z **kroku**; następnie job może je wystawić jako swoje własne outputy.
- `needs.<job>.outputs.<nazwa>` pozwala warunkowo sterować wykonaniem kolejnych jobów.
- Dzięki wejściu `build-status` z `workflow_dispatch` możesz w prosty sposób zasymulować różne scenariusze (sukces/porażka) i zobaczyć wpływ na przepływ pracy.
