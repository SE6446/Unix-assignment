print_csv() {
    # Check if a file was provided and if it exists
    if [ -z "$1" ]; then
        echo "Usage: print_csv <filename>"
        return 1
    fi

    if [ ! -f "$1" ]; then
        echo "Error: File '$1' not found."
        return 1
    fi

    # -s,  : Sets the input delimiter to a comma
    # -t   : Formats input as a table (aligns columns)
    # -o   : (Optional) Sets output separator to " | " to match your example
    column -s, -t -o " | " "$1"
}

print_sorted_csv() {
    local file="$1"
    local col="$2"

    # Check for arguments
    if [[ -z "$file" || -z "$col" ]]; then
        echo "Usage: print_sorted_csv <filename> <column_number>"
        return 1
    fi



    (
        head -n 1 "$file" # The header line
        tail -n +2 "$file" | sort -t, -k"${col}" # The data itself
    ) | column -s, -t -o " | "
}

get_column_from_name() {
    local file="$1"
    local col_name="$2"
    if [[ -z "$file" || -z "$col_name" ]]; then
        echo "Usage: get_column_from_name <filename> <column_name>"
        return 1
    fi
    # Read the header line and find the column index
    local header
    header=$(head -n 1 "$file")
    local col_index=1
    IFS=',' read -ra headers <<< "$header"
    for i in "${!headers[@]}"; do
        if [[ "${headers[i]}" == "$col_name" ]]; then
            col_index=$((i + 1))
            break
        fi
    done

    echo $col_index
}

print_filtered_csv() {
    local file="$1"
    local col="$2"
    local filter="$3"

column_number=$(get_column_from_name tasks.csv Due)
echo "Sorting by column number: $column_number"
print_sorted_csv tasks.csv $column_number


value_comma_check() {
    #checks for commas inside of csv values, returns error if so
    if [["$1" == *","*]]; then
        echo "Values may not contain commas: '$1'" >&2
        return 1
    fi
}

write_csv() {
    #todo list headers
    local name="$1"
    local due="$2"
    local priority="$3"
    local tag="$4"
    local repitition="$5"
    
    #checks for commas in each csv column value
    for value in "$name" "$due" "$priority" "$tag" "$repitition"; do
        value_comma_check "$value" || return 1
    done

    if [[! -f "$TODO_FILE" ]]; then
        echo "name,due,priority,tag,repitition" > "$TODO_FILE"
    fi

    echo "$name,$due,$priority,$tag,$repitition" >> "$TODO_FILE"
}

add_task() {
    local file="tasks.csv" #file name is placeholder

    local name="$1"
    local due="$2"
    local priority="${3:-medium}"
    local tag="${4:-}"
    local repitition="${5:-}"

    if [[ -z "$name" ]]; then
        echo "Usage: add_task <name> <due> <priority> <tag> <repitition>" >&2
        return 1
    fi

    for value in "$name,$due,$priority,$tag,$repitition"; do
      value_comma_check "$value" ||  return 1
    done

    case "$priority" in
        low|medium|high) ;;
        *)
            echo "Priority must be low, medium or high" >&2
            return 1
            ;;
    esac

    if [[ ! -f "$file" ]]; then
        echo "name,due,priority,tag,repitition" > "$file"
    fi

    echo "$name,$due,$priority,$tag,$repitition" >> "$file"
}

create_list() {
    local list_name="$1"
    local filedir="lists"
    local index_file="list_index.csv"

    if [[ -z "$filename" ]]; then
        echo "Usage: create_list <list name>" >&2
        return 1
    fi

    value_comma_check "$filename" || return 1

    mkdir -p "$filedir"

    local list_file="$filedir/$filename.csv"

    if [[ -f "$list_file" ]]; then
        echo "List '$filename' already exists." >&2
        return 1
    fi

    echo "name,due,priority,tag,repitition" > "$list_file"

    if [[ ! -f "$index_file "]]; then
        echo "list__name,file_path,created" > "$index_file"
    fi

    local created
    created="$(date +%f)

    echo "$list_name,$list_file,$created" >> "$index_file"

    echo "List Created: $list_name"
}