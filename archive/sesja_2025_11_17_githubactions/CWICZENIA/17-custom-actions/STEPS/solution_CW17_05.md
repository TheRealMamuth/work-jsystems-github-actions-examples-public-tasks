
# Rozwiązanie: Ćwiczenie 26 — Dodanie logiki tworzenia Pull Requestów w akcji JS

Poniżej znajduje się kompletne, **krok‑po‑kroku** rozwiązanie w języku polskim. Kontynuuje ono poprzednie ćwiczenia z akcji `js-dependency-update` i pokazuje, jak:
1) nadać odpowiednie **uprawnienia** `GITHUB_TOKEN`,
2) **zezwolić** w ustawieniach repo na tworzenie PR‑ów przez Actions,
3) rozszerzyć `index.js`, by po wykryciu zmian **utworzyć gałąź, commit, push i PR** (Octokit),
4) zrozumieć zachowanie przy **kolejnym uruchomieniu**, gdy PR już istnieje.

---

## 1) Uprawnienia tokena i przekazanie `GITHUB_TOKEN` do akcji

**Plik:** `.github/workflows/17-2-custom-actions-js.yaml`

Dodaj na najwyższym poziomie klucz `permissions`, a także przekaż token do wejścia `gh-token` naszej akcji:

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

# ⬇️ WYMAGANE UPRAWNIENIA DO ZAPISU
permissions:
  contents: write
  pull-requests: write

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

## 2) Pozwolenie repozytorium na tworzenie PR przez Actions

W repozytorium przejdź: **Settings → Actions → General → Workflow permissions** i zaznacz:
**Allow GitHub Actions to create and approve pull requests**.

> Po zapisaniu ustawień token `GITHUB_TOKEN` z powyższymi `permissions` będzie mógł faktycznie tworzyć PR‑y.

---

## 3) Rozszerzenie `index.js`: tworzenie gałęzi, commit, push i PR (Octokit)

**Plik:** `.github/actions/js-dependency-update/index.js`
Poniżej kompletna wersja (rozszerzona względem poprzedniego ćwiczenia). Zakłada, że wcześniej wykonujesz `npm update` i sprawdzasz `git status -s package*.json`. Jeśli zmiany **istnieją**, wykonujemy kroki PR:

```js
const core = require('@actions/core');
const github = require('@actions/github');
const { exec, getExecOutput } = require('@actions/exec');

function isValidBranch(name) {
  return /^[A-Za-z0-9._/-]+$/.test(name);
}
function isValidDir(p) {
  return /^[A-Za-z0-9_/-]+$/.test(p);
}

async function run() {
  try {
    const baseBranch = core.getInput('base-branch') || 'main';
    const targetBranch = core.getInput('target-branch') || 'update-dependencies';
    const workingDir = core.getInput('working-directory', { required: true });
    const ghToken = core.getInput('gh-token', { required: true });
    const debug = core.getBooleanInput('debug') || false;

    if (!isValidBranch(baseBranch)) return core.setFailed(`Nieprawidłowa nazwa gałęzi base-branch: "${baseBranch}"`);
    if (!isValidBranch(targetBranch)) return core.setFailed(`Nieprawidłowa nazwa gałęzi target-branch: "${targetBranch}"`);
    if (!isValidDir(workingDir)) return core.setFailed(`Nieprawidłowa ścieżka working-directory: "${workingDir}"`);

    // 1) Aktualizacja zależności
    await exec('npm', ['update'], { cwd: workingDir });

    // 2) Sprawdzenie, czy package*.json zostały zmienione
    const status = await getExecOutput('git', ['status', '-s', 'package*.json'], { cwd: workingDir });
    const hasChanges = (status.stdout || '').trim().length > 0;
    core.info(hasChanges ? 'Wykryto zmiany w package*.json' : 'Brak zmian w package*.json');

    if (!hasChanges) return; // nic do zrobienia

    // 3) Przełączenie/utworzenie gałęzi docelowej (na bazie aktualnego commita)
    await exec('git', ['checkout', '-B', targetBranch], { cwd: workingDir });

    // 4) Dodanie, commit
    await exec('git', ['add', 'package.json', 'package-lock.json'], { cwd: workingDir });
    await exec('git', ['commit', '-m', 'chore(deps): update npm dependencies'], { cwd: workingDir });

    // 5) Push gałęzi
    await exec('git', ['push', '-u', 'origin', targetBranch], { cwd: workingDir });

    // 6) Utworzenie PR za pomocą Octokit
    const octokit = github.getOctokit(ghToken);
    try {
      await octokit.rest.pulls.create({
        owner: github.context.repo.owner,
        repo: github.context.repo.repo,
        title: 'Update NPM dependencies',
        body: 'This pull request updates NPM packages',
        base: baseBranch,
        head: targetBranch
      });
      core.info('PR został utworzony.');
    } catch (e) {
      // Typowy przypadek: PR już istnieje → API zwraca 422 Unprocessable Entity
      if (e.status === 422) {
        core.info('PR prawdopodobnie już istnieje. Pomijam tworzenie nowego.');
      } else {
        core.error('[js-dependency-update] Błąd podczas tworzenia PR.');
        core.setFailed(e.message);
        core.error(e);
      }
    }
  } catch (err) {
    core.setFailed(`Błąd działania akcji: ${(err && err.message) ? err.message : err}`);
  }
}

run();
```

**Uwagi praktyczne:**
- `git checkout -B targetBranch` przełącza na gałąź i tworzy ją, jeśli nie istnieje.
- `git push -u origin targetBranch` ustawia śledzenie zdalnej gałęzi — ułatwia kolejne push’e.
- Błąd **422** przy `pulls.create` zwykle oznacza, że **istnieje już otwarty PR** z tą samą parą `base/head` — w takim wypadku logujemy informację i nie przerywamy działania.

---

## 4) Commit, push i uruchomienie

```bash
git add .github/workflows/17-2-custom-actions-js.yaml         .github/actions/js-dependency-update/index.js
git commit -m "CW26: uprawnienia tokena + tworzenie gałęzi, commit, push i PR (Octokit)"
git push
```

Uruchom workflow z UI (**Actions → 17 – 2 – Custom Actions – JS → Run workflow**).
Po zakończeniu:
- Sprawdź czy pojawiła się **gałąź** `${{ inputs.target-branch }}` i **PR** do `${{ inputs.base-branch }}`.
- Otwórz logi joba — zobaczysz kroki `npm update`, `git status`, `checkout -B`, `commit`, `push`, `pulls.create`.

---

## 5) Co stanie się przy kolejnym uruchomieniu, gdy PR już istnieje?

- `npm update` może nic nie zmienić — `git status` będzie pusty → akcja **nic nie zrobi**.
- Jeśli zmiany **są**, ale PR już istnieje dla (`base`, `head`), próba `pulls.create` zwróci **422** — w kodzie **logujemy** informację „PR prawdopodobnie już istnieje” i **nie traktujemy tego jako błąd**.
- To zachowanie jest pożądane: unikamy duplikowania PR‑ów i utrzymujemy **jeden** wątek aktualizacji.

---

## 6) Checklista końcowa

- [ ] W `17-2-custom-actions-js.yaml` ustawiono `permissions: { contents: write, pull-requests: write }`.
- [ ] Do akcji przekazywany jest `gh-token: ${{ secrets.GITHUB_TOKEN }}`.
- [ ] W ustawieniach repo zaznaczono **Allow GitHub Actions to create and approve pull requests**.
- [ ] `index.js` po wykryciu zmian tworzy gałąź, commit, push i PR; obsługuje przypadek istniejącego PR (422).
- [ ] Uruchomiono workflow i zweryfikowano rezultat w logach oraz w zakładce PR.

---

Powodzenia! 🚀
