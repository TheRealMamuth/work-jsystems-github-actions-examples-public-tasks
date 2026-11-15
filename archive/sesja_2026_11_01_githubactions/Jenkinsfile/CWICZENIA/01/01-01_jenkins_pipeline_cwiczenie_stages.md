# Ćwiczenie: Podstawy składni Jenkins Pipeline

## Cel ćwiczenia

Celem ćwiczenia jest poznanie podstawowej składni Declarative Pipeline w
Jenkinsie oraz zrozumienie bloków: - pipeline - agent - stages - stage -
steps

------------------------------------------------------------------------

## Treść ćwiczenia

### Zadanie

Utwórz Jenkinsfile, który zawiera: - pipeline - agent any - stages - 4
etapy: - Przygotowanie - Budowanie - Testy - Wdrozenie

W każdym etapie użyj steps oraz echo.

------------------------------------------------------------------------

## Szablon

``` groovy
pipeline {
    agent any

    stages {
        stage('Przygotowanie') {
            steps {
                // uzupełnij
            }
        }

        stage('Budowanie') {
            steps {
                // uzupełnij
            }
        }

        stage('Testy') {
            steps {
                // uzupełnij
            }
        }

        stage('Wdrozenie') {
            steps {
                // uzupełnij
            }
        }
    }
}
```

------------------------------------------------------------------------

## Rozwiązanie

``` groovy
pipeline {
    agent any

    stages {
        stage('Przygotowanie') {
            steps {
                echo 'Start pipeline'
                echo 'Przygotowanie środowiska'
            }
        }

        stage('Budowanie') {
            steps {
                echo 'Pobieranie kodu'
                echo 'Budowanie aplikacji'
            }
        }

        stage('Testy') {
            steps {
                echo 'Uruchamianie testów'
                echo 'Testy zakończone'
            }
        }

        stage('Wdrozenie') {
            steps {
                echo 'Symulacja wdrożenia aplikacji'
            }
        }
    }
}
```

------------------------------------------------------------------------

## Pytania kontrolne

1.  Do czego służy blok pipeline?
2.  Co robi agent?
3.  Czym różni się stages od stage?
4.  Gdzie umieszczamy echo?
