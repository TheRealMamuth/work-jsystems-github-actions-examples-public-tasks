# Rozwiązanie ćwiczenia 12 – Praca z danymi wejściowymi (Inputs)

---

## 1️⃣ Utworzenie pliku i definicja podstawowa

1. Przejdź do katalogu `.github/workflows` i utwórz plik:
   ```bash
   11-inputs.yaml
   ```
2. Ustaw nazwę workflow:
   ```yaml
   name: "11 – Working with Inputs"
   ```

---

## 2️⃣ Dodanie wyzwalacza `workflow_dispatch` z trzema wejściami

W tej sekcji zdefiniujemy wejścia (`inputs`), które użytkownik będzie mógł przekazać podczas ręcznego uruchamiania workflow w GitHub Actions UI.

```yaml
on:
  workflow_dispatch:
    inputs:
      dry-run:
        type: boolean
        default: false
        description: "Pomiń wdrożenie i wyświetl jedynie wynik budowania"

      target:
        type: environment
        required: true
        description: "Które środowisko ma być celem workflow"

      tag:
        type: choice
        options:
          - v1
          - v2
          - v3
        default: v3
        description: "Wydanie, z którego ma nastąpić budowa i wdrożenie"
```

---

## 3️⃣ Utworzenie joba `build`

Job `build` wykonuje proces budowania i wypisuje, z jakiego taga (wersji) odbywa się kompilacja.

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Build
        run: echo "Budowanie z tagu ${{ inputs.tag }}"
```

💡 **Wskazówka:** wartość `inputs.tag` pobierana jest bezpośrednio z danych wejściowych użytkownika.

---

## 4️⃣ Utworzenie joba `deploy`

Job `deploy` wykona się tylko wtedy, gdy:

- job `build` zakończy się sukcesem, **i**
- parametr `dry-run` = `false`.

Dodatkowo środowisko (`environment`) ustawiane jest dynamicznie na wartość z `inputs.target`.

```yaml
  deploy:
    runs-on: ubuntu-latest
    needs: build
    if: ${{ inputs.dry-run == false }}
    environment: ${{ inputs.target }}
    steps:
      - name: Deploy
        run: echo "Wdrażanie do ${{ inputs.target }}"
```

---

## 5️⃣ Zatwierdzenie i testowanie workflow

1. Zatwierdź plik w repozytorium:
   ```bash
   git add .
   git commit -m "Add workflow for working with inputs"
   git push
   ```

2. Przejdź do zakładki **Actions** w repozytorium GitHub.
3. Uruchom workflow ręcznie (**Run workflow**) i przetestuj różne kombinacje:
   - `dry-run = true`, `target = prod`, `tag = v1`
   - `dry-run = false`, `target = staging`, `tag = v3`

🔹 **Obserwacja:**  
   - Gdy `dry-run = true`, job `deploy` **nie zostanie uruchomiony**.  
   - Gdy `dry-run = false`, job `deploy` zostanie wykonany i wyświetli nazwę środowiska docelowego.  

---

## 6️⃣ Finalna wersja pliku `11-inputs.yaml`

```yaml
name: "11 – Working with Inputs"

on:
  workflow_dispatch:
    inputs:
      dry-run:
        type: boolean
        default: false
        description: "Pomiń wdrożenie i wyświetl jedynie wynik budowania"
      target:
        type: environment
        required: true
        description: "Które środowisko ma być celem workflow"
      tag:
        type: choice
        options:
          - v1
          - v2
          - v3
        default: v3
        description: "Wydanie, z którego ma nastąpić budowa i wdrożenie"

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Build
        run: echo "Budowanie z tagu ${{ inputs.tag }}"

  deploy:
    runs-on: ubuntu-latest
    needs: build
    if: ${{ inputs.dry-run == false }}
    environment: ${{ inputs.target }}
    steps:
      - name: Deploy
        run: echo "Wdrażanie do ${{ inputs.target }}"
```

---

## 🔍 Podsumowanie

- `workflow_dispatch` umożliwia przekazywanie danych wejściowych podczas ręcznego uruchamiania workflow.  
- `inputs` mogą mieć różne typy: `boolean`, `choice`, `string`, `environment`.  
- Warunek `if:` pozwala kontrolować wykonanie jobów na podstawie wartości wejściowych.  
- Dzięki dynamicznej definicji środowiska (`environment: ${{ inputs.target }}`) można sterować wdrożeniem do różnych środowisk (np. `prod`, `staging`, `test`).  
