
# Rozwiązanie: Ćwiczenie 20 — Eksploracja opcji `exclude` w macierzach (GitHub Actions)

Poniżej masz kompletne rozwiązanie **krok po kroku** w języku polskim. Zawiera gotowe fragmenty YAML, komendy Git oraz oczekiwane rezultaty po każdym etapie.

---

## 0) Kontekst

Wykorzystujemy job `include-example` dodany w poprzednich ćwiczeniach (macierz z kluczami: `color`, `shape`, `size`). Jeśli zaczynasz „na czysto”, skorzystaj z **wersji bazowej** poniżej, aby mieć punkt startowy.

**Wersja bazowa pliku** `.github/workflows/15-matrices.yaml` (fragment z jobem `include-example`):

```yaml
name: 15 – Working with Matrices

on:
  workflow_dispatch:

jobs:
  include-example:
    name: ${{ matrix.color }}-${{ matrix.shape }}-${{ matrix.size }}-opacity:${{ matrix.opacity }}
    runs-on: ubuntu-latest
    strategy:
      matrix:
        color: [red, green]
        shape: [circle, square]
        size:  [small, large]
        include:
          # przykładowy wpis z poprzedniego ćwiczenia
          - color: red
            shape: triangle
          # przykładowa dodatkowa własność spoza macierzy (może być pusta w większości kombinacji)
          - opacity: 50
    steps:
      - name: Dump matrix
        run: echo "${{ matrix.color }}-${{ matrix.shape }}-${{ matrix.size }}-opacity:${{ matrix.opacity }}"
```

> Uwaga: `include` może dodawać nowe kombinacje i *nowe pola* (np. `opacity`). Natomiast **`exclude` może odnosić się tylko do kluczy zdefiniowanych w macierzy** (tu: `color`, `shape`, `size`).

---

## 1) Dodanie `exclude` z wpisem `opacity: 75`

**Zmień** sekcję `strategy.matrix`, dodając **tymczasowo**:

```yaml
      matrix:
        color: [red, green]
        shape: [circle, square]
        size:  [small, large]
        include:
          - color: red
            shape: triangle
          - opacity: 50
        exclude:
          - opacity: 75
```

**Commit i push:**
```bash
git add .github/workflows/15-matrices.yaml
git commit -m "CW20: dodanie exclude z nieobsługiwanym kluczem opacity=75 (demonstracja błędu)"
git push
```

**Uruchom workflow ręcznie** (Actions → *15 – Working with Matrices* → *Run workflow*).

**Oczekiwany rezultat:**  
- **Błąd walidacji** workflow. `matrix.exclude` **musi** korzystać z kluczy zdefiniowanych w macierzy; `opacity` nie jest jednym z nich.  
- Przykładowy komunikat (może się różnić w szczegółach):  
  > *Workflow nie jest prawidłowy: `jobs.include-example.strategy.matrix.exclude[0]` zawiera nieznany klucz `opacity`. `exclude` może odwoływać się wyłącznie do kluczy zdefiniowanych w `matrix` (color/shape/size).*

---

## 2) Poprawka `exclude` oraz modyfikacja `include`

Zgodnie z zadaniem:
- **Usuń** wpis z `opacity` w `exclude`.
- **Dodaj** do `exclude` wpis z **dwoma parametrami**: `color: green` i `shape: circle`.
- **Dodaj** na **końcu tablicy** `include` wpis z **trzema parametrami**: `color: green`, `shape: circle`, `size: medium`.

Zaktualizowany fragment joba:

```yaml
  include-example:
    name: ${{ matrix.color }}-${{ matrix.shape }}-${{ matrix.size }}-opacity:${{ matrix.opacity }}
    runs-on: ubuntu-latest
    strategy:
      matrix:
        color: [red, green]
        shape: [circle, square]
        size:  [small, large]
        include:
          - color: red
            shape: triangle
          - opacity: 50
          # NOWY wpis (MUSI być na końcu):
          - color: green
            shape: circle
            size: medium
        exclude:
          - color: green
            shape: circle
    steps:
      - name: Dump matrix
        run: echo "${{ matrix.color }}-${{ matrix.shape }}-${{ matrix.size }}-opacity:${{ matrix.opacity }}"
```

**Commit i push:**
```bash
git add .github/workflows/15-matrices.yaml
git commit -m "CW20: poprawny exclude (green+circle) i include (green+circle+size:medium)"
git push
```

**Uruchom workflow ręcznie** i sprawdź rezultat.

---

## 3) Ile jobów powstanie i jakie kombinacje się pojawią?

Załóżmy **bazową** liczbę kombinacji bez `include`/`exclude`:  
- `2 (color) × 2 (shape) × 2 (size) = 8`.

Po modyfikacjach:
- `exclude: {color: green, shape: circle}` usuwa **dwie** bazowe kombinacje:  
  - `green-circle-small` oraz `green-circle-large`.  
- `include` dodaje **nową** kombinację spoza macierzy bazowej (bo `size: medium` nie było w liście):  
  - `green-circle-medium`.

**Łącznie:** `8 - 2 + 1 = 7` jobów.

**Oczekiwana lista kombinacji (przykładowe nazwy z kroku `Dump matrix`):**
- `red-circle-small`, `red-circle-large`
- `red-square-small`, `red-square-large`
- `green-square-small`, `green-square-large`
- `green-circle-medium`  ⟵ dodane przez `include`

> Jeśli miałeś dodatkowe wpisy `include` z poprzednich ćwiczeń (np. `shape: triangle` bez `size`), w logach zobaczysz również takie komba – ich liczba zależy od Twojej dokładnej konfiguracji. Powyższe wyliczenie 7 dotyczy **samej** bazy 2×2×2 zmodyfikowanej przez pokazaną parę `include`/`exclude`.

---

## 4) Dlaczego pierwszy wariant z `opacity: 75` w `exclude` był błędny?

- `include` może **dodawać** nowe pola do konkretnych kombinacji (np. `opacity`).
- `exclude` służy do **wykluczania istniejących kombinacji macierzy** i może używać **wyłącznie** kluczy zdefiniowanych w `matrix` (tu: `color`, `shape`, `size`).  
- Dlatego próba użycia `opacity` w `exclude` powoduje błąd walidacji workflow.

---

## 5) Checklista

- [ ] `exclude` odwołuje się **wyłącznie** do `color/shape/size`.  
- [ ] `include` zawiera nowy wpis `{ color: green, shape: circle, size: medium }` dodany **na końcu**.  
- [ ] Workflow uruchamia się poprawnie po poprawkach.  
- [ ] W logach widać **7** jobów (dla czystej bazy 2×2×2), w tym `green-circle-medium` oraz brak `green-circle-small/large`.  
- [ ] Dodatkowe wpisy `include` z wcześniejszych ćwiczeń mogą zwiększyć liczbę jobów – to oczekiwane.

Powodzenia! 🚀
