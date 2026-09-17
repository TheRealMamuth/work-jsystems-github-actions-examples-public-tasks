
# Rozwiązanie: Ćwiczenie 25 — Parsowanie wejść i uruchamianie poleceń powłoki w akcji JS (GitHub Actions)

Poniżej znajdziesz kompletne rozwiązanie **krok po kroku**. Obejmuje korekty pliku akcji `action.yaml`, aktualizację workflowu `17-2-custom-actions-js.yaml` oraz implementację logiki w `index.js` z walidacją wejść i uruchamianiem poleceń powłoki.

---

## 1) Rozszerz `action.yaml` o wymagane wejścia

**Ścieżka:** `.github/actions/js-dependency-update/action.yaml`

Zastąp zawartość pliku następującą treścią (dodane wejścia: `base-branch`, `target-branch`, `working-directory`, `gh-token`, `debug`):

```yaml
name: Update NPM Dependencies
description: "Checks if there are updates to NPM packages, and creates a PR with the updated package*.json files"

inputs:
  base-branch:
    description: The branch used as the base for the dependency update checks
    required: false
    default: main
  target-branch:
    description: The branch from which the PR is created
    required: false
    default: update-dependencies
  working-directory:
    description: The working directory of the project to check for dependency updates
    required: true
  gh-token:
    description: Authentication token with repository access. Must have write access to contents and pull-requests
    required: true
  debug:
    description: Whether the output debug messages to the console
    required: false

runs:
  using: node20
  main: index.js
```

> Uwaga: `gh-token` zostanie przekazany z workflow jako `secrets.GITHUB_TOKEN` (wystarczy zakres domyślny repo, ma zapisy do `contents` i `pull_requests`).

---

## 2) Zaktualizuj workflow `17-2-custom-actions-js.yaml`

**Ścieżka:** `.github/workflows/17-2-custom-actions-js.yaml`

- Dodaj wejścia `workflow_dispatch`: `base-branch`, `target-branch`, `working-dir`, `debug`.
- Przekaż je do akcji przez `with:` (token z sekretu).
- Uzupełnij `run-name`, aby zawierał `base/target/dir`.

```yaml
name: 17 – 2 – Custom Actions – JS

on:
  workflow_dispatch:
    inputs:
      base-branch:
        type: string
        description: Base branch for update checks
        default: main
      target-branch:
        type: string
        description: Target branch (PR source)
        default: update-dependencies
      working-dir:
        type: string
        description: Directory to check for dependency updates
        default: 17-custom-actions/react-app
      debug:
        type: boolean
        description: Enable debug logs
        default: false

run-name: 17 – 2 – Custom Actions – JS | base:${{ inputs['base-branch'] }} → target:${{ inputs['target-branch'] }} | dir:${{ inputs['working-dir'] }}

jobs:
  dependency-update:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Check for dependency updates
        uses: ./.github/actions/js-dependency-update
        with:
          base-branch: ${{ inputs['base-branch'] }}
          target-branch: ${{ inputs['target-branch'] }}
          working-directory: ${{ inputs['working-dir'] }}
          gh-token: ${{ secrets.GITHUB_TOKEN }}
          debug: ${{ inputs['debug'] }}
```

---

## 3) Zaimplementuj logikę w `index.js`

**Ścieżka:** `.github/actions/js-dependency-update/index.js`

- Pobieraj wejścia przez `@actions/core` (`getInput`, `getBooleanInput`).
- Zweryfikuj nazwy gałęzi i ścieżkę katalogu **regexami**.
- Uruchom `npm update` oraz `git status -s package*.json` przez `@actions/exec`.
- Jeśli `git status` zwróci jakiekolwiek znaki na stdout → wypisz, że **są** aktualizacje; w przeciwnym razie, że **brak** aktualizacji.
- W przypadku błędu walidacji lub wykonania — `core.setFailed(...)`.

Skopiuj poniższy kod:

```js
const core = require('@actions/core');
const { exec, getExecOutput } = require('@actions/exec');
const path = require('path');

function isValidBranch(name) {
  // litery, cyfry, _, -, ., /
  return /^[A-Za-z0-9._/-]+$/.test(name);
}

function isValidDir(p) {
  // litery, cyfry, _, -, /  (bez kropek w nazwie katalogów, aby nie dopuścić np. "..")
  return /^[A-Za-z0-9_/-]+$/.test(p);
}

async function run() {
  try {
    const baseBranch = core.getInput('base-branch', { required: false }) || 'main';
    const targetBranch = core.getInput('target-branch', { required: false }) || 'update-dependencies';
    const workingDir = core.getInput('working-directory', { required: true });
    const ghToken = core.getInput('gh-token', { required: true });
    const debug = core.getBooleanInput('debug', { required: false });

    // Proste debugowanie
    if (debug) {
      core.info(`[debug] base-branch=${baseBranch}`);
      core.info(`[debug] target-branch=${targetBranch}`);
      core.info(`[debug] working-directory=${workingDir}`);
    }

    // Walidacje
    if (!isValidBranch(baseBranch)) {
      return core.setFailed(`Nieprawidłowa nazwa gałęzi base-branch: "${baseBranch}"`);
    }
    if (!isValidBranch(targetBranch)) {
      return core.setFailed(`Nieprawidłowa nazwa gałęzi target-branch: "${targetBranch}"`);
    }
    if (!isValidDir(workingDir)) {
      return core.setFailed(`Nieprawidłowa ścieżka working-directory: "${workingDir}"`);
    }

    // Wypisz zatwierdzone wartości
    core.info(`Base branch: ${baseBranch}`);
    core.info(`Target branch: ${targetBranch}`);
    core.info(`Working directory: ${workingDir}`);

    // Ustawienie zmiennych środowiskowych (jeśli akcja miałaby korzystać z tokena w dalszej logice)
    process.env.GITHUB_TOKEN = ghToken;

    // 1) npm update w podanym katalogu
    await exec('npm', ['update'], { cwd: workingDir });

    // 2) git status -s package*.json i zebranie stdout/stderr
    const status = await getExecOutput('git', ['status', '-s', 'package*.json'], { cwd: workingDir });
    const hasChanges = (status.stdout || '').trim().length > 0;

    if (hasChanges) {
      core.info('Dostępne są aktualizacje pakietów (zmiany w package*.json).');
      if (debug) {
        core.info(`[debug] git status output:\n${status.stdout}`);
      }
    } else {
      core.info('Brak aktualizacji w tej chwili (package*.json bez zmian).');
    }
  } catch (err) {
    core.setFailed(`Błąd działania akcji: ${(err && err.message) ? err.message : err}`);
  }
}

run();
```

> Uwaga: Skrypt *nie tworzy* PR (to nie jest wymagane w tym ćwiczeniu). Celem jest parsowanie wejść, walidacja i użycie poleceń powłoki.

---

## 4) Commit, push i uruchomienie

```bash
git add .github/actions/js-dependency-update/action.yaml         .github/actions/js-dependency-update/index.js         .github/workflows/17-2-custom-actions-js.yaml
git commit -m "CW25: wejścia akcji + walidacja + npm update + git status"
git push
```

Uruchom workflow ręcznie (**Actions → 17 – 2 – Custom Actions – JS → Run workflow**), testując **różne** dane wejściowe:
- poprawne i niepoprawne nazwy gałęzi (np. zawierające niedozwolone znaki),  
- poprawne i niepoprawne ścieżki katalogów.

**Obserwuj efekty w logach** — czy akcja prawidłowo odrzuca niepoprawne wartości i wypisuje oczekiwane komunikaty?

---

## 5) Checklista końcowa

- [ ] `action.yaml` zawiera wejścia: `base-branch`, `target-branch`, `working-directory`, `gh-token`, `debug`.  
- [ ] Workflow `17-2-custom-actions-js.yaml` ma wejścia `workflow_dispatch` i przekazuje je do akcji (token z `secrets.GITHUB_TOKEN`).  
- [ ] `index.js` pobiera wejścia, waliduje je i uruchamia `npm update` oraz `git status -s package*.json`.  
- [ ] Dla zmian w `package*.json` w logach pojawia się informacja o dostępnych aktualizacjach; w przeciwnym razie — o ich braku.  
- [ ] Sprawdzone przypadki poprawnych/niepoprawnych danych wejściowych.

Powodzenia! 🚀
