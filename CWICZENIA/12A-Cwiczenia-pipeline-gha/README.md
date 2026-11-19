# Ćwiczenie 12A — pipeline aplikacji pogodowej: inputs i outputs

## 1. Najpierw ustaw zmienne i sekrety repozytorium

W GitHub otwórz swoje repozytorium, następnie **Settings → Secrets and variables
→ Actions**. Konfigurację dodaj na poziomie repozytorium.

W zakładce **Variables** wybierz **New repository variable** i dodaj:

| Nazwa | Wartość | Zastosowanie |
| --- | --- | --- |
| `DOCKERHUB_USERNAME` | Twój login Docker Hub; przykład: `piotrskoska` | Konto publikujące i pobierające obraz |
| `DOCKER_IMAGE_NAME` | `python_pogoda` | Nazwa repozytorium obrazu Docker Hub |

W zakładce **Secrets** wybierz **New repository secret** i dodaj:

| Nazwa | Jaką wartość wpisać | Zastosowanie |
| --- | --- | --- |
| `DOCKERHUB_TOKEN` | Twój token Docker Hub z uprawnieniem publikowania i pobierania obrazu | Logowanie podczas publikacji oraz deploya |
| `OPENWEATHER_API_KEY` | Twój prawdziwy, aktywny klucz OpenWeatherMap | Test kontenera i działająca aplikacja |

Nie wpisuj wartości tokenów ani klucza API do YAML, plików aplikacji, opisu
commita lub parametrów uruchomienia workflow. Login i nazwa obrazu są zwykłymi
`vars`, a dane uwierzytelniające odczytuj przez `secrets`.

Upewnij się, że konto Docker Hub ma repozytorium `python_pogoda`, a podany token
może do niego publikować. Klucz pogodowy musi już działać; test wykonuje
rzeczywiste zapytanie do OpenWeatherMap i nie zastępuje błędu przykładową pogodą.

## 2. Sprawdź otrzymane pliki aplikacji

Gotowa aplikacja znajduje się w [pogoda_python_flusk](./pogoda_python_flusk/).
Masz już Dockerfile, konfigurację Nginxa, kod aplikacji i test
[tests/smoke_test.py](./pogoda_python_flusk/tests/smoke_test.py).

W tym ćwiczeniu przygotowujesz GitHub Actions. Nie musisz zmieniać Pythona,
interfejsu WWW, Dockerfile ani testów aplikacji.

Kontener udostępnia HTTP na porcie `8080`:

| Ścieżka | Co sprawdza lub udostępnia |
| --- | --- |
| `/` | WWW z formularzem miasta |
| `/healthz` | Gotowość aplikacji |
| `/api/weather?city=Warsaw` | API z rzeczywistą pogodą |
| `/openapi.json` | Opis interfejsu API |

Użytkownik podaje tylko miasto. Klucz API trafia do kontenera podczas
`docker run -e OPENWEATHER_API_KEY`; nie przekazuj go do budowania obrazu.

## 3. Zaplanuj pięć jobów i przepływ danych

Pracuj w pliku
[.github/workflows/12A-pogoda-input-output.yaml](../../.github/workflows/12A-pogoda-input-output.yaml).
GitHub uruchamia workflow z katalogu `.github/workflows`; aplikacja pozostaje
w katalogu tego ćwiczenia.

Przygotuj przepływ:

```text
prepare → build → test → publish → deploy
```

| Job | Zadanie | Dane przekazywane dalej |
| --- | --- | --- |
| `prepare` | Walidacja inputs i wyliczenie nazw oraz wyboru runnera | Job outputs opisujące konfigurację |
| `build` | Jednorazowe zbudowanie obrazu | Output `image_id` oraz artefakt `image.tar` |
| `test` | Uruchomienie dokładnie zbudowanego obrazu i test prawdziwego API | Sukces wymagany przez publikację |
| `publish` | Publikacja dokładnie przetestowanego obrazu | Job output `image_digest` |
| `deploy` | Pobranie opublikowanego obrazu i uruchomienie kontenera | Wynik testów oraz adres aplikacji w podsumowaniu |

Joby `prepare`, `build`, `test` i `publish` działają na `ubuntu-latest`.
Runner joba `deploy` wynika z inputu. Obraz budujesz tylko raz; publikacja
wykorzystuje obraz pobrany z artefaktu, bez ponownego budowania.

## 4. Dodaj ręczne uruchomienie i inputs

Użyj wyłącznie zdarzenia `workflow_dispatch`. Nie dodawaj `push` ani `schedule`.

Zdefiniuj parametry formularza **Run workflow**:

| Input | Typ | Wartość lub ograniczenie |
| --- | --- | --- |
| `first_name` | `string` | Wymagane imię; 1–30 znaków, człony z liter ASCII rozdzielone myślnikami, np. `Jan` |
| `last_name` | `string` | Wymagane nazwisko; 1–30 znaków, człony z liter ASCII rozdzielone myślnikami, np. `Kowalski` |
| `deployment_target` | `choice` | `github` albo `self-hosted`; domyślnie `github` |
| `city` | `string` | Domyślnie `Warsaw`; niepuste, do 100 znaków, bez znaków sterujących |
| `app_port` | `number` | Domyślnie `18800`; liczba całkowita od `1024` do `65535` |

W formularzu wpisuj imię i nazwisko bez polskich znaków, np. `Lukasz`,
`Zolc`. `Jan` oraz `Kowalski` mają dać identyfikator `jan-kowalski`.

Przekazuj surowe inputs do kroku przez `env`, a następnie waliduj je w kodzie
kroku. Przykład przekazania wartości:

```yaml
env:
  FIRST_NAME: ${{ inputs.first_name }}
  LAST_NAME: ${{ inputs.last_name }}
```

W skrypcie odczytuj zmienne środowiskowe. Nie wklejaj inputów bezpośrednio
do treści poleceń `run`.

## 5. Przygotuj outputs w jobie `prepare`

Po walidacji wylicz i zapisz do `$GITHUB_OUTPUT`:

| Output | Przykład lub znaczenie |
| --- | --- |
| `student_slug` | `jan-kowalski` |
| `image_tag` | `jan-kowalski-<pełny GITHUB_SHA>` |
| `sha_tag` | Pełny `GITHUB_SHA`, bez skracania |
| `container_name` | Nazwa kontenera uczestnika; stała dla self-hosted, unikalna dla przebiegu na GitHubie |
| `runner_labels` | JSON: `["ubuntu-latest"]` albo `["self-hosted","linux"]` |
| `app_port` | Zwalidowany port z inputu |
| `weather_city` | Zwalidowane miasto z inputu |
| `ci_image` | `cw12a-weather:ci-<pełny GITHUB_SHA>` |
| `deployment_target` | Zwalidowany cel: `github` albo `self-hosted` |

Na self-hosted nazwa ma postać `cw12a-<REPO_ID>-<student_slug>-prod`.
Na GitHubie zamiast `prod` zawiera `RUN_ID`, np.
`cw12a-<REPO_ID>-jan-kowalski-<RUN_ID>`. Stała nazwa na self-hosted pozwala
wymieniać kontener przy kolejnym uruchomieniu tego samego uczestnika
i odróżniać kontenery różnych repozytoriów.

Output kroku jest dostępny jako `steps.<id>.outputs.<nazwa>`. Aby przekazać
go do innego joba, wystaw go także w sekcji `outputs` joba.

W rozwiązaniu krok obliczający konfigurację ma `id: config`. Wystaw jego
wyniki na poziomie joba, np.:

```yaml
outputs:
  student_slug: ${{ steps.config.outputs.student_slug }}
  runner_labels: ${{ steps.config.outputs.runner_labels }}
```

W jobie korzystającym z tych danych dodaj `prepare` do `needs` i odczytaj
`needs.prepare.outputs.student_slug` lub inny wymagany output. Zależności
nie są automatycznie przechodnie: samo `needs: test` nie udostępnia
outputów joba `prepare`.

## 6. Zbuduj obraz i przekaż go jako artefakt

W jobie `build`:

1. Dodaj zależność od `prepare` i checkout repozytorium.
2. Zbuduj obraz z `CWICZENIA/12A-Cwiczenia-pipeline-gha/pogoda_python_flusk`.
3. Użyj nazwy z `needs.prepare.outputs.ci_image`.
4. Odczytaj identyfikator zbudowanego obrazu przez `docker image inspect`.
5. W kroku z `id: image` zapisz identyfikator jako output `image_id`
   i wystaw job output `image_id` przez `steps.image.outputs.image_id`.
6. Zapisz obraz przez `docker save` do `image.tar`.
7. Wyślij `image.tar` przez `actions/upload-artifact@v4` jako
   `cw12a-weather-image`, z retencją jednego dnia i `overwrite: true`,
   aby umożliwić ponowienie przebiegu.

Output `image_id` jest krótką informacją tekstową. Plik obrazu przekazujesz
artefaktem. Nie próbuj przesyłać zawartości `image.tar` przez outputs.

## 7. Przetestuj kontener z prawdziwym kluczem

W jobie `test` ustaw `needs` obejmujące `prepare` i `build`.

1. Pobierz artefakt `cw12a-weather-image`, wykonaj `docker load` i porównaj ID obrazu
   z `needs.build.outputs.image_id`.
2. Uruchom kontener testowy `cw12a-ci` z mapowaniem
   `127.0.0.1:18080:8080`. Sekret przekaż do środowiska kroku, a następnie
   do kontenera przez `-e OPENWEATHER_API_KEY`.
3. Poczekaj na odpowiedź `/healthz`, stosując ponowienia `curl`.
4. Uruchom istniejący `tests/smoke_test.py` z lokalnym adresem kontenera
   i miastem z `needs.prepare.outputs.weather_city`.
5. Przy błędzie pokaż logi kontenera, a w kroku z `if: always()` usuń
   kontener testowy.

Smoke test sprawdza formularz WWW, zasoby statyczne, gotowość, schemat API
i rzeczywiste dane pogodowe. Nie wystarczy sam udany start kontenera.

## 8. Opublikuj ten sam obraz w Docker Hub

Job `publish` musi zależeć od `prepare`, `build` i `test`.

1. Pobierz i załaduj ten sam artefakt `image.tar`.
2. Ponownie sprawdź zgodność ID z outputem joba `build`.
3. Zaloguj się do Docker Hub przez `vars.DOCKERHUB_USERNAME`
   i `secrets.DOCKERHUB_TOKEN`.
4. Nadaj obrazowi dwa tagi i wypchnij oba do rejestru.
5. W kroku z `id: release` zapisz digest jako output `image_digest`.
   Wystaw job output `image_digest` przez `steps.release.outputs.image_digest`.

Dla uczestnika Jan Kowalski wynik ma postać:

```text
<DOCKERHUB_USERNAME>/python_pogoda:jan-kowalski-<pełny GITHUB_SHA>
<DOCKERHUB_USERNAME>/python_pogoda:<pełny GITHUB_SHA>
```

Pierwszy tag łączy dane uczestnika z commitem. Drugi jest samym pełnym SHA.
Nie zamieniaj ich na `latest`, skrócone SHA ani sam identyfikator uczestnika.

Do następnego joba przekazuj sam digest `sha256:...`. Nazwę repozytorium
obrazu składaj ze wspólnych `vars`. Output nie powinien zawierać tokenu,
klucza API ani innych sekretów.

## 9. Wybierz runner deploya na podstawie outputu

Job `deploy` ustawia `needs: [prepare, publish]`. Pobiera digest przez
`needs.publish.outputs.image_digest`, a runner wybiera z JSON wyliczonego
przez `prepare`:

```yaml
runs-on: ${{ fromJSON(needs.prepare.outputs.runner_labels) }}
```

`runner_labels` jest stringiem zapisanym w output, a `fromJSON` zamienia go
w listę etykiet oczekiwaną przez `runs-on`.

| Input `deployment_target` | Runner deploya | Co dzieje się z aplikacją |
| --- | --- | --- |
| `github` | `ubuntu-latest` | Tymczasowa weryfikacja na runnerze GitHuba; kontener jest usuwany na końcu joba |
| `self-hosted` | `[self-hosted, linux]` | Kontener pozostaje na hoście po zakończeniu joba |

Nie potrzebujesz dodatkowej własnej etykiety runnera. W trybie self-hosted
repozytorium musi jednak mieć dostępny runner Linux z etykietami `self-hosted`
i `linux`.

## 10. Przygotuj self-hosted runner, jeśli wybierasz trwały deploy

Na hoście runnera muszą działać Docker, Python 3 i `curl`. Konto usługi
runnera musi mieć uprawnienia do wykonywania poleceń Dockera. Host potrzebuje
dostępu do Docker Hub i OpenWeatherMap.

Dla każdego uczestnika na wspólnym hoście wybierz inny wolny `app_port`,
np. `18800`, `18801`, `18802`. Różne nazwy kontenerów nie pozwalają
równocześnie używać tego samego portu hosta.

Jeśli chcesz otworzyć WWW z własnego komputera, port musi być również
dostępny w regułach sieciowych i firewallu hosta. Nie zmieniaj ustawień
cudzych kontenerów ani nie usuwaj ich, aby zwolnić port.

## 11. Wykonaj deploy opublikowanego obrazu

W jobie `deploy`:

1. Przygotuj prywatny, tymczasowy katalog `DOCKER_CONFIG` i zaloguj się
   do Docker Hub.
2. Złóż referencję `<login>/<nazwa_obrazu>@<digest_z_publish>`.
3. Pobierz obraz przez `docker pull`, zanim usuniesz dotychczasowy kontener.
4. Sprawdź dokładnie nazwę kontenera przekazaną z `prepare`, uwzględniając
   także zatrzymane kontenery. Jeśli istnieje, usuń tylko ten kontener.
5. Uruchom nowy kontener z kluczem API przekazanym wyłącznie podczas startu.
6. Sprawdź `/healthz`, stan kontenera i ponownie wykonaj smoke test WWW/API
   z rzeczywistą pogodą.

W trybie `github` opublikuj port wyłącznie na loopback runnera:
`127.0.0.1:<app_port>:8080`. W trybie `self-hosted` użyj
`<app_port>:8080` oraz `--restart unless-stopped`.

Dodaj współbieżność joba według docelowego kontenera i
`cancel-in-progress: false`, aby dwa deploye tej samej aplikacji nie wymieniały
kontenera jednocześnie. Konfiguracja nie wykonuje automatycznego rollbacku.

W obu trybach końcowy krok z `if: always()` wylogowuje Docker Hub i usuwa
tymczasową konfigurację logowania. Nie usuwaj pozostałych konfiguracji Dockera
użytkownika runnera.

W trybie `github` usuń również kontener, także po błędzie. W trybie
`self-hosted` pozostaw kontener do dalszego korzystania lub diagnostyki;
błąd testu musi nadal oznaczać niepowodzenie joba.

## 12. Użyj outputu kroku do zbudowania podsumowania

Krok weryfikujący deploy ma `id: ready` i zapisuje `base_url` do
`$GITHUB_OUTPUT`. Kolejne kroki odczytują `steps.ready.outputs.base_url`:
najpierw wykonują smoke test, a potem zapisują czytelne podsumowanie do
`$GITHUB_STEP_SUMMARY`. To output kroku wewnątrz jednego joba; nie trzeba
wystawiać dodatkowego job output.

Adres lokalny, np. `http://127.0.0.1:18800`, służy pipeline do testów.
Nie jest adresem dostępnym z Twojego komputera.

Po udanym deployu self-hosted otwórz:

```text
http://<adres-IP-lub-nazwa-hosta-runnera>:18800/
http://<adres-IP-lub-nazwa-hosta-runnera>:18800/api/weather?city=Warsaw
```

Zastąp `18800` wartością wybranego inputu. Możesz użyć adresu IP; domena
nie jest wymagana. W tym ćwiczeniu aplikacja działa przez HTTP.

Tryb `github` nie publikuje trwałego adresu WWW. Po zakończeniu joba runner
GitHuba i kontener nie stanowią hostingu aplikacji.

## 13. Uruchom i sprawdź pipeline

1. Zapisz workflow w podanej ścieżce i udostępnij go na GitHubie. Aby formularz
   ręcznego uruchomienia był dostępny, workflow musi znajdować się także na
   domyślnej gałęzi repozytorium.
2. Otwórz **Actions**, wybierz workflow ćwiczenia i kliknij **Run workflow**.
3. Wskaż gałąź, wpisz swoje imię i nazwisko, wybierz `github`, miasto oraz port.
4. Potwierdź sukces wszystkich pięciu jobów. Odczytaj podsumowanie deploya.
5. W Docker Hub sprawdź dwa tagi z pełnym SHA commita uruchomienia.
6. Przy dostępnym własnym runnerze uruchom ponownie z `self-hosted` i wolnym
   portem. Otwórz WWW oraz endpoint API pod adresem hosta.
7. Powtórz uruchomienie self-hosted z tym samym uczestnikiem i portem.
   Pipeline ma zastąpić poprzedni kontener, bez błędu zajętej nazwy.

Zwróć uwagę, że dwa przebiegi dla tego samego commita mają te same tagi obrazu.
Zmiana commita zmienia pełne SHA w obu tagach.

## 14. Sprawdź, czego używasz do przekazywania danych

| Mechanizm | Zakres | Przykład z ćwiczenia |
| --- | --- | --- |
| `inputs` | Parametry ręcznego uruchomienia | Imię, nazwisko, cel deploya, miasto i port |
| Step output | Dane z kroku do kolejnego kroku tego samego joba | `base_url` z weryfikacji do podsumowania |
| Job output | Dane tekstowe pomiędzy jobami powiązanymi przez `needs` | `student_slug`, `runner_labels`, `image_id`, digest |
| Artifact | Pliki pomiędzy jobami | `image.tar` z dokładnie zbudowanym obrazem |
| `env` / `$GITHUB_ENV` | Zmienne procesu lub kolejnych kroków tego samego joba | Konfiguracja poleceń i ścieżka tymczasowego logowania |
| `vars` | Stała, jawna konfiguracja repozytorium | Login i nazwa obrazu Docker Hub |
| `secrets` | Dane uwierzytelniające | Token rejestru i klucz OpenWeatherMap |

Nie zapisuj sekretów do outputs ani artefaktów. Klucz OpenWeatherMap jest
potrzebny w runtime kontenera testowego i docelowego, nie w jobie `build`.

Zadanie jest ukończone, gdy publikowany obraz ma to samo ID co obraz testowy,
ma oba wymagane tagi, deploy używa opublikowanego digestu, a WWW i prawdziwe
API przechodzą testy. Dodatkowo musi działać wybór runnera przez output
oraz ponowny deploy własnego kontenera na self-hosted.

Dokumentacja mechanizmów użytych w zadaniu:
[ręczne uruchomienie i inputs](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow#defining-inputs-for-manually-triggered-workflows),
[outputs pomiędzy jobami](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/pass-job-outputs)
oraz [funkcja fromJSON](https://docs.github.com/en/actions/reference/workflows-and-actions/expressions#fromjson).
