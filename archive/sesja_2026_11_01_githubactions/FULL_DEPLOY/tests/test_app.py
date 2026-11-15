from unittest.mock import Mock

import pytest
import requests
from fastapi.testclient import TestClient

import app as weather_app


@pytest.fixture(autouse=True)
def offline(monkeypatch):
    monkeypatch.delenv("OPENWEATHER_API_KEY", raising=False)
    monkeypatch.setattr(requests, "get", Mock(side_effect=AssertionError("Unexpected network call")))


@pytest.fixture
def client():
    return TestClient(weather_app.app)


def test_health_is_independent_of_external_services(client):
    assert client.get("/health").json() == {"status": "ok"}


def test_city_is_required(client):
    assert client.get("/weather").status_code == 422


def test_key_is_required(client):
    assert client.get("/weather", params={"city": "Warsaw"}).status_code == 400


def test_openweather_success_uses_environment_key(client, monkeypatch):
    monkeypatch.setenv("OPENWEATHER_API_KEY", "test-only-key")
    get = Mock(return_value=Mock(json=lambda: {
        "cod": 200, "main": {"temp": 21, "humidity": 65},
        "weather": [{"description": "clear sky"}],
    }))
    monkeypatch.setattr(requests, "get", get)
    response = client.get("/weather", params={"city": "Warsaw"})
    assert response.status_code == 200
    assert response.json()["source"] == "openweathermap"
    assert response.json()["temperature"] == 21
    assert get.call_args.kwargs["params"]["appid"] == "test-only-key"


@pytest.mark.parametrize("failure", ["timeout", "invalid_json", "not_found"])
def test_fallback_to_wttr(client, monkeypatch, failure):
    first = {
        "timeout": requests.Timeout(),
        "invalid_json": Mock(json=Mock(side_effect=ValueError())),
        "not_found": Mock(json=lambda: {"cod": "404"}),
    }[failure]
    monkeypatch.setattr(requests, "get", Mock(side_effect=[first, Mock(text='{"current_condition": []}')]))
    response = client.get("/weather", params={"city": "Warsaw", "api_key": "test-only"})
    assert response.status_code == 200
    assert response.json()["source"] == "wttr.in"


def test_both_services_unavailable(client, monkeypatch):
    monkeypatch.setattr(requests, "get", Mock(side_effect=requests.Timeout()))
    response = client.get("/weather", params={"city": "Warsaw", "api_key": "test-only"})
    assert response.status_code == 502
