
# Rozwiązanie: Ćwiczenie 22 — Tworzenie złożonej akcji własnej (Composite Custom Action)

Poniżej znajdziesz kompletne rozwiązanie **krok po kroku** w języku polskim. Odtwarza wymagania zadania i dostarcza gotowy plik `action.yaml` wraz z krótkim omówieniem.

---

## 1) Struktura katalogów i pliku akcji

Utwórz katalog i plik zgodnie z treścią ćwiczenia:

```bash
mkdir -p .github/actions/composite-cache-deps
$EDITOR .github/actions/composite-cache-deps/action.yaml
```

> Jeśli nie używasz `$EDITOR`, możesz skorzystać z dowolnego edytora kodu lub polecenia `code`/`nano`/`vim` itp.

---

## 2) Zawartość pliku `.github/actions/composite-cache-deps/action.yaml`

Skopiuj poniższą zawartość **w całości** do pliku `action.yaml`:

```yaml
name: Cache Node and NPM Dependencies
description: "This action allows to cache both Node and NPM dependencies based on the package-lock.json file."

inputs:
  node-version:
    description: NodeJS version to use
    required: true
    default: 24.x
  working-dir:
    description: The working directory of the application
    required: false
    default: "."

runs:
  using: "composite"
  steps:
    - name: Setup NodeJS version ${{ inputs.node-version }}
      uses: actions/setup-node@v7
      with:
        node-version: ${{ inputs.node-version }}

    - name: Cache dependencies
      id: cache
      uses: actions/cache@v6
      with:
        key: deps-node-modules-${{ hashFiles(format('{0}/{1}', inputs.working-dir, 'package-lock.json')) }}
        path: ${{ inputs.working-dir }}/node_modules

    - name: Install dependencies
      if: ${{ steps.cache.outputs.cache-hit != 'true' }}
      shell: bash
      working-directory: ${{ inputs.working-dir }}
      run: npm ci --include=dev
```

**Dlaczego takie ustawienia?**

- **`inputs`** — zgodnie z wymaganiami: `node-version` (wymagane, domyślnie `24.x`) oraz `working-dir` (opcjonalne, domyślnie bieżący katalog `"."`).
- **`runs.using: composite`** — wskazuje, że tworzymy akcję **złożoną**.  
- **Kroki:**
  - `setup-node` pobiera wersję z wejścia (elastyczne użycie tej samej akcji w wielu workflowach/wersjach Node).
  - `actions/cache` zapisuje/odtwarza `node_modules` **w obrębie zadanego katalogu roboczego**. Klucz oparty o hash **wyłącznie** `package-lock.json` z tego katalogu, aby uniknąć zależności między projektami w monorepo.
  - `Install dependencies` uruchamia `npm ci` **tylko** przy braku trafienia cache (oszczędność czasu i zasobów).

---

## 3) Commit i push

```bash
git add .github/actions/composite-cache-deps/action.yaml
git commit -m "CW22: composite action do cache i instalacji zależności npm"
git push
```

> Na tym etapie nic się jeszcze nie wydarzy w CI — akcja jest gotowa, ale **nie jest** użyta w żadnym workflow. W kolejnym ćwiczeniu podłączysz ją do workflowu.

---

## 4) (Opcjonalnie) Minimalny przykład użycia w workflow

Poniższy fragment pokazuje, **jak** wykorzystać tę akcję w typowym jobie (przykład poglądowy — nie jest wymagany w tym ćwiczeniu):

```yaml
name: Sample usage of composite-cache-deps
on: workflow_dispatch

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - name: Cache & install deps (app1)
        uses: ./.github/actions/composite-cache-deps
        with:
          node-version: 24.x
          working-dir: apps/app1
      - name: Build
        working-directory: apps/app1
        run: npm run build
```

---

## 5) Checklista

- [ ] Utworzono katalog `.github/actions/composite-cache-deps/`.  
- [ ] Dodano plik `action.yaml` z definicją **composite action**.  
- [ ] Zdefiniowano wejścia: `node-version` (required, default `24.x`) i `working-dir` (optional, default `.`).
- [ ] Dodano kroki: `setup-node`, `cache` (id: `cache`), `install dependencies` (warunkowo).  
- [ ] Klucz cache wyliczany z **lokalnego** `package-lock.json` w `working-dir`.  
- [ ] Zmiany zatwierdzone i wypchnięte do repozytorium.

Powodzenia! 🚀
