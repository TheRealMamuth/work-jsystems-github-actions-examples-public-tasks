# Practical Exercise 25 - Parsing Inputs and Running Shell Commands

## English Version

### Exercise Description

In this practical exercise, our goal is to explore how to parse inputs within a JavaScript custom action.

Here are the instructions for the exercise:

1. Extend the file named `action.yaml` under the folder `.github/actions/js-dependency-update` by adding several necessary inputs:
   - a. The `base-branch` input should:
     - i. Have a description of `The branch used as the base for the dependency update checks`.
     - ii. Have a default of `main`.
     - iii. Not be required.
   - b. The `target-branch` input should:
     - i. Have a description of `The branch from which the PR is created`.
     - ii. Have a default of `update-dependencies`.
     - iii. Not be required.
   - c. The `working-directory` input should:
     - i. Have a description of `The working directory of the project to check for dependency updates`.
     - ii. Be required.
   - d. The `gh-token` input should:
     - i. Have a description of `Authentication token with repository access. Must have write access to contents and pull-requests`.
     - ii. Be required.
   - e. The `debug` input should:
     - i. Have a description of `Whether the output debug messages to the console`.
     - ii. Not be required.

2. Extend the file named `17-2-custom-actions-js.yaml` by:
   - a. Adding the necessary inputs to the `workflow_dispatch` trigger. These are the `base-branch`, `target-branch`, `working-dir`, and `debug`.  
      The `gh-token` input for the action can be retrieved from the workflow via the `secrets.GITHUB_TOKEN` secret and does not need to be provided as an input to the workflow.
   - b. Pass these inputs as parameters to the `js-dependency-update` action.
   - c. Update the `run-name` of the workflow to include information about the base branch, target branch, and working directory.

3. [Optional - If you don't want to code in JavaScript, simply copy the code from the link in the resources of this lecture]  
   Update the `index.js` file to:
   - a. Retrieve the inputs by using the `getInput` and `getBooleanInput` methods from the `@actions/core` package.
   - b. Validate that the provided inputs follow these constraints:
     - i. Branch names should contain only letters, digits, underscores, hyphens, dots, and forward slashes.
     - ii. Directory paths should contain only letters, digits, underscores, hyphens, and forward slashes.
   - c. If any validation fails, use the `setFailed` method from the `@actions/core` package to set an error message and fail the action execution.
   - d. If all validations pass, print the following information on the screen:
     - i. The value of the base branch  
     - ii. The value of the target branch  
     - iii. The value of the working directory  
   - e. Leverage the `@actions/exec` package to run shell scripts. For that, use the `exec` method of the mentioned package or the `getExecOutput` method whenever you need access to the stdout and stderr of the command.
     - i. Run the `npm update` command within the provided working directory.  
     - ii. Run the `git status -s package*.json` to check for updates on `package*.json` files. Use the `getExecOutput` method and store the return value for later usage.
   - f. If the stdout of the `git status` command has any characters, print a message saying that there are updates available. Otherwise, print a message saying that there are no updates at this point in time.

4. Commit the changes and push the code. Trigger the workflow from the UI, passing both valid and invalid values to all the inputs, and take a few moments to inspect the output of the workflow run.  
   How did the action handle different inputs?

---

## Wersja Polska

### Opis ćwiczenia

W tym ćwiczeniu praktycznym naszym celem jest poznanie sposobu parsowania danych wejściowych w akcji niestandardowej napisanej w JavaScript.

Oto instrukcje do ćwiczenia:

1. Rozszerz plik `action.yaml` znajdujący się w folderze `.github/actions/js-dependency-update`, dodając kilka wymaganych parametrów wejściowych:
   - a. Parametr `base-branch` powinien:
     - i. Mieć opis: `The branch used as the base for the dependency update checks`  
     - ii. Mieć domyślną wartość `main`  
     - iii. Nie być wymagany
   - b. Parametr `target-branch` powinien:
     - i. Mieć opis: `The branch from which the PR is created`  
     - ii. Mieć domyślną wartość `update-dependencies`  
     - iii. Nie być wymagany
   - c. Parametr `working-directory` powinien:
     - i. Mieć opis: `The working directory of the project to check for dependency updates`  
     - ii. Być wymagany
   - d. Parametr `gh-token` powinien:
     - i. Mieć opis: `Authentication token with repository access. Must have write access to contents and pull-requests`  
     - ii. Być wymagany
   - e. Parametr `debug` powinien:
     - i. Mieć opis: `Whether the output debug messages to the console`  
     - ii. Nie być wymagany

2. Rozszerz plik `17-2-custom-actions-js.yaml` w następujący sposób:
   - a. Dodaj wymagane wejścia do wyzwalacza `workflow_dispatch`: `base-branch`, `target-branch`, `working-dir` i `debug`.  
      Parametr `gh-token` dla akcji można pobrać z workflow poprzez sekret `secrets.GITHUB_TOKEN`, więc nie trzeba go przekazywać ręcznie.
   - b. Przekaż te parametry jako argumenty do akcji `js-dependency-update`.
   - c. Zaktualizuj opcję `run-name` w workflow, aby zawierała informacje o bazowej gałęzi, docelowej gałęzi i katalogu roboczym.

3. [Opcjonalnie — jeśli nie chcesz pisać kodu w JavaScript, po prostu skopiuj kod z linku podanego w materiałach do tej lekcji]  
   Zaktualizuj plik `index.js`, aby:
   - a. Pobierał dane wejściowe za pomocą metod `getInput` i `getBooleanInput` z pakietu `@actions/core`.
   - b. Walidował, że przekazane dane wejściowe spełniają następujące warunki:
     - i. Nazwy gałęzi mogą zawierać tylko litery, cyfry, podkreślenia, myślniki, kropki i ukośniki.
     - ii. Ścieżki katalogów mogą zawierać tylko litery, cyfry, podkreślenia, myślniki i ukośniki.
   - c. Jeśli jakakolwiek walidacja zakończy się niepowodzeniem, użyj metody `setFailed` z pakietu `@actions/core`, aby ustawić komunikat o błędzie i przerwać wykonanie akcji.
   - d. Jeśli wszystkie walidacje zakończą się powodzeniem, wypisz na ekranie następujące informacje:
     - i. Wartość gałęzi bazowej  
     - ii. Wartość gałęzi docelowej  
     - iii. Wartość katalogu roboczego  
   - e. Wykorzystaj pakiet `@actions/exec` do uruchamiania poleceń powłoki.  
     - i. Uruchom polecenie `npm update` w podanym katalogu roboczym.  
     - ii. Uruchom polecenie `git status -s package*.json`, aby sprawdzić aktualizacje plików `package*.json`. Użyj metody `getExecOutput`, aby pobrać wynik i przechować go do dalszego wykorzystania.
   - f. Jeśli wynik polecenia `git status` (stdout) zawiera jakiekolwiek znaki, wypisz komunikat, że dostępne są aktualizacje. W przeciwnym razie wypisz informację, że w tym momencie nie ma aktualizacji.

4. Zatwierdź zmiany i wypchnij kod. Uruchom workflow z interfejsu użytkownika, przekazując zarówno poprawne, jak i niepoprawne wartości dla wszystkich parametrów wejściowych. Poświęć chwilę na przeanalizowanie wyników działania workflow.  
   Jak akcja obsłużyła różne dane wejściowe?
