
# Practical Exercise 05 - Using Filters and Activity Types  
# Ćwiczenie praktyczne 05 – Używanie filtrów i typów aktywności

---

## **English Version**

### Exercise Description

In this practical exercise, our goal is to explore the different ways we can use event filters and activity types to better target when workflows are run.

We will create two workflows for this practical exercise. Here are the instructions for the exercise:

1. **Creating our first workflow:**
   - a. Create a file named `05-1-filters-activity-types.yaml` under the `.github/workflows` folder at the root of your repository.  
   - b. Name the workflow `05 – 1 – Event Filters and Activity Types`.  
   - c. Add the following triggers with event filters and activity types to your workflow:  
     - i. `pull_request`: use activity types to restrict the activities only to `opened` and `synchronize`. Additionally, use event filters to restrict this workflow runs to be triggered only by changes to the `main` branch.  
   d. Add a single job named `echo` to the workflow. The job should contain a single step, which simply prints the following message to the screen:  
      `Running whenever a PR is opened or synchronized AND base branch is main.`  
   - e. Commit the changes and push the code.  
   - f. Edit the `README.md` file at the root of the repository with whatever changes you see fit, and commit the changes to a new branch named `pr-test-1` (on the UI, this option is at the bottom of the window that appears when you want to save the changes).  
   - g. Create a pull request from `pr-test-1` to the main branch and take a few moments to inspect the output of the triggered workflow run.

2. **Creating our second workflow:**
   - a. Create a file named `05-2-filters-activity-types.yaml` under the `.github/workflows` folder at the root of your repository.  
   - b. Name the workflow `05 – 2 – Event Filters and Activity Types`.  
   - c. Add the following triggers with event filters and activity types to your workflow:  
     - i. `pull_request`: use activity types to restrict the activities only to `closed`. Additionally, use event filters to restrict this workflow runs to be triggered only by changes to the `main` branch.  
   - d. Add a single job named `echo` to the workflow. The job should contain a single step, which simply prints the following message to the screen:  
      `Running whenever a PR is closed.`  
   - e. Commit the changes and push the code.  
   - f. Close the PR opened in step 1 of this practical exercise and take a few moments to inspect the output of the triggered workflow run.

3. **Change the workflow triggers** to contain only `workflow_dispatch` to prevent this workflow from running with every push and pollute the list of workflow runs.

---

## **Wersja polska**

### Opis ćwiczenia

W tym ćwiczeniu praktycznym naszym celem jest zbadanie różnych sposobów, w jakie możemy używać filtrów zdarzeń i typów aktywności, aby lepiej kontrolować momenty uruchamiania workflow.

W ramach tego ćwiczenia utworzymy dwa różne workflow. Oto instrukcje:

1. **Tworzenie pierwszego workflow:**
   - a. Utwórz plik o nazwie `05-1-filters-activity-types.yaml` w folderze `.github/workflows` w katalogu głównym repozytorium.  
   - b. Nazwij workflow `05 – 1 – Event Filters and Activity Types`.  
   - c. Dodaj następujące wyzwalacze z filtrami zdarzeń i typami aktywności:  
     - i. `pull_request`: użyj typów aktywności, aby ograniczyć działania tylko do `opened` i `synchronize`. Dodatkowo użyj filtrów zdarzeń, aby uruchamiać workflow tylko w przypadku zmian w gałęzi `main`.  
   - d. Dodaj jedno zadanie o nazwie `echo` do workflow. Zadanie powinno zawierać jeden krok, który wyświetla komunikat:  
      `Running whenever a PR is opened or synchronized AND base branch is main.`  
   - e. Zatwierdź zmiany i wypchnij kod do repozytorium.  
   - f. Edytuj plik `README.md` znajdujący się w katalogu głównym repozytorium – wprowadź dowolne zmiany, a następnie zatwierdź je do nowej gałęzi o nazwie `pr-test-1` (w interfejsie użytkownika opcja ta znajduje się na dole okna, które pojawia się podczas zapisu zmian).  
   - g. Utwórz pull request z gałęzi `pr-test-1` do gałęzi `main` i poświęć chwilę, aby sprawdzić wynik działania uruchomionego workflow.

2. **Tworzenie drugiego workflow:**
   - a. Utwórz plik o nazwie `05-2-filters-activity-types.yaml` w folderze `.github/workflows` w katalogu głównym repozytorium.  
   - b. Nazwij workflow `05 – 2 – Event Filters and Activity Types`.  
   - c. Dodaj następujące wyzwalacze z filtrami zdarzeń i typami aktywności:  
     - i. `pull_request`: użyj typów aktywności, aby ograniczyć działania tylko do `closed`. Dodatkowo użyj filtrów zdarzeń, aby workflow uruchamiał się tylko w przypadku zmian w gałęzi `main`.  
   - d. Dodaj jedno zadanie o nazwie `echo` do workflow. Zadanie powinno zawierać jeden krok, który wyświetla komunikat:  
      `Running whenever a PR is closed.`  
   - e. Zatwierdź zmiany i wypchnij kod do repozytorium.  
   - f. Zamknij pull request utworzony w kroku 1 tego ćwiczenia i poświęć chwilę, aby sprawdzić wynik działania workflow.

3. **Zmień wyzwalacze workflow**, aby pozostał tylko `workflow_dispatch`, co zapobiegnie uruchamianiu workflow przy każdym pushu i zredukuje liczbę uruchomień.

---
