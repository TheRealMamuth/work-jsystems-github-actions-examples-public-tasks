
# Rozwiązanie: Ćwiczenie 30 — Outputs w niestandardowych akcjach (Composite / JS / Docker)

Poniżej dostarczam kompletne rozwiązanie **krok po kroku** po polsku. Wdraża ono ustawianie i odczyt **outputs** dla trzech typów akcji: *composite*, *JavaScript* oraz *Docker*. Na końcu znajdziesz checklistę.
Źródło zadania: fileciteturn14file0

---

## 1) Composite Action — dodanie `outputs.installed-deps`

**Plik:** `.github/actions/composite-cache-deps/action.yaml`

Dodaj (lub uzupełnij) sekcję `outputs`. Composite action może bezpośrednio referencjonować outputy kroków (np. `steps.cache.outputs.cache-hit`).

```yaml
name: Cache Node and NPM Dependencies
description: "Cache i instalacja zależności npm na podstawie package-lock.json, z rozróżnieniem dla dev/prod."

inputs:
  node-version:
    description: Wersja NodeJS
    required: true
    default: 24.x
  working-dir:
    description: Katalog roboczy aplikacji
    required: false
    default: "."
  target-env:
    description: '"dev" lub "prod". Kontroluje instalację devDependencies.'
    required: false
    default: dev

outputs:
  installed-deps:
    description: "Czy zależności zostały zainstalowane (cache miss)?"
    value: ${{ steps.cache.outputs.cache-hit != 'true' }}

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

---

## 2) Workflow `17-1-custom-actions-composite.yaml` — odczyt outputu kroku

**Plik:** `.github/workflows/17-1-custom-actions-composite.yaml`

Dodaj `id: setup-deps` do kroku używającego akcji oraz nowy krok wypisujący output `installed-deps`:

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
        id: setup-deps
        uses: ./.github/actions/composite-cache-deps
        with:
          node-version: 24.x
          working-dir: ${{ env.working-directory }}
          target-env: ${{ inputs['target-env'] }}

      - name: Print setup deps output
        run: |
          echo "Installed dependencies: ${{ steps.setup-deps.outputs.installed-deps }}"
```

Uruchom z UI i sprawdź, czy wartość jest `true` (miss → instalacja) albo `false` (hit → brak instalacji).

---

## 3) JS Action — dodanie `outputs.updates-available` i ustawienie w kodzie

### 3.1 `action.yaml` (JS)

**Plik:** `.github/actions/js-dependency-update/action.yaml`

Dodaj `outputs` — wartość ustawimy w kodzie (`core.setOutput`).

```yaml
name: Update NPM Dependencies
description: "Sprawdza aktualizacje pakietów NPM i tworzy PR z aktualizacjami"

inputs:
  base-branch:
    description: Base branch
    required: false
    default: main
  target-branch:
    description: PR head branch
    required: false
    default: update-dependencies
  working-directory:
    description: Project directory
    required: true
  gh-token:
    description: GitHub token (write perms)
    required: true
  debug:
    description: Debug logs
    required: false

outputs:
  updates-available:
    description: "Czy dostępne są aktualizacje"

runs:
  using: node20
  main: index.js
```

### 3.2 `index.js` — `core.setOutput('updates-available', ...)`

**Plik:** `.github/actions/js-dependency-update/index.js`

Fragment decydujący o ustawieniu outputu — dodaj **po** wywołaniach `npm update` i `git status`:

```js
const core = require('@actions/core');
const { getExecOutput, exec } = require('@actions/exec');

// ... (walidacja wejść, npm update)

const status = await getExecOutput('git', ['status', '-s', 'package*.json'], { cwd: workingDir });
const hasChanges = (status.stdout || '').trim().length > 0;

core.setOutput('updates-available', hasChanges ? 'true' : 'false'); // ⬅ USTAWIENIE OUTPUTU
```

*(Jeżeli bazujesz na wcześniejszym pełnym pliku, wstaw linię z `setOutput` dokładnie po `hasChanges` i **przed** ewentualnym tworzeniem PR).*

---

## 4) Workflow `17-2-custom-actions-js.yaml` — odczyt outputu kroku

**Plik:** `.github/workflows/17-2-custom-actions-js.yaml`

Dodaj `id: update-deps` do kroku wywołującego akcję i nowy krok wypisujący output:

```yaml
name: 17 – 2 – Custom Actions – JS

on:
  workflow_dispatch:
    inputs:
      base-branch:
        type: string
        default: main
      target-branch:
        type: string
        default: update-dependencies
      working-dir:
        type: string
        default: 17-custom-actions/react-app
      debug:
        type: boolean
        default: false

permissions:
  contents: write
  pull-requests: write

jobs:
  dependency-update:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Check for dependency updates
        id: update-deps
        uses: ./.github/actions/js-dependency-update
        with:
          base-branch: ${{ inputs['base-branch'] }}
          target-branch: ${{ inputs['target-branch'] }}
          working-directory: ${{ inputs['working-dir'] }}
          gh-token: ${{ secrets.GITHUB_TOKEN }}
          debug: ${{ inputs['debug'] }}

      - name: Print custom action output
        run: |
          echo "Updates available: ${{ steps.update-deps.outputs.updates-available }}"
```

---

## 5) Docker Action — dodanie `outputs.url-reachable` i zapis do `GITHUB_OUTPUT`

### 5.1 `action.yaml` (Docker)

**Plik:** `.github/actions/docker-ping-url/action.yaml`

Dodaj sekcję `outputs`:

```yaml
name: Ping URL
description: "Ping URL do skutku lub limitu prób"

inputs:
  url:
    description: URL do pingowania
    required: true
  max_trials:
    description: Maksymalna liczba prób
    required: false
    default: '10'
  delay:
    description: Opóźnienie (sekundy) między próbami
    required: false
    default: '5'

outputs:
  url-reachable:
    description: "Czy URL jest osiągalny"

runs:
  using: docker
  image: Dockerfile
  args:
    - --url
    - ${{ inputs.url }}
    - --max-trials
    - ${{ inputs.max_trials }}
    - --delay
    - ${{ inputs.delay }}
```

### 5.2 `main.py` — dopisanie do `GITHUB_OUTPUT`

**Plik:** `.github/actions/docker-ping-url/main.py`

Na końcu funkcji `run()` (po uzyskaniu wyniku z `ping_url`) dopisz ustawienie outputu przez plik `GITHUB_OUTPUT`:

```python
def run() -> None:
    # ... (pobranie INPUT_*, konwersje, wywołanie ping_url)
    ok = ping_url(url=url, delay=delay, max_trials=max_trials)

    # Ustawienie outputu przez plik specjalny
    github_output = os.environ.get("GITHUB_OUTPUT")
    if github_output:
        with open(github_output, "a", encoding="utf-8") as fh:
            print(f"url-reachable={str(ok).lower()}", file=fh)

    if not ok:
        raise RuntimeError("Ping zakończony niepowodzeniem (brak statusu 200).")
```

> Zwróć uwagę na zapis `str(ok).lower()` → spełnienie konwencji `true`/`false` w niższej kasie.

---

## 6) Workflow `17-3-custom-actions-docker.yaml` — odczyt outputu kroku

**Plik:** `.github/workflows/17-3-custom-actions-docker.yaml`

Oznacz krok z akcją jako `id: ping-url` i dodaj krok wypisujący wynik:

```yaml
name: 17 – 3 – Custom Actions – Docker

on:
  workflow_dispatch:
    inputs:
      url:
        type: choice
        options:
          - https://www.google.com
          - http://127.0.0.1:9/
        default: https://www.google.com
      max_trials:
        type: string
        default: '10'
      delay:
        type: string
        default: '5'

jobs:
  ping-url:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Ping URL (Docker Action)
        id: ping-url
        uses: ./.github/actions/docker-ping-url
        with:
          url: ${{ inputs.url }}
          max_trials: ${{ inputs.max_trials }}
          delay: ${{ inputs.delay }}

      - name: Print output from ping url
        run: |
          echo "URL reachable: ${{ steps.ping-url.outputs.url-reachable }}"
```

---

## 7) Commit, push, uruchom z UI i sprawdź logi

```bash
git add .github/actions/composite-cache-deps/action.yaml         .github/workflows/17-1-custom-actions-composite.yaml         .github/actions/js-dependency-update/action.yaml         .github/actions/js-dependency-update/index.js         .github/workflows/17-2-custom-actions-js.yaml         .github/actions/docker-ping-url/action.yaml         .github/actions/docker-ping-url/main.py         .github/workflows/17-3-custom-actions-docker.yaml
git commit -m "CW30: outputs dla composite/JS/Docker + echo w workflowach"
git push
```
Uruchom **każdy** workflow z UI i sprawdź w logach wartości wypisywanych outputów.

---

## 8) Checklista końcowa

- [ ] Composite: w `action.yaml` dodano `outputs.installed-deps` z wartością `${{ steps.cache.outputs.cache-hit != 'true' }}`.  
- [ ] Workflow `17-1-...`: krok `setup-deps` ma `id` i echoje `steps.setup-deps.outputs.installed-deps`.  
- [ ] JS: w `action.yaml` dodano `outputs.updates-available`; w `index.js` ustawiane `core.setOutput('updates-available', ...)`.  
- [ ] Workflow `17-2-...`: krok `update-deps` ma `id` i echoje `steps.update-deps.outputs.updates-available`.  
- [ ] Docker: w `action.yaml` dodano `outputs.url-reachable`; w `main.py` dopisywanie do `GITHUB_OUTPUT`.  
- [ ] Workflow `17-3-...`: krok `ping-url` ma `id` i echoje `steps.ping-url.outputs.url-reachable`.  

Powodzenia! 🚀
