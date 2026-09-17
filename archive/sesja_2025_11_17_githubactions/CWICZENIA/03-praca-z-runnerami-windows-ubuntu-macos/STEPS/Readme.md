# Rozwiązanie ćwiczenia 03 – Workflow Runners

---

## Krok po kroku rozwiązanie

### 1. Utworzenie pliku workflow
W katalogu głównym repozytorium przejdź do folderu `.github/workflows`.  
Utwórz nowy plik o nazwie:

```
03-workflow-runners.yaml
```

---

### 2. Nadanie nazwy workflow
W pliku dodaj pierwszą linijkę z nazwą workflow:

```yaml
name: "03 – Workflow Runners"
```

---

### 3. Dodanie wyzwalacza `push`
Na początku ćwiczenia workflow powinien reagować na zdarzenie `push`:

```yaml
on: push
```

---

### 4. Definicja trzech zadań (jobs)

#### a. Zadanie `ubuntu-echo`
Pierwsze zadanie uruchamia się na runnerze Ubuntu i wypisuje nazwę systemu operacyjnego:

```yaml
jobs:
  ubuntu-echo:
    runs-on: ubuntu-latest
    steps:
      - name: Show OS
        run: |
          echo "This job is running on an Ubuntu runner."
          echo "$RUNNER_OS"
```

#### b. Zadanie `windows-echo`
Drugie zadanie uruchamia się na runnerze Windows i również wypisuje system:

```yaml
  windows-echo:
    runs-on: windows-latest
    steps:
      - name: Show OS
        shell: bash
        run: |
          echo "This job is running on a Windows runner."
          echo "$RUNNER_OS"
```

#### c. Zadanie `mac-echo`
Trzecie zadanie uruchamia się na runnerze MacOS:

```yaml
  mac-echo:
    runs-on: macos-latest
    steps:
      - name: Show OS
        run: |
          echo "This job is running on a MacOS runner."
          echo "$RUNNER_OS"
```

---

### 5. Zmiana wyzwalacza na `workflow_dispatch`
Aby uniknąć automatycznego uruchamiania przy każdym pushu, zastąp `on: push` poniższym zapisem:

```yaml
on: workflow_dispatch
```

---

## Finalny plik `03-workflow-runners.yaml`

```yaml
name: "03 – Workflow Runners"

on: workflow_dispatch

jobs:
  ubuntu-echo:
    runs-on: ubuntu-latest
    steps:
      - name: Show OS
        run: |
          echo "This job is running on an Ubuntu runner."
          echo "$RUNNER_OS"

  windows-echo:
    runs-on: windows-latest
    steps:
      - name: Show OS
        shell: bash
        run: |
          echo "This job is running on a Windows runner."
          echo "$RUNNER_OS"

  mac-echo:
    runs-on: macos-latest
    steps:
      - name: Show OS
        run: |
          echo "This job is running on a MacOS runner."
          echo "$RUNNER_OS"
```

---

## Dodatkowe uwagi

- Runner MacOS jest znacznie droższy od Ubuntu i Windows – warto go używać tylko w razie potrzeby.  
- Zmienna `$RUNNER_OS` zwraca nazwę systemu, na którym uruchamiany jest dany job.
- W przypadku Windows należy jawnie ustawić powłokę `bash`, aby składnia zmiennych środowiskowych działała poprawnie.
