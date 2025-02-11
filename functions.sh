#!/bin/bash
#Autor: Paweł Jasiński

#Funkcja do sprawdzania czy katalog istnieje
check_directory_exists() {
    dir="$1"

    if [ ! -d "$dir" ]; then
        echo "Błąd: Katalog '$dir' nie istnieje." ;exit 1
    fi
}
#Funkcja do sprawdzająca prawa czytania
check_read_permission() {
    dir="$1"

    if [ ! -r "$dir" ]; then
        echo "Błąd: Brak uprawnień do odczytu w katalogu '$dir'."; exit 1
    fi
}
#Funkcja do sprawdzająca prawa pisania
check_write_permission() {
    dir="$1"

    if [ -d "$dir" ] && [ ! -w "$dir" ]; then
        echo "Błąd: Brak uprawnień do zapisu w katalogu '$dir'."
        exit 1
    fi    
}

# Funkcja walidująca argumenty przy opcji organize
validate_organize(){
    src_directory="$1"
    dest_directory="$2"

    if [ -z "$src_dir" ] || [ -z "$dest_dir" ]; then
        echo "Błąd: Brak wymaganych argumentów dla komendy 'organize'."; exit 1;
    fi
    check_directory_exists "$src_directory"
    check_read_permission "$src_directory"
    check_write_permission "$dest_directory"
}
# Funkcja walidująca argumenty przy opcji analyze
validate_analyze(){
    src_directory="$1"

    if [ -z "$src_dir" ]; then
        echo "Błąd: Brak wymaganych argumentów dla komendy 'analyze'." ; exit 1;
    fi
    check_directory_exists "$src_directory"
    check_read_permission "$src_directory"
}
# Funkcja walidująca argumenty przy opcji delete
validate_delete(){
    src_directory="$1"
    start_date="$2"
    end_date="$3"

    if [ -z "$src_dir" ] || [ -z "$start_date" ] || [ -z "$end_date" ]; then
        echo "Błąd: Brak wymaganych argumentów dla komendy 'delete'." ; exit 1;
    fi
    check_directory_exists "$src_directory"
    check_read_permission "$src_directory"
    validate_dates "$start_date" "$end_date"
}

# Funkcja do sprawdzania, czy podano poprawną datę
is_valid_date() {
    if [[ ! "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        return 1
    fi

    date -d "$1" >/dev/null 2>&1
    return $? 
}
# Funkcja sprawdzająca obie daty 
validate_dates() {
    start_date="$1"
    end_date="$2"

    if [ -n "$start_date" ]; then
        is_valid_date "$start_date" || { echo "Błąd: Niepoprawny format daty początkowej."; exit 1; }
    fi
    if [ -n "$end_date" ]; then
        is_valid_date "$end_date" || { echo "Błąd: Niepoprawny format daty końcowej."; exit 1; }
    fi
}
#Funkcja zwracająca datę pliku
get_file_date() {
    file="$1"
    if [[ "$file" =~ \.(jpg|jpeg|png|tiff|raw)$ ]]; then
        file_date=$(exiftool -DateTimeOriginal -d "%Y-%m-%d" "$file" 2>/dev/null | awk -F': ' '/Date\/Time Original/ {print $2}')

        if [[ $? -ne 0 || -z "$file_date" ]]; then
            file_date=$(stat --format=%y "$file" | cut -d' ' -f 1)
        fi
    else
        file_date=$(stat --format=%y "$file" | cut -d' ' -f 1)
    fi
    echo "$file_date"
}
#Funkcja zwracająca folder docelowy
set_dest_folder() {
    file="$1"
    file_date="$2"
    year=$(echo "$file_date" | cut -d'-' -f 1)
    month=$(echo "$file_date" | cut -d'-' -f 2)
    if [[ "$file" =~ \.(jpg|jpeg|png|tiff|raw)$ ]]; then
        dest_folder="$dest_dir/$year/$month/zdjecia"     
    else
        dest_folder="$dest_dir/$year/$month/inne"
    fi
    echo "$dest_folder"
}
#Funkcja przetwarzająca plik i kopiująca go do odpowiedniego folderu
process_file() {
    file="$1"
    dest_dir="$2"

    file_date=$(get_file_date "$file")
    dest_folder=$(set_dest_folder "$file" "$file_date")

    mkdir -p "$dest_folder" >/dev/null 2>&1 || { echo "Błąd: Nie można utworzyć katalogu '$dest_folder'."; return 1; }
    if ! cp -u "$file" "$dest_folder/"; then
        echo "Błąd: Nie udało się skopiować pliku '$file' do '$dest_folder'."
        return 1
    fi

    echo "Skopiowano '$file' do '$dest_folder'"
}


# Funkcja przetwarzająca katalog i organizująca pliki po dacie
organize_files() {
    src_dir="$1"
    dest_dir="$2"
    max_depth="$3"

    mkdir -p "$dest_dir" >/dev/null 2>&1 || { echo "Błąd: Nie można utworzyć katalogu '$dest_dir'."; return 1; }

    while IFS= read -r file; do
        process_file "$file" "$dest_dir"
    done < <(find "$src_dir" $( [ -z "$max_depth" ] || echo "-maxdepth $max_depth" ) -type f)
}

#Funkcja przetwarzająca katalog w celu usunięcia pliku
delete_files_in_range() {
    src_dir="$1"
    start_date="$2"
    end_date="$3"
    max_depth="$4"

    while IFS= read -r file; do
        delete_file_if_in_range "$file" "$start_date" "$end_date"
    done < <(find "$src_dir" $( [ -z "$max_depth" ] || echo "-maxdepth $max_depth" ) -type f)
}

# Funkcja do usuwania pliku, jeśli znajduje się w podanym przedziale czasowym
delete_file_if_in_range() {
    file="$1"
    start_date="$2"
    end_date="$3"

    file_date=$(get_file_date "$file")

    file_date_sec=$(date -d "$file_date" +%s)
    start_date_sec=$(date -d "$start_date" +%s)
    end_date_sec=$(date -d "$end_date" +%s)
  
    if [[ "$file_date_sec" -ge "$start_date_sec" && "$file_date_sec" -le "$end_date_sec" ]]; then
        rm "$file"
        if [[ $? -eq 0 ]]; then
            echo "Usunięto '$file'"
        else
            echo "Błąd: Nie udało się usunąć pliku '$file'" >&2
        fi
    fi
}


# Funkcja do znalezienia klucza z największą wartością w tablicy asocjacyjnej
find_max_in_array() {
    declare -n array="$1"
    max_key=""
    max_value=0

    for key in "${!array[@]}"; do
        if (( array["$key"] > max_value )); then
            max_value=${array["$key"]}
            max_key="$key"
        fi
    done

    echo "$max_key: $max_value"
}


# Funkcja do analizowania folderu
analyze_directory() {
    total_files=0
    total_images=0
    declare -A total_photos_by_camera
    declare -A total_photos_by_shutter_speed
    declare -A total_photos_by_aperture
    src_dir="$1"
    max_depth="$2"

    while IFS= read -r file; do
        analyze_file "$file"
    done < <(find "$src_dir" $( [ -z "$max_depth" ] || echo "-maxdepth $max_depth" ) -type f)

    echo
    echo "Analiza zakończona:"
    echo "Całkowita liczba plików: $total_files"
    echo "Całkowita liczba zdjęć: $total_images"

    if (( ${#total_photos_by_camera[@]} == 0 && ${#total_photos_by_shutter_speed[@]} == 0 && ${#total_photos_by_aperture[@]} == 0 )); then
        echo "Nie znaleziono zdjęć z danymi EXIF"
    else
        echo "Najwięcej zdjęć wykonano aparatem:"
        find_max_in_array total_photos_by_camera

        echo "Najczęstszy czas naświetlania:"
        find_max_in_array total_photos_by_shutter_speed

        echo "Najczęściej używana przysłona:"
        find_max_in_array total_photos_by_aperture
    fi
}

# Funkcja do analizowania pojedynczego pliku
analyze_file() {
    local file="$1"

    echo "Analizuję plik: $file"
    ((total_files++))

    if [[ "$file" =~ \.(jpg|jpeg|png|tiff|raw)$ ]]; then
        ((total_images++))

        local camera_model=$(exiftool -Model "$file" 2>/dev/null | cut -d':' -f 2 | xargs)
        local shutter_speed=$(exiftool -ShutterSpeed "$file" 2>/dev/null | cut -d':' -f 2 | xargs)
        local aperture=$(exiftool -ApertureValue "$file" 2>/dev/null | cut -d':' -f 2 | xargs)

        if [ ! -z "$camera_model" ]; then
            ((total_photos_by_camera["$camera_model"]++))
        fi


        if [ ! -z "$shutter_speed" ]; then
            ((total_photos_by_shutter_speed["$shutter_speed"]++))
        fi


        if [ ! -z "$aperture" ]; then
            ((total_photos_by_aperture["$aperture"]++))
        fi
    fi
}










