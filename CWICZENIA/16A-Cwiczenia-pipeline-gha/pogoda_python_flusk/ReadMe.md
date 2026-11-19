# Pogodnie — WWW i API w jednym kontenerze Python + Nginx

Wpisz miasto na stronie WWW lub wywołaj API z parametrem `city`.
Klucz OpenWeatherMap zna wyłącznie serwer, który odczytuje go ze środowiska
uruchomionego kontenera. Obraz buduje się bez klucza.

Pełne zadanie i konfiguracja GitHub Actions:
[FAZA-1 — instrukcja krok po kroku](../FAZA-1/README.md).

## Uruchomienie lokalne przez HTTP

W tym katalogu zbuduj obraz:

```bash
docker build -t pogoda-local .
```

W Bashu wczytaj prawdziwy klucz bez umieszczania go w historii poleceń:

```bash
read -r -s -p 'Klucz OpenWeatherMap: ' OPENWEATHER_API_KEY
export OPENWEATHER_API_KEY
printf '\n'
docker run -d --name pogoda-local \
  -p 18090:8080 -e OPENWEATHER_API_KEY pogoda-local
```

- WWW: `http://localhost:18090/`
- API: `http://localhost:18090/api/weather?city=Warsaw`
- Dokumentacja API: `http://localhost:18090/docs`
- Gotowość procesu: `http://localhost:18090/healthz`

```bash
curl --fail --get --data-urlencode 'city=New York' \
  http://localhost:18090/api/weather
python3 start.py 'New York'
python3 tests/smoke_test.py --base-url http://localhost:18090 --city Warsaw
```

Ostatnie polecenie sprawdza działający kontener i wymaga prawdziwej odpowiedzi
OpenWeatherMap. Błędny klucz lub niedostępny dostawca oznacza nieudany test.
Alias `/weather?city=Warsaw` pozostaje dostępny. Użytkownik nie podaje klucza
w przeglądarce, argumentach klienta ani URL.

## Jak działa kontener

Nginx obsługuje port `8080`, a Uvicorn nasłuchuje na `127.0.0.1:8000`
w tej samej przestrzeni sieciowej kontenera. Port Pythona nie jest publikowany.
Proces startowy nadzoruje oba serwery, kończy kontener po ich awarii i obsługuje
zatrzymanie przez Dockera. Domyślny użytkownik obrazu nie jest rootem.

Opcjonalnie zamontuj certyfikat i klucz tylko do odczytu oraz ustaw
`TLS_CERT_FILE` i `TLS_KEY_FILE`. Nginx uruchomi wtedy dodatkowy port HTTPS `8443`,
a HTTP `8080` pozostanie dostępny. Dokładne polecenia i zaufanie certyfikatowi
opisano w kroku 17 instrukcji FAZA-1. Nie kopiuje się certyfikatów ani kluczy
prywatnych do obrazu.

## Testy kontraktu i błędów

```bash
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements-dev.txt
.venv/bin/python -m unittest discover -s tests -p 'test_*.py' -v
```

Te testy jednostkowe sprawdzają lokalnie kontrakt API, walidację miasta i ochronę
przed ujawnieniem klucza. Oddzielny test kontenera `tests/smoke_test.py`, używany
przez pipeline przed publikacją i po deployu, zawsze wywołuje prawdziwego dostawcę.
