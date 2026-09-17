
# Rozwiązanie: Ćwiczenie 24 — Przygotowanie akcji niestandardowej w JavaScript (GitHub Actions)

Poniżej dostarczam kompletne rozwiązanie **krok po kroku** w języku polskim. Zawiera komendy, wymagane pliki, fragment `.gitignore`, gotowy workflow oraz checklistę weryfikacyjną.

---

## 1) Struktura katalogów i inicjalizacja projektu akcji JS

**Polecenia:**

```bash
# 1. Utworzenie katalogu na akcję JS
mkdir -p .github/actions/js-dependency-update
cd .github/actions/js-dependency-update

# 2. Inicjalizacja projektu npm
npm init -y

# 3. Instalacja zależności wymaganych przez akcję
npm install @actions/core@1.10.1 @actions/exec@1.1.1 @actions/github@6.0.0 --save-exact
```

**Dlaczego `--save-exact`?**  
Zapewnia deterministyczne wersje (bez dopuszczania automatycznych aktualizacji w przedziałach semantycznych).

---

## 2) Plik akcji: `action.yaml`

Utwórz plik `.github/actions/js-dependency-update/action.yaml` o treści:

```yaml
name: Update NPM Dependencies
description: "Checks if there are updates to NPM packages, and creates a PR with the updated package*.json files"

runs:
  using: node20
  main: index.js
```

**Objaśnienie kluczy:**  
- `using: node20` — akcja uruchamiana przez środowisko Node 20.  
- `main: index.js` — punkt wejścia akcji (plik wykonany przez runnera).

---

## 3) Plik wejściowy akcji: `index.js`

Utwórz plik `.github/actions/js-dependency-update/index.js` o treści:

```js
const core = require('@actions/core');

async function run() {
  core.info('I am a custom JS action');
}

run();
```

> W kolejnym ćwiczeniu można rozwinąć logikę (np. sprawdzanie aktualizacji, tworzenie PR). Tu tylko weryfikujemy, że akcja działa i zapisuje komunikat w logach.

---

## 4) Modyfikacja `.gitignore` – **nie ignoruj** node_modules w katalogach akcji

W głównym katalogu repozytorium dodaj do pliku `.gitignore` linię:

```
!.github/actions/**/node_modules
```

**Po co to?**  
Akcje JS działają z **zacommitowanymi** `node_modules`. To wymóg dla akcji publikowanych z repo (bez bundlowania). Jednocześnie wykluczamy `node_modules` z innych katalogów w repo, jak zwykle.

---

## 5) Workflow: `.github/workflows/17-2-custom-actions-js.yaml`

Utwórz plik `.github/workflows/17-2-custom-actions-js.yaml` o treści:

```yaml
name: 17 – 2 – Custom Actions – JS

on:
  workflow_dispatch:

run-name: 17 – 2 – Custom Actions – JS

jobs:
  dependency-update:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Check for dependency updates
        uses: ./.github/actions/js-dependency-update
```

**Co robi ten workflow?**  
- Uruchamia się ręcznie (workflow_dispatch).  
- Ma pojedynczy job `dependency-update` z dwoma krokami: checkout i uruchomienie **naszej** akcji JS poprzez ścieżkę do katalogu z `action.yaml`.

---

## 6) Commit, push i uruchomienie

```bash
git add .github/actions/js-dependency-update         .github/workflows/17-2-custom-actions-js.yaml         .gitignore
git commit -m "CW24: akcja JS + workflow uruchamiający"
git push
```

Następnie uruchom ręcznie: **Actions → 17 – 2 – Custom Actions – JS → Run workflow**.  
Po wykonaniu sprawdź logi joba: powinien pojawić się wpis `I am a custom JS action`.

---

## 7) Checklista

- [ ] Utworzono katalog `.github/actions/js-dependency-update`.  
- [ ] Zainicjowano `npm` i doinstalowano `@actions/*` z *exact versions*.  
- [ ] Dodano `action.yaml` z `using: node20` i `main: index.js`.  
- [ ] Dodano `index.js` z prostym `core.info(...)`.  
- [ ] Zmieniono `.gitignore` tak, aby **dołączyć** `.github/actions/**/node_modules`.  
- [ ] Dodano workflow `17-2-custom-actions-js.yaml` i uruchomiono go ręcznie.  
- [ ] W logach jest komunikat z akcji.

---

Powodzenia! 🚀
