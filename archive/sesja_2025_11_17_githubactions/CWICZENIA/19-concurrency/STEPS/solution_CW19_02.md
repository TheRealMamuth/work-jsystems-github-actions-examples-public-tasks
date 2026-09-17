
# Rozwiązanie: Ćwiczenie 34 — Zarządzanie współbieżnością na poziomie **jobu** (GitHub Actions)

Poniżej dostarczam kompletne rozwiązanie **krok po kroku** (po polsku), zgodne z treścią zadania. Zawiera gotowy plik YAML workflowu, komendy do uruchomienia oraz omówienie efektów współbieżności na poziomie jobu vs. bez współbieżności.  
Źródło zadania: fileciteturn18file0

---

## 1) Plik workflow: `.github/workflows/19-2-concurrency.yaml`

Skopiuj następującą zawartość:

```yaml
name: 19 – 2 – Managing Concurrency

on:
  workflow_dispatch:

jobs:
  ping-with-concurrency:
    name: Ping with job-level concurrency
    runs-on: ubuntu-latest

    # Współbieżność ustawiona NA POZIOMIE JOBU
    concurrency:
      # zgodnie z poleceniem: "<nazwa workflow>-<git ref>"
      group: ${{ github.workflow }}-${{ github.ref }}
      # domyślnie "cancel-in-progress" = false (kolejkowanie), można też jawnie ustawić
      # cancel-in-progress: false

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Ping URL
        uses: ./.github/actions/docker-ping-url
        with:
          url: http://127.0.0.1:9/
          max_trials: '20'
          delay: '5'

  ping-without-concurrency:
    name: Ping without concurrency
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Ping URL
        uses: ./.github/actions/docker-ping-url
        with:
          url: http://127.0.0.1:9/
          max_trials: '20'
          delay: '5'
```

**Uwagi do konfiguracji:**
- W **`ping-with-concurrency`** zdefiniowano `concurrency.group` = `${{ github.workflow }}-${{ github.ref }}`, co spełnia dokładnie wymóg *„<nazwa workflow>-<git ref>”*.  
- W **`ping-without-concurrency`** brak konfiguracji współbieżności — job będzie uruchamiany równolegle, o ile runner jest dostępny.

---

## 2) Commit i push

```bash
git add .github/workflows/19-2-concurrency.yaml
git commit -m "CW34: concurrency na poziomie jobu (porównanie z jobem bez concurrency)"
git push
```

---

## 3) Test w UI

1. Otwórz **Actions → 19 – 2 – Managing Concurrency**.  
2. Klikaj **Run workflow** kilka razy co 3–5 sekund (na tej samej gałęzi).  
3. Obserwuj:

### Efekt dla jobu z concurrency (ping-with-concurrency)
- Uruchomienia **tego jobu** będą **kolejkowane** w obrębie tej samej grupy (workflow+ref).  
- W danym momencie wykonywana jest **co najwyżej jedna** instancja tego jobu; następne czekają, aż poprzednia zakończy się.  
- To dobrze widać, bo `docker-ping-url` próbuje 20 razy co 5 s, więc każde uruchomienie trwa ~1–2 min.

### Efekt dla jobu bez concurrency (ping-without-concurrency)
- Ten job **nie** ma ograniczeń współbieżności. Jeśli odpalisz workflow wielokrotnie, jego kolejne instancje mogą wystartować **równolegle**, o ile runner ma zasoby.  
- W rezultacie zobaczysz równoległe „pingi” dla wielu uruchomień workflowu.

> Jeśli chcesz, by **najnowsze** uruchomienie jobu z concurrency **anulowało trwające** starsze: dodaj `cancel-in-progress: true` do sekcji `concurrency` w jobie `ping-with-concurrency`.

---

## 4) Najczęstsze pułapki

- **Różne gałęzie = różne grupy**: `${{ github.ref }}` różni się między `main` a `feature/*` → joby na innych gałęziach **nie będą** wzajemnie blokować wykonywania.  
- **Zasięg concurrency**: ustawienie współbieżności na **jobie** dotyczy **tylko tego jobu**, inne joby w tym samym przebiegu nie są nim ograniczane (chyba że również mają własną sekcję `concurrency`).  
- **Ścieżka do akcji Dockera**: pamiętaj o prefiksie `./` w `uses: ./.github/actions/docker-ping-url`.

---

## 5) Checklista końcowa

- [ ] Plik `.github/workflows/19-2-concurrency.yaml` istnieje.  
- [ ] Job **ping-with-concurrency** ma `concurrency.group: ${{ github.workflow }}-${{ github.ref }}`.  
- [ ] Job **ping-without-concurrency** nie ma żadnej sekcji `concurrency`.  
- [ ] Oba joby uruchamiają lokalną akcję `docker-ping-url` z `url=http://127.0.0.1:9/`, `max_trials=20`, `delay=5`.  
- [ ] Test z UI potwierdził: job z concurrency jest **kolejkowany**, a bez concurrency może startować **równolegle**.
