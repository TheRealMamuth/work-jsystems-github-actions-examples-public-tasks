# Zadanie – Using Actions: Docker Nginx build & curl test

## Cel
Zbudować obraz Dockera z Nginx, który serwuje prostą stronę z tekstem **„szkolenie github”**, a następnie w GitHub Actions:
1) zbudować obraz,  
2) uruchomić kontener,  
3) przetestować stronę przez `curl`,  
4) posprzątać zasoby.

---

## Wymagania wstępne
- Repozytorium na GitHubie
- Włączone GitHub Actions
- Podstawowa znajomość Dockera

---

## Struktura katalogów (do utworzenia)

```
CWICZENIA/
└─ 04-praca-z-zewnetrzymi-akcjami/
   └─ docker-app/
      ├─ Dockerfile
      ├─ index.html
      └─ .dockerignore   (opcjonalnie)
.github/
└─ workflows/
   └─ 04-using-actions-docker-nginx.yaml
```

---

## Pliki aplikacji

### `CWICZENIA/04-praca-z-zewnetrzymi-akcjami/docker-app/Dockerfile`
```dockerfile
FROM nginx:alpine

# Wrzucamy własny index.html do katalogu serwowanego przez Nginx
COPY ./index.html /usr/share/nginx/html/index.html

EXPOSE 80
```

### `CWICZENIA/04-praca-z-zewnetrzymi-akcjami/docker-app/index.html`
```html
<!doctype html>
<html lang="pl">
  <head>
    <meta charset="utf-8" />
    <title>Szkolenie GitHub</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
  </head>
  <body style="font-family: system-ui, sans-serif;">
    <h1>szkolenie github</h1>
  </body>
</html>
```

### (opcjonalnie) `CWICZENIA/04-praca-z-zewnetrzymi-akcjami/docker-app/.dockerignore`
```gitignore
.git
.gitignore
node_modules
```

---

## Plik z akcją GitHub (wklej **dosłownie** poniżej do `.github/workflows/04-using-actions-docker-nginx.yaml`)

```yaml
name: "04 - Using Actions:Docker Nginx build & curl test"

on:
  workflow_dispatch:

jobs:
  build-and-test:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      # (opcjonalnie) Setup Buildx - przydaje się przy bardziej złożonych buildach
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build Docker image
        working-directory: CWICZENIA/04-praca-z-zewnetrzymi-akcjami/docker-app
        run: |
          set -eux
          IMAGE_TAG=my-nginx:${GITHUB_SHA}
          docker build -t "${IMAGE_TAG}" .

          # zapisz tag do env, użyjemy go w kolejnych krokach
          echo "IMAGE_TAG=${IMAGE_TAG}" >> "$GITHUB_ENV"

      - name: Run container
        run: |
          set -eux
          # uruchamiamy w tle, mapujemy port 8080 na hosta
          CID=$(docker run -d -p 8080:80 "${IMAGE_TAG}")
          echo "CID=${CID}" >> "$GITHUB_ENV"

      - name: Wait for Nginx to be ready
        run: |
          set -eux
          for i in {1..30}; do
            if curl -fsS http://localhost:8080/ >/dev/null; then
              echo "Nginx odpowiada"; exit 0
            fi
            sleep 1
          done
          echo "Nginx nie wstał na czas" >&2
          exit 1

      - name: Test page content with curl
        run: |
          set -eux
          BODY=$(curl -fsS http://localhost:8080/)
          echo "----- PAGE BODY START -----"
          echo "$BODY"
          echo "------ PAGE BODY END ------"

          # Sprawdzamy, że treść zawiera frazę "szkolenie github" (case-insensitive)
          echo "$BODY" | grep -qi "szkolenie github"

      - name: Cleanup
        if: always()
        run: |
          set -eux
          # pokaż logi z kontenera (pomocne przy debugowaniu)
          if [ -n "${CID:-}" ]; then
            docker logs "$CID" || true
            docker rm -f "$CID" || true
          fi
```

---

## Kroki do wykonania

1. **Utwórz katalogi i pliki** jak w sekcji „Struktura katalogów”.  
2. **Dodaj i zacommituj zmiany**:
   ```bash
   git add .
   git commit -m "Ćwiczenie: Docker Nginx + curl test (index.html, Dockerfile, GHA)"
   git push
   ```
3. **Uruchom workflow ręcznie**: zakładka **Actions** → wybierz workflow  
   **“04 - Using Actions:Docker Nginx build & curl test”** → **Run workflow**.
4. **Sprawdź logi**: upewnij się, że kroki **Build**, **Run**, **Wait**, **Test** i **Cleanup** zakończyły się sukcesem.  
   W kroku „Test page content with curl” w logach powinien być zwrócony HTML zawierający frazę **„szkolenie github”**.

---

## Kryteria zaliczenia
- Obraz buduje się poprawnie (krok **Build Docker image**: OK).  
- Kontener startuje i odpowiada pod `http://localhost:8080/`.  
- Test `curl` znajduje frazę **„szkolenie github”**.  
- Sprzątanie (usunięcie kontenera) wykonuje się zawsze.  

> Jeśli zmienisz ścieżkę katalogu aplikacji, **zaktualizuj** pole `working-directory` w kroku „Build Docker image”.
