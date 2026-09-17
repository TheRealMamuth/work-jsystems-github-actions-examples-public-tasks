# Rozwiązanie ćwiczenia 05 – Używanie filtrów i typów aktywności

---

## Krok po kroku rozwiązanie

### 1. Tworzenie pierwszego workflow

1. Przejdź do katalogu `.github/workflows` w repozytorium.
2. Utwórz nowy plik o nazwie:
   ```bash
   05-1-filters-activity-types.yaml
   ```
3. Dodaj nazwę workflow:
   ```yaml
   name: "05 – 1 – Event Filters and Activity Types"
   ```
4. Skonfiguruj wyzwalacz `pull_request` z odpowiednimi filtrami i typami aktywności:
   ```yaml
   on:
     pull_request:
       types: [opened, synchronize]
       branches:
         - main
   ```
5. Dodaj jedno zadanie `echo`, które wyświetla komunikat w konsoli:
   ```yaml
   jobs:
     echo:
       runs-on: ubuntu-latest
       steps:
         - name: Show message
           run: echo "Running whenever a PR is opened or synchronized AND base branch is main."
   ```
6. Zatwierdź i wypchnij zmiany do repozytorium:
   ```bash
   git add .
   git commit -m "Add first workflow using filters and activity types"
   git push
   ```
7. W pliku `README.md` wprowadź drobną zmianę, np. dopisz komentarz, a następnie utwórz nową gałąź:
   ```bash
   git checkout -b pr-test-1
   git add README.md
   git commit -m "Test PR trigger"
   git push --set-upstream origin pr-test-1
   ```
8. Utwórz pull request z gałęzi `pr-test-1` do `main`.  
   Sprawdź w zakładce **Actions**, że workflow uruchomił się automatycznie i zakończył sukcesem.

---

### 2. Tworzenie drugiego workflow

1. W tym samym folderze `.github/workflows` utwórz plik o nazwie:
   ```bash
   05-2-filters-activity-types.yaml
   ```
2. Dodaj nazwę workflow:
   ```yaml
   name: "05 – 2 – Event Filters and Activity Types"
   ```
3. Skonfiguruj wyzwalacz `pull_request`, aby reagował tylko na zamknięcie PR (`closed`) w gałęzi `main`:
   ```yaml
   on:
     pull_request:
       types: [closed]
       branches:
         - main
   ```
4. Dodaj zadanie `echo`, które wyświetla komunikat w momencie zamknięcia PR:
   ```yaml
   jobs:
     echo:
       runs-on: ubuntu-latest
       steps:
         - name: Show message
           run: echo "Running whenever a PR is closed."
   ```
5. Zatwierdź i wypchnij zmiany:
   ```bash
   git add .
   git commit -m "Add second workflow for closed PR events"
   git push
   ```
6. Zamknij pull request utworzony w poprzednim kroku.  
   Następnie przejdź do zakładki **Actions** i sprawdź, że nowy workflow uruchomił się poprawnie po zamknięciu PR.

---

### 3. Zmiana wyzwalacza workflow

Aby uniknąć automatycznego uruchamiania workflow przy każdym zdarzeniu, zmień sekcję `on` na `workflow_dispatch` w obu plikach:

#### W pliku `05-1-filters-activity-types.yaml`
```yaml
on: workflow_dispatch
```

#### W pliku `05-2-filters-activity-types.yaml`
```yaml
on: workflow_dispatch
```

---

## Finalne wersje plików

### Plik `05-1-filters-activity-types.yaml`
```yaml
name: "05 – 1 – Event Filters and Activity Types"

on: workflow_dispatch

jobs:
  echo:
    runs-on: ubuntu-latest
    steps:
      - name: Show message
        run: echo "Running whenever a PR is opened or synchronized AND base branch is main."
```

### Plik `05-2-filters-activity-types.yaml`
```yaml
name: "05 – 2 – Event Filters and Activity Types"

on: workflow_dispatch

jobs:
  echo:
    runs-on: ubuntu-latest
    steps:
      - name: Show message
        run: echo "Running whenever a PR is closed."
```

---

## Dodatkowe uwagi

- Typy aktywności (`activity types`) pozwalają ograniczyć uruchamianie workflow do konkretnych zdarzeń w ramach jednego eventu.  
- Filtry zdarzeń (`event filters`) umożliwiają precyzyjne określenie gałęzi, dla których workflow ma się uruchamiać.  
- Zmienienie wyzwalacza na `workflow_dispatch` jest dobrą praktyką przy ćwiczeniach — pozwala uniknąć niepotrzebnego uruchamiania workflow przy każdej zmianie w repozytorium.  
- Zawsze możesz ręcznie uruchomić workflow z poziomu GitHub UI w zakładce **Actions**.

