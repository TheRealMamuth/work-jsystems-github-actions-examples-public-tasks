
# Rozwiązanie: Ćwiczenie 16 — Wiele zadań (jobs) dla lepszego buforowania w GitHub Actions

Poniżej znajduje się kompletne rozwiązanie **krok po kroku**, zgodne z opisem zadania.
Wynik to gotowy plik workflow **`.github/workflows/13-caching.yaml`**, który:
- wprowadza dedykowane zadanie `install-deps` generujące **klucz cache** i (jeśli trzeba) **instalujące zależności**,
- udostępnia ten klucz jako **output joba**, dzięki czemu pozostałe zadania (`lint-test`, `build`) przywracają zależności z cache lub instalują je, jeśli cache nie jest dostępny,
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
name: 13 - Using Caching

on:
  workflow_dispatch:
    inputs:
      use-cache:
        description: Whether to execute cache steps
        type: boolean
        default: true
      node-version:
        description: Node version supported by Vite and Vitest
        type: choice
        options:
          - 22.x
          - 24.x
        default: 24.x

permissions:
  contents: read

env:
  CI: 'true'

jobs:
  install-deps:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: 13-caching/react-app
    outputs:
      deps-cache-key: ${{ steps.cache-key.outputs.CACHE_KEY }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v7
      - name: Setup Node
        id: node
        uses: actions/setup-node@v7
        with:
          node-version: ${{ inputs.node-version }}
          package-manager-cache: false
      - name: Calculate cache key
        id: cache-key
        env:
          CACHE_KEY: react-deps-v2-${{ runner.os }}-${{ runner.arch }}-node-${{ steps.node.outputs.node-version }}-${{ hashFiles('13-caching/react-app/package-lock.json') }}
        run: echo "CACHE_KEY=$CACHE_KEY" >> "$GITHUB_OUTPUT"
      - name: Download cached dependencies
        if: ${{ inputs.use-cache }}
        id: cache
        uses: actions/cache@v6
        with:
          path: 13-caching/react-app/node_modules
          key: ${{ steps.cache-key.outputs.CACHE_KEY }}
      - name: Install dependencies
        if: ${{ steps.cache.outputs.cache-hit != 'true' }}
        run: npm ci --include=dev
  lint-test:
    runs-on: ubuntu-latest
    needs: install-deps
    defaults:
      run:
        working-directory: 13-caching/react-app
    steps:
      - name: Checkout code
        uses: actions/checkout@v7
      - name: Setup Node
        uses: actions/setup-node@v7
        with:
          node-version: ${{ inputs.node-version }}
          package-manager-cache: false
      - name: Download cached dependencies
        if: ${{ inputs.use-cache }}
        id: cache
        uses: actions/cache@v6
        with:
          path: 13-caching/react-app/node_modules
          key: ${{ needs.install-deps.outputs.deps-cache-key }}
      - name: Install dependencies on cache miss or when cache is disabled
        if: ${{ steps.cache.outputs.cache-hit != 'true' }}
        run: npm ci --include=dev
      - name: Typecheck
        run: npm run typecheck
      - name: Testing
        run: npm test
  build:
    runs-on: ubuntu-latest
    needs: install-deps
    defaults:
      run:
        working-directory: 13-caching/react-app
    steps:
      - name: Checkout code
        uses: actions/checkout@v7
      - name: Setup Node
        uses: actions/setup-node@v7
        with:
          node-version: ${{ inputs.node-version }}
          package-manager-cache: false
      - name: Download cached dependencies
        if: ${{ inputs.use-cache }}
        id: cache
        uses: actions/cache@v6
        with:
          path: 13-caching/react-app/node_modules
          key: ${{ needs.install-deps.outputs.deps-cache-key }}
      - name: Install dependencies on cache miss or when cache is disabled
        if: ${{ steps.cache.outputs.cache-hit != 'true' }}
        run: npm ci --include=dev
      - name: Building
        run: npm run build
```

**Dlaczego to działa?**
- `install-deps` przygotowuje cache przed zadaniami zależnymi.
- `lint-test` i `build` korzystają z tego samego klucza; przy braku trafienia lub wyłączeniu cache wykonują własne `npm ci --include=dev`.
- `needs: [install-deps]` pozwala skorzystać z wcześniej przygotowanego cache. Każdy job ma osobny system plików, więc cache jest optymalizacją, a nie warunkiem poprawności.

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

3. Uruchom workflow ręcznie kilka razy (zakładka **Actions** → **13 - Using Caching** → **Run workflow**).
   - Pierwsze uruchomienie: prawdopodobnie **cache miss** w `install-deps` → wykona się `npm ci`.
   - Kolejne uruchomienia (bez zmian w `package-lock.json`): **cache hit** → `npm ci` **nie** wykona się.

---

## 4) Jak mierzyć i porównać czasy

1. Zwróć uwagę na czasy kroków w poszczególnych jobach:
   - `install-deps / Install dependencies (only on cache miss)` — powinien być **pomijany** przy cache hit.
   - `lint-test` i `build` pomijają instalację przy trafieniu cache, ale wykonują ją w pozostałych przypadkach.
2. Zanotuj:
   - **Czas instalacji** przy „miss” (zwykle kilkadziesiąt sekund).
   - **Czas przy cache hit** (krok instalacji pominięty, jedynie przywrócenie cache, zwykle kilkanaście sekund lub mniej w zależności od rozmiaru).
3. Oszacuj koszt 1000 uruchomień:
   - Bez cache (hipotetycznie): `~czas_npm_ci * 1000`.
   - Z cache: `~czas_restore_cache * 1000` (instalacja tylko przy zmianach locka).

---

## 5) Najczęstsze pułapki i wskazówki

- **Ścieżka w cache** musi być podana względem katalogu głównego repozytorium (`13-caching/react-app/node_modules`), ponieważ `actions/cache` nie dziedziczy `working-directory` z `defaults.run`.
- Zmiana `package-lock.json` → **nowy hash** → **nowy klucz** → naturalny „miss” i jednorazowa instalacja.
- Jeżeli równolegle uruchamiasz różne joby na **tej samej gałęzi**, zależność `needs: [install-deps]` gwarantuje, że inne joby **poczekają** na przygotowanie cache.
- Jeśli chcesz, możesz dodać `restore-keys` dla „najbliższych” trafień, ale w tym ćwiczeniu stosujemy **precyzyjny** klucz (najbezpieczniej).

---

## 6) Checklista

- [ ] Plik `.github/workflows/13-caching.yaml` z trzema jobami: `install-deps`, `lint-test`, `build`.
- [ ] `install-deps` publikuje output `deps-cache-key` i **warunkowo** uruchamia `npm ci` (tylko przy cache miss).
- [ ] `lint-test` i `build` mają `needs: [install-deps]` i **zawsze** korzystają z tego samego klucza cache.
- [ ] Czas instalacji porównany dla miss/hit; oszacowane koszty 1000 przebiegów.

Powodzenia! 🚀

### Cache wyłączony lub niedostępny

Każdy job instaluje zależności przy braku trafienia cache. `use-cache=false`
pomija cache we wszystkich jobach, ale nadal uruchamia `npm ci --include=dev`.
Do klucza cache należą system, architektura, wersja Node i hash właściwego lockfile.
