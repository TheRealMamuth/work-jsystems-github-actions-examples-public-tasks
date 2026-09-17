# 🧩 Zadanie: Docker Bake + GitHub Actions – budowa obrazu NGINX z metadanymi

## 🎯 Cel ćwiczenia

Celem zadania jest przygotowanie w pełni zautomatyzowanego procesu budowy obrazu Dockera dla prostego serwisu opartego o NGINX, który:
- serwuje statyczną stronę HTML z dynamicznie wstrzykniętymi danymi środowiska,
- wykorzystuje `docker/bake-action@v6` do budowy wielostopniowej,
- generuje metadane i adnotacje obrazu przy użyciu `docker/metadata-action@v5`,
- korzysta z cache typu `gha` dla przyspieszenia kolejnych buildów,
- opcjonalnie potrafi budować obrazy wieloarchitekturowe (`amd64` / `arm64`).

---

## 🧱 Struktura katalogów

Po wykonaniu zadania Twoje repozytorium powinno wyglądać następująco:

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

Prosty szablon HTML serwowany przez NGINX, zawierający wstawki zmiennych środowiskowych.

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

Minimalna konfiguracja NGINX-a:

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

Przygotowuje obraz oparty na `nginx:alpine`, kopiuje pliki konfiguracyjne oraz umożliwia użycie zmiennych build-time (ARG).  
Zastosuj etykiety (LABEL) oraz zmienne środowiskowe, tak by były widoczne w metadanych obrazu.

---

### 4. `docker-bake.hcl`

Definiuje konfigurację Buildx Bake – zbudowanie celu o nazwie `web`, który:
- korzysta z kontekstu (`context`) wskazującego na katalog źródłowy z plikami NGINX,
- odwołuje się do `Dockerfile`,
- obsługuje cache z GitHub Actions (`type=gha`),
- umożliwia multi-arch build.

---

### 5. `.github/workflows/ci.yml`

Workflow GitHub Actions realizujący build Dockera przy użyciu `docker/bake-action@v6`.

Powinien:
1. Uruchamiać się ręcznie (`workflow_dispatch`).
2. Ustawiać nazwę obrazu w zmiennej `IMAGE_NAME`.
3. Wykonywać checkout repozytorium.
4. Konfigurować Buildx.
5. Wywoływać `docker/metadata-action@v5` w celu generowania tagów i anotacji.
6. Budować obraz za pomocą `docker/bake-action@v6`, przekazując plik `docker-bake.hcl` oraz bake files z poprzedniego kroku.

Przykład fragmentu:
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
```

---

## 🧩 Zadanie do wykonania

1. Utwórz repozytorium z powyższą strukturą.
2. Uzupełnij wszystkie pliki zgodnie z opisem.
3. Skonfiguruj workflow GitHub Actions (`ci.yml`), tak aby poprawnie:
   - generował metadane obrazu,
   - budował go z użyciem Bake,
   - obsługiwał cache `gha`.
4. Uruchom workflow ręcznie w GitHub Actions i zweryfikuj, że proces kończy się sukcesem.

---

## ✅ Efekt końcowy

Rezultatem zadania powinny być działające pliki:
- `Dockerfile`
- `docker-bake.hcl`
- `nginx/default.conf`
- `nginx/html/index.template.html`
- `.github/workflows/ci.yml`

Gotowy projekt po zbudowaniu lokalnie poleceniem:
```bash
docker buildx bake
```
powinien uruchamiać serwer NGINX serwujący stronę z danymi środowiska i wersji obrazu.

---

### 💡 Wskazówki

- Zmiennych `APP_NAME` i `APP_ENV` użyj poprzez `ARG` → `ENV`.
- W `metadata-action` zastosuj przykładowe tagi: `semver`, `sha`.
- Upewnij się, że cache jest poprawnie zdefiniowany (`cache-from` / `cache-to` typu `gha`).
- Do testów lokalnych możesz użyć:
  ```bash
  docker buildx bake --set web.args.APP_ENV=local --set web.args.APP_NAME=test
  ```

---

**Powodzenia!**
