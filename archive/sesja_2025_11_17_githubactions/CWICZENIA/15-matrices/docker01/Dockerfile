# Używamy lekkiej bazy
FROM alpine:3.20

# Argument z CI – będziemy go podawać z matrixa (dev / staging / prod)
ARG APP_ENV=dev

# Zapiszmy informację o środowisku do pliku
RUN echo "Hello from environment: ${APP_ENV}" > /message.txt

# Domyślne polecenie – po prostu wyświetla komunikat
CMD ["cat", "/message.txt"]
