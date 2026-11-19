#!/usr/bin/env python3
"""Test działającego kontenera: WWW, zasoby, health i prawdziwa pogoda z API.

Nie przyjmuje klucza ani danych przykładowych. Klucz jest wyłącznie w kontenerze.
Każdy błąd dostawcy, w tym zły klucz API, kończy test niepowodzeniem.
"""

from __future__ import annotations

import argparse
import json
import math
import ssl
import sys
import urllib.error
import urllib.parse
import urllib.request


def verify(base_url: str, city: str, ca_file: str | None = None) -> dict:
    context = ssl.create_default_context(cafile=ca_file)
    base = base_url.rstrip("/")
    parsed = urllib.parse.urlsplit(base)
    if parsed.scheme not in ("http", "https") or not parsed.hostname or parsed.username or parsed.password:
        raise ValueError("Podaj poprawny adres HTTP/HTTPS bez danych logowania.")

    def get(path: str, as_json: bool = False):
        request = urllib.request.Request(base + path, headers={"Accept": "application/json" if as_json else "*/*"})
        with urllib.request.urlopen(request, context=context, timeout=30) as response:
            if response.status != 200:
                raise ValueError("Nieoczekiwany status HTTP aplikacji.")
            content = response.read().decode("utf-8")
        return json.loads(content) if as_json else content

    if get("/healthz", True).get("status") != "ok":
        raise ValueError("Kontrola healthz nie potwierdziła gotowości aplikacji.")
    if 'id="weather-form"' not in get("/"):
        raise ValueError("Interfejs WWW nie zawiera formularza miasta.")
    for asset in ("/static/styles.css", "/static/app.js"):
        if not get(asset).strip():
            raise ValueError("Brakuje zasobu interfejsu WWW.")
    schema = get("/openapi.json", True)
    parameters = schema["paths"]["/api/weather"]["get"]["parameters"]
    if {parameter["name"] for parameter in parameters if parameter["in"] == "query"} != {"city"}:
        raise ValueError("API ma przyjmować wyłącznie miasto, bez klucza w URL.")

    weather = get("/api/weather?" + urllib.parse.urlencode({"city": city}), True)
    if weather.get("source") != "openweathermap" or weather.get("units") != "metric":
        raise ValueError("Brak potwierdzonej odpowiedzi pogodowej OpenWeatherMap.")
    if not isinstance(weather.get("city"), str) or not weather["city"].strip():
        raise ValueError("Odpowiedź pogodowa nie zawiera miasta.")
    for name in ("temperature", "feels_like", "humidity", "pressure", "wind_speed"):
        value = weather.get(name)
        if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value):
            raise ValueError("Odpowiedź pogodowa nie zawiera kompletnych pomiarów.")
    if not isinstance(weather.get("observed_at"), int) or weather["observed_at"] <= 0:
        raise ValueError("Brakuje czasu pomiaru pogody.")
    return weather


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-url", required=True)
    parser.add_argument("--city", default="Warsaw")
    parser.add_argument("--ca-file", help="Zaufany certyfikat CA dla opcjonalnego HTTPS")
    args = parser.parse_args()
    try:
        weather = verify(args.base_url, args.city, args.ca_file)
    except urllib.error.HTTPError as error:
        print(f"TEST NIEUDANY: aplikacja zwróciła HTTP {error.code}. Sprawdź konfigurację i dostępność dostawcy.", file=sys.stderr)
        return 1
    except (OSError, ValueError, KeyError, TypeError, AttributeError, ssl.SSLError, urllib.error.URLError):
        print("TEST NIEUDANY: niepoprawna odpowiedź, brak WWW/API albo błąd połączenia.", file=sys.stderr)
        return 1
    print(f"OPENWEATHER_OK: {weather['city']}, {weather['temperature']} °C; WWW i API działają.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
