Cel ćwiczenia
	•	Zbudować obraz nginx z prostymi plikami statycznymi.
	•	Przekazać zmienne na etapie build (ARG/labels).
	•	Użyć docker/bake-action@v6 do buildu (Bake).
	•	Dodać image annotations generowane z docker/metadata-action@v5 i wstrzyknięte do Bake.
	•	Włączyć cache typu gha dla szybszych buildów.
	•	Opcjonalnie zbudować multi-arch (amd64/arm64).

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

```dockerfile
# Wersja Nginx jako build-arg
ARG NGINX_VERSION=1.27-alpine
FROM nginx:${NGINX_VERSION}

# Build-time argumenty → ENV (domyślne wartości)
ARG APP_NAME="demo-web"
ARG APP_ENV="dev"
ARG IMAGE_VERSION="0.0.0"

ENV APP_NAME=${APP_NAME} \
    APP_ENV=${APP_ENV} \
    IMAGE_VERSION=${IMAGE_VERSION}

# Nginx config
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# html + envsubst (użyjemy sh w ENTRYPOINT żeby podmienić templaty na gotowe index.html)
RUN apk add --no-cache gettext

COPY nginx/html/index.template.html /usr/share/nginx/html/index.template.html

# Minimalny healthcheck
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost/healthz || exit 1

# Proste etykiety (będą też nadpisywane przez metadata-action)
LABEL org.opencontainers.image.title="demo-nginx" \
      org.opencontainers.image.description="Demo app with Nginx" \
      org.opencontainers.image.version="${IMAGE_VERSION}"

# Podmiana templatu na finalny index.html w starcie kontenera
ENTRYPOINT ["/bin/sh","-c","envsubst < /usr/share/nginx/html/index.template.html > /usr/share/nginx/html/index.html && exec nginx -g 'daemon off;'"]
```

```hcl
group "default" {
  targets = ["web"]
}

target "web" {
  context    = "DODATKOWE/docker-bake-actions-01"
  dockerfile = "DODATKOWE/docker-bake-actions-01/Dockerfile"


  # Multi-arch (opcjonalnie) – możesz zostawić jedną platformę dla szybkości
  platforms = ["linux/amd64", "linux/arm64"]

  # Domyślne tagi (nadpisze je metadata-action przez bake-file-tags)
  tags = ["piotrskoska/github-action-test:local"]

  # Cache do GitHub Actions (szybkie buildy)
  cache-from = ["type=gha"]
  cache-to   = ["type=gha,mode=max"]

  # Build args → ENV w Dockerfile
  args = {
    NGINX_VERSION = "1.27-alpine"
    APP_NAME      = "demo-nginx"
    APP_ENV       = "ci"
    IMAGE_VERSION = "0.1.0"  # zostanie nadpisane tagami/annotacjami z metadata
  }

  # (opcjonalnie) dodatkowe, ręczne annotations – będą scalone z tymi z metadata-action
  # annotations = ["org.opencontainers.image.vendor=HelpPointIT"]
}
```


