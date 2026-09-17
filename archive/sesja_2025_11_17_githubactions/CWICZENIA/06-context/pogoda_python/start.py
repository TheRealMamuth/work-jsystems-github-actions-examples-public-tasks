#!/usr/bin/env python3
import sys
import json
import urllib.request
import urllib.parse
import urllib.error


def get_openweather(city: str, api_key: str):
    """Pobiera surową odpowiedź JSON z OpenWeatherMap lub None przy błędzie."""
    params = urllib.parse.urlencode({
        "q": city,
        "appid": api_key,
        "units": "metric",
    })
    url = f"https://api.openweathermap.org/data/2.5/weather?{params}"

    try:
        with urllib.request.urlopen(url, timeout=10) as resp:
            data = resp.read().decode("utf-8")
            return data
    except urllib.error.HTTPError as e:
        # Jeśli API zwróciło błąd HTTP, też próbujemy przeanalizować treść
        try:
            data = e.read().decode("utf-8")
            return data
        except Exception:
            return None
    except Exception:
        return None


def get_wttr(city: str) -> str:
    """Pobiera zwięzłą prognozę z wttr.in."""
    url = f"https://wttr.in/{urllib.parse.quote(city)}?format=2"
    try:
        with urllib.request.urlopen(url, timeout=10) as resp:
            return resp.read().decode("utf-8").strip()
    except Exception as e:
        return f"Nie udało się pobrać danych z wttr.in: {e}"


def main():
    # Sprawdzenie argumentów (tak jak w Twoim skrypcie bash)
    if len(sys.argv) < 2:
        print(f"Użycie: {sys.argv[0]} nazwa_miasta klucz_api")
        sys.exit(1)

    if len(sys.argv) < 3:
        print("Brak klucza API. Użycie: nazwa_miasta klucz_api")
        sys.exit(1)

    city = sys.argv[1]
    api_key = sys.argv[2]

    response_text = get_openweather(city, api_key)

    if response_text is None:
        print("API nie odpowiedziało prawidłowo. Sprawdzam wttr.in...")
        print(get_wttr(city))
        sys.exit(1)

    # Próba sparsowania JSON-a
    try:
        data = json.loads(response_text)
    except json.JSONDecodeError:
        print("Nieprawidłowa odpowiedź z OpenWeatherMap. Sprawdzam wttr.in...")
        print(get_wttr(city))
        sys.exit(1)

    # Sprawdzenie kodu błędu tak jak '404' w bashu
    cod = data.get("cod")

    # OWM czasem zwraca 'cod' jako string, czasem jako int – obsłużmy oba
    if str(cod) == "404":
        print(f"Nie znaleziono danych dla miasta: {city}. Sprawdzam wttr.in...")
        print(city)
        print(get_wttr(city))
        sys.exit(1)

    # Jeśli w odpowiedzi jest sekcja 'main', to bierzemy temperaturę
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
