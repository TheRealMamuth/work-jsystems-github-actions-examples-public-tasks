
# Rozwiązanie: Ćwiczenie 18 — Wprowadzenie do macierzy (GitHub Actions)

Poniżej znajdziesz kompletne rozwiązanie **krok po kroku** w języku polskim, zgodne z treścią zadania. Zawiera gotowe pliki YAML, komendy Git i checklistę weryfikacyjną.

---

## 1) Inicjalizacja pliku workflow

**Ścieżka pliku:** `.github/workflows/15-matrices.yaml`  
**Cel:** Konfiguracja macierzy (Node 18/20/21 × Ubuntu/Windows) oraz dwóch kroków w jobie.

> Utwórz folder i plik:
```bash
mkdir -p .github/workflows
$EDITOR .github/workflows/15-matrices.yaml
```

---

## 2) Pierwsza wersja workflow (bazowa)

Skopiuj poniższy YAML do pliku `.github/workflows/15-matrices.yaml`:

```yaml
name: 15 – Working with Matrices

on:
  workflow_dispatch:

jobs:
  backwards-compatibility:
    name: ${{ matrix.os }}-${{ matrix.node-version }}
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest]
        node-version: [18.x, 20.x, 21.x]

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup node
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}

      - name: Perform some tests
        run: |
          echo "Running tests on OS ${{ matrix.os }} and NodeJS ${{ matrix.node-version }}"
```

**Co robi ta wersja?**  
- Uruchamia job `backwards-compatibility` w **6 kombinacjach** (2 systemy × 3 wersje Node).  
- Nadaje nazwę instancji joba w formacie `<os>-<node-version>`.  
- Wykonuje dwa kroki: instalacja Node oraz test (tu: wydruk komunikatu).

**Commit i uruchomienie:**

```bash
git add .github/workflows/15-matrices.yaml
git commit -m "CW18: bazowa macierz Node (18/20/21) na Ubuntu/Windows"
git push
```
Następnie w GitHubie przejdź do **Actions → 15 – Working with Matrices → Run workflow** i obejrzyj wyniki.

---

## 3) Rozszerzenie macierzy (Node 16.x na Ubuntu + tag „experimental” dla 21.x na Ubuntu) oraz `fail-fast: false`

Zaktualizuj plik `.github/workflows/15-matrices.yaml` do następującej wersji. Dodajemy:
- wpis **Node 16.x** wyłącznie dla `ubuntu-latest` (przez `include`),
- klucz **tag: experimental** dla **Node 21.x** na `ubuntu-latest`,
- ustawienie **`fail-fast: false`**.

```yaml
name: 15 – Working with Matrices

on:
  workflow_dispatch:

jobs:
  backwards-compatibility:
    name: ${{ matrix.os }}-${{ matrix.node-version }}
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest]
        node-version: [18.x, 20.x, 21.x]
        include:
          # dodatkowa kombinacja: Node 16.x tylko na Ubuntu
          - os: ubuntu-latest
            node-version: 16.x
          # dodanie tagu 'experimental' dla Node 21.x na Ubuntu
          - os: ubuntu-latest
            node-version: 21.x
            tag: experimental

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup node
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}

      - name: Fail if experimental
        if: ${{ matrix.tag == 'experimental' }}
        run: |
          echo "Experimental combo detected (OS=${{ matrix.os }}, Node=${{ matrix['node-version'] }}) — failing intentionally."
          exit 1

      - name: Perform some tests
        run: |
          echo "Running tests on OS ${{ matrix.os }} and NodeJS ${{ matrix['node-version'] }}"
          sleep 10

      - name: Upload test results
        run: echo "Uploading test results"
```

**Dlaczego `include`?**  
- Pozwala dodać **pojedyncze, niestandardowe** kombinacje do macierzy (np. 16.x tylko na Ubuntu).  
- Umożliwia dołączenie dodatkowych kluczy (np. `tag`) do wybranych kombinacji bez modyfikowania wszystkich przypadków.

**Commit i uruchomienie:**

```bash
git add .github/workflows/15-matrices.yaml
git commit -m "CW18: rozszerzenie macierzy (16.x na Ubuntu, tag experimental), fail-fast=false"
git push
```
Uruchom ręcznie i przeanalizuj wyniki (zwróć uwagę, że konfiguracja z `experimental` celowo **padnie** na kroku „Fail if experimental”).

---

## 4) Zmiana `fail-fast` na `true` i obserwacja efektu

Zmień fragment strategii na:

```yaml
strategy:
  fail-fast: true
  matrix:
    os: [ubuntu-latest, windows-latest]
    node-version: [18.x, 20.x, 21.x]
    include:
      - os: ubuntu-latest
        node-version: 16.x
      - os: ubuntu-latest
        node-version: 21.x
        tag: experimental
```

**Commit i uruchomienie:**

```bash
git add .github/workflows/15-matrices.yaml
git commit -m "CW18: fail-fast=true – obserwacja wpływu na przebieg macierzy"
git push
```

**Na co zwrócić uwagę?**  
- Przy **`fail-fast: false`**: niepowodzenie jednej kombinacji **nie** zatrzymuje pozostałych — wszystkie pozostałe instancje joba kończą bieg.  
- Przy **`fail-fast: true`**: pierwszy błąd w macierzy spowoduje **anulowanie** trwających/oczekujących kombinacji.

---

## 5) Checklista końcowa

- [ ] Plik `.github/workflows/15-matrices.yaml` istnieje i zawiera **macierz OS × Node**.  
- [ ] Pierwsza wersja: działa echo testu dla 6 kombinacji (Ubuntu/Windows × 18/20/21).  
- [ ] Rozszerzona wersja: dodana kombinacja **Node 16.x na Ubuntu** i **tag: experimental** dla **21.x na Ubuntu**.  
- [ ] Krok **Fail if experimental** wyzwala błąd tylko dla przypadku „experimental”.  
- [ ] Krok **Perform some tests** posiada **10‑sekundowe opóźnienie**.  
- [ ] Krok **Upload test results** wyświetla komunikat o wysyłce.  
- [ ] Przetestowano różnicę między `fail-fast: false` a `fail-fast: true`.

Powodzenia! 🚀
