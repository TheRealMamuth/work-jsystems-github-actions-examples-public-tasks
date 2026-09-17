
# Rozwiązanie: Ćwiczenie 31 — Tworzenie i używanie **Reusable Workflows** (GitHub Actions)

Poniżej masz kompletne rozwiązanie **krok po kroku** (po polsku) z gotowymi plikami YAML, komendami i checklistą.  
Źródło zadania: fileciteturn15file0

---

## 1) Utwórz reusable workflow: `18-1-reusable-workflows.yaml`

**Ścieżka:** `.github/workflows/18-1-reusable-workflows.yaml`  
**Nazwa:** `18 – 1 – Reusable Workflows – Reusable Definition`

Skopiuj poniższy YAML:

```yaml
name: 18 – 1 – Reusable Workflows – Reusable Definition

on:
  workflow_call:
    inputs:
      target-directory:
        description: Directory to use in the build step
        required: true
        type: string
    outputs:
      build-status:
        description: The status of the build process
        value: ${{ jobs.deploy.outputs.build-status }}
      url:
        description: The url of the deployed version
        value: ${{ jobs.deploy.outputs.url }}

jobs:
  deploy:
    runs-on: ubuntu-latest
    outputs:
      build-status: ${{ steps.build.outputs.build-status }}
      url: ${{ steps.deploy.outputs.url }}

    steps:
      - name: Checkout repo
        uses: actions/checkout@v4

      - name: Build
        id: build
        shell: bash
        run: |
          echo "Building using directory ${{ inputs['target-directory'] }}"
          echo "build-status=success" >> "$GITHUB_OUTPUT"

      - name: Deploy
        id: deploy
        shell: bash
        run: |
          echo "Deploying build artifacts"
          echo "url=https://www.google.com" >> "$GITHUB_OUTPUT"
```

**Wyjaśnienia najważniejszych elementów:**
- `on.workflow_call.inputs` — przyjmuje **wymagane** wejście `target-directory` (string).
- `on.workflow_call.outputs` — eksportuje dwa wyjścia mapując je na outputy joba `deploy`.
- J’ob `deploy` definiuje **outputs** na podstawie outputów kroków `build` i `deploy` (kroków!).
- W krokach używamy **pliku specjalnego** `$GITHUB_OUTPUT`, aby ustawić outputy `build-status` i `url`.

---

## 2) Utwórz workflow wywołujący reusable: `18-2-reusable-workflow.yaml`

**Ścieżka:** `.github/workflows/18-2-reusable-workflow.yaml`  
**Nazwa:** `18 – 2 – Reusable Workflows`

Skopiuj poniższy YAML:

```yaml
name: 18 – 2 – Reusable Workflows

on:
  workflow_dispatch:

jobs:
  deploy:
    uses: ./.github/workflows/18-1-reusable-workflows.yaml
    with:
      target-directory: apps/web   # ← przekaż dowolną wartość (np. katalog w repo)

  print-outputs:
    runs-on: ubuntu-latest
    needs: [deploy]
    steps:
      - name: Print outputs
        run: |
          echo "Build status: ${{ needs.deploy.outputs.build-status }}"
          echo "URL: ${{ needs.deploy.outputs.url }}"
```

**Co tu się dzieje?**
- Job **`deploy`** na poziomie workflow **używa** definicji z poprzedniego pliku (`uses: ./.github/workflows/18-1-reusable-workflows.yaml`).  
- W `with:` przekazujemy wartość **`target-directory`**.  
- Job **`print-outputs`** zależy od `deploy` i odczytuje jego outputy przez `needs.deploy.outputs.*`.

---

## 3) Commit i push

```bash
git add .github/workflows/18-1-reusable-workflows.yaml         .github/workflows/18-2-reusable-workflow.yaml
git commit -m "CW31: reusable workflow + workflow wywołujący"
git push
```

---

## 4) Ręczne uruchomienie i weryfikacja

1. Przejdź w GitHub UI do **Actions → 18 – 2 – Reusable Workflows → Run workflow**.  
2. Po zakończeniu biegu sprawdź logi:
   - w jobie **deploy** powinien pojawić się komunikat z kroku *Build* z katalogiem z wejścia,
   - w jobie **print-outputs** powinny wydrukować się:  
     - `Build status: success`  
     - `URL: https://www.google.com`

---

## 5) Checklista końcowa

- [ ] `18-1-reusable-workflows.yaml` istnieje i posiada `workflow_call` z wejściem `target-directory` oraz wyjściami `build-status`, `url`.  
- [ ] J’ob `deploy` ustawia outputy na podstawie kroków `build` i `deploy`.  
- [ ] Kroki używają `$GITHUB_OUTPUT` do ustawiania `build-status=success` oraz `url=https://www.google.com`.  
- [ ] `18-2-reusable-workflow.yaml` wywołuje definicję z `uses: ./.github/workflows/18-1-reusable-workflows.yaml` i przekazuje `target-directory`.  
- [ ] Job `print-outputs` odczytuje wartości `needs.deploy.outputs.build-status` i `needs.deploy.outputs.url`.  
- [ ] Test przebiegł poprawnie po ręcznym uruchomieniu workflowu.
