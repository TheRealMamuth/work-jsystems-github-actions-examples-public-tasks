
# Practical Exercise 03 - Working with Windows and Ubuntu Runners / Ćwiczenie praktyczne 03 – Praca z runnerami Windows i Ubuntu

---

## **English Version**

### Exercise Description

In this practical exercise, our goal is to explore different possibilities for setting runners for our workflows.

Here are the instructions for the exercise:

1. **Create a file named** `03-workflow-runners.yaml` under the `.github/workflows` folder in the root of your repository.

2. **Name the workflow:** `03 – Workflow Runners`.

3. **Add the following trigger to your workflow:**
   - a. `push`

4. **Add three jobs to the workflow:**
   - a. The first job, `ubuntu-echo`, should run on `ubuntu-latest` and have a single step named **Show OS**, which runs a multi-line bash script printing `"This job is running on an Ubuntu runner."` and then the runner OS on the next line.
   - b. The second job, `windows-echo`, should run on `windows-latest` and have a single step named **Show OS**, which runs a multi-line bash script printing `"This job is running on a Windows runner."` and then the runner OS on the next line.
   - c. The third job, `mac-echo`, should run on `macos-latest` and have a single step named **Show OS**, which runs a multi-line bash script printing `"This job is running on a MacOS runner."` and then the runner OS on the next line.

5. **Change the workflow trigger** to contain only `workflow_dispatch` to prevent this workflow from running with every push and cluttering the workflow list.

---

### Tips

#### Be careful with MacOS runners – they are expensive!

MacOS runners are costly when used in private repositories, as they can quickly consume all the free minutes available for your GitHub plan. Use them carefully if you are working in a private repository.

#### How to access the runner OS

The runner OS is available through an environment variable named `$RUNNER_OS`.

#### Accessing environment variables in Windows

Windows’ default shell is **not** compatible with bash-like syntax for environment variables.  
To use bash syntax, explicitly set the shell in your step, as shown below:

```yaml
steps:
  - name: Show OS
    shell: bash
    run: echo "I'm running on bash."
```

---

## **Wersja polska**

### Opis ćwiczenia

W tym ćwiczeniu naszym celem jest poznanie różnych możliwości ustawiania runnerów (maszyn wykonawczych) dla workflow.

Instrukcje do ćwiczenia:

1. **Utwórz plik o nazwie** `03-workflow-runners.yaml` w folderze `.github/workflows` w katalogu głównym repozytorium.

2. **Nazwij workflow:** `03 – Workflow Runners`.

3. **Dodaj następujący wyzwalacz:**  
   - a. `push`

4. **Dodaj trzy zadania (jobs):**
   - a. Pierwsze zadanie, `ubuntu-echo`, powinno działać na `ubuntu-latest` i zawierać jeden krok **Show OS**, który uruchamia wieloliniowy skrypt bash wypisujący `"This job is running on an Ubuntu runner."`, a następnie nazwę systemu operacyjnego runnera.
   - b. Drugie zadanie, `windows-echo`, powinno działać na `windows-latest` i zawierać jeden krok **Show OS**, który wypisuje `"This job is running on a Windows runner."`, a następnie nazwę systemu operacyjnego runnera.
   - c. Trzecie zadanie, `mac-echo`, powinno działać na `macos-latest` i zawierać jeden krok **Show OS**, który wypisuje `"This job is running on a MacOS runner."`, a następnie nazwę systemu operacyjnego runnera.

5. **Zmień wyzwalacz workflow**, aby zawierał tylko `workflow_dispatch`, co zapobiegnie uruchamianiu go przy każdym pushu i zanieczyszczaniu listy uruchomień.

---

### Wskazówki

#### Uważaj na MacOS runnerów – są drodzy!

Runnerzy MacOS są kosztowni przy użyciu w prywatnych repozytoriach, ponieważ mogą bardzo szybko zużyć wszystkie darmowe minuty dostępne w planie GitHub. Używaj ich ostrożnie, jeśli pracujesz w prywatnym repozytorium.

#### Jak uzyskać dostęp do systemu operacyjnego runnera

System operacyjny runnera jest dostępny jako zmienna środowiskowa `$RUNNER_OS`.

#### Dostęp do zmiennych środowiskowych w systemie Windows

Domyślna powłoka systemu Windows **nie** jest zgodna ze składnią bash dla zmiennych środowiskowych.  
Aby użyć bash, należy jawnie ustawić powłokę dla kroku, jak pokazano poniżej:

```yaml
steps:
  - name: Show OS
    shell: bash
    run: echo "Działa na bashu."
```
