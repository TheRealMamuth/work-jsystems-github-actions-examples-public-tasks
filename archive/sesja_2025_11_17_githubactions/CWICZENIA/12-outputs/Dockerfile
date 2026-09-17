FROM nginx:alpine

# Usuwamy domyślną stronę (opcjonalnie)
RUN rm -rf /usr/share/nginx/html/*

# Kopiujemy nasz index.html do katalogu serwowanego przez Nginx
COPY index.html /usr/share/nginx/html/index.html

# Nginx nasłuchuje na porcie 80
EXPOSE 80

# Domyślna komenda już jest ustawiona w obrazie nginx,
# więc nie musimy definiować CMD/ENTRYPOINT
