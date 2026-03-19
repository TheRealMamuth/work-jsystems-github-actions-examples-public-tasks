# 🧪 Zadanie: Automatyzacja CI/CD dla aplikacji Docker z użyciem Jenkins Pipeline

## 🎯 Cel zadania
Celem zadania jest przygotowanie pipeline’u w Jenkins, który automatyzuje proces:
- budowy obrazu Docker,
- uruchomienia aplikacji w kontenerze,
- testowania endpointu API,
- publikacji obrazu w Docker Hub.

---

## 📦 Opis aplikacji
Repozytorium zawiera aplikację webową napisaną w Pythonie (Flask), która:
- udostępnia endpoint `/weather`,
- pobiera dane pogodowe z API OpenWeather,
- wymaga klucza API przekazanego jako zmienna środowiskowa.

📁 Lokalizacja aplikacji:
```
./CWICZENIA/06-context/pogoda_python_flusk
```

---

## ⚙️ Wymagania funkcjonalne

### 🔹 1. Checkout kodu
- Pipeline powinien pobrać kod z repozytorium (SCM).

---

### 🔹 2. Budowa obrazu Docker
- Zbuduj obraz Docker z katalogu aplikacji.
- Nadaj obrazowi nazwę:
```
python_pogoda:test
```

---

### 🔹 3. Uruchomienie kontenera
Uruchom kontener z następującą konfiguracją:
- nazwa: `pogoda_api`
- porty: `8000:8000`
- zmienna środowiskowa:
```
OPENWEATHER_API_KEY
```
- klucz API pobrany z Jenkins Credentials

---

### 🔹 4. Oczekiwanie na start aplikacji
- Dodaj opóźnienie (np. `sleep 10`), aby aplikacja mogła się uruchomić.

---

### 🔹 5. Test endpointu API
Wykonaj zapytanie:
```
http://localhost:8000/weather?city=Warsaw&api_key=<API_KEY>
```

Wymagania:
- użyj `curl -f`
- pipeline ma zakończyć się błędem, jeśli endpoint nie działa
- wyświetl komunikat sukcesu

---

### 🔹 6. Logowanie do Docker Hub
Zaloguj się używając danych z Jenkins Credentials:
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

---

### 🔹 7. Tagowanie obrazu
Otaguj obraz jako:
- `jenkinsfile` (lub `latest`)
- skrócony commit SHA (7 znaków)

📌 Przykład:
```
username/python_pogoda:jenkinsfile
username/python_pogoda:<short_sha>
```

---

### 🔹 8. Publikacja obrazu
- Wypchnij oba tagi do Docker Hub.

---

### 🔹 9. Obsługa błędów i cleanup

#### W przypadku błędu:
- wyświetl logi kontenera:
```
docker logs pogoda_api
```

#### Zawsze:
- zatrzymaj kontener
- usuń kontener

---

## 🔐 Wymagane Credentials w Jenkins
Pipeline musi korzystać z:
- `OPENWEATHER_API_KEY`
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

---

## 🧩 Wymagania techniczne
- użyj **Declarative Pipeline**
- wykorzystaj:
  - `environment`
  - `stages`
  - `withCredentials`
  - `post`

---

## ✅ Kryteria oceny
- poprawne działanie pipeline
- poprawne użycie credentials
- test endpointu działa
- obraz trafia do Docker Hub
- poprawna obsługa błędów

---

## ⭐ (Opcjonalnie)
- zamiast `sleep` użyj aktywnego sprawdzania API (retry)
- dodaj `HEALTHCHECK` w Dockerfile
- użyj taga `latest`
