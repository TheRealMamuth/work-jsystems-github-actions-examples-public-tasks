
# Rozwiązanie: Ćwiczenie 16 — Wiele zadań (jobs) dla lepszego buforowania w GitHub Actions

Poniżej znajduje się kompletne rozwiązanie **krok po kroku**, zgodne z opisem zadania.
Wynik to gotowy plik workflow **`.github/workflows/13-caching.yaml`**, który:
- wprowadza dedykowane zadanie `install-deps` generujące **klucz cache** i (jeśli trzeba) **instalujące zależności**,
- udostępnia ten klucz jako **output joba**, dzięki czemu pozostałe zadania (`linting`, `build`) **nie instalują** równolegle zależności — tylko pobierają je z cache,
- pozwala mierzyć czas z i bez trafienia w cache.

---

## 1) Założenia i przygotowanie repozytorium

1. Struktura projektu (jak w poprzednim ćwiczeniu):
   ```text
   13-caching/
     └─ react-app/
         ├─ package.json
         ├─ package-lock.json
         └─ ...
   .github/
     └─ workflows/
         └─ 13-caching.yaml
   ```

2. Aplikacja React TS powinna być już utworzona w `13-caching/react-app` (jeśli nie — patrz poprzednie ćwiczenie).

---

## 2) Docelowy workflow (pełny YAML)

> Skopiuj poniższy plik jako `.github/workflows/13-caching.yaml` w repozytorium.

```yaml
name: 13 – Using Caching (multi-jobs)

on:
  workflow_dispatch:
    inputs:
      node-version:
        type: choice
        description: Node version
        options: [18.x, 20.x, 21.x]
        default: 20.x

jobs:
  # 1) Job, który wylicza klucz cache oraz (jeśli trzeba) instaluje zależności
  install-deps:
    name: Install deps and expose cache key
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: 13-caching/react-app

    outputs:
      deps-cache-key: ${{ steps.cache-key.outputs.CACHE_KEY }}

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}

      - name: Calculate cache key
        id: cache-key
        run: |
          echo "CACHE_KEY=deps-node-modules-${{ hashFiles('13-caching/react-app/package-lock.json') }}" >> "$GITHUB_OUTPUT"

      - name: Download cached dependencies
        id: cache
        uses: actions/cache@v3
        with:
          key: ${{ steps.cache-key.outputs.CACHE_KEY }}
          path: 13-caching/react-app/node_modules

      - name: Install dependencies (only on cache miss)
        if: ${{ steps.cache.outputs.cache-hit != 'true' }}
        run: npm ci

  # 2) Job lintujący i testujący – korzysta wyłącznie z cache, nie instaluje zależności samodzielnie
  linting:
    name: Linting & Tests (from cache)
    runs-on: ubuntu-latest
    needs: [install-deps]
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

      - name: Download cached dependencies (use key from install-deps)
        id: cache
        uses: actions/cache@v3
        with:
          key: ${{ needs.install-deps.outputs.deps-cache-key }}
          path: 13-caching/react-app/node_modules

      - name: Testing
        run: npm run test -- --watchAll=false

      - name: Linting
        run: echo "Linting..."

  # 3) Job build – zależy od install-deps, korzysta z tego samego cache
  build:
    name: Build (from cache)
    runs-on: ubuntu-latest
    needs: [install-deps]
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

      - name: Download cached dependencies (use key from install-deps)
        id: cache
        uses: actions/cache@v3
        with:
          key: ${{ needs.install-deps.outputs.deps-cache-key }}
          path: 13-caching/react-app/node_modules

      - name: Building
        run: npm run build

      - name: Deploying to nonprod
        run: echo "Deploying to nonprod"
```

**Dlaczego to działa?**
- Tylko **jeden** job (`install-deps`) może faktycznie uruchomić `npm ci` i to **wyłącznie** przy „cache miss”.
- Pozostałe joby (`linting`, `build`) **zawsze** biorą zależności z cache, bazując na **tym samym kluczu**, przekazanym jako output joba.
- Dzięki `needs: [install-deps]` unikamy **równoległej instalacji** oraz wyścigu o `node_modules`.

---

## 3) Kroki wprowadzania zmian

1. Utwórz/zmień plik workflow:
   ```bash
   mkdir -p .github/workflows
   $EDITOR .github/workflows/13-caching.yaml
   ```

2. Zatwierdź i wypchnij zmiany:
   ```bash
   git add .github/workflows/13-caching.yaml
   git commit -m "CW16: multi-job caching with install-deps, linting, build"
   git push
   ```

3. Uruchom workflow ręcznie kilka razy (zakładka **Actions** → **13 – Using Caching (multi-jobs)** → **Run workflow**).
   - Pierwsze uruchomienie: prawdopodobnie **cache miss** w `install-deps` → wykona się `npm ci`.
   - Kolejne uruchomienia (bez zmian w `package-lock.json`): **cache hit** → `npm ci` **nie** wykona się.

---

## 4) Jak mierzyć i porównać czasy

1. Zwróć uwagę na czasy kroków w poszczególnych jobach:
   - `install-deps / Install dependencies (only on cache miss)` — powinien być **pomijany** przy cache hit.
   - `linting` i `build` nie mają kroku instalacji — jedynie **przywracają cache**.
2. Zanotuj:
   - **Czas instalacji** przy „miss” (zwykle kilkadziesiąt sekund).
   - **Czas przy cache hit** (krok instalacji pominięty, jedynie przywrócenie cache, zwykle kilkanaście sekund lub mniej w zależności od rozmiaru).
3. Oszacuj koszt 1000 uruchomień:
   - Bez cache (hipotetycznie): `~czas_npm_ci * 1000`.
   - Z cache: `~czas_restore_cache * 1000` (instalacja tylko przy zmianach locka).

---

## 5) Najczęstsze pułapki i wskazówki

- **Ścieżka w cache** musi być bezwzględna względem repo (`13-caching/react-app/node_modules`), ponieważ `actions/cache` nie dziedziczy `working-directory` z `defaults.run`.
- Zmiana `package-lock.json` → **nowy hash** → **nowy klucz** → naturalny „miss” i jednorazowa instalacja.
- Jeżeli równolegle uruchamiasz różne joby na **tej samej gałęzi**, zależność `needs: [install-deps]` gwarantuje, że inne joby **poczekają** na przygotowanie cache.
- Jeśli chcesz, możesz dodać `restore-keys` dla „najbliższych” trafień, ale w tym ćwiczeniu stosujemy **precyzyjny** klucz (najbezpieczniej).

---

## 6) Checklista

- [ ] Plik `.github/workflows/13-caching.yaml` z trzema jobami: `install-deps`, `linting`, `build`.
- [ ] `install-deps` publikuje output `deps-cache-key` i **warunkowo** uruchamia `npm ci` (tylko przy cache miss).
- [ ] `linting` i `build` mają `needs: [install-deps]` i **zawsze** korzystają z tego samego klucza cache.
- [ ] Czas instalacji porównany dla miss/hit; oszacowane koszty 1000 przebiegów.

Powodzenia! 🚀
