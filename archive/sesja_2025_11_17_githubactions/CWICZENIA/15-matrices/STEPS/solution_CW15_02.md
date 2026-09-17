
# Rozwiązanie: Ćwiczenie 19 — Eksploracja opcji `include` w macierzach (GitHub Actions)

Poniżej znajdziesz kompletne rozwiązanie **krok po kroku** w języku polskim. Zawiera gotowe pliki YAML, komendy oraz wskazówki, jak obserwować wpływ `include` na generowane kombinacje.

---

## 0) Kontekst i plik workflow

W ćwiczeniu korzystamy z istniejącego pliku `.github/workflows/15-matrices.yaml` (z poprzedniego zadania). Wszystkie zmiany wykonujemy **w tym samym** pliku.

---

## 1) Dodanie joba `include-example` z bazową macierzą

**Cel:** Nowy job z macierzą trzech parametrów: `color`, `shape`, `size` oraz pierwszym wpisem `include`, który wprowadza kombinację z trójkątem.

Skopiuj/uzupełnij w pliku `.github/workflows/15-matrices.yaml` poniższą sekcję (nie usuwając poprzednich jobów, np. `backwards-compatibility`):

```yaml
name: 15 – Working with Matrices

on:
  workflow_dispatch:

jobs:
  # ... (istniejące joby, np. backwards-compatibility)

  include-example:
    name: ${{ matrix.color }}-${{ matrix.shape }}-${{ matrix.size }}
    runs-on: ubuntu-latest
    strategy:
      matrix:
        color: [red, green]
        shape: [circle, square]
        size:  [small, large]
        include:
          - color: red
            shape: triangle
    steps:
      - name: Dummy step
        run: |
          echo "${{ matrix.color }}-${{ matrix.shape }}-${{ matrix.size }}"
```

**Wyjaśnienia:**  
- Bazowa macierz generuje kombinacje: `2 (color) × 2 (shape) × 2 (size) = 8`.  
- Wpis `include` dodaje **dodatkową** kombinację z `shape: triangle` i `color: red`. Ponieważ `size` nie jest wskazane, w tym scenariuszu warto mieć świadomość, że **niektóre pola mogą pozostać puste** — w nazwie joba i w wypisywanym ciągu pola bez wartości pojawią się jako puste segmenty (np. `red-triangle-`).

**Commit i uruchomienie:**

```bash
git add .github/workflows/15-matrices.yaml
git commit -m "CW19: job include-example z bazową macierzą i pierwszym include (triangle)"
git push
```
Uruchom workflow ręcznie (**Actions → 15 – Working with Matrices → Run workflow**) i **zobacz ile jobów powstało** oraz **jakie nazwy** zostały nadane (zwróć uwagę na wpis z `triangle`).

---

## 2) Dodanie wpisu `opacity: 50` i uwzględnienie go w nazwie oraz kroku

**Cel:** Rozszerzyć `include` o wpis ustawiający dodatkową właściwość `opacity`, a także dopisać ją do nazwy joba i do wypisywanego tekstu.

Zmień sekcję `include-example` na:

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
          - opacity: 50
          - color: red
            shape: triangle
    steps:
      - name: Dummy step
        run: |
          echo "${{ matrix.color }}-${{ matrix.shape }}-${{ matrix.size }}-opacity:${{ matrix.opacity }}"
```

**Komentarz:**  
- Pierwszy wpis `- opacity: 50` dodaje **osobną kombinację** (z samą `opacity`) lub może **nadpisać/uzupełnić** istniejące kombinacje, jeśli zdefiniujesz pełne dopasowanie w późniejszych krokach. Ponieważ w tym momencie `color/shape/size` nie są wprost wskazane, w powstałym jobie te wartości mogą być puste (wypisywanie i nazewnictwo nadal zadziała — puste segmenty będą widoczne).  
- Wpis z `triangle` nadal dodaje/uzupełnia kombinację dla `color: red` i `shape: triangle`.

**Commit i uruchomienie:**

```bash
git add .github/workflows/15-matrices.yaml
git commit -m "CW19: include opacity=50 i uzupełnienie nazwy/kroku o opacity"
git push
```

Uruchom ręcznie i policz, **ile jobów** powstało w praktyce oraz **jak wyglądają nazwy** (zwróć uwagę na segment `opacity:`).

---

## 3) Dodanie dwóch kolejnych wpisów tuż po `opacity: 50`

**Cel:** Zobaczyć, jak kolejne wpisy `include` mogą **nadpisywać** wartości z wcześniejszych wpisów.

Zaktualizuj `include` tak, aby wyglądało następująco (kolejność ma znaczenie!):

```yaml
        include:
          - opacity: 50
          - color: red
            opacity: 75
          - shape: circle
            opacity: 100
          - color: red
            shape: triangle
```

**Commit i uruchomienie:**

```bash
git add .github/workflows/15-matrices.yaml
git commit -m "CW19: dodatkowe wpisy include (red→opacity:75, circle→opacity:100)"
git push
```

Uruchom ręcznie i zweryfikuj:  
- **Które kombinacje** zostały wygenerowane?  
- **Jakie wartości `opacity`** pojawiły się w jobach z `color: red` albo `shape: circle`?  
- Zauważ, że **późniejsze wpisy** w `include` mogą **nadpisać** wartości z wcześniejszych — w zależności od tego, czy dopasowują te same kombinacje.

---

## 4) Przeniesienie wpisu `opacity: 50` na **koniec** listy `include`

**Cel:** Obserwacja efektu **zmiany kolejności** wpisów.

Zmień kolejność, aby `opacity: 50` było **ostatnie**:

```yaml
        include:
          - color: red
            opacity: 75
          - shape: circle
            opacity: 100
          - color: red
            shape: triangle
          - opacity: 50
```

**Commit i uruchomienie:**

```bash
git add .github/workflows/15-matrices.yaml
git commit -m "CW19: przeniesienie opacity:50 na koniec include (test nadpisywania przez kolejność)"
git push
```

Po uruchomieniu porównaj wyniki z poprzednim przebiegiem i odpowiedz:  
- Czy `opacity` dla wybranych kombinacji zostało **nadpisane** przez przesunięty wpis?  
- Które nazwy jobów (i wartości w `Dummy step`) uległy zmianie?

---

## 5) Wskazówki praktyczne i typowe pułapki

- `include` **może dodawać zupełnie nowe kombinacje** (także z polami spoza bazowej macierzy), jak i **nadpisywać istniejące**. **Kolejność wpisów ma znaczenie** — późniejsze wpisy mogą modyfikować to, co dodały wcześniejsze (jeżeli dotyczą tych samych kluczy).  
- Jeżeli dany wpis `include` nie określa wszystkich kluczy z bazowej macierzy, wartości **niezdefiniowane** mogą być **puste**. Dlatego w nazwach i echo używamy prostego łączenia, akceptując puste segmenty.  
- Jeżeli chcesz, aby dany wpis dotyczył **konkretnych przypadków** bazowej macierzy, podaj w nim **pełne dopasowanie** kluczy (np. `color`, `shape`, `size`), a następnie dodaj/zmień dodatkowe właściwości (np. `opacity`).  
- Testuj zmiany małymi krokami i obserwuj listę wygenerowanych zadań w interfejsie GitHub Actions.

---

## 6) Checklista końcowa

- [ ] `include-example` istnieje w `.github/workflows/15-matrices.yaml`.  
- [ ] Bazowa macierz zawiera `color` (red, green), `shape` (circle, square), `size` (small, large).  
- [ ] Wpis z `triangle` został dodany i jest widoczny w wynikach.  
- [ ] Dodano `opacity: 50`, a nazwa joba i `Dummy step` uwzględniają `opacity`.  
- [ ] Dodano wpisy `color: red, opacity: 75` oraz `shape: circle, opacity: 100` (sprawdzono efekty i nadpisywania).  
- [ ] Zmieniono kolejność, przenosząc `opacity: 50` na koniec — porównano różnice.

Powodzenia! 🚀
