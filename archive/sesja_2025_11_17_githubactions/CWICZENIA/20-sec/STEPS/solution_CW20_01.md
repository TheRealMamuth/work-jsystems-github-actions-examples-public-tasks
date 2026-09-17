
# Rozwiązanie: Ćwiczenie 35 — Zapobieganie wstrzyknięciom skryptów przez zmienne pośrednie (GitHub Actions)

Poniżej masz kompletne rozwiązanie **krok po kroku** po polsku: dwa joby (`unsafe-pr` i `safer-pr`), gotowy YAML, komendy oraz oczekiwane rezultaty dla złośliwego tytułu PR `"abc"; ls -R;`.

---

## 1) Utworzenie workflowu

**Ścieżka:** `.github/workflows/20-workflow-security.yaml`  
**Nazwa:** `20 – Workflow Security`  
**Wyzwalacz:** `pull_request`

```yaml
name: 20 – Workflow Security

on:
  pull_request:

jobs:
  unsafe-pr:
    name: Unsafe PR title check
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Check PR title (UNSAFE)
        shell: bash
        run: |
          title=${{ github.event.pull_request.title }}
          if [[ $title =~ ^feat ]]; then
            echo "PR is a feature"
            exit 0
          else
            echo "PR is not a feature"
            exit 1
          fi

  safer-pr:
    name: Safer PR title check
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Check PR title (SAFER via env)
        env:
          # przekazujemy wartość z eventu do ZMIENNEJ ŚRODOWISKOWEJ (pośredniej)
          TITLE: ${{ github.event.pull_request.title }}
        shell: bash
        run: |
          set -euo pipefail
          # UŻYWAJ CUDZYSŁOWÓW przy referencji, by uniknąć globbingu/word-splittingu
          if [[ "$TITLE" =~ ^feat ]]; then
            echo "PR is a feature"
            exit 0
          else
            echo "PR is not a feature"
            exit 1
          fi
```

**Dlaczego `safer-pr` jest bezpieczniejszy?**  
- W `unsafe-pr` wartość tytułu jest **wstrzykiwana** w skrypt za pomocą interpolacji wyrażeń. Ciąg `"abc"; ls -R;` staje się **częścią skryptu**, więc powłoka wykona `ls -R`.  
- W `safer-pr` tytuł PR trafia do **zmiennej środowiskowej** (`env.TITLE`) ustawianej przez runnera **przed** uruchomieniem powłoki. W samym skrypcie odwołujemy się do *wartości* zmiennej (`"$TITLE"`), a nie doklejamy nieufny tekst do kodu. To eliminuje wstrzyknięcie.

---

## 2) Commit i pierwsza próba (wariant niebezpieczny)

1. Zatwierdź plik i wypchnij zmiany:
   ```bash
   git add .github/workflows/20-workflow-security.yaml
   git commit -m "CW35: workflow security – dodanie unsafe-pr i safer-pr"
   git push
   ```
2. Otwórz PR z **dowolną zmianą** i nadaj tytuł:  
   ```
   "abc"; ls -R;
   ```
3. Oczekiwany rezultat w jobie **`unsafe-pr`**:  
   - Linia `title=${{ github.event.pull_request.title }}` rozszerzy się do:
     ```bash
     title="abc"; ls -R;
     ```
   - Powłoka **wykona** `ls -R` (rekurencyjny listing repo) **zanim** wejdzie do `if`. W logach zobaczysz wypisane pliki/katalogi.  
   - To jest przykład **script injection**.

---

## 3) Druga próba (wariant bezpieczniejszy)

1. Utwórz kolejny PR (lub zaktualizuj istniejący) z **tym samym tytułem**:  
   ```
   "abc"; ls -R;
   ```
2. Oczekiwany rezultat w jobie **`safer-pr`**:  
   - Nie ma wstrzyknięcia do treści skryptu. Zmienna środowiskowa `TITLE` ma dosłowną wartość tytułu i jest używana w warunku jako `"$TITLE"`.  
   - **Żadne dodatkowe polecenia** (np. `ls -R`) **nie zostaną wykonane**.  
   - Warunek `[[ "$TITLE" =~ ^feat ]]` zwróci `false`, więc krok zakończy się `exit 1` z komunikatem „PR is not a feature”.

---

## 4) Dodatkowe zalecenia (hardening)

- **Zawsze cytuj** zmienne w Bashu: `"$VAR"` zamiast `$VAR`.  
- Wykorzystuj **`env`/`with`/`inputs`** do przekazywania nieufnego tekstu do kroków — **nie sklejaj** go z kodem.  
- Rozważ **`shell: bash --noprofile --norc -eo pipefail`** oraz osobne skrypty `.sh` w repo (łatwiej testować/linować).  
- Przy eventach zewnętrznych (`pull_request` z forka) stosuj zasady ochrony (np. ograniczenia uprawnień, `permissions`, ręczne zatwierdzanie, `pull_request_target` wyłącznie świadomie itd.).

---

## 5) Checklista

- [ ] Utworzono plik `.github/workflows/20-workflow-security.yaml` z wyzwalaczem `pull_request`.  
- [ ] Dodano job **`unsafe-pr`** z bezpośrednim wstrzyknięciem tytułu do skryptu.  
- [ ] Dodano job **`safer-pr`** z pośrednim przekazaniem tytułu przez `env.TITLE` i cytowaniem `"$TITLE"`.  
- [ ] Zweryfikowano w logach: w `unsafe-pr` uruchomiło się `ls -R`; w `safer-pr` żadne zewnętrzne polecenie nie zostało wykonane.  
- [ ] Utrwalono dobre praktyki (cytowanie, `env`, twarde opcje shella).
