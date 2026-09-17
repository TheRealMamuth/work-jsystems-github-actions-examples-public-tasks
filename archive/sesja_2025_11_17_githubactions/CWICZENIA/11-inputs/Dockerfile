FROM nginx:alpine

# Parametry build-time – przychodzą z workflow (choice + number)
ARG APP_ENV=dev
ARG BUILD_NUMBER=0

# Dla podglądu w obrazie (docker inspect)
LABEL app.environment="${APP_ENV}" \
      app.build_number="${BUILD_NUMBER}"

# Prosta statyczna strona
COPY index.html /usr/share/nginx/html/index.html

# Domyślny port Nginxa
EXPOSE 80
