#  Zadanie: Jenkins Pipeline (wersja z lukami)

Uzupełnij poniższy Jenkinsfile, wpisując brakujące elementy w miejscach
oznaczonych `___`.

------------------------------------------------------------------------

##  Jenkinsfile

    pipeline {
        agent ___

        environment {
            LOCAL_IMAGE_NAME = "___"
            WORKDIR = "___"
        }

        stages {

            stage('Checkout') {
                steps {
                    ___
                }
            }

            stage('Build Docker image') {
                steps {
                    sh '''
                        docker build -t ___ ___
                    '''
                }
            }

            stage('Run container') {
                steps {
                    withCredentials([string(credentialsId: '___', variable: '___')]) {
                        sh '''
                            docker run -d \
                              --name ___ \
                              -p ___:___ \
                              -e ___=$___ \
                              ___
                        '''
                    }
                }
            }

            stage('Wait for API') {
                steps {
                    sh '''
                        echo "Czekam..."
                        sleep ___
                    '''
                }
            }

            stage('Test endpoint') {
                steps {
                    withCredentials([string(credentialsId: '___', variable: '___')]) {
                        sh '''
                            set -e
                            curl -f "___"
                        '''
                    }
                }
            }

            stage('Docker Hub Login') {
                steps {
                    withCredentials([
                        string(credentialsId: '___', variable: '___'),
                        string(credentialsId: '___', variable: '___')
                    ]) {
                        sh '''
                            echo "$___" | docker login -u "$___" --password-stdin
                        '''
                    }
                }
            }

            stage('Tag image') {
                steps {
                    script {
                        def shortSha = env.___.take(___)
                        env.___ = shortSha
                    }

                    sh '''
                        docker tag ___ ___:___
                    '''
                }
            }

            stage('Push image') {
                steps {
                    sh '''
                        docker push ___:___
                    '''
                }
            }
        }

        post {
            failure {
                sh '''
                    docker logs ___
                '''
            }

            always {
                sh '''
                    docker stop ___ || true
                    docker rm ___ || true
                '''
            }
        }
    }

------------------------------------------------------------------------

##  Wskazówki

-   `agent any` -- najczęściej używane
-   `checkout scm` -- pobranie repozytorium
-   port aplikacji: `8000`
-   endpoint testowy:

```{=html}
<!-- -->
```
    http://localhost:8000/weather?city=Warsaw&api_key=$API_KEY

-   commit SHA:

```{=html}
<!-- -->
```
    env.GIT_COMMIT.take(7)

------------------------------------------------------------------------

## 🎯 Cel

Po uzupełnieniu: - pipeline powinien się wykonać bez błędów - kontener
powinien działać - endpoint powinien zwrócić dane - obraz powinien
zostać wysłany do Docker Hub

------------------------------------------------------------------------

Powodzenia 🚀
