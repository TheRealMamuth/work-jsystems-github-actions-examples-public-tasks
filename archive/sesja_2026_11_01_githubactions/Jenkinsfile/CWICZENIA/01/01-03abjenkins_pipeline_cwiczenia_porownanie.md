# Ćwiczenia: Jenkins Pipeline na podstawie GitHub Actions

------------------------------------------------------------------------

## 🔹 Ćwiczenie 1 -- Pipeline z błędem

### Treść zadania

Zbuduj pipeline Jenkins, który:

-   składa się z dwóch etapów:
    -   `echo-hello`
    -   `echo-goodbye`
-   w etapie `echo-hello` wyświetla komunikat:
    -   `"Hello, World!"`
-   w etapie `echo-goodbye`:
    -   najpierw wyświetla komunikat `"I will fail"`
    -   następnie wykonuje polecenie, które kończy się błędem (`exit 1`)
    -   na końcu próbuje wyświetlić `"Goodbye!"`

------------------------------------------------------------------------

### Dodatkowe pytania

Odpowiedz:

-   Czy komunikat `"Goodbye!"` zostanie wyświetlony?
-   Czy pipeline zatrzyma się po błędzie?
-   Jak Jenkins reaguje na `exit 1`?

------------------------------------------------------------------------

## 🔹 Ćwiczenie 2 -- Pipeline bez błędu

### Treść zadania

Zbuduj pipeline Jenkins, który:

-   składa się z dwóch etapów:
    -   `echo-hello`
    -   `echo-goodbye`
-   w etapie `echo-hello` wyświetla:
    -   `"Hello, World!"`
-   w etapie `echo-goodbye`:
    -   wyświetla `"I will succeed now"`
    -   wykonuje polecenie zakończone sukcesem (`exit 0`)
    -   następnie wyświetla `"Goodbye!"`

------------------------------------------------------------------------

### Dodatkowe pytania

Odpowiedz:

-   Czym różni się `exit 0` od `exit 1`?
-   Czy wszystkie kroki zostały wykonane?
-   Jaki jest status pipeline?

------------------------------------------------------------------------

## 🔥 Zadanie porównawcze

Porównaj oba pipeline i odpowiedz:

1.  Co powoduje zatrzymanie pipeline?
2.  W którym przypadku wszystkie kroki się wykonują?
3.  Jak Jenkins sygnalizuje błąd?
4.  Jakie są różnice względem GitHub Actions?
