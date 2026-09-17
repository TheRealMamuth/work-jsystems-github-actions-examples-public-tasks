# 🧩 Zadanie: Docker Bake + GitHub Actions – budowa i publikacja obrazu NGINX

## 🎯 Cel ćwiczenia

Celem zadania jest przygotowanie kompletnego procesu CI/CD dla obrazu Dockera opartego o NGINX, który:
- buduje obraz z prostymi plikami statycznymi,
- wstrzykuje zmienne środowiskowe oraz metadane obrazu,
- używa `docker/bake-action@v6` do budowy,
- generuje adnotacje i tagi przez `docker/metadata-action@v5`,
- korzysta z cache `gha` dla przyspieszenia buildów,
- **dodatkowo loguje się do Docker Hub i publikuje gotowy obraz (push)**.

---

## 🧱 Struktura katalogów

```
.
├─ Dockerfile
├─ docker-bake.hcl
├─ nginx/
│  ├─ default.conf
│  └─ html/
│     └─ index.template.html
└─ .github/
   └─ workflows/
      └─ ci.yml
```

---

## 🗂️ Opis elementów

### 1. `index.template.html`

Plik HTML z dynamicznymi wstawkami środowiskowymi:

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>{{APP_NAME}} :: {{APP_ENV}}</title>
</head>
<body>
  <h1>Witaj z Nginx!</h1>
  <p>App: <strong>{{APP_NAME}}</strong></p>
  <p>Env: <strong>{{APP_ENV}}</strong></p>
  <p>Version (label): <strong>${IMAGE_VERSION}</strong></p>
</body>
</html>
```

---

### 2. `nginx/default.conf`

Minimalna konfiguracja serwera NGINX:

```conf
server {
  listen 80;
  server_name _;

  location / {
    root   /usr/share/nginx/html;
    index  index.html;
  }

  location /healthz {
    return 200 'ok';
    add_header Content-Type text/plain;
  }
}
```

---

### 3. `Dockerfile`

Obraz Dockera powinien:
- bazować na `nginx:alpine`,
- kopiować pliki konfiguracyjne i HTML,
- korzystać z `ARG` i `ENV`,
- zawierać etykiety (`LABEL`) generowane z metadanych.

---

### 4. `docker-bake.hcl`

Zawiera definicję celu `web`, w tym:
- ustawienie kontekstu i Dockerfile,
- konfigurację cache (`type=gha`),
- możliwość multi-arch (`amd64`, `arm64`),
- sekcję `tags` i `annotations` dla integracji z GitHub Actions.

---

### 5. `.github/workflows/ci.yml`

Workflow CI/CD z pełnym procesem build + push.

#### Kluczowe kroki:
1. **Checkout** – pobranie repozytorium.
2. **Debug paths** – wypisanie katalogów roboczych (pomocne przy testach).
3. **Setup Buildx** – konfiguracja buildera.
4. **Login to Docker Hub** – logowanie do rejestru Dockera:
   ```yaml
   - name: Login to Docker Hub
     uses: docker/login-action@v3
     with:
       username: ${{ vars.DOCKERHUB_USERNAME }}
       password: ${{ secrets.DOCKERHUB_TOKEN }}
   ```
5. **Extract Docker metadata** – generowanie tagów i adnotacji.
6. **Build & Push image (Bake)** – budowanie i publikowanie obrazu:
   ```yaml
   - name: Build (Bake) with annotations
     uses: docker/bake-action@v6
     with:
       files: |
         cwd://DODATKOWE/docker-bake-actions-01/docker-bake.hcl
         cwd://${{ steps.meta.outputs.bake-file-tags }}
         cwd://${{ steps.meta.outputs.bake-file-annotations }}
       set: |
         web.context=cwd://DODATKOWE/docker-bake-actions-01
         web.dockerfile=cwd://DODATKOWE/docker-bake-actions-01/Dockerfile
       push: true  # publikacja do Docker Hub
   ```

---

## 🧩 Zadanie do wykonania

1. Utwórz repozytorium i zaimplementuj strukturę plików zgodnie z powyższym opisem.  
2. Uzupełnij workflow `.github/workflows/ci.yml`, aby:
   - logował się do Docker Hub,
   - generował tagi i metadane,
   - budował obraz przez Bake,
   - **publikował wynikowy obraz do rejestru.**
3. Zdefiniuj sekrety i zmienne:
   - `DOCKERHUB_USERNAME` w zmiennych środowiskowych GitHub (Variables),
   - `DOCKERHUB_TOKEN` w sekcjach Secrets.

4. Uruchom workflow ręcznie (`workflow_dispatch`) i sprawdź w logach poprawność buildu i publikacji.

---

## ✅ Wynik końcowy

Po wykonaniu zadania:
- obraz zostaje zbudowany i opublikowany w Docker Hub (`piotrskoska/github-action-test`),
- metadane (tagi, adnotacje OCI) są automatycznie generowane,
- cache `gha` jest wykorzystywany przy kolejnych buildach,
- workflow kończy się statusem **✅ success**.

---

### 💡 Wskazówki

- Pamiętaj o ustawieniu **DockerHub credentials** w repozytorium GitHub.
- Jeśli chcesz testować lokalnie, możesz tymczasowo ustawić `push: false`.
- Do debugowania użyj:
  ```bash
  docker buildx bake --print
  ```
- W przypadku błędów autoryzacji – sprawdź zakres tokena (`repo`, `write:packages`).

---

**Powodzenia!**
