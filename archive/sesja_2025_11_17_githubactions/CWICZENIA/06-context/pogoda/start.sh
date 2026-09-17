#!/bin/bash
set -e
# Twój klucz API dla OpenWeatherMap
# zabezpiecz go przed udostępnianiem publicznym
API_KEY="7cff9972d5c98a9a47ddf6a59cb34d8e"

# Sprawdzenie, czy podano miasto
if [ -z "$1" ]; then
    echo "Użycie: $0 nazwa_miasta"
    exit 1
fi

if [ -z "$2" ]; then
    echo "Brak klucza API. Użycie: $0 nazwa_miasta klucz_api"
    exit 1
fi

CITY="$1"
API_KEY="$2"
URL="https://api.openweathermap.org/data/2.5/weather?q=$CITY&appid=$API_KEY&units=metric"

# Pobieranie danych pogodowych za pomocą curl
response=$(curl -s "$URL")

# Sprawdzenie, czy zapytanie się powiodło
if echo "$response" | grep -q "404"; then
    echo "Nie znaleziono danych dla miasta: $CITY. Sprawdzam wttr.in..."
    echo "$CITY"
    curl "https://wttr.in/$CITY?format=2"
    exit 1
elif echo "$response" | grep -q "main"; then
    # Wyświetlanie temperatury
    temperature=$(echo $response | jq -r '.main.temp')
    echo "Temperatura w $CITY wynosi: $temperature°C"
else
    echo "API nie odpowiedziało prawidłowo. Sprawdzam wttr.in..."
    curl "https://wttr.in/$CITY?format=2"
    exit 1
fi
