# Rozwiązanie ćwiczenia 09 — Zmienne organizacyjne, repozytoryjne i środowiskowe

---

## 1️⃣ Przygotowanie środowiska i zmiennych

### 🔹 Zmienne organizacyjne (jeśli masz dostęp do organizacji)
1. Przejdź do **Settings → Organization settings → Variables**.
2. Utwórz dwie zmienne:
   ```text
   ORG_VAR = organization value
   OVERWRITTEN_VAR = organization value 2
   ```

### 🔹 Zmienne repozytoryjne
1. Przejdź do **Settings → Secrets and variables → Actions → Variables**.
2. Dodaj zmienną:
   ```text
   REPOSITORY_VAR = repository value
   ```

### 🔹 Środowiska (Environments)
1. W repozytorium otwórz **Settings → Environments**.
2. Utwórz środowisko `prod`:
   - `TARGET_VAR = prod`
   - `OVERWRITTEN_VAR = prod value`
3. Utwórz środowisko `staging`:
   - `TARGET_VAR = staging`

---

## 2️⃣ Rozszerzenie pliku `08-variables.yaml`

Otwórz plik workflow `08-variables.yaml` i rozbuduj go o nowe elementy.

### 🔹 a) Dodanie nowej zmiennej na poziomie workflow

Dodaj trzecią zmienną środowiskową w sekcji `env`:

```yaml
env:
  WORKFLOW_VAR: "I am a workflow env var"
  OVERWRITTEN: "I will be overwritten"
  UNDEFINED_VAR_WITH_DEFAULT: ${{ vars.UNDEFINED_VAR || 'default value' }}
```

---

## 3️⃣ Dodanie joba `echo2`

### 🔹 Cel: wypisać zmienne organizacyjne i repozytoryjne

```yaml
  echo2:
    runs-on: ubuntu-latest
    steps:
      - name: Print Variables
        run: |
          echo "Org var: ${{ vars.ORG_VAR }}"
          echo "Org overwritten var: ${{ vars.OVERWRITTEN_VAR }}"
          echo "Repo var: ${{ vars.REPOSITORY_VAR }}"
```

💡 Jeśli nie używasz organizacji, usuń linie z `ORG_VAR` i `OVERWRITTEN_VAR`.

---

## 4️⃣ Dodanie joba `echo-prod`

### 🔹 Cel: wypisać zmienne środowiskowe środowiska `prod`

```yaml
  echo-prod:
    runs-on: ubuntu-latest
    environment: prod
    steps:
      - name: Print Prod Variables
        run: |
          echo "Org var: ${{ vars.ORG_VAR }}"
          echo "Org overwritten var: ${{ vars.OVERWRITTEN_VAR }}"
          echo "Repo var: ${{ vars.REPOSITORY_VAR }}"
          echo "Environment var: ${{ vars.TARGET_VAR }}"
```

🧠 Uwaga: `environment: prod` powoduje automatyczne pobranie zmiennych środowiska `prod` zdefiniowanych w ustawieniach repozytorium.

---

## 5️⃣ Dodanie joba `echo-undefined`

### 🔹 Cel: sprawdzenie domyślnej wartości niezdefiniowanej zmiennej

```yaml
  echo-undefined:
    runs-on: ubuntu-latest
    steps:
      - name: Print Undefined Variables
        run: |
          echo "Org var: ${{ env.UNDEFINED_VAR_WITH_DEFAULT }}"
```

Jeśli `UNDEFINED_VAR` nie istnieje, workflow wyświetli:
```
Org var: default value
```

---

## 6️⃣ Testowanie workflow

1. Zatwierdź zmiany:
   ```bash
   git add .
   git commit -m "Add organization, repo, and environment variables workflow"
   git push
   ```

2. Uruchom workflow automatycznie przez **push** lub ręcznie przez **workflow_dispatch**.

3. Obserwuj, jak zmienia się wynik po:
   - zmianie środowiska z `prod` na `staging`,
   - usunięciu lub dodaniu zmiennych w repozytorium lub organizacji.

---

## 7️⃣ Ograniczenie wyzwalaczy do `workflow_dispatch`

Aby uniknąć uruchamiania przy każdym `push`, zmień sekcję `on`:

```yaml
on:
  workflow_dispatch:
```

---

## 8️⃣ Finalna wersja pliku `09-variables.yaml`

```yaml
name: "09 — Organization, Repository, and Environment Variables"

on:
  workflow_dispatch:

env:
  WORKFLOW_VAR: "I am a workflow env var"
  OVERWRITTEN: "I will be overwritten"
  UNDEFINED_VAR_WITH_DEFAULT: ${{ vars.UNDEFINED_VAR || 'default value' }}

jobs:
  echo2:
    runs-on: ubuntu-latest
    steps:
      - name: Print Variables
        run: |
          echo "Org var: ${{ vars.ORG_VAR }}"
          echo "Org overwritten var: ${{ vars.OVERWRITTEN_VAR }}"
          echo "Repo var: ${{ vars.REPOSITORY_VAR }}"

  echo-prod:
    runs-on: ubuntu-latest
    environment: prod
    steps:
      - name: Print Prod Variables
        run: |
          echo "Org var: ${{ vars.ORG_VAR }}"
          echo "Org overwritten var: ${{ vars.OVERWRITTEN_VAR }}"
          echo "Repo var: ${{ vars.REPOSITORY_VAR }}"
          echo "Environment var: ${{ vars.TARGET_VAR }}"

  echo-undefined:
    runs-on: ubuntu-latest
    steps:
      - name: Print Undefined Variables
        run: |
          echo "Org var: ${{ env.UNDEFINED_VAR_WITH_DEFAULT }}"
```

---

## 🔍 Notatki końcowe

- Priorytety zmiennych w GitHub Actions:
  1. **Zmienna kroku (step env)**
  2. **Zmienna joba (job env)**
  3. **Zmienna workflow (workflow env)**
  4. **Zmienna repozytorium / organizacji / środowiska (`vars.*`)**
- Zmienna `vars` odczytuje wartości globalne i środowiskowe.
- Domyślne wartości można ustawiać przez `${{ expression || 'default' }}`.
- Używaj `workflow_dispatch` do testowania, aby uniknąć nadmiernych uruchomień.
