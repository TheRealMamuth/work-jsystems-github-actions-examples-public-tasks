FROM nginx:alpine

# Narzędzie do pobrania obrazka
RUN apk add --no-cache curl

# Pobierz obrazek do katalogu assets/
RUN mkdir -p /usr/share/nginx/html/assets \
    && curl -L "https://4kwallpapers.com/images/walls/thumbs_3t/18568.jpg" \
       -o /usr/share/nginx/html/assets/wall.jpg

# Skopiuj nasz plik HTML do katalogu Nginx
COPY index.html /usr/share/nginx/html/index.html

# Nginx nasłuchuje na porcie 80
EXPOSE 80
