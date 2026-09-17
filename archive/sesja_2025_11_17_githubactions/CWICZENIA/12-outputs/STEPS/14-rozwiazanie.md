# Rozwiązanie ćwiczenia 14 – Unikanie błędu nadpisania pliku wyjściowego (`GITHUB_OUTPUT`)

---

## 1️⃣ Rozszerzenie pliku `12-outputs.yaml`

### 🔹 Krok 1 – Dodanie nowych wartości wyjściowych w kroku `build`

1. Otwórz plik `12-outputs.yaml` i znajdź sekcję kroku o identyfikatorze `build`.
2. Dodaj polecenia do zapisania dwóch wartości (`output1` i `output2`) do pliku `GITHUB_OUTPUT`.

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      output1: ${{ steps.build.outputs.output1 }}
    steps:
      - name: Build
        id: build
        run: |
          echo "output1=value1" >> "$GITHUB_OUTPUT"
          echo "output2=value2" >> "$GITHUB_OUTPUT"
          cat "$GITHUB_OUTPUT"
```

3. Po poleceniu `cat`, które wyświetla zawartość pliku, dodaj linię, która **nadpisuje** zawartość pliku `GITHUB_OUTPUT` (z błędem):

```bash
echo "mistake=true" > "$GITHUB_OUTPUT"
```

4. Następnie ponownie wyświetl zawartość pliku, aby zobaczyć efekt nadpisania:

```bash
cat "$GITHUB_OUTPUT"
```

### 🔹 Krok 2 – Zdefiniowanie danych wyjściowych na poziomie joba

W sekcji `outputs:` joba `build` dodaj przypisanie wartości do `output1`:

```yaml
outputs:
  output1: ${{ steps.build.outputs.output1 }}
```

W ten sposób `build` będzie przekazywał tę wartość do innych jobów.

---

## 2️⃣ Dodanie kroku w jobie `deploy`

W jobie `deploy` dodaj nowy krok o nazwie **Print Outputs**, który wypisze dane wyjściowe z joba `build`:

```yaml
  deploy:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy
        run: echo "Deploying..."

      - name: Print Outputs
        run: echo "Output1 from build: ${{ needs.build.outputs.output1 }}"
```

---

## 3️⃣ Testowanie efektu błędu

1. Zatwierdź i wypchnij zmiany:
   ```bash
   git add .
   git commit -m "Add intentional GITHUB_OUTPUT overwrite mistake"
   git push
   ```

2. Uruchom workflow z interfejsu GitHub **Actions**.
3. Obserwuj wynik działania kroku **Build**:
   - Po pierwszym `cat "$GITHUB_OUTPUT"` widoczne będą obie wartości (`output1`, `output2`).
   - Po wykonaniu błędnej linii `echo "mistake=true" > "$GITHUB_OUTPUT"`, zawartość pliku zostanie nadpisana.
   - W efekcie `output1` i `output2` zostaną utracone.

4. W jobie **deploy** w kroku **Print Outputs** zauważysz, że wartość `output1` będzie pusta – ponieważ plik został nadpisany i dane wyjściowe utracone.

---

## 4️⃣ Poprawa błędu – przeniesienie nadpisania do osobnego kroku

1. Aby naprawić problem, utwórz nowy krok po kroku **Build**, który celowo zawiera błędną linię z `>`.
2. Przenieś linie z `Build` (z `output2` i `cat`) do nowego kroku **Step with mistake**.

Ostatecznie sekcja `build` powinna wyglądać następująco:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      output1: ${{ steps.build.outputs.output1 }}
    steps:
      - name: Build
        id: build
        run: |
          echo "output1=value1" >> "$GITHUB_OUTPUT"
          cat "$GITHUB_OUTPUT"

      - name: Step with mistake
        run: |
          echo "output2=value2" >> "$GITHUB_OUTPUT"
          cat "$GITHUB_OUTPUT"
          echo "mistake=true" > "$GITHUB_OUTPUT"
          cat "$GITHUB_OUTPUT"
```

---

## 5️⃣ Test ponowny po poprawie

1. Zatwierdź zmiany i wypchnij je:
   ```bash
   git add .
   git commit -m "Move mistake to separate step"
   git push
   ```

2. Uruchom workflow ponownie w zakładce **Actions**.

3. Zauważ:
   - Dane wyjściowe z kroku **Build** nie zostały utracone.
   - Błąd nadpisania wystąpił tylko w nowym kroku (**Step with mistake**), nie wpływając na wcześniejsze dane.

---

## ✅ Finalna wersja pliku `12-outputs.yaml`

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
      output1: ${{ steps.build.outputs.output1 }}
    steps:
      - name: Build
        id: build
        run: |
          echo "output1=value1" >> "$GITHUB_OUTPUT"
          cat "$GITHUB_OUTPUT"

      - name: Step with mistake
        run: |
          echo "output2=value2" >> "$GITHUB_OUTPUT"
          cat "$GITHUB_OUTPUT"
          echo "mistake=true" > "$GITHUB_OUTPUT"
          cat "$GITHUB_OUTPUT"

  deploy:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy
        run: echo "Deploying..."

      - name: Print Outputs
        run: echo "Output1 from build: ${{ needs.build.outputs.output1 }}"
```

---

## 🔍 Wnioski

- Operator `>>` **dopisywał** nowe linie do pliku `GITHUB_OUTPUT`.  
- Operator `>` **nadpisuje** cały plik, powodując utratę wcześniejszych danych.  
- Każdy krok w jobie ma swoją odrębną przestrzeń wykonania – dlatego dane zapisane w poprzednich krokach nie są automatycznie kasowane, o ile nie zostaną nadpisane.  
- Aby uniknąć utraty danych wyjściowych, zawsze używaj `>>` do dodawania wartości do `GITHUB_OUTPUT`.  
