# Ćwiczenie: Jenkins Pipeline -- Docker Web CI

## Cel ćwiczenia

Celem ćwiczenia jest zbudowanie pełnego pipeline Jenkins, który: -
pobiera kod z repozytorium (checkout) - buduje obraz Docker - uruchamia
kontener - wykonuje testy HTTP - sprząta zasoby po wykonaniu

Ćwiczenie omawia każdy krok pipeline.

------------------------------------------------------------------------

## Zadanie główne

Zbuduj Jenkins Pipeline, który realizuje poniższe etapy:

1.  Checkout kodu z repozytorium (z użyciem sparse checkout)
2.  Sprawdzenie wersji narzędzi
3.  Budowanie obrazu Docker
4.  Cleanup przed uruchomieniem
5.  Uruchomienie kontenera
6.  Healthcheck HTTP
7.  Cleanup po zakończeniu

------------------------------------------------------------------------

## Etap 1: Checkout

### Cel

Pobranie tylko wybranego fragmentu repozytorium.

### Wymagania

-   branch: main
-   repo: GitHub
-   użyj sparse checkout (tylko jeden katalog)

### Kod do uzupełnienia

``` groovy
stage('Checkout') {
    steps {
        // uzupełnij checkout
    }
}
```

------------------------------------------------------------------------

## Etap 2: Wersje narzędzi

### Cel

Sprawdzenie czy Docker i curl są dostępne.

### Wymagania

-   użyj `dir()`
-   wykonaj polecenia:
    -   docker --version
    -   curl --version

------------------------------------------------------------------------

## Etap 3: Build obrazu

### Cel

Zbudowanie obrazu Docker na podstawie Dockerfile.

### Wymagania

-   użyj docker build
-   użyj zmiennych:
    -   IMAGE_NAME
    -   TAG

------------------------------------------------------------------------

## Etap 4: Pre-cleanup

### Cel

Usunięcie starego kontenera i zwolnienie portu.

### Wymagania

-   usuń kontener jeśli istnieje
-   zwolnij port (fuser)

------------------------------------------------------------------------

## Etap 5: Run kontenera

### Cel

Uruchomienie aplikacji w kontenerze Docker.

### Wymagania

-   użyj docker run
-   mapowanie portów HOST:CONTAINER
-   wyświetl docker ps

------------------------------------------------------------------------

## Etap 6: Healthcheck HTTP

### Cel

Sprawdzenie czy aplikacja działa.

### Wymagania

-   użyj curl
-   sprawdź:
    -   czy serwer odpowiada
    -   czy kod HTTP = 200

------------------------------------------------------------------------

## Etap 7: Healthcheck HTTP 2

### Cel

Dodatkowa walidacja aplikacji.

### Wymagania

-   sprawdź zawartość strony (grep)
-   sprawdź czy obrazek zwraca HTTP 200

------------------------------------------------------------------------

## Etap 8: Post (cleanup i logi)

### Cel

Wykonanie operacji niezależnie od wyniku pipeline.

### Wymagania

-   zawsze:
    -   pokaż logi kontenera
    -   usuń kontener
    -   usuń obraz

------------------------------------------------------------------------

## Wskazówki

-   używaj `environment` do zmiennych
-   używaj `dir()` dla working directory
-   używaj `post { always }` dla cleanup
-   pamiętaj o `set -euxo pipefail`

------------------------------------------------------------------------

## Pytania kontrolne

1.  Do czego służy `dir()`?
2.  Co robi `post { always }`?
3.  Co się stanie gdy docker build się nie powiedzie?
4.  Dlaczego robimy pre-cleanup?
5.  Jak działa healthcheck?

------------------------------------------------------------------------

## Zadanie dodatkowe

Zmodyfikuj pipeline tak, aby: - port był parametrem - tag był commit
sha - healthcheck miał timeout jako zmienną
