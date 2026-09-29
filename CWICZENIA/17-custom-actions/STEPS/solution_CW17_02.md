
# Rozwiązanie: Ćwiczenie 23 — Użycie i rozszerzenie złożonej akcji niestandardowej (Composite)

Poniżej znajdziesz kompletne rozwiązanie **krok po kroku** w języku polskim. Obejmuje utworzenie aplikacji React, dodanie workflowu korzystającego z wcześniej przygotowanej akcji `composite-cache-deps`, a następnie **rozszerzenie** tej akcji o obsługę środowisk `dev`/`prod` z odpowiednim buforowaniem.

---

## 0) Założenia wstępne

- W repozytorium masz już utworzoną złożoną akcję własną z poprzedniego ćwiczenia w ścieżce:
  ```text
  .github/actions/composite-cache-deps/action.yaml
  ```
- Będziemy z niej korzystać i **rozszerzymy** ją w kroku 4.

---

## 1) Przygotowanie aplikacji React

1. W głównym katalogu repo utwórz folder ćwiczenia i przejdź do niego:
   ```bash
   mkdir -p 17-custom-actions
   cd 17-custom-actions
   ```
2. Wygeneruj aplikację React (TypeScript) w podkatalogu `react-app`:
   ```bash
   # Node.js 24 LTS
   node --version
   npm create vite@9.2.1 react-app -- --template react-ts --no-interactive
   cd react-app
   npm install
   npm run dev
   ```

   Otwórz adres wypisany przez Vite (zwykle http://localhost:5173). Zatrzymaj serwer przez Ctrl+C i pozostań w `react-app`. Wykonaj kroki od punktu 2 z [instrukcji konfiguracji Vite i Vitest](../../REACT_VITE.md) przed przejściem dalej: dodają testy i katalog `build/`. Vite uruchamiaj przez `npm run dev`; szablon nie ma skryptu `start`.

3. (Opcjonalnie) uruchom szybki test, aby upewnić się, że środowisko działa:
   ```bash
   cd react-app
   npm run test -- --watchAll=false
   cd ../..
   ```

---

## 2) Utworzenie workflowu: `17-1-custom-actions-composite.yaml`

**Ścieżka:** `.github/workflows/17-1-custom-actions-composite.yaml`  
**Nazwa workflowu:** `17 – 1 – Custom Actions – Composite`

Skopiuj poniższy YAML do wskazanego pliku (wersja **pierwsza**, bez rozszerzeń prod/dev):
```yaml
name: 17 - 1 - Custom Actions - Composite
run-name: 17 - 1 - Custom Actions - Composite | env - ${{ inputs.target-env }}

on:
  workflow_dispatch:
    inputs:
      target-env:
        description: Dependency cache environment
        type: choice
        options:
          - dev
          - prod
        default: dev

permissions:
  contents: read

env:
  CI: 'true'
  working-directory: 17-custom-actions/react-app

jobs:
  build:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ${{ env.working-directory }}
    steps:
      - uses: actions/checkout@v7
      - name: Setup Node and NPM Dependencies
        id: setup-deps
        uses: ./.github/actions/composite-cache-deps
        with:
          node-version: '24.x'
          working-dir: ${{ env.working-directory }}
          target-env: ${{ inputs.target-env }}
          # Vite, TypeScript and Vitest are needed even for a production build.
          include-dev: 'true'
      - name: Print setup deps output
        env:
          INSTALLED_DEPS: ${{ steps.setup-deps.outputs.installed-deps }}
        run: |
          echo "Installed dependencies during this run: $INSTALLED_DEPS"
      - name: Test
        run: npm test
      - name: Build
        run: npm run build
```

**Co tu się dzieje?**
- `workflow_dispatch` przyjmuje **input** `target-env` (`dev`/`prod`) i wykorzystujemy go w `run-name` (na razie tylko dla czytelności).  
- Na poziomie workflowu ustawiamy `env.working-directory` i używamy go w `defaults.run.working-directory`.  
- Krok **Setup Node and NPM Dependencies** korzysta z lokalnej akcji `.github/actions/composite-cache-deps` i przekazuje **wymagane wejścia**.

**Commit i push:**
```bash
git add .
git commit -m "CW23: workflow 17-1-custom-actions-composite – użycie akcji złożonej"
git push
```

Przed pierwszym uruchomieniem tego workflowu zapisz rozszerzoną akcję z kroku 4,
która definiuje użyte wejścia `target-env` i `include-dev`. Następnie uruchom
workflow ręcznie i sprawdź przebieg.

---

## 3) Instalacja runtime a narzędzia etapu budowania

Chcemy, aby **ta sama akcja** potrafiła instalować zależności:
- pełne (`npm ci --include=dev`) dla `dev`,
- **bez devDependencies** (`npm ci --omit=dev`) dla `prod`, gdy `include-dev=false`,
- pełne także dla `prod`, gdy budujemy i testujemy aplikację Vite (`include-dev=true`),
i aby **cache był rozróżniany** per środowisko, żeby nie mieszać artefaktów (`node_modules`) między `dev` a `prod`.

---

## 4) Rozszerzenie akcji złożonej: dodanie inputu `target-env` i warunków

Otwórz `.github/actions/composite-cache-deps/action.yaml` i **zastąp** zawartość poniższą wersją (z zachowaniem dotychczasowych wejść i kroków, ale z rozszerzeniami):

```yaml
name: Cache Node and NPM Dependencies
description: Install and cache npm dependencies for the selected project and environment.

inputs:
  node-version:
    description: Node.js version
    required: true
    default: '24.x'
  working-dir:
    description: Application directory relative to the repository root
    required: false
    default: '.'
  target-env:
    description: Dependency environment (dev or prod)
    required: false
    default: dev
  include-dev:
    description: Keep build and test tools when target-env is prod
    required: false
    default: 'false'

outputs:
  installed-deps:
    description: Whether npm ci ran instead of restoring an exact cache match
    value: ${{ steps.install.outputs.installed-deps || 'false' }}

runs:
  using: composite
  steps:
    - name: Select dependency mode
      id: mode
      shell: bash
      working-directory: ${{ inputs.working-dir }}
      env:
        TARGET_ENV: ${{ inputs.target-env }}
        INCLUDE_DEV: ${{ inputs.include-dev }}
      run: |
        case "$TARGET_ENV" in
          dev|prod) ;;
          *) echo 'target-env must be dev or prod' >&2; exit 1 ;;
        esac
        case "$INCLUDE_DEV" in
          true|false) ;;
          *) echo 'include-dev must be true or false' >&2; exit 1 ;;
        esac
        test -f package-lock.json
        if [[ "$TARGET_ENV" == prod && "$INCLUDE_DEV" != true ]]; then
          echo 'dependency-mode=prod' >> "$GITHUB_OUTPUT"
        else
          echo 'dependency-mode=dev' >> "$GITHUB_OUTPUT"
        fi
    - name: Setup Node
      id: node
      uses: actions/setup-node@v7
      with:
        node-version: ${{ inputs.node-version }}
        package-manager-cache: false
    - name: Cache dependencies
      id: cache
      uses: actions/cache@v6
      with:
        path: ${{ inputs.working-dir }}/node_modules
        key: react-deps-v2-${{ runner.os }}-${{ runner.arch }}-node-${{ steps.node.outputs.node-version }}-${{ inputs.target-env }}-${{ steps.mode.outputs.dependency-mode }}-${{ hashFiles(format('{0}/package-lock.json', inputs.working-dir)) }}
    - name: Install dependencies
      id: install
      if: ${{ steps.cache.outputs.cache-hit != 'true' }}
      shell: bash
      working-directory: ${{ inputs.working-dir }}
      env:
        DEPENDENCY_MODE: ${{ steps.mode.outputs.dependency-mode }}
      run: |
        if [[ "$DEPENDENCY_MODE" == prod ]]; then
          npm ci --omit=dev
        else
          npm ci --include=dev
        fi
        echo 'installed-deps=true' >> "$GITHUB_OUTPUT"
```

**Co zmieniliśmy i dlaczego?**
- Dodaliśmy **`inputs.target-env`** z domyślną wartością `dev`.  
- Klucz cache uwzględnia `${{ inputs.target-env }}` → rozdziela pamięć podręczną na `dev` i `prod`.  
- Instalacja jest wykonywana tylko przy braku trafienia cache. `include-dev=true` zachowuje Vite, TypeScript i Vitest również dla `prod`. Klucz cache rozróżnia środowisko oraz faktyczny zestaw zależności.

**Commit i push:**
```bash
git add .github/actions/composite-cache-deps/action.yaml
git commit -m "CW23: rozszerzenie akcji – target-env (dev/prod), cache per env, warunkowa instalacja"
git push
```

---

## 5) Aktualizacja workflowu — przekazanie `target-env` do akcji

Zmień sekcję kroku **Setup Node and NPM Dependencies** w pliku `.github/workflows/17-1-custom-actions-composite.yaml` tak, aby przekazywać wartość wejścia:

```yaml
      - name: Setup Node and NPM Dependencies
        uses: ./.github/actions/composite-cache-deps
        with:
          node-version: 24.x
          working-dir: ${{ env.working-directory }}
          target-env: ${{ inputs['target-env'] }}
          include-dev: 'true'
```

**Commit i push:**
```bash
git add .github/workflows/17-1-custom-actions-composite.yaml
git commit -m "CW23: przekazanie target-env (dev/prod) do akcji złożonej"
git push
```

---

## 6) Testy i obserwacje

1. Uruchom workflow **dwukrotnie**:
   - raz z `target-env=dev`,
   - raz z `target-env=prod`.
2. Obserwuj:
   - W `Setup Node and NPM Dependencies` przy **pierwszym przebiegu** powinien zostać zbudowany cache (miss) i wykona się odpowiednia instalacja.  
   - Przy **kolejnym przebiegu z tym samym `target-env`** powinieneś zobaczyć `cache-hit='true'` i **pominiętą** instalację.  
   - Budowa (`npm run build`) i testy (`npm run test`) powinny działać identycznie dla obu środowisk.

---

## 7) Checklista końcowa

- [ ] Aplikacja React dostępna w `17-custom-actions/react-app`.  
- [ ] Workflow `17-1-custom-actions-composite.yaml` istnieje i używa akcji `.github/actions/composite-cache-deps`.  
- [ ] Akcja złożona przyjmuje `node-version`, `working-dir`, **`target-env`** z domyślnym `dev`.  
- [ ] Cache rozdzielony per środowisko dzięki prefiksowi `${{ inputs.target-env }}` w `key`.  
- [ ] Instalacja zależności jest warunkowa: `npm ci` dla `dev`, `npm ci --omit=dev` dla `prod`.  
- [ ] Workflow przekazuje `inputs['target-env']` do akcji.  
- [ ] Przetestowano przebiegi dla `dev` i `prod`; potwierdzono zachowanie cache i różnice w instalacji.

---

Powodzenia! 🚀

### Dlaczego build produkcyjny potrzebuje devDependencies?

Vite, TypeScript i Vitest są narzędziami etapu CI, dlatego workflow przekazuje
`include-dev: 'true'` zarówno dla `dev`, jak i `prod`. Samo `npm ci --omit=dev`
nie przygotuje aplikacji do budowania ani testów. Wersja produkcyjna frontendu
to zawartość `build/`; pominięcie devDependencies nie zmniejsza automatycznie bundla.
Akcja nadal obsługuje instalację samych zależności runtime, gdy `target-env=prod`
i `include-dev=false`, ale po takim wywołaniu nie uruchamiamy Vite ani Vitest.
