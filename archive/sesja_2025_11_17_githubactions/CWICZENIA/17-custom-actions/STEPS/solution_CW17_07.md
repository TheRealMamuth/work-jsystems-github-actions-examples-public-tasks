
# Rozwiązanie: Ćwiczenie 29 — Dodanie logiki Ping w Pythonie i rozszerzenie workflowu

Poniżej masz kompletne rozwiązanie **krok po kroku** (po polsku) spełniające wymagania zadania: rozbudowę workflowu `17-3-custom-actions-docker.yaml` o nowe wejścia oraz uzupełnienie logiki „pingowania” w skrypcie Pythona wykorzystywanym przez naszą **akcję Docker**.

---

## 1) Rozszerz workflow `17-3-custom-actions-docker.yaml` o wejścia i ich przekazanie

**Ścieżka:** `.github/workflows/17-3-custom-actions-docker.yaml`

Zastąp (lub uzupełnij) zawartość pliku poniższą wersją. Zmiany względem poprzedniej wersji:
- `url` ma teraz typ **choice** i dwie opcje: jedna działa (np. `https://www.google.com`), druga jest nieosiągalna (np. `http://127.0.0.1:9/` — port discard zazwyczaj zamknięty).
- dodano `max_trials` (string, domyślnie `'10'`) oraz `delay` (string, domyślnie `'5'`),
- **wszystkie** wejścia są poprawnie przekazane do akcji Dockera poprzez `with:` (co ustawia zmienne środowiskowe `INPUT_*` w kontenerze).

```yaml
name: 17 – 3 – Custom Actions – Docker

on:
  workflow_dispatch:
    inputs:
      url:
        type: choice
        description: Adres URL do sprawdzenia
        options:
          - https://www.google.com
          - http://127.0.0.1:9/
        default: https://www.google.com
      max_trials:
        type: string
        description: Maximum trials until action fails
        default: '10'
        required: false
      delay:
        type: string
        description: Delay in seconds between trials
        default: '5'
        required: false

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
          max_trials: ${{ inputs.max_trials }}
          delay: ${{ inputs.delay }}
```

> Uwaga: Dla akcji typu **Docker** GitHub automatycznie udostępni w kontenerze zmienne środowiskowe `INPUT_URL`, `INPUT_MAX_TRIALS`, `INPUT_DELAY` na podstawie wartości przekazanych w `with:` — dzięki temu skrypt Pythona może je odczytać bez konieczności przekazywania argumentów.

---

## 2) Uzupełnij skrypt Pythona o logikę Ping oraz funkcję `run()`

**Ścieżka:** `.github/actions/docker-ping-url/main.py`

W tej wersji skryptu:
- dodajemy funkcję `ping_url(url, delay, max_trials)`:
  - dopóki liczba prób jest **mniejsza** niż `max_trials`: wykonujemy żądanie; gdy `status_code == 200` → zwracamy `True`; w przeciwnym razie czekamy `delay` sekund i kontynuujemy,
  - gdy wyczerpano limit prób → zwracamy `False`;
- dodajemy funkcję `run()`:
  - czyta wartości wejść ze zmiennych środowiskowych: `INPUT_URL`, `INPUT_DELAY`, `INPUT_MAX_TRIALS`,
  - konwertuje typy i wywołuje `ping_url(...)`,
  - jeśli `ping_url` zwróci `False` → zgłasza wyjątek;
- w bloku głównym wywołujemy `run()`.

```python
import os
import time
import requests

def ping_url(url: str, delay: float, max_trials: int) -> bool:
    trials = 0
    while trials < max_trials:
        try:
            r = requests.get(url, timeout=10)
            print(f"[{trials+1}/{max_trials}] GET {url} -> {r.status_code}")
            if r.status_code == 200:
                print("OK: Status 200 – strona dostępna.")
                return True
        except requests.RequestException as e:
            print(f"[{trials+1}/{max_trials}] Błąd zapytania: {e}")
        trials += 1
        if trials < max_trials:
            time.sleep(delay)
    print("NOK: Nie uzyskano statusu 200 w zadanej liczbie prób.")
    return False

def run() -> None:
    # Odczyt wejść z ENV: INPUT_<NAZWA>
    url = os.environ.get("INPUT_URL", "").strip()
    delay_s = os.environ.get("INPUT_DELAY", "5").strip()
    max_trials_s = os.environ.get("INPUT_MAX_TRIALS", "10").strip()

    if not url:
        raise ValueError("Brak wymaganego wejścia: url (INPUT_URL).")

    try:
        delay = float(delay_s)
        max_trials = int(max_trials_s)
    except ValueError:
        raise ValueError("Nieprawidłowa wartość dla delay/max_trials – oczekiwano liczb.")

    ok = ping_url(url=url, delay=delay, max_trials=max_trials)
    if not ok:
        raise RuntimeError("Ping zakończony niepowodzeniem (brak statusu 200).")

if __name__ == "__main__":
    run()
```

> Jeśli wcześniej korzystałeś z wersji skryptu przyjmującej argumenty wiersza poleceń (`--url`, `--max-trials`, `--delay`), ta wersja jest **zamiennikiem** — czyta wartości z ENV zgodnie z wymaganiami ćwiczenia.

---

## 3) Commit, push i uruchomienie z UI

```bash
git add .github/workflows/17-3-custom-actions-docker.yaml         .github/actions/docker-ping-url/main.py
git commit -m "CW29: workflow inputs (choice/string) + logika ping w Pythonie + run() z ENV"
git push
```

Następnie uruchom ręcznie: **Actions → 17 – 3 – Custom Actions – Docker → Run workflow**.  
Przetestuj obie opcje `url` i obserwuj logi:
- dla istniejącej strony powinieneś przerwać pętlę szybko i zakończyć sukcesem,
- dla nieosiągalnego hosta po wykorzystaniu liczby prób zobaczysz błąd joba.

---

## 4) Checklista końcowa

- [ ] `url` w workflow ma typ **choice** (dwie opcje), dodano `max_trials` i `delay` z domyślnymi wartościami.  
- [ ] Wszystkie wejścia są przekazywane do akcji przez `with:`, co udostępnia **`INPUT_*`** w kontenerze.  
- [ ] Skrypt `main.py` zawiera funkcje `ping_url(...)` i `run()`, odczytuje ENV i zgłasza błąd przy niepowodzeniu.  
- [ ] Zmiany zacommitowane, wypchnięte; workflow uruchomiony z UI i przeanalizowane logi.

Powodzenia! 🚀
