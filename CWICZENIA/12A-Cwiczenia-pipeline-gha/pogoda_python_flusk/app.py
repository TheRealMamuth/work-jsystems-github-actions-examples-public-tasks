"""WWW i API pogody. Klucz dostawcy pochodzi wyłącznie ze środowiska procesu."""

import os
from pathlib import Path
from typing import Literal

import requests
from fastapi import FastAPI, HTTPException, Query, Response
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, ConfigDict, Field, ValidationError

BASE_DIR = Path(__file__).resolve().parent
PROVIDER_URL = "https://api.openweathermap.org/data/2.5/weather"
app = FastAPI(
    title="Pogodnie — WWW i API",
    description="Podaj miasto. Klucz API obsługuje wyłącznie serwer.",
    version="1.0.0",
)
app.mount("/static", StaticFiles(directory=BASE_DIR / "static"), name="static")


class Weather(BaseModel):
    model_config = ConfigDict(allow_inf_nan=False)

    city: str = Field(min_length=1)
    country: str
    temperature: float
    feels_like: float
    description: str = Field(min_length=1)
    humidity: int = Field(ge=0, le=100)
    pressure: int = Field(gt=0)
    wind_speed: float = Field(ge=0)
    visibility: int | None = Field(default=None, ge=0)
    clouds: int | None = Field(default=None, ge=0, le=100)
    condition_code: int
    is_day: bool
    observed_at: int = Field(gt=0)
    sunrise: int | None = Field(default=None, gt=0)
    sunset: int | None = Field(default=None, gt=0)
    timezone_offset: int = Field(ge=-86400, le=86400)
    source: Literal["openweathermap"] = "openweathermap"
    units: Literal["metric"] = "metric"


@app.get("/", include_in_schema=False)
def homepage() -> FileResponse:
    return FileResponse(BASE_DIR / "static" / "index.html")


@app.get("/healthz", tags=["Stan aplikacji"])
def health() -> dict:
    """Gotowość procesu, bez wywołania dostawcy pogody."""
    return {"status": "ok", "service": "pogoda", "version": "1.0.0"}


def fetch_weather(city: str) -> Weather:
    key = os.environ.get("OPENWEATHER_API_KEY", "").strip()
    if not key:
        raise HTTPException(503, "Serwis pogody nie jest jeszcze skonfigurowany. Skontaktuj się z administratorem.")
    try:
        provider = requests.get(
            PROVIDER_URL,
            params={"q": city, "appid": key, "units": "metric", "lang": "pl"},
            timeout=(5, 15),
        )
    except requests.RequestException:
        # Wyjątek requests może zawierać URL z kluczem. Nie zwracaj ani nie loguj go.
        raise HTTPException(502, "Nie udało się połączyć z dostawcą pogody. Spróbuj ponownie za chwilę.") from None
    if provider.status_code == 404:
        raise HTTPException(404, "Nie znaleziono miasta. Sprawdź pisownię lub dopisz kod kraju, np. Warsaw,PL.")
    if provider.status_code in (401, 403):
        raise HTTPException(503, "Dostawca pogody odrzucił konfigurację serwera. Skontaktuj się z administratorem.")
    if provider.status_code == 429:
        raise HTTPException(503, "Limit zapytań do pogody został osiągnięty. Spróbuj ponownie później.")
    if provider.status_code != 200:
        raise HTTPException(502, "Dostawca pogody jest chwilowo niedostępny. Spróbuj ponownie później.")
    try:
        data = provider.json()
        if not isinstance(data, dict) or str(data.get("cod")) != "200":
            raise ValueError("Niepoprawny kod odpowiedzi dostawcy")
        details = data["weather"][0]
        main = data["main"]
        system = data.get("sys", {})
        return Weather(
            city=data["name"], country=system.get("country", ""),
            temperature=main["temp"], feels_like=main["feels_like"],
            description=details["description"], humidity=main["humidity"],
            pressure=main["pressure"], wind_speed=data["wind"]["speed"],
            visibility=data.get("visibility"), clouds=data.get("clouds", {}).get("all"),
            condition_code=details["id"], is_day=not str(details.get("icon", "01d")).endswith("n"),
            observed_at=data["dt"], sunrise=system.get("sunrise"), sunset=system.get("sunset"),
            timezone_offset=data.get("timezone", 0),
        )
    except (ValueError, KeyError, IndexError, TypeError, AttributeError, ValidationError):
        raise HTTPException(502, "Dostawca zwrócił niepełne dane pogodowe. Spróbuj ponownie za chwilę.") from None


@app.get("/weather", response_model=Weather, include_in_schema=False)
@app.get("/api/weather", response_model=Weather, tags=["Pogoda"])
def weather(
    response: Response,
    city: str = Query(..., min_length=1, max_length=100, description="Nazwa miasta, opcjonalnie z kodem kraju"),
) -> Weather:
    if any(ord(character) < 32 for character in city):
        raise HTTPException(422, "Podaj poprawną nazwę miasta.")
    city = city.strip()
    if not city:
        raise HTTPException(422, "Podaj poprawną nazwę miasta.")
    response.headers["Cache-Control"] = "no-store"
    return fetch_weather(city)
