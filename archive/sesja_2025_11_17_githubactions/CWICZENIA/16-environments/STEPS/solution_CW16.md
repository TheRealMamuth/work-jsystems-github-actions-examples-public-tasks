
# Rozwiązanie: Ćwiczenie 21 — Praca ze środowiskami (GitHub Actions Environments)

Poniżej masz kompletne rozwiązanie **krok po kroku** w języku polskim, zgodne z zadaniem. Zawiera gotowe pliki YAML, instrukcje konfiguracji środowisk w repozytorium oraz checklistę.

---

## 1) Plik workflow i nazwa

**Ścieżka:** `.github/workflows/16-environments.yaml`  
**Nazwa workflow:** `16 – Working with Environments`

Utwórz katalog i plik:
```bash
mkdir -p .github/workflows
$EDITOR .github/workflows/16-environments.yaml
```

---

## 2) Wersja 1 — wejście `target-env` (typ: environment) + `run-name`

Skopiuj poniższy YAML do `.github/workflows/16-environments.yaml`:

```yaml
name: 16 – Working with Environments

on:
  workflow_dispatch:
    inputs:
      target-env:
        type: environment
        description: Wybór środowiska
        default: staging

run-name: 16 – Working with Environments | env – ${{ inputs['target-env'] }}

jobs:
  echo:
    name: Echo for ${{ inputs['target-env'] }}
    runs-on: ubuntu-latest
    environment: ${{ inputs['target-env'] }}
    env:
      my-env-value: ${{ vars.MY_ENV_VALUE || 'default value' }}

    steps:
      - name: Echo vars
        run: echo "Env variable: ${{ env.my-env-value }}"
```

**Co robi ta wersja?**
- `workflow_dispatch` z wejściem `target-env` typu **environment** (domyślnie `staging`).  
- `run-name` nadaje nazwę przebiegowi z wstrzykniętą wartością środowiska.  
- Job `echo`:
  - uruchamia się na `ubuntu-latest`,  
  - ma ustawiony `environment` na wartość wejściową,  
  - ustawia zmienną `my-env-value` na `vars.MY_ENV_VALUE`, a gdy jej brak — używa `'default value'`,  
  - wypisuje: `Env variable: …`.

> Uwaga: klucz `my-env-value` w `env` jest odczytywany przez wstrzyknięcie wyrażenia **przed** wykonaniem kroku, więc zapisy z myślnikami zadziałają w `${{ env.my-env-value }}`.

---

## 3) Utworzenie środowisk: `prod` i `staging`

1. **`prod`**  
   - Wejdź w **Settings → Environments → New Environment**.  
   - Nazwa: `prod`.  
   - Włącz **Required reviewers** i dodaj siebie.  
   - Włącz **Wait timer** i ustaw **1 minutę**.  
   - Dodaj zmienną środowiskową **`MY_ENV_VALUE` = `prod value`**.

2. **`staging`**  
   - **Settings → Environments → New Environment** → nazwa: `staging`.  
   - Bez dodatkowych zabezpieczeń/konfiguracji.

---

## 4) Commit, push i uruchomienie ręczne

```bash
git add .github/workflows/16-environments.yaml
git commit -m "CW21: Wersja 1 – run-name + input target-env (type: environment)"
git push
```

W GitHubie: **Actions → 16 – Working with Environments → Run workflow**.  
Wybierz `staging` lub `prod` i uruchom. Sprawdź log kroku **Echo vars** — dla `prod` powinieneś zobaczyć `prod value` (po akceptacji i odczekaniu timera), a dla `staging` — wartość z `vars` jeśli ustawiona globalnie dla środowiska, w przeciwnym razie `'default value'`.

---

## 5) Wersja 2 — pipeline: deploy staging → E2E → deploy prod (z ochroną środowiska)

Zastąp zawartość `.github/workflows/16-environments.yaml` poniższym YAML-em:

```yaml
name: 16 – Working with Environments

on:
  workflow_dispatch:

jobs:
  deploy-staging:
    name: Deploy to staging
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - name: Echo vars
        run: echo "Deploying to staging"

  e2e-tests:
    name: E2E
    runs-on: ubuntu-latest
    needs: [deploy-staging]
    steps:
      - name: E2E tests
        run: echo "Running E2E"

  deploy-prod:
    name: Deploy to prod
    runs-on: ubuntu-latest
    needs: [e2e-tests]
    environment: prod
    env:
      my-env-value: ${{ vars.MY_ENV_VALUE }}
    steps:
      - name: Echo vars
        run: echo "Deploying to prod"
```

**Co tu się dzieje?**
- `deploy-staging` uruchamia się bez zabezpieczeń (środowisko `staging`).  
- `e2e-tests` odpala się **po** stagingu (`needs`).  
- `deploy-prod` odpala się **po** testach E2E i jest związany z `prod`, więc w repo prywatnym z ochroną środowiska:
  - **zatrzyma się** na bramce **„Review deployments”**,  
  - odczeka skonfigurowany **Wait timer** (1 minuta),  
  - wymaga **akceptacji recenzenta** (Ciebie).

---

## 6) Commit, push i uruchomienie Wersji 2

```bash
git add .github/workflows/16-environments.yaml
git commit -m "CW21: Wersja 2 – deploy staging → E2E → deploy prod (environments)"
git push
```

Uruchom ręcznie (Actions → *16 – Working with Environments* → *Run workflow*).  
Obserwuj przebieg: staging → E2E → **prod (oczekuje na zatwierdzenie + timer)**.

---

## 7) Co stanie się z jobem `deploy-prod` i jak go zatwierdzić?

- Po dojściu do `deploy-prod` zobaczysz w widoku przebiegu **baner** / panel **„Review deployments”**.  
- Początkowo będzie wskazany **licznik odliczania** z **Wait timer (1 minuta)**.  
- Po odczekaniu timera (lub równolegle, jeśli UI na to pozwala), jako uprawniony **Required reviewer** kliknij:
  1) **Review deployments** →
  2) Wybierz środowisko `prod` →
  3) **Approve and deploy**.  
- Po akceptacji job `deploy-prod` ruszy dalej i zakończy się sukcesem (o ile nie wystąpi inny błąd).

---

## 8) Przydatne uwagi i pułapki

- **Wejście typu `environment`** w `workflow_dispatch` automatycznie podpowiada istniejące środowiska w UI.  
- **`vars` środowiskowe** są rozdzielone per environment; możesz mieć inne `MY_ENV_VALUE` dla `prod` i `staging`.  
- W wyrażeniach GitHub Actions operator `||` pozwala ustawić **wartość domyślną**, gdy pierwsza jest pusta.  
- Jeśli zmienna ma wrażliwą treść, rozważ **secrets** (np. `secrets.MY_SECRET`) zamiast `vars`.  
- Ochrona środowiska (reviewers, wait timer) działa jako **bramka** — job wstrzymuje się aż do spełnienia warunków.

---

## 9) Checklista końcowa

- [ ] Plik `.github/workflows/16-environments.yaml` utworzony.  
- [ ] Wersja 1: `workflow_dispatch` z inputem `target-env` (environment), `run-name`, job `echo` i echo zmiennej.  
- [ ] Środowiska `prod` i `staging` istnieją; `prod` ma **Required reviewers** i **Wait timer = 1 min**; `prod` ma `vars.MY_ENV_VALUE = "prod value"`.  
- [ ] Wersja 2: pipeline `deploy-staging → e2e-tests → deploy-prod`, z `environment: prod` i `env: my-env-value`.  
- [ ] Uruchomienie ręczne przetestowane; **`deploy-prod` czeka na akceptację**, zatwierdzone w UI przez **Approve and deploy**.

Powodzenia! 🚀
