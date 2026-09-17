# Rozwiązanie ćwiczenia 04 – Praca z niestandardowymi akcjami firm trzecich

---

## Krok po kroku rozwiązanie

### 1. Utworzenie aplikacji React

1. W katalogu głównym repozytorium utwórz folder o nazwie:
   ```bash
   mkdir 04-using-actions
   ```
2. Przejdź do nowo utworzonego folderu:
   ```bash
   cd 04-using-actions
   ```
3. Wygeneruj aplikację React przy pomocy polecenia:
   ```bash
   npx create-react-app --template typescript react-app
   ```
4. Po zakończeniu generowania aplikacji sprawdź, czy pojawił się komunikat o pomyślnym utworzeniu projektu.  
5. Przejrzyj strukturę plików w katalogu `react-app`, aby zapoznać się z układem projektu.

---

### 2. Utworzenie pierwszej wersji workflow

1. W katalogu `.github/workflows` utwórz plik o nazwie:
   ```bash
   04-using-actions.yaml
   ```
2. Dodaj do pliku nagłówek z nazwą workflow:
   ```yaml
   name: "04 – Using Actions"
   ```
3. Ustaw wyzwalacz na `push`:
   ```yaml
   on: push
   ```
4. Utwórz pierwsze zadanie `build` z dwoma krokami:
   ```yaml
   jobs:
     build:
       runs-on: ubuntu-latest
       steps:
         - name: Checkout Code
           uses: actions/checkout@v4

         - name: Printing Folders
           run: ls -R
   ```
5. Zatwierdź i wypchnij zmiany:
   ```bash
   git add .
   git commit -m "Add initial workflow for React app"
   git push
   ```
6. Sprawdź w zakładce „Actions” na GitHubie, czy workflow zakończył się sukcesem.

---

### 3. Rozszerzenie workflow – instalacja Node i zależności React

1. Usuń krok **Printing Folders**.  
2. Dodaj nowy krok **Setup Node** po **Checkout Code**:
   ```yaml
   - name: Setup Node
     uses: actions/setup-node@v4
     with:
       node-version: '20.x'
   ```
3. Dodaj krok **Install Dependencies** po **Setup Node**:
   ```yaml
   - name: Install Dependencies
     run: npm ci
     working-directory: 04-using-actions/react-app
   ```
4. Zatwierdź i wypchnij zmiany, a następnie przeanalizuj wyniki działania workflow.

---

### 4. Rozszerzenie workflow – uruchamianie testów jednostkowych

1. Dodaj po kroku **Install Dependencies** nowy krok **Run Unit Tests**:
   ```yaml
   - name: Run Unit Tests
     run: npm run test
     working-directory: 04-using-actions/react-app
   ```
2. Zatwierdź i wypchnij zmiany:
   ```bash
   git add .
   git commit -m "Add unit test execution step"
   git push
   ```
3. Upewnij się, że testy zostały uruchomione poprawnie w zakładce „Actions”.

---

### 5. Zmiana wyzwalacza workflow

Aby zapobiec automatycznemu uruchamianiu workflow przy każdym `push`, zmień sekcję `on` na:

```yaml
on: workflow_dispatch
```

---

## Finalna wersja pliku `04-using-actions.yaml`

```yaml
name: "04 – Using Actions"

on: workflow_dispatch

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20.x'

      - name: Install Dependencies
        run: npm ci
        working-directory: 04-using-actions/react-app

      - name: Run Unit Tests
        run: npm run test
        working-directory: 04-using-actions/react-app
```

---

## Dodatkowe uwagi

- **actions/checkout@v4** – służy do pobrania kodu źródłowego repozytorium.  
- **actions/setup-node@v4** – umożliwia konfigurację środowiska Node.js.  
- **workflow_dispatch** – pozwala ręcznie uruchomić workflow z interfejsu GitHub.  
- Polecenie `npm ci` instaluje zależności zgodne z plikiem `package-lock.json`.  
- Polecenie `npm run test` uruchamia testy jednostkowe aplikacji React.

