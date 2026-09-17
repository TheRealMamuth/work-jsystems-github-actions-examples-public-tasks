# Minimalna baza z Nginx
FROM nginx:alpine

# Wrzucamy własny index.html
COPY ./index.html /usr/share/nginx/html/index.html

# (opcjonalnie) proste healthcheck (nie jest wymagany do ćwiczenia)
HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD wget -qO- http://localhost:80/ >/dev/null 2>&1 || exit 1

EXPOSE 80
