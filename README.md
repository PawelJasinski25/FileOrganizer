# Skrypt do organizowania, analizowania i usuwania plików

Skrypt pozwala na zarządzanie plikami w katalogach w trzech głównych funkcjach:

* Organizowanie plików w zależności od daty ich utworzenia lub modyfikacji.
* Usuwanie plików w zadanym przedziale czasowym.
* Analiza plików w katalogu, w tym zdjęć, z wyciąganiem danych EXIF, takich jak model aparatu, czas naświetlania i przysłona.


## Wymagania
Aby uruchomić skrypt, należy zainstalować następujące narzędzia:

* exiftool


## Użycie

Program można uruchomić komendą :

`bash main.sh opcje`


## Opcje
* `--organize <katalog_źródłowy> <katalog_docelowy>` <br>
Organizowanie plików w katalogu źródłowym do katalogu docelowego w zależności od daty (roku i miesiąca). Pliki będą kopiowane do odpowiednich folderów rok/miesiac/zdjecia lub rok/miesiac/inne. Do folderu zdjecia trafiają pliki jpg|jpeg|png|tiff|raw. Do folderu inne wszystkie pozostałe. Jeżeli plik posiada dane exif to data jest ustalana na ich podstawie. W przeciwnym przypadku jest pobierana data systemowa pliku.

 * `--delete <katalog_źródłowy> <data_początkowa> <data_końcowa>` <br>
Usuwanie plików w katalogu źródłowym w zadanym przedziale dat (format: YYYY-MM-DD). Przedział jest traktowany jako zamknięty.

* `--analyze <katalog_źródłowy>` <br>
Analiza plików w katalogu źródłowym. Podawane są informacje o liczbie przetworzonych plików, zdjęć a także o najczęstszym modelu aparatu, przysłonie i czasie naświetlania zdjęcia.

* `--max-depth n` <br>
Określa maksymalną głębokość skanowania katalogów w przypadku operacji `--organize`, `--delete`  i `--analyze`. Jest to opcjonalny parametr.

* `--help` <br>
Wyświetla pomoc, opis komend i ich użycie.
