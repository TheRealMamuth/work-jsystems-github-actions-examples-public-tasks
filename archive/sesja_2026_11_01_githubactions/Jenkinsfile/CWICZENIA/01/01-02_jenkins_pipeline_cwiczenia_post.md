# Ćwiczenie: Blok `post` w Jenkins Pipeline

## Cel ćwiczenia

Celem ćwiczenia jest poznanie działania bloku `post` w Jenkins
Declarative Pipeline oraz zrozumienie jego zastosowania do obsługi
wyników wykonania pipeline.

Blok `post` pozwala wykonać określone akcje w zależności od wyniku
pipeline lub etapu.

------------------------------------------------------------------------

## Treść ćwiczenia

### Zadanie

Utwórz Jenkinsfile, który zawiera:

-   pipeline
-   agent any
-   stages (minimum 2 etapy)
-   blok `post` na poziomie całego pipeline

------------------------------------------------------------------------

## Wymagania

### Etapy:

1.  `Build`
    -   echo "Budowanie aplikacji"
2.  `Test`
    -   echo "Uruchamianie testów"

------------------------------------------------------------------------

### Blok `post` (pipeline-level)

Dodaj obsługę:

-   always → echo "Pipeline zakończony"
-   success → echo "Pipeline zakończony sukcesem"
-   failure → echo "Pipeline zakończony błędem"

------------------------------------------------------------------------

## Szablon

``` groovy
pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                // uzupełnij
            }
        }

        stage('Test') {
            steps {
                // uzupełnij
            }
        }
    }

    post {
        always {
            // uzupełnij
        }
        success {
            // uzupełnij
        }
        failure {
            // uzupełnij
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
        stage('Build') {
            steps {
                echo 'Budowanie aplikacji'
            }
        }

        stage('Test') {
            steps {
                echo 'Uruchamianie testów'
            }
        }
    }

    post {
        always {
            echo 'Pipeline zakończony'
        }
        success {
            echo 'Pipeline zakończony sukcesem'
        }
        failure {
            echo 'Pipeline zakończony błędem'
        }
    }
}
```

------------------------------------------------------------------------

## Rozszerzenie ćwiczenia

### Zadanie dodatkowe

Dodaj blok `post` wewnątrz jednego ze stage (np. `Test`), który:

-   always → echo "Stage Test zakończony"
-   success → echo "Testy przeszły poprawnie"
-   failure → echo "Testy nie powiodły się"

------------------------------------------------------------------------

## Rozwiązanie rozszerzone

``` groovy
pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                echo 'Budowanie aplikacji'
            }
        }

        stage('Test') {
            steps {
                echo 'Uruchamianie testów'
            }
            post {
                always {
                    echo 'Stage Test zakończony'
                }
                success {
                    echo 'Testy przeszły poprawnie'
                }
                failure {
                    echo 'Testy nie powiodły się'
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline zakończony'
        }
        success {
            echo 'Pipeline zakończony sukcesem'
        }
        failure {
            echo 'Pipeline zakończony błędem'
        }
    }
}
```

------------------------------------------------------------------------

## Omówienie

### 1. Blok `post`

Blok `post` służy do wykonywania akcji po zakończeniu pipeline lub
stage.

Może zawierać m.in.: - always -- zawsze się wykona - success -- tylko
przy sukcesie - failure -- tylko przy błędzie

------------------------------------------------------------------------

### 2. Gdzie można używać `post`?

-   na poziomie całego pipeline
-   wewnątrz konkretnego stage

------------------------------------------------------------------------

## Pytania kontrolne

1.  Kiedy wykonuje się blok `always`?
2.  Czym różni się `success` od `failure`?
3.  Czy można mieć blok `post` w stage?
4.  Czy blok `post` może istnieć bez `stages`?
