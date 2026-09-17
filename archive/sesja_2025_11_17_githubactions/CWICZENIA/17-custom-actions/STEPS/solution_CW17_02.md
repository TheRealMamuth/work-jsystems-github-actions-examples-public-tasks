
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
   npx create-react-app --template typescript react-app
   ```
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
name: 17 – 1 – Custom Actions – Composite

on:
  workflow_dispatch:
    inputs:
      target-env:
        type: choice
        description: Wybór środowiska
        options: [dev, prod]
        default: dev

run-name: 17 – 1 – Custom Actions – Composite | env – ${{ inputs['target-env'] }}

env:
  working-directory: 17-custom-actions/react-app

jobs:
  build:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ${{ env.working-directory }}

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node and NPM Dependencies
        uses: ./.github/actions/composite-cache-deps
        with:
          node-version: 20.x
          working-dir: ${{ env.working-directory }}

      - name: Test
        run: npm run test -- --watchAll=false

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

Uruchom ręcznie (**Actions → 17 – 1 – Custom Actions – Composite → Run workflow**) i sprawdź przebieg.

---

## 3) Wymaganie biznesowe: możliwość pomijania devDependencies w buildach prod

Chcemy, aby **ta sama akcja** potrafiła instalować zależności:
- pełne (`npm ci`) dla `dev`,
- **bez devDependencies** (`npm ci --omit=dev`) dla `prod`,
i aby **cache był rozróżniany** per środowisko, żeby nie mieszać artefaktów (`node_modules`) między `dev` a `prod`.

---

## 4) Rozszerzenie akcji złożonej: dodanie inputu `target-env` i warunków

Otwórz `.github/actions/composite-cache-deps/action.yaml` i **zastąp** zawartość poniższą wersją (z zachowaniem dotychczasowych wejść i kroków, ale z rozszerzeniami):

```yaml
name: Cache Node and NPM Dependencies
description: "Cache i instalacja zależności npm na podstawie package-lock.json, z rozróżnieniem dla dev/prod."

inputs:
  node-version:
    description: Wersja NodeJS
    required: true
    default: 20.x
  working-dir:
    description: Katalog roboczy aplikacji
    required: false
    default: "."
  target-env:
    description: '"dev" lub "prod". Kontroluje instalację devDependencies.'
    required: false
    default: dev

runs:
  using: "composite"
  steps:
    - name: Setup NodeJS ${{ inputs.node-version }}
      uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}

    - name: Cache dependencies
      id: cache
      uses: actions/cache@v4
      with:
        key: >-
          deps-node-modules-${{ inputs.target-env }}-
          ${{ hashFiles(format('{0}/{1}', inputs.working-dir, 'package-lock.json')) }}
        path: ${{ inputs.working-dir }}/node_modules

    - name: Install dependencies (dev)
      if: ${{ steps.cache.outputs.cache-hit != 'true' && inputs.target-env == 'dev' }}
      shell: bash
      working-directory: ${{ inputs.working-dir }}
      run: npm ci

    - name: Install dependencies (prod without devDependencies)
      if: ${{ steps.cache.outputs.cache-hit != 'true' && inputs.target-env == 'prod' }}
      shell: bash
      working-directory: ${{ inputs.working-dir }}
      run: npm ci --omit=dev
```

**Co zmieniliśmy i dlaczego?**
- Dodaliśmy **`inputs.target-env`** z domyślną wartością `dev`.  
- Klucz cache uwzględnia `${{ inputs.target-env }}` → rozdziela pamięć podręczną na `dev` i `prod`.  
- Instalacja zależności jest **warunkowa**: osobne kroki dla `dev` i `prod`, wykonywane tylko gdy **cache miss**.

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
          node-version: 20.x
          working-dir: ${{ env.working-directory }}
          target-env: ${{ inputs['target-env'] }}
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
