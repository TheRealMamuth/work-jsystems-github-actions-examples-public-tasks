# Kroki Zadanie 01

## Zaczynamy

Aby zacząć z github action należy utworzyć odpowiednią strukturę katalogów w naszym repozytorium.
Należy utworzyć katalog `.github/workflows/` w głównym katalogu repozytorium.

## Dodatki do Visual Studio Code
Aby ułatwić sobie pracę z plikami YAML, warto zainstalować w Visual Studio Code odpowiednie rozszerzenia.
Polecane rozszerzenia to:
- YAML by Red Hat
- GitHub Actions by GitHub

## Tworzymy pierwszy workflow

Aby utworzyć pierwszy workflow, należy dodać plik YAML do katalogu `.github/workflows/`. Możemy nazwać go `first-workflow.yml`. Nazwa nie ma znaczenia, ważne jest rozszerzenie `.yml` lub `.yaml`.
Oczywiście nazwa powinna nam coś mowić o tym, do czego dany workflow służy. Ale co do zasady, może to być dowolna nazwa np `main.yml`, `build.yml` itp.

Poniżej znajduje się przykładowa zawartość pliku `first-workflow.yml`, który definiuje prosty workflow uruchamiany przy każdym pushu do repozytorium:

```yaml
name: My First Workflow
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      - name: Run a one-line script
        run: echo Hello, world!
```

Rozłóżmy ten plik na części pierwsze:
- `name: My First Workflow` - nazwa naszego workflow, którą zobaczymy w interfejsie GitHub Actions.
- `on: [push]` - określa zdarzenie, które uruchamia workflow. W tym przypadku jest to każde `push` do repozytorium.
- `jobs:` - sekcja definiująca zadania (jobs) w naszym workflow.
- `build:` - nazwa zadania. Możemy mieć wiele zadań w jednym workflow.
- `runs-on: ubuntu-latest` - określa środowisko, na którym będzie uruchamiane zadanie. W tym przypadku jest to najnowsza wersja Ubuntu.
- `steps:` - sekcja definiująca kroki (steps) w zadaniu.
- `- name: Checkout code` - nazwa kroku.
- `uses: actions/checkout@v2` - używa gotowej akcji `actions/checkout`, która klonuje kod repozytorium.
- `- name: Run a one-line script` - nazwa kolejnego kroku.
- `run: echo Hello, world!` - uruchamia prosty skrypt, który wypisuje "Hello, world!" w konsoli.

## Rozwiązanie naszego zadania:

```yaml
name: 01 - Build Blocks

on:
  workflow_dispatch:

jobs:
  echo-hello:
    runs-on: ubuntu-latest
    steps:
      - name: Say Hello
        run: echo "Hello, World!"
```

- Teraz commit i push do repozytorium pliku `first-workflow.yml` (lub innej nazwy, którą wybraliśmy).
- Po wykonaniu pusha, przechodzimy do zakładki "Actions" w naszym repozytorium na GitHubie.
- Powinniśmy zobaczyć nasz pierwszy workflow o nazwie "My First Workflow" (lub inną nazwę, którą wybraliśmy).
- Klikamy na niego, aby zobaczyć szczegóły i historię uruchomień.
- Możemy kliknąć na ostatnie uruchomienie, aby zobaczyć logi i szczegóły wykonania naszego workflow.

```yaml
name: 01 - Build Blocks

on:
  workflow_dispatch:

jobs:
  echo-hello:
    runs-on: ubuntu-latest
    steps:
      - name: Say Hello
        run: echo "Hello, World!"
  echo-goodbye:
    runs-on: ubuntu-latest
    steps:
      - name: Failed Step
        run: |
          echo "I will fail now"
          exit 1
      - name: Say Goodbye
        run: |
          echo "This step will be skipped if the previous step fails"
```

- teraz commit i push do repozytorium pliku `first-workflow.yml` (lub innej nazwy, którą wybraliśmy).
- Po wykonaniu pusha, przechodzimy do zakładki "Actions" w naszym repozytorium na GitHubie.
- Powinniśmy zobaczyć nasz workflow o nazwie "My First Workflow" (lub inną nazwę, którą wybraliśmy).


