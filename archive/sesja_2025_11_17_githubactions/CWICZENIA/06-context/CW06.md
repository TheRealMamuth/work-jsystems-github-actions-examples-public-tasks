
# Practical Exercise 06 - Working with Different Contexts  
# Ćwiczenie praktyczne 06 – Praca z różnymi kontekstami

---

## **English Version**

### Exercise Description

In this practical exercise, our goal is to work with different contexts available during workflow runs.

Here are the instructions for the exercise:

1. **Creating the first version of the workflow:**
   - a. Create a file named `06-contexts.yaml` under the `.github/workflows` folder in the root of your repository.  
   - b. Name the workflow `06 – Contexts`.  
   - c. Add the following triggers to your workflow:  
     - i. `push`  
     - ii. `workflow_dispatch`  
   - d. Add a single job to the workflow. The job, named `echo-data`, should run on `ubuntu-latest` and contain two steps:  
     - i. The first step, named **Display Information**, should print the following lines containing information from the `github` context (tip: use a multi-line script with several `echo` commands):  
       - i. `"Event name: <retrieve the event name here>"`  
       - ii. `"Ref: <retrieve the ref here>"`  
       - iii. `"SHA: <retrieve the commit sha here>"`  
       - iv. `"Actor: <retrieve the actor name here>"`  
       - v. `"Workflow: <retrieve the workflow name here>"`  
       - vi. `"Run ID: <retrieve the run ID here>"`  
       - vii. `"Run number: <retrieve the run number here>"`  
     - ii. The second step, named **Retrieve Variable**, should print a single line containing the value of a repository variable named `MY_VAR`.  
   - e. Create a repository variable named `MY_VAR`. Check the **Tips** section below for the step-by-step of how to create repository variables. Set the value of this variable to `hello world`.  
   - f. Commit the changes and push the code. Take some time to inspect the output of the workflow run.

2. **Extending the workflow with invalid contexts:**  
   - a. Now add a new configuration key named `run-name` to the workflow. This is defined at the top-level, as a sibling to the `name` and `on` keys. The run-name allows you to define the name of the workflow run that appears on the UI.  
   - b. Set the value of `run-name` to `My custom workflow run name – ${{ runner.os }}`  
   - c. Commit the changes and push the code. Take some time to inspect the output of the workflow run. Which error message appeared?

3. **Fixing invalid contexts and extending the workflow with inputs:**  
   - a. Replace the `run-name` with `06 – Contexts | DEBUG – ${{ inputs.debug }}`  
   - b. Add an input to the `workflow_dispatch` trigger. The input should be named `debug`, have a `boolean` type, and have a default value of `false`. If you are not sure how to do it, check the **Tips** section below for the step-by-step of how to define inputs for the `workflow_dispatch` trigger.  
   - c. Commit the changes and push the code. Take some time to inspect the output of the workflow run triggered by the push event trigger. Which value was populated for the `debug` input?  
   - d. Now trigger the workflow from the UI and try it with different variations for the `debug` input. How does this impact the result of the workflow runs?

4. **Extending the workflow with the `env` context:**  
   - a. Add a top-level `env` key to define two environment variables:  
     - i. `MY_WORKFLOW_VAR`, with the value set to `'workflow'`  
     - ii. `MY_OVERWRITTEN_VAR`, with the value set to `'workflow'`  
   - b. Under the `echo-data` job, add an `env` key to define two environment variables:  
     - i. `MY_JOB_VAR`, with the value set to `'job'`  
     - ii. `MY_OVERWRITTEN_VAR`, with the value set to `'job'`  
   - c. Add an additional step after the **Retrieve Variable** step, and name it **Print Env Variables**.  
   - d. Under the **Print Env Variables**, add an `env` key to define a single environment variable:  
     - i. `MY_OVERWRITTEN_VAR`, with the value set to `'step'`  
   - e. Execute a multi-line script to print the following information on the screen:  
     - i. `"Workflow env: <retrieve the value of the MY_WORKFLOW_VAR env variable here>"`  
     - ii. `"Overwritten env: <retrieve the value of the MY_OVERWRITTEN_VAR env variable here>"`  
   - f. Add yet another step after the first Print Env Variables. You can name the step similarly to the previous one. Do not define any additional env variables.  
   - g. Execute a multi-line script to print the following information on the screen:  
     - i. `"Workflow env: <retrieve the value of the MY_WORKFLOW_VAR env variable here>"`  
     - ii. `"Overwritten env: <retrieve the value of the MY_OVERWRITTEN_VAR env variable here>"`  
   - h. Commit the changes and push the code. Take some time to inspect the output of the workflow run. How were the `env` variables overwritten regarding the workflow, job, and step hierarchy?

5. **After exploring the different ways to trigger a workflow, reduce the list of triggers to leave only `workflow_dispatch`** to prevent this workflow from running with every push and pollute the list of workflow runs.

---

### Tips

#### Creating repository variables

To create repository variables, follow these steps:

1. In the repository page, click on **Settings** at the right top side of the screen.  
2. Scroll down and expand the **Secrets and variables** section on the left-side menu. Click on **Actions**, and then click on **Variables** on the tabs visible under the description text.  
3. Scroll down and click on the **New repository variable** button.

#### Defining inputs for the workflow_dispatch trigger

We discuss inputs and outputs in detail at **Section 12 – Inputs and Outputs**, but we can already define some inputs for the workflow_dispatch trigger. The syntax is as follows:

```yaml
on:
  workflow_dispatch:
    inputs:
      debug:
        type: boolean
        default: false
```

This will add a checkbox to our UI pop up when triggering the workflow.

---

## **Wersja polska**

### Opis ćwiczenia

W tym ćwiczeniu praktycznym naszym celem jest praca z różnymi kontekstami dostępnymi podczas działania workflow.

Oto instrukcje do wykonania ćwiczenia:

1. **Tworzenie pierwszej wersji workflow:**
   - a. Utwórz plik o nazwie `06-contexts.yaml` w folderze `.github/workflows` w katalogu głównym repozytorium.  
   - b. Nazwij workflow `06 – Contexts`.  
   - c. Dodaj następujące wyzwalacze:  
     - i. `push`  
     - ii. `workflow_dispatch`  
   - d. Dodaj jedno zadanie o nazwie `echo-data`, które będzie uruchamiane na `ubuntu-latest` i zawierać dwa kroki:  
     - i. Pierwszy krok, **Display Information**, powinien wyświetlać informacje z kontekstu `github` (użyj skryptu wieloliniowego z kilkoma poleceniami `echo`):  
       -  i. `"Event name: <pobierz nazwę zdarzenia>"`  
       -  ii. `"Ref: <pobierz odniesienie>"`  
       -  iii. `"SHA: <pobierz sha commita>"`  
       -  iv. `"Actor: <pobierz nazwę aktora>"`  
       -  v. `"Workflow: <pobierz nazwę workflow>"`  
       -  vi. `"Run ID: <pobierz ID uruchomienia>"`  
       -  vii. `"Run number: <pobierz numer uruchomienia>"`  
     - ii. Drugi krok, **Retrieve Variable**, powinien wyświetlać wartość zmiennej repozytorium o nazwie `MY_VAR`.  
   - e. Utwórz zmienną repozytorium o nazwie `MY_VAR`. Sprawdź sekcję **Wskazówki** poniżej, aby zobaczyć krok po kroku, jak tworzyć zmienne repozytorium. Ustaw wartość tej zmiennej na `hello world`.  
   - f. Zatwierdź zmiany i wypchnij kod. Sprawdź wynik działania workflow.

2. **Rozszerzenie workflow o nieprawidłowe konteksty:**  
   - a. Dodaj nowy klucz konfiguracji `run-name` do workflow. Zdefiniuj go na najwyższym poziomie, równolegle do `name` i `on`. Pozwala on określić nazwę uruchomienia workflow, która będzie widoczna w interfejsie.  
   - b. Ustaw wartość `run-name` na `My custom workflow run name – ${{ runner.os }}`  
   - c. Zatwierdź zmiany i wypchnij kod. Sprawdź wynik działania workflow. Jaki komunikat błędu się pojawił?

3. **Naprawa błędnych kontekstów i rozszerzenie workflow o wejścia:**  
   - a. Zastąp `run-name` wartością `06 – Contexts | DEBUG – ${{ inputs.debug }}`  
   - b. Dodaj wejście (`input`) do wyzwalacza `workflow_dispatch`. Wejście powinno nazywać się `debug`, mieć typ `boolean` i domyślną wartość `false`. Jeśli nie wiesz, jak to zrobić, zajrzyj do sekcji **Wskazówki** poniżej.  
   - c. Zatwierdź zmiany i wypchnij kod. Sprawdź wynik działania workflow wywołanego przez zdarzenie `push`. Jaka wartość została przypisana do `debug`?  
   - d. Uruchom workflow z interfejsu użytkownika, testując różne warianty parametru `debug`. Jak wpływa to na wynik działania workflow?

4. **Rozszerzenie workflow o kontekst `env`:**  
   - a. Dodaj klucz `env` na najwyższym poziomie, aby zdefiniować dwie zmienne środowiskowe:  
     - i. `MY_WORKFLOW_VAR` o wartości `'workflow'`  
     - ii. `MY_OVERWRITTEN_VAR` o wartości `'workflow'`  
   - b. W zadaniu `echo-data` dodaj klucz `env` definiujący dwie zmienne:  
     - i. `MY_JOB_VAR` o wartości `'job'`  
     - ii. `MY_OVERWRITTEN_VAR` o wartości `'job'`  
   - c. Dodaj krok po **Retrieve Variable** o nazwie **Print Env Variables**.  
   - d. Pod **Print Env Variables** dodaj `env` definiujący jedną zmienną:  
     - i. `MY_OVERWRITTEN_VAR` o wartości `'step'`  
   - e. Uruchom skrypt wieloliniowy, który wyświetli:  
     - i. `"Workflow env: <pobierz wartość MY_WORKFLOW_VAR>"`  
     - ii. `"Overwritten env: <pobierz wartość MY_OVERWRITTEN_VAR>"`  
   - f. Dodaj kolejny krok po poprzednim, nazwany podobnie. Nie definiuj dodatkowych zmiennych środowiskowych.  
   - g. Uruchom skrypt wieloliniowy wyświetlający te same informacje.  
   - h. Zatwierdź i wypchnij zmiany. Sprawdź, jak zmienne `env` zostały nadpisane w kontekście workflow, job i step.

5. **Po przetestowaniu różnych sposobów uruchamiania workflow**, usuń wszystkie wyzwalacze oprócz `workflow_dispatch`, aby zapobiec automatycznemu uruchamianiu workflow przy każdym pushu.

---

### Wskazówki

#### Tworzenie zmiennych repozytorium

1. W repozytorium kliknij **Settings** w prawym górnym rogu.  
2. Przewiń w dół, rozwiń sekcję **Secrets and variables**, kliknij **Actions**, a następnie **Variables**.  
3. Kliknij przycisk **New repository variable**.

#### Definiowanie wejść dla `workflow_dispatch`

Składnia definiowania wejść wygląda tak:

```yaml
on:
  workflow_dispatch:
    inputs:
      debug:
        type: boolean
        default: false
```

To dodaje checkbox w interfejsie użytkownika podczas uruchamiania workflow.
