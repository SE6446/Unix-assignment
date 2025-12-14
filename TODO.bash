TODO_DIR="lists"

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

    # Check for arguments
    if [[ -z "$file" || -z "$col" ]]; then
        echo "Usage: print_filtered_csv <filename> <column_number>"
        return 1
    fi
}

write_csv() {
    local file_name="$1"
    #todo csv headers
    local name="$2"
    local due="$3"
    local priority="$4"
    local tag="$5"
    local repitition="$6"
    
    #checks for commas in each csv column value
    for value in "$name" "$due" "$priority" "$tag" "$repitition"; do
        value_comma_check "$value" || return 1
    done

    if [[! -f "$TODO_FILE" ]]; then
        echo "name,due,priority,tag,repitition" > "$file_name.csv"
    fi

    echo "$name,$due,$priority,$tag,$repitition" >> "$file_name.csv"
}

add_task() {
    local file="$1.csv"

    local name="$2"
    local due="$3"
    local priority="${4:-medium}"
    local tag="${5:-}"
    local repitition="${6:-}"

    if [[ -z "$name" ]]; then
        echo "Usage: add_task <name> <due> <priority> <tag> <repitition>" >&2
        return 1
    fi

    for value in "$name,$due,$priority,$tag,$repitition"; do
      value_comma_check "$value" ||  return 1
    done


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

complete() {
    local archive="archive.csv"
    local keyword="$1"
    local date_col=2
    if [ -z "$keyword" ]; then
            echo "Error: Please provide a keyword."
            return 1
    fi

    if [ ! -f "$list.csv" ]; then
        echo "Error: $list.csv not found."
        return 1
    fi
    # Find the line(s) containing the keyword
    # We use 'grep' to find the line.
    local match=$(grep -v Name,Due "$list.csv" | grep "$keyword" | head -n 1) #We don't have time to do complex searching, so we pick the first viable option
    if [ -z "$match" ]; then
        echo "No task found matching: '$keyword'"
        return 1
    fi


    # 3. Return (Print) the line to the console
    echo "Completed:"
    if echo "$match" | grep -q "@repeat"; then
        echo "Recurring task detected. Updating due date..."
        # Extract the old date using awk
        # We look at the specific column defined in date_col
        # This was a nightmare to figure out
        local old_date=$(echo "$match" | awk -F, -v col="$date_col" '{print $col}')
        # Only works on linux. If you're using Mac, perhaps reconsider why we are making a program in bash, as opposed to... I don't know a PROGRAMMING language? (suffer)
        if echo "$match" | grep -q "@repeatWeekly"; then
            local new_date=$(date -d "$old_date + 7 days" +%Y-%m-%d)
        elif echo "$match" | grep -q "@repeatDaily"; then
            local new_date=$(date -d "$old_date + 1 day" +%Y-%m-%d)
        elif echo "$match" | grep -q "@repeatMonthly"; then
            local new_date=$(date -d "$old_date + 30 days" +%Y-%m-%d)
        elif echo "$match" | grep -q "@repeatYearly"; then
            local new_date=$(date -d "$old_date + 1 year" +%Y-%m-%d)
        fi
        echo "   Old Date: $old_date"
        echo "   New Date: $new_date"
        # Update the file using awk
        # We create a temp file where we swap the date ONLY for the matching line
        # This damn well is going to cause me to use one of my free counselling sessions at the uni counseller. Yes, this was AI assisted, after 1 hour of crying to myself.
        awk -F, -v key="$keyword" -v dcol="$date_col" -v ndate="$new_date" \
        'BEGIN {OFS=","}
         $0 ~ key { $dcol = ndate; print $0; next }
         { print $0 }' "$list.csv" > "$list.tmp" && mv "$list.tmp" "$list.csv"
    else
        # Not repeating? Archive and delete it.
        echo "$match" >> "$archive"
        echo "Sent entries $match to the archive"
        grep -v "$keyword" "$list.csv" > "$list.tmp" && mv "$list.tmp" "$list.csv"
        echo "Removed from list."
    fi
}

# Main goes in here
list=tasks
while getopts ":darc:l:" flag; do
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
        c)
            complete $OPTARG
            exit 0
            ;;
        *)
            echo "Invalid option: -$OPTARG"
            exit 1
            ;;
    esac
done

    if [[ ! -f "$file" ]]; then
        echo "name,due,priority,tag,repitition" > "$file"
    fi

    echo "$name,$due,$priority,$tag,$repitition" >> "$file"
}

remove_task() {
    local file="$1"
    local task_num="$2"

    if [[ -z "$file" || -z "$task_num" ]]; then
        echo "Usage: remove_task <List Name> <Task Number>" >&2
        return 1
    fi

    if [[ ! -f "$file" ]]; then
        echo "File not found: '$file'" > &2
        return 1
    fi

    if ! [["$task_num" =~ ^[0-9]+$ ]] || [["$task_num" -le 0]]; then
        echo "Task number must be a positive integer" >&2
        return 1
    fi

    local delete_line=$((task_num + 1))
    
    local total_lines
    total_lines=$(wc -1 < "$file")

    if [[delete_line -gt total_lines ]]; then
        echo "Task number out of range."
        return 1
    fi

    local tmp
    temp=$(mktemp)

    awk -v line="$delete_line" 'NR != line' "$file" > "$temp"
    mv "$temp" "$file"

    echo "Removed task: '$task_num'"

}

create_list() {
    local list_name="$1"
    local file_dir="lists"
    local index_file="list_index.csv"

    if [[ -z "$filename" ]]; then
        echo "Usage: create_list <list name>" >&2
        return 1
    fi

    value_comma_check "$list_name" || return 1

    mkdir -p "$file_dir"

    local list_file="$file_dir/$list_name.csv"

    if [[ -f "$list_file" ]]; then
        echo "List '$list_name' already exists." >&2
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