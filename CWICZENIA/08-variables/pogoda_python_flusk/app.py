import os
from typing import Optional

import requests
from fastapi import FastAPI, HTTPException, Query

app = FastAPI(
    title="Pogoda API",
    description="Proste API do pobierania pogody z OpenWeatherMap z fallbackiem na wttr.in",
    version="0.1.0",
)


def get_openweather(city: str, api_key: str) -> dict | None:
    url = "https://api.openweathermap.org/data/2.5/weather"
    params = {
        "q": city,
        "appid": api_key,
        "units": "metric",
    }

    try:
        resp = requests.get(url, params=params, timeout=10)
    except requests.RequestException:
        return None

    try:
        data = resp.json()
    except ValueError:
        return None

    return data


def get_wttr(city: str) -> str:
    url = f"https://wttr.in/{city}"
    params = {"format": "j1"}  # JSON, możemy np. zwrócić dalej
    try:
        resp = requests.get(url, params=params, timeout=10)
        resp.raise_for_status()
        return resp.text
    except requests.RequestException:
        return ""


@app.get("/weather")
def weather(
    city: str = Query(..., description="Nazwa miasta"),
    api_key: Optional[str] = Query(
        default=None,
        description="Klucz API dla OpenWeatherMap. Jeśli brak – użyje ENV OPENWEATHER_API_KEY.",
    ),
):
    """
    Zwraca dane pogodowe z OWM, a jeśli miasto nie istnieje lub wystąpi błąd –
    próbuje zwrócić dane z wttr.in.
    """
    key = api_key or os.getenv("OPENWEATHER_API_KEY")
    if not key:
        raise HTTPException(
            status_code=400,
            detail="Brak klucza API. Podaj ?api_key=... albo ustaw zmienną OPENWEATHER_API_KEY.",
        )

    data = get_openweather(city, key)

    if data is None:
        # Fallback: wttr.in
        wttr_data = get_wttr(city)
        if not wttr_data:
            raise HTTPException(
                status_code=502,
                detail="Nie udało się pobrać danych ani z OpenWeatherMap, ani z wttr.in.",
            )
        return {
            "source": "wttr.in",
            "city": city,
            "raw": wttr_data,
        }

    cod = data.get("cod")
    if str(cod) == "404":
        # Miasto nie istnieje w OWM, spróbuj wttr.in
        wttr_data = get_wttr(city)
        if not wttr_data:
            raise HTTPException(
                status_code=404,
                detail=f"Miasto '{city}' nie znalezione w OWM, a wttr.in też zwrócił błąd.",
            )
        return {
            "source": "wttr.in",
            "city": city,
            "raw": wttr_data,
        }

    main_section = data.get("main") or {}
    weather_desc = ""
    if isinstance(data.get("weather"), list) and data["weather"]:
        weather_desc = data["weather"][0].get("description", "")

    return {
        "source": "openweathermap",
        "city": city,
        "temperature": main_section.get("temp"),
        "feels_like": main_section.get("feels_like"),
        "pressure": main_section.get("pressure"),
        "humidity": main_section.get("humidity"),
        "description": weather_desc,
        "raw": data,
    }
