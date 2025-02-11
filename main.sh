#!/bin/bash
#Autor: Paweł Jasiński

source ./functions.sh

# Funkcja wyswietlajaca pomoc
function help() {
    echo "Opcje:"
    echo "  --organize <katalog_źródłowy> <katalog_docelowy>                    Organizowanie plików w katalogach w zależności od daty"
    echo "  --delete <katalog_źródłowy> <data_początkowa> <data_końcowa>        Usuwanie plików w zadanym przedziale dat, data w formacie YYYY-MM-DD"
    echo "  --analyze <katalog_źródłowy>                                        Analiza plików w katalogu"
    echo "  --max-depth n                                                       Ustawia maksymalną głębokość skanowania katalogów (parametr opcjonalny)"
    echo "  --help                                                              Wyświetla pomoc"
    exit 0
}

max_depth=""
command=""
src_dir=""
dest_dir=""
start_date=""
end_date=""

# Przetwarzanie argumentów
TEMP=$(getopt -o "" --long organize,delete,analyze,max-depth:,help -- "$@")
if [[ $? -ne 0 ]]; then
    echo "Błąd: Niepoprawne opcje" >&2
    help
    exit 1
fi

eval set -- "$TEMP"

while true; do
    case "$1" in
        --organize)
            command="organize"
            shift
            ;;
        --delete)
            command="delete"
            shift
            ;;
        --analyze)
            command="analyze"
            shift
            ;;

        --max-depth)
             if [[ -z "$2" || "$2" == -* || ! "$2" =~ ^[0-9]+$ || "$2" -lt 0 ]]; then
                echo "Błąd: Nie podano poprawnej głębokości dla --max-depth" >&2
                exit 1
            fi
            max_depth="$2"
            shift 2
            ;;
        --help)
            help
            ;;
        --)
            shift
            break
            ;;
        *)
            break
            ;;
    esac
done


# Przypisanie katalogów
if [ "$command" == "delete" ]; then
    src_dir="$1"
    shift
    start_date="$1"
    shift
    end_date="$1"
    shift
# to w przypadku opcji organize i analyze
elif [[ -z "$src_dir" && -n "$1" ]]; then
    src_dir="$1"
    shift
fi

if [[ "$command" == "organize" && -n "$1" ]]; then
    dest_dir="$1"
    shift
fi

if [ "$command" == "organize" ]; then
    validate_organize "$src_dir" "$dest_dir"
    organize_files "$src_dir" "$dest_dir" "$max_depth"

elif [ "$command" == "delete" ]; then
    validate_delete "$src_dir" "$start_date" "$end_date"
    delete_files_in_range "$src_dir" "$start_date" "$end_date" "$max_depth"

elif [ "$command" == "analyze" ]; then
    validate_analyze "$src_dir"
    analyze_directory "$src_dir" "$max_depth"
else
    echo "Błąd: Niepoprawna komenda '$command'."
    help
    exit 1
fi
