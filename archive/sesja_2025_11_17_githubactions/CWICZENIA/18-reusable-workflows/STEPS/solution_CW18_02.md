
# Rozwiązanie: Ćwiczenie 32 — Reużywalne workflowy między repozytoriami (GitHub Actions)

Poniżej znajdziesz kompletne rozwiązanie **krok po kroku** (po polsku) z gotowymi plikami, komendami oraz checklistą. Treść odpowiada wymaganiom ćwiczenia: utworzenie projektu Cypress E2E w **nowym repozytorium**, zbudowanie dla niego workflowu `e2e.yaml`, a następnie jego **wywołanie** z repozytorium głównego jako reusable workflow (z uwzględnieniem uprawnień i PAT).

---

## 1) Nowe repozytorium z Cypress E2E

**Założenie:** nazwa nowego repozytorium: `github-actions-course-example-e2e` (prywatne).

1. Utwórz repo w UI (prywatne, z `README`), sklonuj **jako sąsiedni** katalog względem `github-actions-course`.
2. W terminalu nowego repo:
   ```bash
   npm init -y
   npm install cypress@13.6.1 --save-dev --save-exact
   npx cypress open
   ```
   W kreatorze Cypress: **Continue → E2E Testing → Continue → Start E2E Testing in Chrome → Scaffold example specs**.
3. Dodaj do `package.json` skrypt:
   ```json
   {
     "scripts": {
       "test:e2e": "cypress run"
     }
   }
   ```
4. (Opcjonalnie dla szybkości) usuń folder `cypress/e2e/2-advanced-examples`.
5. Dodaj `.gitignore` z wpisem `node_modules/`.
6. Uruchom lokalnie testy: `npm run test:e2e`.
7. Commit i push.

---

## 2) Workflow E2E w nowym repo: `.github/workflows/e2e.yaml`

**Nazwa:** `E2E Tests`  
**Cel:** uruchamianie testów E2E lokalnie (ręcznie) **i** możliwość użycia jako reusable workflow.

> Plik łączy **dwa** wyzwalacze: `workflow_dispatch` (lokalne uruchomienie) oraz `workflow_call` (wywołanie z innego repo). Dodatkowo przy `workflow_call` deklarujemy **secrets**.

```yaml
name: E2E Tests

on:
  workflow_dispatch:
  workflow_call:
    secrets:
      access-token:
        required: false
        description: "Opcjonalny token dostępu (PAT) do checkoutu tego repo podczas wywołania z innego repo"

jobs:
  e2e-tests:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          # Zalecane przy wywołaniu z innego repo – jawny checkout tego repo:
          repository: ${{ github.repository }}
          ref: main
          # Token: jeśli wywołanie z innego repo dostarczy secret access-token, użyj go; w przeciwnym razie użyj GITHUB_TOKEN
          token: ${{ secrets.access-token || secrets.GITHUB_TOKEN }}

      - name: Setup node
        uses: actions/setup-node@v4
        with:
          node-version: '20.x'

      - name: Install dependencies
        run: npm ci

      - name: Run E2E tests
        run: npm run test:e2e
```

**Weryfikacja lokalna:** commit/push i uruchom z UI (Actions → **E2E Tests** → *Run workflow*).

---

## 3) Uprawnienia i dostępność reusable workflowu

### 3.1 Włącz w repo `github-actions-course-example-e2e`
- **Settings → Actions → General**  
  - **Actions permissions:** `Allow all actions and reusable workflows`  
  - **Access:** Zezwól na dostęp dla repozytoriów **właściciela/użytkownika** (dostęp między repo w obrębie Twojego konta/organizacji).

> Jeśli repo główne `github-actions-course` jest publiczne, rozważ ustawienie go jako **prywatne** (zgodnie z zadaniem), aby uprościć autoryzację przepływu.

---

## 4) Reużycie z repo głównego: `.github/workflows/18-3-reusable-workflows.yaml` w `github-actions-course`

**Nazwa:** `18 – 3 – Reusable Workflows`  
**Opis:** job `deploy` używa **lokalnego** reusable workflowu (z poprzedniego ćwiczenia), a job `e2e-tests` – **zdalnego** `e2e.yaml` z repo `github-actions-course-example-e2e`.

```yaml
name: 18 – 3 – Reusable Workflows

on:
  workflow_dispatch:

jobs:
  deploy:
    uses: ./.github/workflows/18-1-reusable-workflows.yaml
    with:
      target-directory: apps/web

  e2e-tests:
    needs: [deploy]
    # UZUPEŁNIJ wiersz poniżej własnymi wartościami: <owner>/<repo>@<ref>
    uses: <owner>/<repository>/.github/workflows/e2e.yaml@<branch-or-tag-or-sha>
    secrets:
      # przekaż dalej PAT jako secret 'access-token' oczekiwany przez e2e.yaml
      access-token: ${{ secrets.GH_TOKEN }}
```

**Uwaga o referencji:** dla `<branch-or-tag-or-sha>` zalecane jest użycie **tagu** lub konkretnego **SHA**, aby bieg był deterministyczny.

---

## 5) Osobisty token dostępu (PAT) i secret w repo głównym

1. Wygeneruj **Fine-grained PAT**: **Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token**.  
2. W sekcji **Repository access** wskaż **konkretnie**: `github-actions-course-example-e2e`.  
3. Nadaj **Read access** (wystarczające do checkoutu). Zapisz token.
4. W repo `github-actions-course` dodaj sekret repozytorium: **Settings → Secrets and variables → Actions → New repository secret**  
   - **Name:** `GH_TOKEN`  
   - **Value:** *wartość wygenerowanego PAT*.

> Dzięki temu w kroku 4 przekażemy `access-token: ${{ secrets.GH_TOKEN }}` do workflowu `e2e.yaml` wołanego z innego repo.

---

## 6) Commit i uruchomienie z repo głównego

W `github-actions-course`:

```bash
git add .github/workflows/18-3-reusable-workflows.yaml
git commit -m "CW32: wywołanie zdalnego reusable workflowu E2E + przekazanie PAT"
git push
```

Uruchom ręcznie: **Actions → 18 – 3 – Reusable Workflows → Run workflow**.  
Po zakończeniu:
- upewnij się, że job `deploy` zadziałał,
- job `e2e-tests` powinien pobrać kod z repo E2E, zainstalować zależności i uruchomić Cypress.

---

## 7) Częste problemy i ich rozwiązania

- **404 / permission denied przy checkout** – sprawdź:
  - czy token (`GH_TOKEN`) ma dostęp do `github-actions-course-example-e2e`,
  - czy poprawnie przekazałeś `secrets.access-token` w `e2e.yaml`,
  - czy w wywołaniu `uses: <owner>/<repo>/.github/workflows/e2e.yaml@<ref>` podałeś **właściwego ownera**, **repo** oraz **ref** istniejący w tamtym repo.
- **Brak uprawnień do uruchamiania reusable workflowów** – włącz `Allow all actions and reusable workflows` **w obu repo**.
- **Zbyt wolne testy** – usuń `2-advanced-examples` albo parametryzuj zestaw testów.

---

## 8) Checklista końcowa

- [ ] Repo `github-actions-course-example-e2e` utworzone, Cypress zainstalowany, `test:e2e` działa lokalnie.  
- [ ] Plik `.github/workflows/e2e.yaml` zawiera **`workflow_dispatch` + `workflow_call`**, deklaruje `secrets.access-token`, krok checkout korzysta z `token`.  
- [ ] W repo E2E włączono `Allow all actions and reusable workflows` oraz dostęp dla repo właściciela.  
- [ ] W repo `github-actions-course` istnieje `.github/workflows/18-3-reusable-workflows.yaml` z jobami `deploy` i `e2e-tests`.  
- [ ] Utworzono **PAT** z dostępem **read** do repo E2E, zapisano jako `GH_TOKEN` w sekretach repo głównego.  
- [ ] Ręczne uruchomienie w repo głównym powoduje wywołanie workflowu z repo E2E i wykonanie testów.

Powodzenia! 🚀
