"""Lokalne testy kontraktu i obsługi błędów; CI kontenera osobno wywołuje realne API."""

import copy
import os
import unittest
from unittest.mock import Mock, patch

import requests
from fastapi.testclient import TestClient

from app import app

PAYLOAD = {
    "cod": 200, "name": "Warszawa", "sys": {"country": "PL", "sunrise": 1731900000, "sunset": 1731930000},
    "main": {"temp": 8.2, "feels_like": 6.1, "humidity": 76, "pressure": 1012},
    "weather": [{"id": 803, "description": "pochmurnie", "icon": "04d"}],
    "wind": {"speed": 3.2}, "visibility": 10000, "clouds": {"all": 80},
    "dt": 1731910000, "timezone": 3600,
}


class WeatherTests(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(app)
        self.environment = patch.dict(os.environ, {"OPENWEATHER_API_KEY": "unit-test-key-only"})
        self.environment.start()
        self.addCleanup(self.environment.stop)

    def provider(self, status=200, data=None):
        return Mock(status_code=status, json=Mock(return_value=PAYLOAD if data is None else data))

    def test_homepage_static_and_health_are_available(self):
        self.assertIn('id="weather-form"', self.client.get("/").text)
        for path in ("/static/styles.css", "/static/app.js", "/healthz"):
            self.assertEqual(self.client.get(path).status_code, 200)

    def test_schema_accepts_city_only(self):
        parameters = self.client.get("/openapi.json").json()["paths"]["/api/weather"]["get"]["parameters"]
        self.assertEqual([parameter["name"] for parameter in parameters], ["city"])

    @patch("app.requests.get")
    def test_success_is_normalized_and_uses_runtime_key(self, get):
        get.return_value = self.provider()
        response = self.client.get("/api/weather", params={"city": " Warsaw ", "api_key": "must-not-override"})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["temperature"], 8.2)
        self.assertEqual(response.json()["source"], "openweathermap")
        self.assertEqual(get.call_args.kwargs["params"]["appid"], "unit-test-key-only")
        self.assertEqual(get.call_args.kwargs["params"]["q"], "Warsaw")
        self.assertNotIn("unit-test-key-only", response.text)
        self.assertNotIn("raw", response.json())

    @patch("app.requests.get")
    def test_missing_key_fails_without_contacting_provider(self, get):
        with patch.dict(os.environ, {"OPENWEATHER_API_KEY": ""}):
            self.assertEqual(self.client.get("/api/weather?city=Warsaw").status_code, 503)
        get.assert_not_called()

    @patch("app.requests.get")
    def test_invalid_key_has_no_fallback_or_secret_in_response(self, get):
        get.return_value = self.provider(status=401)
        response = self.client.get("/api/weather?city=Warsaw")
        self.assertEqual(response.status_code, 503)
        self.assertNotIn("unit-test-key-only", response.text)
        self.assertEqual(get.call_count, 1)

    @patch("app.requests.get")
    def test_unknown_city_and_provider_limit(self, get):
        for provider_status, api_status in ((404, 404), (429, 503), (500, 502)):
            get.return_value = self.provider(status=provider_status)
            self.assertEqual(self.client.get("/api/weather?city=missing").status_code, api_status)

    @patch("app.requests.get")
    def test_network_error_does_not_expose_provider_url_with_key(self, get):
        get.side_effect = requests.Timeout("https://provider.invalid/?appid=unit-test-key-only")
        response = self.client.get("/api/weather?city=Warsaw")
        self.assertEqual(response.status_code, 502)
        self.assertNotIn("appid", response.text)
        self.assertNotIn("unit-test-key-only", response.text)

    @patch("app.requests.get")
    def test_incomplete_and_nonfinite_weather_fail(self, get):
        for payload in ({"cod": 200}, {"cod": 401}, [], {"cod": 200, "weather": []}):
            get.return_value = self.provider(data=payload)
            self.assertEqual(self.client.get("/api/weather?city=Warsaw").status_code, 502)
        payload = copy.deepcopy(PAYLOAD)
        payload["main"]["temp"] = float("nan")
        get.return_value = self.provider(data=payload)
        self.assertEqual(self.client.get("/api/weather?city=Warsaw").status_code, 502)

    @patch("app.requests.get")
    def test_blank_city_is_rejected_before_provider_call(self, get):
        for params in ({}, {"city": " "}, {"city": "a" * 101}, {"city": "Warsaw\n"}):
            self.assertEqual(self.client.get("/api/weather", params=params).status_code, 422)
        get.assert_not_called()

    @patch("app.requests.get")
    def test_legacy_weather_route_uses_same_runtime_configuration(self, get):
        get.return_value = self.provider()
        self.assertEqual(self.client.get("/weather?city=Warsaw").status_code, 200)


if __name__ == "__main__":
    unittest.main()
