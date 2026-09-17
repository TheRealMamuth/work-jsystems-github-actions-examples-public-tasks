
# Rozwiązanie: Ćwiczenie 33 — Zarządzanie współbieżnością na poziomie workflow (GitHub Actions)

Poniżej znajdziesz kompletne rozwiązanie **krok po kroku** w języku polskim. Obejmuje gotowy plik workflow, komendy do uruchomienia oraz omówienie oczekiwanego efektu współbieżności.
Źródło zadania: **CW19_01.md** (Managing Concurrency).

---

## 1) Plik workflow: `.github/workflows/19-1-concurrency.yaml`

Skopiuj poniższy YAML do nowego pliku **`.github/workflows/19-1-concurrency.yaml`**:

```yaml
name: 19 – 1 – Managing Concurrency

on:
  workflow_dispatch:

# Jeden wspólny "worek" współbieżności dla wszystkich uruchomień tego workflowu
# z tej samej gałęzi/refa. Wartości pobieramy dynamicznie:
#  - github.workflow  → nazwa workflow
#  - github.ref       → pełny ref (np. refs/heads/main)
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}

jobs:
  ping:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Ping URL
        uses: ./.github/actions/docker-ping-url
        with:
          # Prawidłowy, ale nieosiągalny adres (port DISCARD zwykle zamknięty)
          url: http://127.0.0.1:9/
          max_trials: '20'
          delay: '5'
```

**Dlaczego tak?**
- `concurrency.group` ustawia **wspólną grupę** dla uruchomień tego workflowu na danym `ref`. Dzięki temu **tylko jeden przebieg** jest wykonywany naraz w tej grupie, a kolejne czekają w kolejce (domyślne zachowanie, bo nie podajemy `cancel-in-progress`).  
- `github.workflow` i `github.ref` spełniają dokładnie wymaganie *„<nazwa workflow>-<git ref>”*.  
- Job `ping` korzysta z Twojej akcji Dockera `docker-ping-url`, która będzie wielokrotnie próbować „spingować” podany URL (20 prób, odstęp 5 s) — co ułatwia obserwację kolejki współbieżności.

---

## 2) Commit i push

Wykonaj w repozytorium:

```bash
git add .github/workflows/19-1-concurrency.yaml
git commit -m "CW33: concurrency na poziomie workflow (group = ${github.workflow}-${github.ref})"
git push
```

---

## 3) Test z UI

1. Wejdź w **Actions → 19 – 1 – Managing Concurrency**.  
2. Kliknij **Run workflow** kilka razy z kilkusekundowymi odstępami (np. 3–5 s).

**Czego się spodziewać?**
- Pierwsze uruchomienie zacznie się normalnie (krok *Ping URL* będzie zajmował runner ~1–2 min ze względu na 20 prób × 5 s).  
- Kolejne uruchomienia (na **tej samej gałęzi**) trafią do **kolejki** tej samej grupy współbieżności i **nie wystartują równolegle**.  
- Gdy aktywny przebieg dobiegnie końca, następny z kolejki ruszy.  
- Jeśli chcesz, aby **nowsze uruchomienia anulowały** wcześniejsze w toku, dodaj:
  ```yaml
  concurrency:
    group: ${{ github.workflow }}-${{ github.ref }}
    cancel-in-progress: true
  ```
  – wtedy poprzedni run zostanie przerwany, a najnowszy ruszy od razu.

---

## 4) Najczęstsze pułapki

- **Różne refy = różne grupy**: jeśli uruchomisz workflow na innej gałęzi (np. `feature/x`), utworzy się **inna** grupa i uruchomienia **mogą** biec równolegle względem `main`.  
- **Literałów nie mieszaj z ekspresjami**: trzymaj definicję `group` w całości w wyrażeniu `${{ ... }}` (jak powyżej).  
- **Nazwy/refs w logach**: aby łatwiej diagnozować, możesz dopisać krok echa:
  ```yaml
  - name: Debug info
    run: |
      echo "workflow=${{ github.workflow }}"
      echo "ref=${{ github.ref }}"
  ```

---

## 5) Checklista końcowa

- [ ] Plik `.github/workflows/19-1-concurrency.yaml` istnieje i ma `workflow_dispatch`.  
- [ ] Na top‑level ustawiono `concurrency.group: ${{ github.workflow }}-${{ github.ref }}`.  
- [ ] Job `ping` ma kroki: `checkout@v4` oraz `docker-ping-url` z `url=http://127.0.0.1:9/`, `max_trials=20`, `delay=5`.  
- [ ] Ręcznie wyzwolono kilka biegów; kolejne **ustawiały się w kolejce** (jeden aktywny, reszta oczekuje).  
- [ ] (Opcjonalnie) Przetestowano `cancel-in-progress: true` – nowe uruchomienia anulują poprzednie w tej samej grupie.
