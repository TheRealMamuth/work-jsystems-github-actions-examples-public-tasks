
# Rozwiązanie: Ćwiczenie 36 — Zapobieganie wstrzyknięciom skryptów przy użyciu **niestandardowej akcji JS**

Poniżej masz kompletne rozwiązanie **krok po kroku** (po polsku). Wykonuje ono wymagania: przygotowanie akcji JS `Safe Title Check`, rozszerzenie workflowu `20-workflow-security.yaml` o job `js-safer-pr`, a następnie weryfikację efektu dla tytułu PR `"abc"; ls -R;`.

Źródło zadania: CW20_02.md. 

---

## 1) Utwórz niestandardową akcję JS – **Safe Title Check**

**Struktura katalogu:**
```
.github/actions/safe-title-check/
├─ action.yaml
└─ index.js
```

### 1.1 `action.yaml`
Utwórz plik `.github/actions/safe-title-check/action.yaml` z treścią:
```yaml
name: Safe Title Check
description: Safely checks the title of a PR

inputs:
  pr-title:
    description: The PR title
    required: true

runs:
  using: node20
  main: index.js
```

### 1.2 `index.js`
Utwórz plik `.github/actions/safe-title-check/index.js` z treścią:
```js
const core = require('@actions/core');

async function run() {
  try {
    const title = core.getInput('pr-title', { required: true });
    if (title.startsWith('feat')) {
      core.info('PR is a feature');
    } else {
      core.info('PR is not a feature');
    }
  } catch (err) {
    core.setFailed(err instanceof Error ? err.message : String(err));
  }
}

run();
```

> Uwaga: Tu **nie** ma żadnej interpolacji do skryptu shella. `title` jest odczytywany jako **input** akcji i traktowany wyłącznie jako **dane**, więc nie ma ryzyka, że `"abc"; ls -R;` stanie się kodem do wykonania.

**Commit:**
```bash
git add .github/actions/safe-title-check
git commit -m "CW36: add Safe Title Check custom JS action"
```

---

## 2) Rozszerz workflow `20-workflow-security.yaml` o job `js-safer-pr`

Otwórz `.github/workflows/20-workflow-security.yaml` (z poprzedniego ćwiczenia) i **dodaj** nowy job:

```yaml
name: 20 – Workflow Security

on:
  pull_request:

jobs:
  # … (istniejące joby z poprzedniego ćwiczenia: unsafe-pr, safer-pr)

  js-safer-pr:
    name: JS – Safer PR title check
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Check PR title
        uses: ./.github/actions/safe-title-check
        with:
          pr-title: ${{ github.event.pull_request.title }}
```

**Dlaczego to jest bezpieczne?**  
- Wartość tytułu PR jest przekazywana do **wejścia akcji** (`with.pr-title`), a następnie odczytana przez `core.getInput(...)` w Node.js.  
- Nie ma tu wstrzyknięcia do Basha, więc ciąg `"abc"; ls -R;` nie może się wykonać jako komendy powłoki.

**Commit:**
```bash
git add .github/workflows/20-workflow-security.yaml
git commit -m "CW36: add js-safer-pr job using Safe Title Check action"
git push
```

---

## 3) Test: utwórz PR z tytułem `"abc"; ls -R;`

1. Zmień dowolny plik, zatwierdź w **nowej gałęzi** i wypchnij.  
2. Otwórz **Pull Request** i nadaj tytuł:
   ```
   "abc"; ls -R;
   ```
3. Poczekaj na uruchomienie workflowu **20 – Workflow Security** i sprawdź logi jobu **JS – Safer PR title check**.

**Oczekiwany wynik:**  
- W logach zobaczysz **tylko** jeden z komunikatów akcji:
  - `PR is a feature` — jeśli tytuł zaczyna się od `feat`, lub
  - `PR is not a feature` — dla wszystkich pozostałych (w tym dla `"abc"; ls -R;`).  
- **Żadne złośliwe polecenia** (np. `ls -R`) **nie zostaną wykonane**, bo wejście jest traktowane jako dane, a nie kod.

---

## 4) Dodatkowe wskazówki (higiena bezpieczeństwa)

- Unikaj wstrzykiwania nieufnych danych do skryptów Basha. Preferuj **inputs** akcji i przetwarzanie w **Node/Python**.  
- Gdy musisz użyć shella, **cytuj** zmienne (`"$VAR"`) i rozważ `set -euo pipefail`.  
- W repo z PR-ami od forków doprecyzuj uprawnienia (`permissions`) i świadomie używaj `pull_request_target` tylko dla bezpiecznych przepływów.

---

## 5) Checklista końcowa

- [ ] Jest katalog `.github/actions/safe-title-check/` z plikami `action.yaml` i `index.js`.  
- [ ] `action.yaml` ma **name**, **description**, input `pr-title` (required) i `runs: node20`.  
- [ ] `index.js` pobiera input i wypisuje wynik bez uruchamiania shella.  
- [ ] W `20-workflow-security.yaml` istnieje job `js-safer-pr` z checkoutem i wywołaniem akcji przez `uses: ./.github/actions/safe-title-check`.  
- [ ] PR z tytułem `"abc"; ls -R;` nie wykonuje złośliwych poleceń; log akcji pokazuje jedynie komunikat o rodzaju PR.

Powodzenia! 🚀
