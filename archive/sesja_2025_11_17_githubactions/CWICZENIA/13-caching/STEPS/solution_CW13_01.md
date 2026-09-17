
# Rozwiązanie: Ćwiczenie 15 – Wykorzystanie buforowania do przyspieszenia instalacji zależności

Poniżej znajdziesz **kompletne, krok‑po‑kroku** rozwiązanie z gotowymi fragmentami YAML i komendami. Możesz je skopiować do swojego repozytorium Git i uruchomić w GitHub Actions.

---

## 1) Wygenerowanie aplikacji React (TypeScript)

**Kroki:**

1. W katalogu głównym repo:
   ```bash
   mkdir -p 13-caching
   cd 13-caching
   ```

2. Wygeneruj aplikację React w katalogu `react-app`:
   ```bash
   npx create-react-app --template typescript react-app
   ```

3. Po sukcesie inicjalizacji zajrzyj do struktury projektu:
   ```bash
   tree -L 2 react-app
   ```

> Uwaga: Jeżeli polecenie `tree` nie jest dostępne lokalnie, po prostu przejrzyj zawartość katalogu w edytorze.

---

## 2) Pierwsza wersja workflowu (bez cache)

**Ścieżka pliku:** `.github/workflows/13-caching.yaml`

**Cel:** Uruchomić checkout, ustawienie Node 20.x, instalację zależności, testy, build oraz „pseudo‑deploy” z komunikatem.

**YAML:**

```yaml
name: 13 – Using Caching

on:
  workflow_dispatch:
    inputs:
      use-cache:
        type: boolean
        description: Whether to execute cache step
        default: true

jobs:
  build:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: 13-caching/react-app

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 20.x

      - name: Install dependencies
        run: npm ci

      - name: Testing
        run: npm run test -- --watchAll=false

      - name: Building
        run: npm run build

      - name: Deploying to nonprod
        run: echo "Deploying to nonprod"
```

**Co zrobić dalej:**

1. Zatwierdź zmiany i wypchnij do zdalnego repo:
   ```bash
   git add .
   git commit -m "CW15: initial workflow without cache"
   git push
   ```
2. Ręcznie uruchom workflow (`Actions` → `13 – Using Caching` → `Run workflow`) **kilka razy**.
3. Zwróć uwagę na czas kroku **Install dependencies**.
   - Zanotuj średni czas (np. 40–120 s w zależności od projektu i obciążenia runnera).
   - Oszacuj koszt przy 1000 uruchomień: `średni_czas * 1000`.

---

## 3) Wersja rozszerzona: wejście `node-version` + cache node_modules

**Modyfikacje:**

- Dodajemy wejście `node-version` (choice: 18.x, 20.x, 21.x; domyślnie 20.x).
- Krok `Setup Node` korzysta z wartości wejścia.
- Dodajemy krok **Download cached dependencies** z `actions/cache@v3` (uruchamiany tylko, gdy `use-cache` = true).
- `Install dependencies` wykonuje się **tylko**, gdy nie znaleziono trafienia w cache (tj. `cache-hit != 'true'`).

**Zmieniony YAML:**

```yaml
name: 13 – Using Caching

on:
  workflow_dispatch:
    inputs:
      use-cache:
        type: boolean
        description: Whether to execute cache step
        default: true
      node-version:
        type: choice
        description: Node version
        options:
          - 18.x
          - 20.x
          - 21.x
        default: 20.x

jobs:
  build:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: 13-caching/react-app

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}

      - name: Download cached dependencies
        if: ${{ inputs.use-cache == true }}
        id: cache
        uses: actions/cache@v3
        with:
          key: deps-node-modules-${{ hashFiles('13-caching/react-app/package-lock.json') }}
          path: 13-caching/react-app/node_modules

      - name: Install dependencies
        # Wykonujemy npm ci tylko, jeśli cache nie został trafiony
        if: ${{ steps.cache.outputs.cache-hit != 'true' }}
        run: npm ci

      - name: Testing
        run: npm run test -- --watchAll=false

      - name: Building
        run: npm run build

      - name: Deploying to nonprod
        run: echo "Deploying to nonprod"
```

**Dlaczego pełna ścieżka w `path`?**  
Ustawienie `defaults.run.working-directory` dotyczy tylko poleceń `run`. Dla akcji cache należy **wprost** wskazać pełną ścieżkę, w której przechowujemy `node_modules`.

---

## 4) Jak porównać czasy i zweryfikować zysk

1. Uruchom workflow z **cache wyłączonym** (`use-cache=false`) i zanotuj czas kroku **Install dependencies**.
2. Uruchom workflow z **cache włączonym** (`use-cache=true`) i **bez zmiany** `package-lock.json`:
   - Za pierwszym razem cache się zbuduje (cache miss → `npm ci`).
   - Za drugim i kolejnych – jeśli lock się nie zmieni – powinniśmy mieć **cache hit** i **ominięty** krok `Install dependencies`.
3. Porównaj czasy:
   - **Bez cache:** pełne `npm ci`.
   - **Z cache:** krok instalacji pomijany (czas ≈ 0 s), a całość przyspiesza głównie etap przygotowania środowiska.
4. Pamiętaj: każdy **commit zmieniający** `package-lock.json` spowoduje nowy klucz i „miss” (co jest oczekiwane, bo zależności faktycznie się zmieniły).

---

## 5) Dodatkowe wskazówki (opcjonalne)

- Jeśli chcesz, możesz ustawić **strategię kluczy** z `restore-keys`, aby próbować przywracać zbliżone cache; w tym zadaniu stosujemy **precyzyjny** klucz oparty o hash `package-lock.json`, co jest najbezpieczniejszym wariantem.
- W testach CI używaj `--watchAll=false`, aby test runner nie oczekiwał na wejście interaktywne.
- `setup-node` potrafi również włączyć wbudowany cache `npm` (opcja `cache: 'npm'`), ale tutaj **celowo** cache’ujemy **node_modules** zgodnie z treścią ćwiczenia.

---

## 6) Szybka checklista

- [ ] Folder `13-caching/react-app` istnieje i buduje się lokalnie.
- [ ] Plik `.github/workflows/13-caching.yaml` utworzony.
- [ ] Pierwszy bieg: brak cache → `npm ci` działa poprawnie.
- [ ] Kolejne biegi, bez zmian locka: jest `cache-hit='true'` i **pomijamy** instalację.
- [ ] Porównane czasy z i bez cache.

---

Powodzenia! :rocket:
