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
