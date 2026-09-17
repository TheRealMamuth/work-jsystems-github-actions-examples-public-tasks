
# GitHub Actions Workflow: **10F Example – Flow Control Demo**
*(Line-by-line annotated walkthrough — English first, then Polish)*

---

## EN 🇬🇧 — Line‑by‑line Explanation

> **Goal:** Demonstrate flow control patterns in GitHub Actions (conditional jobs/steps, matrix strategy, gates, and passing data via outputs).

### Header

- `name: 10F Example - Flow Control Demo`  
  Human‑readable workflow name shown in the Actions UI.

### Triggers (`on`)

- `on:`  
  Declares events that start the workflow.

- `push:`  
  Run on git pushes…

  - `branches:` → `main`, `release/*`  
    Only for pushes to `main` or any branch matching `release/<anything>`.

  - `paths-ignore: "docs/**"`  
    Ignore pushes that change only files under `docs/` (no run if docs‑only).

- `pull_request:`  
  Run on **any** pull request …

  - `branches: "**"`  
    …targeting any branch (the double asterisk matches all).

- `workflow_dispatch:`  
  Allow manual runs from the UI with input parameters.

  - `inputs.force_deploy`  
    - `description: "Wymuś deploy (true/false)"` — user‑facing prompt.  
    - `default: "false"` — string default.  
    - `required: true` — UI requires a value.

### Permissions

- `permissions: contents: read`  
  Grants read‑only access to repo contents (principle of least privilege).

### Global Environment

- `env.NODE_VERSION: "20"`  
  A default environment variable available to all jobs/steps unless overridden.

---

## Jobs

### 1) `prep` — PR‑only preflight

```yaml
if: ${ github.event_name == 'pull_request' }
```
Runs **only** for PR events. This job:
- `runs-on: ubuntu-latest` — runner image.
- Defines an **output** `should_run_e2e` sourced from step `decide` (`steps.decide.outputs.e2e`).

**Steps:**

1. `actions/checkout@v4` — fetch the code.
2. **Decide strategy** (`id: decide`)  
   Bash uses GitHub context to detect PR base branch:
   - If `github.base_ref == "main"` → `echo "e2e=true" >> $GITHUB_OUTPUT`  
   - Else → `e2e=false`  
   The `GITHUB_OUTPUT` file is how a step exposes outputs.

3. **Debug logging** (`if: ${ always() }`)  
   Prints the event name, base branch, and computed flag.  
   `always()` means the step runs even if previous steps fail/cancel/skip.

**Effect:** PRs into `main` set `prep.outputs.should_run_e2e = "true"`; other PRs = `"false"`.

---

### 2) `build` — matrix build, but effectively Linux‑only work

- `runs-on: ubuntu-latest` at job level (runner selection for the job).  
  Steps selectively run per matrix conditions.
- `defaults.run.working-directory` points commands to the React app path.
- `strategy.matrix` defines combinations:  
  `os ∈ {ubuntu-latest, windows-latest}` × `node ∈ {18, 20}`.

**Steps:**

1. Checkout.
2. Setup Node using matrix value: `node-version: ${ matrix.node }`.
3. **Install deps** — guarded by `if: ${ matrix.os == 'ubuntu-latest' }`.  
   Skips on Windows; runs `npm ci` on Ubuntu.
4. **Build** — stricter guard: Linux **and** Node 20.  
   `if: ${ matrix.os == 'ubuntu-latest' && matrix.node == 20 }` → `npm run build`.
5. **Artifact placeholder** — Linux‑only; echoes where you’d normally upload artifacts.

**Effect:** The matrix enumerates all pairs, but heavy work executes only on Linux (and build only on Node 20 + Linux).

---

### 3) `unit` — depends on `build`

- `needs: build` — job starts after all matrix runs in `build` finish (success/skip rules apply).  
- Uses same working directory; runs: checkout → `npm ci` → `npm test`.

**Effect:** Fails if unit tests fail; blocks downstream gates that require success.

---

### 4) `security` — optional skip for feature branches on PR

- `needs: build`
- Conditional:
```yaml
if: ${ !startsWith(github.head_ref || github.ref_name, 'feature/') }
```
  - For PRs, `github.head_ref` is the source branch name.  
  - For non‑PR events, fall back to `github.ref_name`.  
  - If branch starts with `feature/` → **job is skipped**; otherwise it runs.

- Placeholder step for dependency scanning (e.g., `npm audit`, `trivy`, `osv-scanner`).

**Effect:** Eases developer iteration on `feature/*` PRs by skipping security job.

---

### 5) `e2e` — end‑to‑end tests, gated by `prep` output

- `needs: [prep, build]` — require both jobs to complete first.
- `if: ${ needs.prep.outputs.should_run_e2e == 'true' }`  
  Only run when `prep` decided `e2e=true` (PRs into `main`).

**Steps:** checkout → `npm ci` → `npm run e2e`.

**Effect:** E2E coverage is focused where it matters (PRs into `main`).

---

### 6) `gate_po_testach` — OR‑like gate after tests

- `needs: [unit, e2e]`
- Condition:
```yaml
if: ${ contains(needs.*.result, 'success') && !contains(needs.*.result, 'failure') }
```
  - `needs.*.result` is the array of job results for `unit` and `e2e`.  
  - Pass when **at least one** is `success` **and none** is `failure` (i.e., the other may be `skipped` or `cancelled`).

**Effect:** If either unit **or** e2e succeeds (and the other isn’t a failure), this gate opens.

---

### 7) `release_gate` — classic AND gate

- `needs: [unit, security]`
- Condition requires **no** `failure`, `cancelled`, or `skipped` in the results:
```yaml
if: ${ !contains(needs.*.result, 'failure') && !contains(needs.*.result, 'cancelled') && !contains(needs.*.result, 'skipped') }
```
- Exposes `outputs.can_release: "true"` (static “green light”).

**Effect:** Enforces both unit **and** security must succeed (no skips).

---

### 8) `deploy` — only on `main`, gated by tests or manual override

- `needs: [gate_po_testach, release_gate]`
- Condition (multi‑line):
```yaml
if: ${ (github.ref == 'refs/heads/main') && (contains(needs.*.result, 'success') || inputs.force_deploy == 'true') }
```
  - Restrict to **main** branch.  
  - Proceed if **any** upstream gate succeeded (`gate_po_testach` **or** `release_gate`) **or** the manual input forced deployment.

**Steps:**
1. Checkout.
2. Deploy — placeholder for `./scripts/deploy.sh`.
3. Post‑deploy verification, guarded by `if: ${ success() }` (only when this job’s prior steps are successful).
4. Cleanup with `if: ${ always() }` — runs regardless of success/failure/cancelled.

**Effect:** Safe deploys by default; manual override possible via `workflow_dispatch` input.

---

### 9) `report` — always‑on summary

- `needs: [prep, build, unit, security, e2e, gate_po_testach, release_gate, deploy]`
- `if: ${ always() }` — emits a status report regardless of upstream outcomes.
- Prints the `.result` of each job from `needs` (useful for post‑mortems and auditing).

**Effect:** Central, reliable end‑of‑run summary.

---

## Key Patterns Highlighted

- **Job/step conditionals:** `if:`, `always()`, `success()`, `startsWith()`, `contains()`.
- **Matrix pruning via step‑level `if`:** run only on selected OS/Node versions.
- **Dataflow via outputs:** step → job output (`GITHUB_OUTPUT`) → `needs.<job>.outputs`.
- **Gates:** OR‑style (`contains` success, no failure) and AND‑style (no failure/cancel/skip).
- **Manual override:** `workflow_dispatch` `inputs.force_deploy` with string values.

---

## PL 🇵🇱 — Wyjaśnienie linia po linii

> **Cel:** Pokazać sterowanie przepływem w GitHub Actions (warunki, macierze, bramki i przekazywanie danych przez outputs).

### Nagłówek

- `name: 10F Example - Flow Control Demo`  
  Czytelna nazwa workflow widoczna w UI Actions.

### Wyzwalacze (`on`)

- `on:` — lista zdarzeń uruchamiających workflow.

- `push:`  
  Uruchamiaj przy pushach…
  - `branches: main, release/*` — tylko na `main` i gałęzie `release/<co_kolwiek>`.
  - `paths-ignore: "docs/**"` — ignoruj commity zmieniające **wyłącznie** pliki w `docs/`.

- `pull_request:`  
  Uruchamiaj na **każdym** PR…
  - `branches: "**"` — do dowolnej gałęzi (wildcard „**”).

- `workflow_dispatch:`  
  Pozwala na ręczne uruchomienie z UI z parametrami.
  - `inputs.force_deploy`  
    - opis w UI, domyślnie `"false"`, pole wymagane.

### Uprawnienia

- `permissions: contents: read`  
  Minimalne, tylko‑do‑odczytu dla zawartości repo.

### Zmienne środowiskowe (globalne)

- `env.NODE_VERSION: "20"`  
  Domyślna zmienna dla wszystkich zadań/kroków (o ile nie nadpisana).

---

## Zadania (jobs)

### 1) `prep` — tylko dla PR

- `if: ${ github.event_name == 'pull_request' }` — job działa wyłącznie na PR.
- `runs-on: ubuntu-latest` — runner.
- `outputs.should_run_e2e` — wyjście z kroku `decide`.

**Kroki:**

1. Checkout kodu.
2. **Decyzja** (`id: decide`)  
   Jeżeli `github.base_ref == "main"` → `e2e=true`, w przeciwnym razie `e2e=false`.  
   Zapis przez `GITHUB_OUTPUT` udostępnia wartość jako output kroku.
3. **Logi debug** (`if: always()`) — wydrukuj event, base_ref, flagę e2e.

**Efekt:** PR do `main` ⇒ `e2e=true`; inne PR ⇒ `e2e=false`.

---

### 2) `build` — macierz, praca realnie na Linuxie

- `runs-on: ubuntu-latest` — runner jobu; warunki na krokach filtrują wykonanie.
- `defaults.run.working-directory` — katalog aplikacji React.
- `strategy.matrix` — `os: ubuntu/windows` × `node: 18/20`.

**Kroki:**

1. Checkout.
2. Setup Node z `matrix.node`.
3. Instalacja zależności **tylko Linux** (`if: matrix.os == 'ubuntu-latest'`) → `npm ci`.
4. Budowa **tylko Linux + Node 20** (`if: matrix.os == 'ubuntu-latest' && matrix.node == 20`) → `npm run build`.
5. Placeholder artefaktu **tylko Linux** (w praktyce użyj `upload-artifact`).

**Efekt:** Macierz się enumeruje, ale ciężkie kroki wykonują się tylko na Linuxie (build: Node 20).

---

### 3) `unit` — zależny od `build`

- `needs: build` — start po zakończeniu macierzy `build`.
- Kroki: checkout → `npm ci` → `npm test`.

**Efekt:** Niepowodzenie blokuje kolejne bramki.

---

### 4) `security` — może pominąć PR z `feature/*`

- `needs: build`
- Warunek:
```yaml
if: ${ !startsWith(github.head_ref || github.ref_name, 'feature/') }
```
  Dla PR używa `github.head_ref`, dla innych zdarzeń `github.ref_name`.  
  Gałęzie `feature/*` → **skip**; inne → uruchom.

- Placeholder skanera zależności.

**Efekt:** Szybsze iteracje na PR z gałęzi feature.

---

### 5) `e2e` — start tylko gdy `prep` → `e2e=true`

- `needs: [prep, build]`
- `if: ${ needs.prep.outputs.should_run_e2e == 'true' }`

Kroki: checkout → `npm ci` → `npm run e2e`.

**Efekt:** E2E uruchamiane selektywnie (PR do `main`).

---

### 6) `gate_po_testach` — bramka typu OR

- `needs: [unit, e2e]`
- Warunek:
```yaml
if: ${ contains(needs.*.result, 'success') && !contains(needs.*.result, 'failure') }
```
  Przepuszcza, jeśli **co najmniej jeden** z (`unit`, `e2e`) jest `success` i **żaden** nie jest `failure`.

**Efekt:** Wystarczy sukces jednego zestawu testów (drugi może być `skipped`/`cancelled`).

---

### 7) `release_gate` — klasyczne AND

- `needs: [unit, security]`
- Warunek: żadnych `failure`, `cancelled`, `skipped` w wynikach:
```yaml
if: ${ !contains(needs.*.result, 'failure') && !contains(needs.*.result, 'cancelled') && !contains(needs.*.result, 'skipped') }
```
- `outputs.can_release: "true"` — stały „zielony” sygnał.

**Efekt:** Wymaga sukcesu obu: unit **i** security (bez skipów).

---

### 8) `deploy` — tylko `main`, z bramek albo wymuszenie

- `needs: [gate_po_testach, release_gate]`
- Warunek:
```yaml
if: ${ (github.ref == 'refs/heads/main') && (contains(needs.*.result, 'success') || inputs.force_deploy == 'true') }
```
  - Tylko na `main`.
  - Przepuszcza, gdy **którykolwiek** z gate’ów jest `success` **lub** użytkownik wymusił deploy.

**Kroki:** checkout → deploy (placeholder) → post‑deploy (`if: success()`) → cleanup (`if: always()`).

**Efekt:** Bezpieczny deploy domyślnie, z opcją ręcznego override.

---

### 9) `report` — zawsze

- `needs: [prep, build, unit, security, e2e, gate_po_testach, release_gate, deploy]`
- `if: always()` — uruchamia się niezależnie od wyników poprzedników.
- Wypisuje `needs.<job>.result` dla pełnego podsumowania.

**Efekt:** Centralne podsumowanie na koniec.

---

## Wzorce w pigułce

- **Warunki:** `if:`, `always()`, `success()`, `startsWith()`, `contains()`.
- **Przycinanie macierzy na krokach:** `if` per kombinacja.
- **Przepływ danych:** `GITHUB_OUTPUT` → `outputs` jobu → `needs.<job>.outputs`.
- **Bramki:** OR (co najmniej jeden success, brak failure) i AND (oba success, brak skipów).
- **Ręczne wymuszenie:** `workflow_dispatch` + `inputs.force_deploy`.
