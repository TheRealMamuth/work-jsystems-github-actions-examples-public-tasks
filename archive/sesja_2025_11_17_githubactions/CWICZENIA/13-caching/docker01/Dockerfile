# Prosty obraz nginx z Alpine
FROM ubuntu/nginx:1.24-24.04_edge

RUN apt-get update && apt-get install -y curl htop vim tmux fontconfig openjdk-21-jre
RUN apt-get install -y wget unzip
# Usuwamy domyślne pliki z katalogu HTML (opcjonalne)
RUN rm -rf /usr/share/nginx/html/*

# Kopiujemy nasz index.html do katalogu serwowanego przez nginx
COPY index.html /usr/share/nginx/html/index.html

# Domyślny port nginx
EXPOSE 80

# Standardowy entrypoint nginx z obrazu bazowego
CMD ["nginx", "-g", "daemon off;"]
