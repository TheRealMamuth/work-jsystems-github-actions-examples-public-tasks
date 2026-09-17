# Practical Exercise 24 - Setting Up Our JavaScript Custom Action

## English Version

### Exercise Description

In this practical exercise, our goal is to explore how to setup a JavaScript custom action in GitHub Actions.

The goal of our JavaScript custom action is to check for updates in the npm dependencies of a project, and to abstract that behind an easy-to-use reusable action. Here are the instructions for the exercise:

1. Create the folder `.github/actions/js-dependency-update`.  
   This folder is where we will host all the files for our JavaScript custom action.
2. Open a terminal and change into this directory.
3. Initialize an npm project by running the command `npm init -y`.
4. Install the necessary dependencies by running  
   `npm install @actions/core@1.10.1 @actions/exec@1.1.1 @actions/github@6.0.0 --save-exact`.
5. Create a file named `action.yaml` under the folder `.github/actions/js-dependency-update`.
6. In the `action.yaml` file, add the following properties:
   - a. A `name` of `Update NPM Dependencies`;  
   - b. A `description` of `"Checks if there are updates to NPM packages, and creates a PR with the updated package*.json files"`;  
   - c. Add a top-level `runs` key. This is the core of defining our JavaScript custom action. For a JavaScript custom action, the `runs` key has the following shape:
     - i. `runs:`  
     - ii. `using: node20`  
     - iii. `main: index.js`  
      - where:  
        - `using: <Node version>` defines with which version of NodeJS the action will be run.  
        - `main: <JavaScript file>` defines which file will be executed as the entrypoint of our JavaScript custom action.
7. Create an `index.js` file under the folder `.github/actions/js-dependency-update` and add the following code to the file:

```js
const core = require('@actions/core');

async function run() {
  core.info('I am a custom JS action');
}

run();
```
The code above is leveraging the `@actions/core` package to write a line to the output of our custom action. In the next exercise, we will continue the development of the JavaScript code.

8. Create a file named `17-2-custom-actions-js.yaml` under the `.github/workflows` folder at the root of your repository.
9. Name the workflow `17 – 2 – Custom Actions – JS`.
10. Add the following triggers with event filters and activity types to your workflow:  
    - a. `workflow_dispatch`
11. Set the `run-name` option of the workflow to `17 – 2 – Custom Actions – JS`.
12. Add a single job named `dependency-update` to the workflow.  
    - a. It should run on `ubuntu-latest`.  
    - b. It should contain two steps:  
      - i. The first step should checkout the code.  
      - ii. The second step, named `Check for dependency updates`, should use the recently created JS custom action. To reference a custom action created in the same repository as the workflow, you can simply provide the path of the directory where the `action.yaml` file is located. In this case, this would be `./.github/actions/js-dependency-update`.
13. Modify the `.gitignore` file at the root of the repository so that the `node_modules` folder under the `js-dependency-update` folder is **not ignored**. It should be committed if we want our action to work correctly. One way of doing that is to add the following line to the file:  
    `!.github/actions/**/node_modules`.  
    This will make sure that all `node_modules` folders under any subdirectory of the `.github/actions` folder are committed, while still ignoring the `node_modules` directories from other folders.
14. Commit the changes and push the code. Trigger the workflow from the UI and take a few moments to inspect the output of the workflow run.

---

## Wersja Polska

### Opis ćwiczenia

W tym ćwiczeniu praktycznym naszym celem jest poznanie sposobu tworzenia akcji niestandardowej w JavaScript w GitHub Actions.

Celem naszej akcji JavaScript jest sprawdzenie aktualizacji zależności npm w projekcie oraz ukrycie tego za prostą w użyciu, wielokrotnego użytku akcją. Oto instrukcje do ćwiczenia:

1. Utwórz folder `.github/actions/js-dependency-update`.  
   W tym folderze będziemy przechowywać wszystkie pliki naszej akcji JavaScript.
2. Otwórz terminal i przejdź do tego katalogu.
3. Zainicjuj projekt npm, uruchamiając polecenie `npm init -y`.
4. Zainstaluj niezbędne zależności, uruchamiając polecenie  
   `npm install @actions/core@1.10.1 @actions/exec@1.1.1 @actions/github@6.0.0 --save-exact`.
5. Utwórz plik o nazwie `action.yaml` w folderze `.github/actions/js-dependency-update`.
6. W pliku `action.yaml` dodaj następujące właściwości:
   - a. `name` ustaw na `Update NPM Dependencies`;  
   - b. `description` ustaw na `"Checks if there are updates to NPM packages, and creates a PR with the updated package*.json files"`;  
   - c. Dodaj klucz najwyższego poziomu `runs`. To podstawowy element definiujący naszą akcję JavaScript. Dla akcji JavaScript klucz `runs` ma następującą strukturę:  
     - i. `runs:`  
     - ii. `using: node20`  
     - iii. `main: index.js`  
      - gdzie:  
        - `using: <Node version>` definiuje, z jaką wersją NodeJS zostanie uruchomiona akcja.  
        - `main: <JavaScript file>` określa, który plik zostanie wykonany jako punkt wejścia naszej akcji JavaScript.
7. Utwórz plik `index.js` w folderze `.github/actions/js-dependency-update` i dodaj do niego następujący kod:

```js
const core = require('@actions/core');

async function run() {
  core.info('I am a custom JS action');
}

run();
```
Powyższy kod wykorzystuje pakiet `@actions/core` do wypisania linii tekstu w wyjściu naszej akcji niestandardowej. W następnym ćwiczeniu rozwiniemy dalszą część kodu JavaScript.

8. Utwórz plik `17-2-custom-actions-js.yaml` w folderze `.github/workflows` w katalogu głównym repozytorium.
9. Nazwij workflow `17 – 2 – Custom Actions – JS`.
10. Dodaj następujący wyzwalacz w workflow:  
    - a. `workflow_dispatch`
11. Ustaw opcję `run-name` workflow na `17 – 2 – Custom Actions – JS`.
12. Dodaj pojedyncze zadanie (job) o nazwie `dependency-update` do workflow.  
    - a. Powinno działać na `ubuntu-latest`.  
    - b. Powinno zawierać dwa kroki:  
      - i. Pierwszy krok powinien klonować kod.  
      - ii. Drugi krok, nazwany `Check for dependency updates`, powinien używać wcześniej utworzonej akcji JS. Aby odwołać się do akcji w tym samym repozytorium, należy podać ścieżkę do katalogu, w którym znajduje się plik `action.yaml`. W tym przypadku będzie to `./.github/actions/js-dependency-update`.
13. Zmodyfikuj plik `.gitignore` w katalogu głównym repozytorium tak, aby folder `node_modules` znajdujący się w `js-dependency-update` **nie był ignorowany**. Należy go zatwierdzić, aby nasza akcja działała poprawnie. Można to zrobić, dodając następującą linię:  
    `!.github/actions/**/node_modules`.  
    Dzięki temu wszystkie foldery `node_modules` znajdujące się w podkatalogach `.github/actions` zostaną zatwierdzone, przy jednoczesnym ignorowaniu innych folderów `node_modules`.
14. Zatwierdź zmiany i wypchnij kod. Uruchom workflow z poziomu interfejsu użytkownika i poświęć chwilę na sprawdzenie wyników działania.
