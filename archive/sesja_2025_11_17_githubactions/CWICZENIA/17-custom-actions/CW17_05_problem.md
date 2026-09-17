# Practical Exercise 26 - Adding the Logic to Create PRs

## English Version

### Exercise Description

In this practical exercise, our goal is to finish the JavaScript part of our code in order to correctly create PRs from within our custom action.

Here are the instructions for the exercise:

1. Extend the file named `17-2-custom-actions-js.yaml` by:
   - a. Extending the permissions of the GITHUB_TOKEN token by adding a top-level permissions key with two parameters, `contents` and `pull-requests`, both set to `write`.
   - b. Pass the value of `secrets.GITHUB_TOKEN` to the `gh-token` input of the custom action.

2. Allow GitHub Actions to create PRs by modifying the repository settings as follows:
   - a. Click on **Settings** at the top-right of the menu tabs in the repository page.  
   - b. On the left-side menu, click on **Actions** and then on **General**.  
   - c. Scroll to the bottom until the **Workflow permissions** header.  
   - d. Tick the box next to **Allow GitHub Actions to create and approve pull requests**.

3. [Optional - If you don't want to code in JavaScript, simply copy the code from the link in the resources of this lecture]  
   Update the `index.js` file to run the following commands if the stdout of the `git status` command is not empty:
   - a. Run a git command to change to the new branch provided via the `target-branch` input.  
   - b. Add both the `package.json` and `package-lock.json` files to the staged files for a commit.  
   - c. Commit both files with whatever message you see fit.  
   - d. Push the changes to the remote branch provided via the `target-branch` input. You might have to add a `-u origin ${targetBranch}` after git push for it to work properly.  
   - e. Open a PR using the **Octokit API**. Here is the snippet necessary to open the PR:

```js
// At the beginning of the file, import the @actions/github package
const github = require('@actions/github');

// Remaining code
const octokit = github.getOctokit(ghToken);

try {
  await octokit.rest.pulls.create({
    owner: github.context.repo.owner,
    repo: github.context.repo.repo,
    title: `Update NPM dependencies`,
    body: `This pull request updates NPM packages`,
    base: baseBranch,
    head: targetBranch
  });
} catch (e) {
  core.error('[js-dependency-update] : Something went wrong while creating the PR. Check logs below.');
  core.setFailed(e.message);
  core.error(e);
}
```

4. Commit the changes and push the code. Trigger the workflow from the UI, and take a few moments to inspect the output of the workflow run.  
   What happened when the workflow was run a second time and the PR was already open?

---

## Wersja Polska

### Opis ćwiczenia

W tym ćwiczeniu praktycznym naszym celem jest dokończenie części kodu w JavaScript, aby umożliwić prawidłowe tworzenie Pull Requestów (PR) z poziomu naszej akcji niestandardowej.

Oto instrukcje do ćwiczenia:

1. Rozszerz plik `17-2-custom-actions-js.yaml` poprzez:
   - a. Rozszerzenie uprawnień tokena `GITHUB_TOKEN` przez dodanie klucza najwyższego poziomu `permissions` z dwoma parametrami: `contents` i `pull-requests`, oba ustawione na `write`.  
   - b. Przekazanie wartości `secrets.GITHUB_TOKEN` do parametru wejściowego `gh-token` w akcji niestandardowej.

2. Zezwól GitHub Actions na tworzenie PR-ów, modyfikując ustawienia repozytorium w następujący sposób:
   - a. Kliknij **Settings** w prawym górnym rogu zakładek menu na stronie repozytorium.  
   - b. W menu po lewej stronie kliknij **Actions**, a następnie **General**.  
   - c. Przewiń na dół do sekcji **Workflow permissions**.  
   - d. Zaznacz pole obok opcji **Allow GitHub Actions to create and approve pull requests**.

3. [Opcjonalnie — jeśli nie chcesz pisać kodu w JavaScript, możesz skopiować kod z linku dostępnego w materiałach do tej lekcji]  
   Zaktualizuj plik `index.js`, aby uruchamiał poniższe polecenia, jeśli wynik polecenia `git status` (stdout) nie jest pusty:
   - a. Uruchom polecenie `git`, aby przełączyć się na nową gałąź podaną w parametrze `target-branch`.  
   - b. Dodaj pliki `package.json` i `package-lock.json` do listy plików przeznaczonych do zatwierdzenia.  
   - c. Zatwierdź oba pliki z dowolnym komunikatem.  
   - d. Wypchnij zmiany do zdalnej gałęzi określonej przez `target-branch`. Być może konieczne będzie dodanie `-u origin ${targetBranch}` po poleceniu `git push`, aby działało poprawnie.  
   - e. Otwórz Pull Request przy użyciu **Octokit API**. Oto fragment kodu potrzebny do jego otwarcia:

```js
// Na początku pliku zaimportuj pakiet @actions/github
const github = require('@actions/github');

// Pozostała część kodu
const octokit = github.getOctokit(ghToken);

try {
  await octokit.rest.pulls.create({
    owner: github.context.repo.owner,
    repo: github.context.repo.repo,
    title: `Update NPM dependencies`,
    body: `This pull request updates NPM packages`,
    base: baseBranch,
    head: targetBranch
  });
} catch (e) {
  core.error('[js-dependency-update] : Something went wrong while creating the PR. Check logs below.');
  core.setFailed(e.message);
  core.error(e);
}
```

4. Zatwierdź zmiany i wypchnij kod. Uruchom workflow z interfejsu użytkownika i poświęć chwilę na przeanalizowanie wyników jego działania.  
   Co się stało, gdy workflow został uruchomiony ponownie, a Pull Request był już otwarty?
