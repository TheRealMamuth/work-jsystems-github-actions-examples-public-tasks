# React + TypeScript

Aplikacja do ćwiczeń z GitHub Actions. Używa Vite do budowania i Vitest do testów.

## Wymagania

Node.js 24 LTS oraz npm — tej wersji używamy lokalnie i domyślnie w GitHub Actions.

## Polecenia

```sh
npm ci
npm run dev
```

Serwer deweloperski uruchamia się domyślnie na http://localhost:3000.

- `npm run build` — sprawdza TypeScript i zapisuje gotową aplikację w `build/`.
- `npm test` — uruchamia testy jednokrotnie, również poza CI.
- `npm run test:watch` — uruchamia testy w trybie obserwowania zmian.
- `npm test -- --coverage` — zapisuje raporty HTML i LCOV w `coverage/`.
- `npm run typecheck` — sprawdza typy bez budowania.
- `npm run preview` — udostępnia lokalnie zawartość wcześniejszego buildu.
- `npm audit` — sprawdza znane podatności zależności.

Dotychczasowe argumenty testów `--ci`, `--watchAll=false` i `--runInBand`
są obsługiwane przez `scripts/test.mjs`, aby polecenia z ćwiczeń nadal działały.
Jeżeli aplikacja ma skrypt `e2e`, pozostaje on aliasem istniejących testów
komponentu; nie jest osobnym zestawem testów przeglądarkowych.

Plik wejściowy HTML znajduje się w głównym katalogu aplikacji, a zasoby statyczne
w `public/`. Zmienne dostępne w przeglądarce używają prefiksu `VITE_` i są
odczytywane przez `import.meta.env`. Nie należy umieszczać w nich sekretów.
Konfiguracja Vite zastępuje `react-scripts`; polecenie `eject` nie jest potrzebne.
