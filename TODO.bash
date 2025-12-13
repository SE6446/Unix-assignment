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

<<<<<<< HEAD
column_number=$(get_column_from_name tasks.csv Due)
echo "Sorting by column number: $column_number"
print_sorted_csv tasks.csv $column_number


value_comma_check() {
    if [["$1" == *","*]]; then
        echo "Values may not contain commas: '$1'" >&2
        return 1
    fi
}

write_csv() {
    local name="$1"
    local due="$2"
    local priority="$3"
    local tag="$4"
    local repitition="$5"
    
    for value in "$name" "$due" "$priority" "$tag" "$repitition"; do
        value_comma_check "$value" || return 1
    done

    if [[! -f "$TODO_FILE" ]]; then
        echo "name,due,priority,tag,repitition" > "$TODO_FILE"
    fi

    echo "$name,$due,$priority,$tag,$repitition" >> "$TODO_FILE"
}

add_task() {
    local file="tasks.csv"

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
=======
    # Check for arguments
    if [[ -z "$file" || -z "$col" ]]; then
        echo "Usage: print_filtered_csv <filename> <column_number>"
        return 1
    fi



    (
        head -n 1 "$file"
        tail -n +2 "$file" | sort -t, -k"${col}" # The data itself
    ) | column -s, -t -o " | " | grep -e "$filter" -e "Name"
}

display() {
    local col_index="$1"
    local filter="$2"
    if [[ -z "$col_index" ]]; then
        # if it is empty, we make it priority
        col_index=3 # Default to priority
    else
        col_index=$(get_column_from_name $list.csv "$col_index")
    fi

    if [[ -z "$filter" ]]; then
        print_sorted_csv $list.csv "$col_index"
    else
        print_filtered_csv $list.csv "$col_index" "$filter"
    fi
}

# Main goes in here
list=tasks
while getopts ":darl:" flag; do
    case "${flag}" in
        l)
            list=${OPTARG:-tasks}
            ;;
        d)
            # To allow for Optional Arguments, we need to do a little hacking.
            # First we use OPTIND to 'steal' the next argument.
            next_arg="${!OPTIND}"

            #Then we check if the next argument exists and isn't flagged.
            if [[ -n "$next_arg" && "$next_arg" != -* ]]; then
                #When we get a match, we set OPTARG to it.
                OPTARG="$next_arg"

                # IMPORTANT: We must manually tell getopts to skip the next argument (since we stole it)
                # so it doesn't try to process the args in the next pass.
                OPTIND=$((OPTIND + 1))
            else
                # No argument found (or next was a flag like -a)
                OPTARG=""
            fi

            read -r -a args <<< "$OPTARG"
            display "${args[0]}" "${args[1]}"
            exit 0
            ;;
        a)
            echo "Adding Not implemented"
            exit 0
            ;;
        r)
            echo "Removing Not implemented"
            exit 0
            ;;
        *)
            echo "Invalid option: -$OPTARG"
            exit 1
            ;;
    esac
done

#Force people to READ!
echo "Error: No arguments provided!"
cat usage.txt
>>>>>>> 2b1257461dd61e333b025cad0b13105632e91749
