# 🧩 Podpowiedzi: Jak zbudować Jenkins Pipeline krok po kroku

Ten dokument zawiera wskazówki, jakie elementy (bloki) należy wykorzystać w Jenkinsfile, aby poprawnie zrealizować zadanie.

---

## 🔹 1. Definicja pipeline

Użyj składni declarative:
```
pipeline {
    agent any
}
```

---

## 🔹 2. Sekcja environment

Zdefiniuj zmienne globalne:
- nazwa obrazu Docker
- ścieżka do aplikacji

```
environment {
    LOCAL_IMAGE_NAME = "..."
    WORKDIR = "..."
}
```

---

## 🔹 3. Sekcja stages

Wszystkie kroki wykonuj w blokach:
```
stages {
    stage('Nazwa') {
        steps {
            // komendy
        }
    }
}
```

---

## 🔹 4. Checkout kodu

Użyj:
```
checkout scm
```

---

## 🔹 5. Wykonywanie komend shell

Do uruchamiania poleceń systemowych:
```
sh '''
komendy
'''
```

---

## 🔹 6. Budowanie obrazu Docker

Wykorzystaj:
```
docker build -t NAZWA_OBRAZU ŚCIEŻKA
```

---

## 🔹 7. Praca z credentials

Do bezpiecznego pobierania sekretów:
```
withCredentials([string(credentialsId: 'ID', variable: 'ZMIENNA')]) {
    // użycie zmiennej
}
```

---

## 🔹 8. Uruchamianie kontenera

Polecenie:
```
docker run -d \
  --name NAZWA \
  -p PORTY \
  -e ZMIENNA=wartość \
  OBRAZ
```

---

## 🔹 9. Oczekiwanie na aplikację

Najprostsza opcja:
```
sleep 10
```

---

## 🔹 10. Test endpointu

Użyj curl:
```
curl -f URL
```

Dodatkowo:
```
set -e
```
aby pipeline przerwał się przy błędzie.

---

## 🔹 11. Logowanie do Docker Hub

```
echo "$HASLO" | docker login -u "$USER" --password-stdin
```

---

## 🔹 12. Operacje na zmiennych (script block)

Do przetwarzania danych (np. commit SHA):
```
script {
    def shortSha = env.GIT_COMMIT.take(7)
    env.SHORT_SHA = shortSha
}
```

---

## 🔹 13. Tagowanie obrazu

```
docker tag IMAGE NOWY_TAG
```

---

## 🔹 14. Push do Docker Hub

```
docker push IMAGE:TAG
```

---

## 🔹 15. Sekcja post

Obsługa po wykonaniu pipeline:

```
post {
    failure {
        // logi
    }
    always {
        // cleanup
    }
}
```

---

## 🔹 16. Debugowanie (logi kontenera)

```
docker logs NAZWA_KONTENERA
```

---

## 🔹 17. Sprzątanie (cleanup)

```
docker stop NAZWA || true
docker rm NAZWA || true
```

---

## 💡 Wskazówki końcowe

- Każdy etap powinien być osobnym `stage`
- Używaj czytelnych nazw etapów
- Zawsze zabezpieczaj cleanup (`|| true`)
- Trzymaj dane w `environment` lub `credentials`

---

Powodzenia 🚀
