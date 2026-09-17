
# Practical Exercise 02 - Using Different Events to Trigger Workflows / Ćwiczenie praktyczne 02 – Używanie różnych zdarzeń do uruchamiania workflow

---

## **English Version**

### Exercise Description

In this practical exercise, our goal is to explore the different ways we can trigger workflows in GitHub Actions.

Here are the instructions for the exercise:

1. **Create a file named** `02-workflow-events.yaml` under the `.github/workflows` folder in the root of your repository.

2. **Name the workflow:** `02 – Workflow Events`.

3. **Add the following trigger to your workflow:**  
   - a. `push`

4. **Add a single job to the workflow:**  
   - a. The job, named `echo`, should run on `ubuntu-latest` and contain a single step named **Show the trigger**, which prints the name of the event that triggered the workflow.

5. **Commit the changes and push the code.**  
   Take some time to inspect the output of the workflow run.

6. **Now add more triggers to the workflow:**  
   - a. `pull_request`  
   - b. `schedule` (using a cron expression)  
   - c. `workflow_dispatch`

7. **Commit the changes and push the code.**  
   Observe the different ways the workflow can be triggered.

   - a. You can create a **pull request** to see how that trigger behaves.  
   - b. You can also try triggering it manually from the **GitHub UI**:
      - i. Click on the **“Actions”** tab on the repository’s main page.  
      - ii. Select the workflow named `02 – Workflow Events` from the sidebar.  
      - iii. Click **“Run workflow”** on the right, next to “This workflow has a workflow_dispatch event trigger.”

8. **After testing different triggers**, reduce the list of triggers to only include `workflow_dispatch` to prevent the workflow from running automatically on every push.

---

### Tips

#### Using a valid cron syntax

At the time of this exercise, GitHub Actions does **not** support cron expressions with six elements (e.g., `'0 0 * * * *'`). It only supports five-element definitions.

A valid syntax looks like this:

```yaml
on:
  schedule:
    - cron: '0 0 * * *'
```

#### Accessing the name of the event that triggered the workflow

You can print the name of the triggering event using this syntax:

```yaml
steps:
  - name: Event name
    run: |
      echo "Event name: ${{ github.event_name }}"
```

The `${{ github.event_name }}` variable retrieves the event type (e.g., `push`, `pull_request`, `schedule`, etc.).

---

## **Wersja polska**

### Opis ćwiczenia

W tym ćwiczeniu naszym celem jest poznanie różnych sposobów uruchamiania workflow w GitHub Actions.

Instrukcje do ćwiczenia:

1. **Utwórz plik o nazwie** `02-workflow-events.yaml` w folderze `.github/workflows` w katalogu głównym repozytorium.

2. **Nazwij workflow:** `02 – Workflow Events`.

3. **Dodaj następujący wyzwalacz:**  
   - a. `push`

4. **Dodaj jedno zadanie (job):**  
   - a. Zadanie o nazwie `echo` powinno działać na `ubuntu-latest` i zawierać jeden krok **Show the trigger**, który wyświetla nazwę zdarzenia, które uruchomiło workflow.

5. **Zatwierdź zmiany i wypchnij kod.**  
   Sprawdź wynik działania workflow.

6. **Dodaj więcej wyzwalaczy:**  
   - a. `pull_request`  
   - b. `schedule` (z użyciem wyrażenia cron)  
   - c. `workflow_dispatch`

7. **Zatwierdź i wypchnij kod.**  
   Obserwuj różne sposoby uruchamiania workflow.

   - a. Utwórz **pull request**, aby zobaczyć, jak działa ten wyzwalacz.  
   - b. Spróbuj uruchomić workflow ręcznie z poziomu **GitHub UI**:
      - i. Kliknij zakładkę **“Actions”** w repozytorium.  
      - ii. Wybierz workflow o nazwie `02 – Workflow Events`.  
      - iii. Kliknij **“Run workflow”**, obok napisu „This workflow has a workflow_dispatch event trigger.”

8. **Po przetestowaniu różnych wyzwalaczy**, pozostaw tylko `workflow_dispatch`, aby workflow nie uruchamiał się automatycznie przy każdym pushu.

---

### Wskazówki

#### Poprawna składnia cron

GitHub Actions nie obsługuje składni cron z sześcioma elementami (np. `'0 0 * * * *'`).  
Prawidłowy przykład:

```yaml
on:
  schedule:
    - cron: '0 0 * * *'
```

#### Wyświetlanie nazwy zdarzenia, które uruchomiło workflow

Aby wyświetlić nazwę zdarzenia, użyj następującej składni:

```yaml
steps:
  - name: Event name
    run: |
      echo "Event name: ${{ github.event_name }}"
```

Zmienna `${{ github.event_name }}` zwraca typ zdarzenia (np. `push`, `pull_request`, `schedule` itp.).
