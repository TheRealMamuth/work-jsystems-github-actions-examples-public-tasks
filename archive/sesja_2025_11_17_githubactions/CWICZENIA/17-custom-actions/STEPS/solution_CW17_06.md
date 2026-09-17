
# Rozwiązanie: Ćwiczenie 27 — Konfiguracja niestandardowej akcji Dockera (Ping URL)

Poniżej znajdziesz kompletne **krok‑po‑kroku** rozwiązanie w języku polskim. Zawiera minimalną wersję startową zgodną z treścią zadania oraz wersję rozszerzoną, która faktycznie „pinguje” URL, czeka między próbami i kończy się statusem błędu, jeśli nie uzyska kodu 200 w limicie prób. Na końcu dołączona jest checklista.

Źródło ćwiczenia: fileciteturn12file0

---

## 1) Struktura katalogów

Utwórz strukturę katalogów na akcję Dockera:

```bash
mkdir -p .github/actions/docker-ping-url
```

---

## 2) `action.yaml` — metadane akcji

> Wersja minimalna (jak w zadaniu) + **od razu** przygotowane przekazanie parametrów do kontenera przez `args` (przyda się w wersji rozszerzonej).

**Plik:** `.github/actions/docker-ping-url/action.yaml`

```yaml
name: Ping URL
description: "Ping URL do momentu przekroczenia maksymalnej liczby prób. Jeśli status 200 nie pojawi się na czas – akcja kończy się błędem."

inputs:
  url:
    description: URL do pingowania
    required: true
  max_trials:
    description: Maksymalna liczba prób zanim akcja nie powiedzie się
    required: false
    default: '10'
  delay:
    description: Opóźnienie (sekundy) pomiędzy próbami
    required: false
    default: '5'

runs:
  using: docker
  image: Dockerfile
  args:
    - --url
    - ${{ inputs.url }}
    - --max-trials
    - ${{ inputs.max_trials }}
    - --delay
    - ${{ inputs.delay }}
```

> Uwaga: w wielu przykładach spotkasz wywołanie akcji lokalnej jako `uses: ./.github/actions/docker-ping-url` (z **kropką i ukośnikiem** na początku). Unikaj literówki `./github/...`.

---

## 3) Przygotowanie środowiska Pythona lokalnie (dla developmentu)

> To pomoże szybciej iterować lokalnie nad skryptem przed budową obrazu.

```bash
cd .github/actions/docker-ping-url
python -m venv venv
echo "venv" >> .gitignore
. venv/bin/activate
pip install "requests==2.31.0"
pip freeze > requirements.txt
```

---

## 4) Skrypt Pythona

### 4.1 Wersja startowa (z zadania)

**Plik:** `.github/actions/docker-ping-url/main.py`

```python
if __name__ == "__main__":
    print("Hello world")
```

### 4.2 Wersja rozszerzona (realne pingowanie)

Zastąp treść `main.py` kodem, który:
- parsuje `--url`, `--max-trials`, `--delay`,
- wykonuje zapytania `GET`,
- przerywa sukcesem przy **status_code == 200**,
- po wykorzystaniu limitu kończy się kodem wyjścia ≠ 0.

```python
import sys
import time
import argparse
import requests

def ping_url(url: str, max_trials: int, delay: float) -> int:
    for i in range(1, max_trials + 1):
        try:
            r = requests.get(url, timeout=10)
            print(f"[{i}/{max_trials}] GET {url} -> {r.status_code}")
            if r.status_code == 200:
                print("OK: Status 200 – strona dostępna.")
                return 0
        except requests.RequestException as e:
            print(f"[{i}/{max_trials}] Błąd zapytania: {e}")
        if i < max_trials:
            time.sleep(delay)
    print("NOK: Nie uzyskano statusu 200 w zadanej liczbie prób.")
    return 1

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", required=True)
    parser.add_argument("--max-trials", type=int, default=10)
    parser.add_argument("--delay", type=float, default=5.0)
    args = parser.parse_args()
    sys.exit(ping_url(args.url, args.max_trials, args.delay))
```

---

## 5) Obraz Dockera i ignorowanie zasobów lokalnych

**Plik:** `.github/actions/docker-ping-url/Dockerfile`

```dockerfile
FROM python:alpine3.19

# Zapewnij środowisko wykonawcze
WORKDIR /app

# Zależności do pingu
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Skrypt
COPY main.py ./

# Domyślna komenda
ENTRYPOINT ["python", "/app/main.py"]
```

**Plik:** `.github/actions/docker-ping-url/.dockerignore`

```
venv
```

---

## 6) Workflow — uruchomienie akcji Dockera

**Plik:** `.github/workflows/17-3-custom-actions-docker.yaml`  
**Nazwa workflow:** `17 – 3 – Custom Actions – Docker`

```yaml
name: 17 – 3 – Custom Actions – Docker

on:
  workflow_dispatch:
    inputs:
      url:
        type: string
        description: Adres URL do sprawdzenia
        default: 'https://www.google.com'

jobs:
  ping-url:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Ping URL (Docker Action)
        uses: ./.github/actions/docker-ping-url
        with:
          url: ${{ inputs.url }}
          # poniższe parametry są opcjonalne – jeśli chcesz, ustaw je jawnie:
          # max_trials: '10'
          # delay: '5'
```

---

## 7) Commit, push, uruchomienie

```bash
git add .github/actions/docker-ping-url         .github/workflows/17-3-custom-actions-docker.yaml
git commit -m "CW27: Docker Action ping URL (minimal + rozszerzona implementacja)"
git push
```

W GitHub UI przejdź do **Actions → 17 – 3 – Custom Actions – Docker → Run workflow**, wskaż `url` (lub użyj domyślnego) i uruchom.

---

## 8) Oczekiwane zachowanie i typowe pułapki

- **Sukces:** jeśli w którejkolwiek próbie serwer odpowie `200`, job kończy się powodzeniem.  
- **Błąd:** jeżeli w `max_trials` nie pojawi się `200`, akcja zwróci niezerowy kod wyjścia (job = failed).  
- **Literówka w ścieżce `uses`:** poprawna to **`./.github/actions/docker-ping-url`** (lokalna ścieżka do katalogu z `action.yaml`).  
- **Wersje bibliotek:** trzymaj `requirements.txt` w repo (deterministyczna budowa obrazu).  
- **Czas:** pamiętaj, że każda próba czeka `delay` sekund.

---

## 9) Checklista

- [ ] Utworzono `.github/actions/docker-ping-url/` z plikami: `action.yaml`, `main.py`, `requirements.txt`, `Dockerfile`, `.dockerignore`.  
- [ ] `action.yaml` definiuje wejścia `url`, `max_trials`, `delay` i `runs: using: docker` (z `image: Dockerfile` i `args`).  
- [ ] `requirements.txt` zawiera `requests==2.31.0`.  
- [ ] `main.py` (wersja rozszerzona) ping‑uje adres do skutku lub limitu prób.  
- [ ] `.dockerignore` zawiera `venv`.  
- [ ] Workflow `17-3-custom-actions-docker.yaml` poprawnie uruchamia lokalną akcję.  
- [ ] Przetestowano uruchomienie ręczne i zweryfikowano logi.

Powodzenia! 🚀
