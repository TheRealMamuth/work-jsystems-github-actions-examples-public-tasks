# Assignment: GitHub Actions Workflow with Node.js Caching (EN)  

## Goal  
Create a GitHub Actions workflow that performs a basic CI (Continuous Integration) process for a Node.js project and uses **actions/cache** to cache `node_modules`, in order to speed up subsequent runs.  

---

## Requirements  

1. **Repository and branch**  
   - Use the existing repository with the Node.js project.  
   - Assume that the project you are building is located in the directory:  
     `./CWICZENIA/13-caching/nodejs02`  
   - The workflow should be triggered only for changes on the branch:  
     - `cw13` (push events),  
     but must also support:  
     - all `pull_request` events,  
     - manual runs via `workflow_dispatch`.  

2. **Workflow file**  
   - Create a workflow file in:  
     `.github/workflows/13-caching-02.yml` (or similar path/name agreed for this task).  
   - The workflow name should clearly indicate that this is **Node.js CI with actions/cache**.  

3. **Defaults configuration**  
   - Configure `defaults.run` so that all `run` commands are executed:  
     - with `bash` as the shell,  
     - in the working directory:  
       `./CWICZENIA/13-caching/nodejs02`.  

4. **Job definition**  
   - Define a single job named, for example, `build`.  
   - The job must run on the virtual machine:  
     - `ubuntu-latest`.  

5. **Checkout step**  
   - Add a step that checks out the repository sources using the official action:  
     - `actions/checkout` in the current stable major version 4.  

6. **Node.js setup step**  
   - Add a step that configures Node.js using:  
     - `actions/setup-node` in the current stable major version 4.  
   - Configure it to use Node.js version **20**.  

7. **Cache configuration (actions/cache)**  
   - Add a step that uses `actions/cache` (major version 4) to cache the `node_modules` directory of the project.  
   - The cached path should point to:  
     `./CWICZENIA/13-caching/nodejs02/node_modules`  
   - Define a cache key that:  
     - depends on the operating system (`runner.os`),  
     - uniquely reflects changes in `package-lock.json` (use hashing of this file).  
   - Define a `restore-keys` prefix that allows reusing older cache entries for a given OS and Node.js setup when the exact key is not found.  

8. **Install dependencies step**  
   - Add a step that installs Node.js dependencies using the command:  
     - `npm ci`  
   - This step should use the cache from the previous step when available.  

9. **Test step**  
   - Add a step that runs the test suite with:  
     - `npm test -- --watch=false`  
   - If no tests are defined, the step should **not fail the entire workflow**.  
     - Handle this gracefully, for example by allowing the test command to fail and printing an informative message instead.  

10. **Build / verification step**  
    - Add a final step that simulates a build or server verification.  
    - In this step:  
      - Print a message indicating that this is where a build could run (e.g. `npm run build`).  
      - Run a Node.js script (e.g. `node server.js`) with a flag that only performs a check (e.g. `--check-only`) instead of starting a long-running server.  

---

## Acceptance criteria  

Your workflow will be considered correct if:  
- It is triggered on pushes to `cw13`, all pull requests, and manually via `workflow_dispatch`.  
- It uses `defaults.run` to set the working directory and shell.  
- It defines a single job that runs on `ubuntu-latest`.  
- It checks out the sources, sets up Node.js 20, and configures a cache for `node_modules` using `actions/cache@v4` with an appropriate key and restore-keys prefix.  
- It installs dependencies with `npm ci`, runs tests without failing when no tests exist, and finally executes a step that prints an informational build message and runs `node server.js --check-only` (or an equivalent check).  

---

# Zadanie: Workflow GitHub Actions z cache dla Node.js (PL)  

## Cel  
Stwórz workflow GitHub Actions, który realizuje podstawowy proces CI (Continuous Integration) dla projektu Node.js oraz wykorzystuje **actions/cache** do cache’owania katalogu `node_modules`, aby przyspieszyć kolejne uruchomienia.  

---

## Wymagania  

1. **Repozytorium i gałąź**  
   - Użyj istniejącego repozytorium z projektem Node.js.  
   - Załóż, że projekt, dla którego budujemy workflow, znajduje się w katalogu:  
     `./CWICZENIA/13-caching/nodejs02`  
   - Workflow ma uruchamiać się tylko dla zmian na gałęzi:  
     - `cw13` (zdarzenia push),  
     ale powinien również obsługiwać:  
     - wszystkie zdarzenia `pull_request`,  
     - ręczne wywołania przez `workflow_dispatch`.  

2. **Plik workflow**  
   - Utwórz plik workflow w:  
     `.github/workflows/13-caching-02.yml` (lub zbliżonej ścieżce/nazwie ustalonej w zadaniu).  
   - Nazwa workflow powinna jasno wskazywać, że jest to **Node.js CI z actions/cache**.  

3. **Konfiguracja defaults**  
   - Skonfiguruj `defaults.run` tak, aby wszystkie polecenia `run` były wykonywane:  
     - z użyciem powłoki `bash`,  
     - w katalogu roboczym:  
       `./CWICZENIA/13-caching/nodejs02`.  

4. **Definicja joba**  
   - Zdefiniuj pojedynczy job, np. o nazwie `build`.  
   - Job powinien być wykonywany na maszynie wirtualnej:  
     - `ubuntu-latest`.  

5. **Krok checkout**  
   - Dodaj krok, który pobierze źródła repozytorium z użyciem oficjalnej akcji:  
     - `actions/checkout` w aktualnej stabilnej wersji major 4.  

6. **Krok konfiguracji Node.js**  
   - Dodaj krok konfigurujący Node.js z użyciem:  
     - `actions/setup-node` w aktualnej stabilnej wersji major 4.  
   - Skonfiguruj użycie wersji **Node.js 20**.  

7. **Konfiguracja cache (actions/cache)**  
   - Dodaj krok wykorzystujący `actions/cache` (major version 4) do cache’owania katalogu `node_modules` projektu.  
   - Ścieżka cache powinna wskazywać na:  
     `./CWICZENIA/13-caching/nodejs02/node_modules`  
   - Zdefiniuj klucz cache, który:  
     - zależy od systemu operacyjnego (`runner.os`),  
     - w unikalny sposób odzwierciedla zmiany w `package-lock.json` (wykorzystaj haszowanie tego pliku).  
   - Zdefiniuj `restore-keys` w taki sposób, aby umożliwiały wykorzystanie starszych wpisów cache dla danego systemu operacyjnego i konfiguracji Node.js, gdy dokładny klucz nie zostanie odnaleziony.  

8. **Krok instalacji zależności**  
   - Dodaj krok instalujący zależności Node.js poleceniem:  
     - `npm ci`  
   - Ten krok powinien korzystać z cache, jeśli jest dostępny.  

9. **Krok testów**  
   - Dodaj krok uruchamiający testy poleceniem:  
     - `npm test -- --watch=false`  
   - Jeśli testy nie są zdefiniowane, krok **nie może powodować niepowodzenia całego workflow**.  
     - Obsłuż to w taki sposób, aby w przypadku braku testów komenda nie psuła buildu, tylko wypisywała informacyjny komunikat.  

10. **Krok build / weryfikacji**  
    - Dodaj końcowy krok, który będzie symulował build lub weryfikację działania serwera.  
    - W tym kroku:  
      - Wypisz komunikat informujący, że tutaj mógłby zostać wykonany build (np. `npm run build`).  
      - Uruchom skrypt Node.js (np. `node server.js`) z flagą, która wykonuje jedynie weryfikację, a nie uruchamia długotrwale działającego serwera (np. `--check-only`).  

---

## Kryteria akceptacji  

Workflow zostanie uznany za poprawny, jeżeli:  
- Uruchamia się dla pushy na `cw13`, wszystkich pull requestów oraz ręcznie przez `workflow_dispatch`.  
- Wykorzystuje `defaults.run` do ustawienia katalogu roboczego i powłoki.  
- Definiuje pojedynczy job działający na `ubuntu-latest`.  
- Pobiera źródła, konfiguruje Node.js 20 oraz ustawia cache dla `node_modules` z użyciem `actions/cache@v4` z odpowiednim kluczem i prefiksem `restore-keys`.  
- Instaluje zależności przez `npm ci`, uruchamia testy w sposób niewywodzący do błędu przy braku testów oraz na końcu wykonuje krok wypisujący informacyjny komunikat o buildzie i uruchamiający `node server.js --check-only` (lub analogiczny check).
