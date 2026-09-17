#!/usr/bin/env python3
import sys
import os
import requests


def get_openweather(city: str, api_key: str) -> dict | None:
    """Pobiera dane z OpenWeatherMap. Zwraca dict albo None przy błędzie."""
    url = "https://api.openweathermap.org/data/2.5/weather"
    params = {
        "q": city,
        "appid": api_key,
        "units": "metric",
    }

    try:
        resp = requests.get(url, params=params, timeout=10)
    except requests.RequestException as e:
        print(f"Błąd sieci przy łączeniu z OpenWeatherMap: {e}")
        return None

    # Jeśli HTTP != 200, spróbujmy też przeanalizować JSON (często jest tam "cod")
    try:
        data = resp.json()
    except ValueError:
        print("Nieprawidłowy JSON z OpenWeatherMap.")
        return None

    return data


def get_wttr(city: str) -> str:
    """Pobiera zwięzłą prognozę z wttr.in jako tekst."""
    url = f"https://wttr.in/{city}"
    params = {"format": "2"}
    try:
        resp = requests.get(url, params=params, timeout=10)
        resp.raise_for_status()
        return resp.text.strip()
    except requests.RequestException as e:
        return f"Nie udało się pobrać danych z wttr.in: {e}"


def main():
    # Argumenty jak wcześniej: miasto i klucz API
    if len(sys.argv) < 2:
        print(f"Użycie: {sys.argv[0]} nazwa_miasta [klucz_api]")
        sys.exit(1)

    city = sys.argv[1]

    # Klucz albo z argumentu, albo z ENV (np. dla CI/CD)
    api_key = None
    if len(sys.argv) >= 3:
        api_key = sys.argv[2]
    else:
        api_key = os.getenv("OPENWEATHER_API_KEY")

    if not api_key:
        print("Brak klucza API. Podaj jako drugi argument lub ustaw zmienną OPENWEATHER_API_KEY.")
        sys.exit(1)

    data = get_openweather(city, api_key)

    if data is None:
        print("API nie odpowiedziało prawidłowo. Sprawdzam wttr.in...")
        print(get_wttr(city))
        sys.exit(1)

    cod = data.get("cod")

    # 404 – nie znaleziono miasta
    if str(cod) == "404":
        print(f"Nie znaleziono danych dla miasta: {city}. Sprawdzam wttr.in...")
        print(city)
        print(get_wttr(city))
        sys.exit(1)

    main_section = data.get("main")
    if isinstance(main_section, dict) and "temp" in main_section:
        temperature = main_section["temp"]
        print(f"Temperatura w {city} wynosi: {temperature}°C")
    else:
        print("API nie zwróciło poprawnych danych pogodowych. Sprawdzam wttr.in...")
        print(get_wttr(city))
        sys.exit(1)


if __name__ == "__main__":
    main()
