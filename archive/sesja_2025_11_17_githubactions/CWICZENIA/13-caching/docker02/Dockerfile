# Leki obraz nginx na Alpine
FROM nginx:1.27-alpine

# Usuwamy domyślną zawartość katalogu HTML (opcjonalne)
RUN rm -rf /usr/share/nginx/html/*

# Kopiujemy naszą stronę do katalogu serwowanego przez nginx
COPY index.html /usr/share/nginx/html/index.html

# Standardowy port nginx
EXPOSE 80

# Domyślny entrypoint nginx z obrazu bazowego
CMD ["nginx", "-g", "daemon off;"]
