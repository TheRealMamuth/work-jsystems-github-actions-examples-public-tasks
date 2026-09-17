
# Practical Exercise 04 - Working with Third-Party Custom Actions  
# Ćwiczenie praktyczne 04 – Praca z niestandardowymi akcjami firm trzecich

---

## **English Version**

### Exercise Description

In this practical exercise, our goal is to explore how we can use third-party custom actions to perform tasks without having to define them from scratch.

To achieve that, we will leverage a React application that we will scaffold with the help of the **create-react-app** utility. Check the tips section for the specific command to scaffold your React application.

Here are the instructions for the exercise:

1. **Generate a React application:**  
   - a. Create a new folder named `04-using-actions` at the root of the repository.  
   - b. Using a terminal, `cd` into this directory and scaffold a React application inside a `react-app` directory. You can either create the directory yourself or let the `create-react-app` utility do it for you.  
   - c. Once the React setup is done, you should see a success message.  
   - d. Take a few moments to inspect the files and get familiar with the application folder structure.

2. **Create the first version of the workflow:**  
   - a. Create a file named `04-using-actions.yaml` under the `.github/workflows` folder at the root of your repository.  
   - b. Name the workflow **04 – Using Actions**.  
   - c. Add the following triggers to your workflow:  
      i. `push`  
   - d. Add a single job named `build` to the workflow. The job should contain two steps:  
      - i. The first one, named **Checkout Code**, should checkout the repository code into the current working directory.  
      - ii. The second one, named **Printing Folders**, should simply print the folder structure after the checkout command.  
   - e. Commit the changes and push the code.  
   - f. Take a few moments to inspect the output of the workflow run.

3. **Extend the workflow to setup Node and install the dependencies of the React application:**  
   - a. Remove the **Printing Folders** step.  
   - b. Add a new step after the **Checkout Code** step. This new step should be named **Setup Node** and setup Node using the `20.x` version.  
   - c. Add a new step after the **Setup Node** step. This new step should be named **Install Dependencies** and install the dependencies of our React application by running the `npm ci` command inside the React application folder.  
      You can either `cd` into the directory before running the command or pass the working directory by adding:  
      `working-directory: 04-using-actions/react-app`.  
   - d. Commit the changes and push the code.  
   - e. Take a few moments to inspect the output of the workflow run.

4. **Extend the workflow to execute the automated tests from the React application:**  
   a. Add a new step after the **Install Dependencies** step. This new step should be named **Run Unit Tests** and it should execute the automated tests by running the `npm run test` command inside the React application folder.  
      You can either `cd` into the directory before running the command or use the `working-directory: 04-using-actions/react-app` option.  
   - b. Commit the changes and push the code.  
   - c. Take a few moments to inspect the output of the workflow run.

5. **Change the workflow triggers** to contain only `workflow_dispatch` to prevent this workflow from running with every push and polluting the list of workflow runs.

---

### Tips

#### Scaffolding a React application with create-react-app

To generate a React application with a single command, run the following inside the `04-using-actions` folder:  
```bash
npx create-react-app --template typescript react-app
```

#### Using third-party actions in GitHub Actions Workflows

The syntax to leverage a third-party action is very simple. Instead of using the `run` key and defining a shell script, use the `uses` key and pass the name and version of the action you wish to use. Example:

```yaml
steps:
  - name: Using the Checkout Action
    uses: actions/checkout@v4
```

#### Useful third-party actions for this exercise

1. **actions/checkout@v4** – used to checkout the repository code into the working directory of the workflow run. Without this, we cannot work with the repository code.  
2. **actions/setup-node@v4** – used to setup Node with a specific version, as well as any other necessary dependencies. Example:

```yaml
steps:
  - name: Setup Node
    uses: actions/setup-node@v4
    with:
      node-version: '20.x'
```

---

## **Wersja polska**

### Opis ćwiczenia

W tym ćwiczeniu naszym celem jest zbadanie, jak można korzystać z niestandardowych akcji firm trzecich, aby wykonywać zadania bez konieczności ich definiowania od podstaw.

Aby to osiągnąć, wykorzystamy aplikację React, którą utworzymy przy pomocy narzędzia **create-react-app**. W sekcji „Wskazówki” znajdziesz konkretne polecenie do stworzenia aplikacji React.

Oto instrukcje do ćwiczenia:

1. **Utwórz aplikację React:**  
   - a. Utwórz nowy folder o nazwie `04-using-actions` w katalogu głównym repozytorium.  
   - b. W terminalu przejdź do tego katalogu (`cd`) i utwórz aplikację React wewnątrz folderu `react-app`. Możesz utworzyć katalog samodzielnie lub pozwolić, aby narzędzie `create-react-app` zrobiło to za Ciebie.  
   - c. Po zakończeniu konfiguracji powinien pojawić się komunikat o powodzeniu.  
   - d. Poświęć chwilę, aby zapoznać się ze strukturą plików aplikacji.

2. **Utwórz pierwszą wersję workflow:**  
   - a. Utwórz plik `04-using-actions.yaml` w folderze `.github/workflows`.  
   - b. Nazwij workflow **04 – Using Actions**.  
   - c. Dodaj następujący wyzwalacz:  
      i. `push`  
   - d. Dodaj jedno zadanie o nazwie `build`, które powinno zawierać dwa kroki:  
      i. Pierwszy, o nazwie **Checkout Code**, ma pobrać kod repozytorium do bieżącego katalogu roboczego.  
      ii. Drugi, o nazwie **Printing Folders**, ma wyświetlić strukturę folderów po wykonaniu pobrania kodu.  
   - e. Zatwierdź i wypchnij zmiany do repozytorium.  
   - f. Sprawdź wynik działania workflow.

3. **Rozszerz workflow o instalację Node i zależności aplikacji React:**  
   - a. Usuń krok **Printing Folders**.  
   - b. Dodaj nowy krok po **Checkout Code** o nazwie **Setup Node**, który ustawia Node w wersji `20.x`.  
   - c. Dodaj kolejny krok po **Setup Node** o nazwie **Install Dependencies**, który instaluje zależności aplikacji React, uruchamiając polecenie `npm ci` w katalogu aplikacji (`04-using-actions/react-app`).  
   - d. Zatwierdź i wypchnij zmiany.  
   - e. Sprawdź wynik działania workflow.

4. **Rozszerz workflow o uruchamianie testów automatycznych:**  
   - a. Dodaj krok po **Install Dependencies** o nazwie **Run Unit Tests**, który uruchamia testy automatyczne przy użyciu polecenia `npm run test` w katalogu aplikacji React.  
   - b. Zatwierdź i wypchnij zmiany.  
   - c. Przeanalizuj wynik działania workflow.

5. **Zmień wyzwalacze workflow**, aby pozostał tylko `workflow_dispatch`, dzięki czemu workflow nie będzie uruchamiany przy każdym `push`.

---

### Wskazówki

#### Tworzenie aplikacji React za pomocą create-react-app

Aby utworzyć aplikację React jednym poleceniem, uruchom w folderze `04-using-actions`:  
```bash
npx create-react-app --template typescript react-app
```

#### Używanie akcji firm trzecich w GitHub Actions

Aby skorzystać z akcji firm trzecich, zamiast pisać własny skrypt w sekcji `run`, użyj klucza `uses` i określ nazwę oraz wersję akcji. Przykład:

```yaml
steps:
  - name: Using the Checkout Action
    uses: actions/checkout@v4
```

#### Przydatne akcje firm trzecich dla tego ćwiczenia

1. **actions/checkout@v4** – pobiera kod repozytorium do katalogu roboczego workflow.  
2. **actions/setup-node@v4** – instaluje Node.js w określonej wersji oraz wymagane zależności. Przykład:

```yaml
steps:
  - name: Setup Node
    uses: actions/setup-node@v4
    with:
      node-version: '20.x'
```
