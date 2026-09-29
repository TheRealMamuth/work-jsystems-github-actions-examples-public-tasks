# Uruchomienie aplikacji React i test w przeglądarce

Ten przykład uzupełnia ćwiczenie 04 o test E2E rzeczywiście uruchomionej aplikacji.
Używamy Node.js 24 LTS i Cypress 16.1.0. Zależności testów są zapisane w osobnym
`package.json` i `package-lock.json` w tym katalogu.

## GitHub Actions

Workflow `04-01-using-actions-v3-e2e.yml` znajduje się w katalogu
`.github/workflows` repozytorium. W GitHub przejdź do **Actions**, wybierz
**04-01 - Using Actions - Start App and Browser Test** i kliknij **Run workflow**.
Plik musi być wcześniej zapisany w repozytorium na GitHub; ręczne uruchamianie
wymaga obecności workflowu na gałęzi domyślnej.

Workflow wykonuje następujące kroki:

1. Pobiera kod i przygotowuje Node.js 24.
2. Akcją `bahmutov/npm-install@v1` instaluje zależności aplikacji z lockfile.
3. Akcją `cypress-io/github-action@v7` instaluje Cypress, buduje aplikację
   i uruchamia podgląd gotowego buildu na `http://127.0.0.1:18000`.
4. Czeka do 60 sekund na odpowiedź serwera, a następnie uruchamia test
   w przeglądarce Electron, w trybie bez okna.
5. Zapisuje raport JUnit XML i zrzuty ekranu jako artefakt
   **react-app-browser-test-results**, przechowywany przez 7 dni.

Serwer i przeglądarka działają na tym samym runnerze, na czas joba.
Dlatego `127.0.0.1` jest tutaj właściwe i nie trzeba dodawać domeny laboratorium
do `allowedHosts`. Zajęty port powoduje błąd dzięki `--strictPort`.
Cypress działa lokalnie na runnerze; nie wymaga konta ani tokenu Cypress Cloud.

## Co sprawdza test

Test `cypress/e2e/homepage.cy.js` otwiera stronę główną i sprawdza:

- czy React wyrenderował widoczną zawartość w `#root`;
- czy ekran pokazuje tekst `src/App.tsx`;
- czy widoczny jest odnośnik **Learn React** z oczekiwanym adresem;
- czy logo zostało poprawnie załadowane.

Na końcu zapisuje zrzut strony. Błąd testu powoduje niepowodzenie workflowu.
Asercje dotyczą istniejącej aplikacji `../react-app`, która zachowuje ekran
„Learn React”. Jeśli zastąpisz ją nowym szablonem lub zmienisz interfejs,
dostosuj oczekiwaną treść testu.

## Uruchomienie lokalne

W pierwszym terminalu, zaczynając w głównym katalogu repozytorium:

```bash
cd CWICZENIA/04-praca-z-zewnetrzymi-akcjami/react-app
npm ci --include=dev
npm run build
npm run preview -- --host 127.0.0.1 --port 18000 --strictPort
```

Pozostaw serwer uruchomiony. W drugim terminalu, również zaczynając w głównym
katalogu repozytorium:

```bash
cd CWICZENIA/04-praca-z-zewnetrzymi-akcjami/react-app-e2e
npm ci --include=dev
npm test
```

Cypress wymaga bibliotek systemowych przeglądarki. Na własnym Linuksie sprawdź
[wymagania instalacji](https://docs.cypress.io/app/get-started/install-cypress).
Runner `ubuntu-latest` ma wymagane biblioteki. `npm run open` uruchamia okno
Cypress na komputerze ze środowiskiem graficznym.

Po teście zatrzymaj podgląd aplikacji przez Ctrl+C. Katalogi `node_modules`,
`reports` oraz zrzuty ekranu są ignorowane przez Git.

Opis parametrów `build`, `start`, `wait-on` i `working-directory` znajduje się
w [dokumentacji akcji Cypress](https://github.com/cypress-io/github-action).
