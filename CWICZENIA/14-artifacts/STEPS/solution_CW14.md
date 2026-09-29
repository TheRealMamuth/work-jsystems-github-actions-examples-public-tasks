
# Rozwiązanie: Ćwiczenie 17 — Praca z artefaktami (GitHub Actions)

Poniżej otrzymujesz kompletne rozwiązanie **krok po kroku** w języku polskim, zgodne z treścią zadania. Zawiera ono gotowe pliki YAML, komendy oraz checklistę weryfikacyjną.

---

## 1) Przygotowanie aplikacji React

**Kroki:**

1. W katalogu głównym repozytorium utwórz folder na ćwiczenie:
   ```bash
   mkdir -p 14-artifacts
   cd 14-artifacts
   ```

2. Wygeneruj aplikację React (TypeScript) w podkatalogu `react-app`:
   ```bash
   # Node.js 24 LTS
   node --version
   npm create vite@9.2.1 react-app -- --template react-ts --no-interactive
   cd react-app
   npm install
   npm run dev
   ```

   Otwórz adres wypisany przez Vite (zwykle http://localhost:5173). Zatrzymaj serwer przez Ctrl+C i pozostań w `react-app`. Wykonaj kroki od punktu 2 z [instrukcji konfiguracji Vite i Vitest](../../REACT_VITE.md) przed przejściem dalej: dodają testy i katalog `build/`. Vite uruchamiaj przez `npm run dev`; szablon nie ma skryptu `start`.

3. (Opcjonalnie) podejrzyj strukturę:
   ```bash
   cd react-app
   npm run test -- --watchAll=false # szybki test, aby zainicjować środowisko
   cd ../..
   ```

> Uwaga: Użyj Node.js 24 LTS lokalnie i w GitHub Actions. Nie instaluj generatora globalnie; `npm create` pobiera wskazaną wersję.

---

## 2) Pierwsza wersja workflow — test, build i upload artefaktu „app”

**Ścieżka pliku:** `.github/workflows/14-artifacts.yaml`  
**Cel:** Zbudować aplikację, a wynik (`build/`) wysłać jako artefakt do ponownego użycia w innym jobie.

Skopiuj poniższy YAML do pliku `.github/workflows/14-artifacts.yaml`:

```yaml
name: 14 – Working with Artifacts

on:
  workflow_dispatch:

jobs:
  test-build:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: 14-artifacts/react-app

    steps:
      - name: Checkout code
        uses: actions/checkout@v7

      - name: Setup Node
        uses: actions/setup-node@v7
        with:
          node-version: 24.x

      - name: Download cached dependencies
        id: cache
        uses: actions/cache@v6
        with:
          key: deps-node-modules-${{ hashFiles('14-artifacts/react-app/package-lock.json') }}
          path: 14-artifacts/react-app/node_modules

      - name: Install dependencies (only on cache miss)
        if: ${{ steps.cache.outputs.cache-hit != 'true' }}
        run: npm ci --include=dev

      - name: Unit tests
        run: npm run test -- --watchAll=false

      - name: Build code
        run: npm run build

      - name: Upload build files
        uses: actions/upload-artifact@v7
        with:
          name: app
          path: 14-artifacts/react-app/build

  deploy:
    runs-on: ubuntu-latest
    needs: [test-build]

    steps:
      - name: Download build files
        uses: actions/download-artifact@v8
        with:
          name: app
          path: build

      - name: Show folder structure
        run: ls -R
```

**Co to daje?**  
- `test-build` odpowiada za pobranie kodu, przygotowanie środowiska, testy i build.  
- `upload-artifact` pakuje zawartość `build/` pod nazwą `app`.  
- `deploy` pobiera artefakt `app` i pokazuje strukturę katalogów — symuluje dalsze etapy (np. publikację).

---

## 3) Komendy: commit, push i ręczne uruchomienie

1. Zatwierdź zmiany i wypchnij:
   ```bash
   git add .
   git commit -m "CW17: pierwszy workflow z artefaktami (app)"
   git push
   ```

2. Uruchom ręcznie w GitHubie: **Actions → 14 – Working with Artifacts → Run workflow**.

3. Po zakończeniu przebiegu:
   - Wejdź w stronę konkretnego runa → zakładka **Artifacts**.  
   - Pobierz artefakt **app** i sprawdź jego zawartość lokalnie (powinien zawierać zawartość `build/`).

---

## 4) Rozszerzenie: artefakty zależne od commita + raport pokrycia testów

W tej wersji:
- wprowadzamy **zmienne środowiskowe** dla nazw artefaktów, powiązane z aktualnym commitem (`github.sha`),  
- aktualizujemy krok testów tak, aby generował **raport pokrycia** (Vitest + `--coverage`),
- dodajemy **drugi artefakt** z folderem `coverage/`.

Zastąp zawartość pliku `.github/workflows/14-artifacts.yaml` poniższym YAML-em:

```yaml
name: 14 – Working with Artifacts

on:
  workflow_dispatch:

env:
  build-artifact-key: app-${{ github.sha }}
  test-coverage-key: test-coverage-${{ github.sha }}

jobs:
  test-build:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: 14-artifacts/react-app

    steps:
      - name: Checkout code
        uses: actions/checkout@v7

      - name: Setup Node
        uses: actions/setup-node@v7
        with:
          node-version: 24.x

      - name: Download cached dependencies
        id: cache
        uses: actions/cache@v6
        with:
          key: deps-node-modules-${{ hashFiles('14-artifacts/react-app/package-lock.json') }}
          path: 14-artifacts/react-app/node_modules

      - name: Install dependencies (only on cache miss)
        if: ${{ steps.cache.outputs.cache-hit != 'true' }}
        run: npm ci --include=dev

      - name: Unit tests (with coverage)
        run: npm run test -- --coverage --watchAll=false

      - name: Upload test results (coverage)
        if: ${{ always() }} # wyślij nawet gdy testy padną, aby mieć artefakty do analizy
        uses: actions/upload-artifact@v7
        with:
          name: ${{ env.test-coverage-key }}
          path: 14-artifacts/react-app/coverage

      - name: Build code
        run: npm run build

      - name: Upload build files
        uses: actions/upload-artifact@v7
        with:
          name: ${{ env.build-artifact-key }}
          path: 14-artifacts/react-app/build

  deploy:
    runs-on: ubuntu-latest
    needs: [test-build]

    steps:
      - name: Download build files
        uses: actions/download-artifact@v8
        with:
          name: ${{ env.build-artifact-key }}
          path: build

      - name: Show folder structure
        run: ls -R
```

**Najważniejsze zmiany vs. wersja pierwsza:**  
- Dodano `env.build-artifact-key` i `env.test-coverage-key` wiążące nazwy artefaktów z identyfikatorem commita.  
- Testy uruchamiane z `--coverage` generują raport w `coverage/`.  
- Artefakt z coverage wysyłany zawsze (`if: always()`), aby móc pobrać logi/raport nawet w razie niepowodzenia testów.  
- `deploy` pobiera już artefakt o nazwie dynamicznej (z `env`).

---

## 5) Weryfikacja i analiza wyników

1. **Ponów commit i push:**
   ```bash
   git add .github/workflows/14-artifacts.yaml
   git commit -m "CW17: artefakty zależne od commita + coverage"
   git push
   ```

2. **Uruchom ręcznie** workflow i poczekaj na zakończenie.

3. **Sprawdź artefakty** w widoku runa:
   - `app-<sha>` — spakowane pliki produkcyjne (`build/`).  
   - `test-coverage-<sha>` — raport pokrycia (`coverage/`, m.in. HTML).  
   Pobierz i otwórz `coverage/lcov-report/index.html` lokalnie w przeglądarce.

4. **Zaleta podejścia:** artefakty są **zero-konfliktowe** i łatwo śledzić, z którego commita pochodzą. Integracja z cache Node pozwala przyspieszyć instalację zależności.

---

## 6) Checklista końcowa

- [ ] Folder `14-artifacts/react-app` zawiera działającą aplikację React.  
- [ ] W repo istnieje `.github/workflows/14-artifacts.yaml`.  
- [ ] Pierwsza wersja workflow działa: tworzy artefakt `app` i job `deploy` prezentuje jego zawartość.  
- [ ] Rozszerzona wersja tworzy artefakty `app-<sha>` i `test-coverage-<sha>`.  
- [ ] Raport pokrycia można pobrać i obejrzeć (`lcov-report/index.html`).

Powodzenia! 🚀
