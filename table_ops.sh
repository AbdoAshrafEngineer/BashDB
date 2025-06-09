#! /usr/bin/bash

check_table_is_exist()
{
    if [[ -f "${1}_data" ]] || [[ -f "${1}_meta_data" ]]
    then
        return 0
    else 
        return 1
    fi
}

get_existing_table_name()
{
    while true;
    do
        read -rp "Enter table name: " table_name
        if check_table_is_exist $table_name
        then
            echo "${table_name} is found ✅"
            break
        else
            echo "❌ ${table_name} is not exist"
        fi
    done
}

read_table_metadata()
{
    local table="$1"
    local -n names_ref="$2"
    local -n types_ref="$3" 

    while IFS=":" read -r col_name col_type _
    do
        names_ref+=("$col_name")
        types_ref+=("$col_type")
    done < "${table}_meta_data"
}

#==============================list tables functions===========================================
list_tables()
{
    echo "Existing Tables:"
    ls *_meta_data 2>/dev/null | sed 's/_meta_data$//'
}


#=============================create table functions============================================
get_table_name() 
{
    while true; do
        read -rp "Enter table name: " table_name

        # Check for valid name (alphanumeric, no spaces)
        if [[ ! "$table_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
            echo "❌ Invalid table name."
            continue
        fi

        if check_table_is_exist $table_name; then
            echo "❌ Table '$table_name' already exists."
            continue
        fi

        echo "Table '$table_name' is created ✅"
        break
    done
    return 0
}
get_number_of_columns() 
{
    while true; do
        read -rp "Enter number of columns: " num_cols
        if ! [[ "$num_cols" =~ ^[1-9][0-9]*$ ]]; then
            echo "❌ Invalid number."
            continue
        fi
        break
    done
}

define_columns() 
{
    for (( i=1; i<=num_cols; i++ )); do
        local col_name col_type

        if ((i == 1)); then
            read -rp "enter primary key col_name: " col_name
        else
            read -rp "Enter column $i name: " col_name
        fi

        if [[ ! "$col_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
            echo "❌ Invalid column name. Use letters, digits, and underscores, starting with a letter or underscore."
            ((i--))
            continue
        fi

        if grep -q "^$col_name:" "${table_name}_meta_data"; then
            echo "❌ Column name '$col_name' already exists."
            ((i--))
            continue
        fi
        
        PS3="Choose data type (1 or 2): "
        select col_type in string integer; do
            if [[ -n "$col_type" ]]; then
                break
            else
                echo "❌ Invalid choice. Please enter 1 or 2."
            fi
        done

        if (( i == 1 )); then
            echo "$col_name:$col_type:pk" >> "${table_name}_meta_data"
        else
            echo "$col_name:$col_type" >> "${table_name}_meta_data"
        fi
    done
}

create_table() 
{
    local old_ps3=$PS3
    get_table_name || return 1
    
    touch "${table_name}_data"
    touch "${table_name}_meta_data"

    get_number_of_columns
    define_columns
    echo "Table '$table_name' meta data is now have columns ✅"
    PS3=$old_ps3
}

#=======================insert data functions==================================================

validate_value() 
{
    local value="$1"
    local type="$2"

    case "$type" in
        string)
            [[ -n "$value" ]] && return 0
            ;;
        integer)
            [[ "$value" =~ ^[0-9]+$ ]] && return 0
            ;;
    esac

    return 1
}

insert_row()
{
    local table=$1
    local -n names=$2
    local -n types=$3

    local values=()

    for (( i=0; i < ${#names[@]}; i++))
    do
        local value
        while true
        do
            read -p "Enter value for ${names[i]} (${types[i]}): " value
            if ! validate_value ${value} ${types[i]}
            then
                echo "❌ Invalid value for type ${types[i]}"
                continue
            fi
            if (( i == 0 )); then
                if cut -d: -f1 "${table}_data" | grep -qx "$value"
                then
                    echo "❌ Primary key '${names[i]}' must be unique. '$value' already exists."
                    continue
                fi
            fi
            values+=("$value")
            break
        done
    done

    local row=$(IFS=":"; echo "${values[*]}")
    echo $row >> ${table}_data
}

insert_data() 
{
    local table_name
    get_existing_table_name || return 1
    local -a col_names col_types
    read_table_metadata "$table_name" col_names col_types
    insert_row "$table_name" col_names col_types
    echo "Row inserted successfully.✅"
}
#==============================select table functions===========================================
is_table_empty()
{
    local table=$1
    if [[ -s ${table}_data ]]
    then
        return 1
    else
        return 0
    fi
}
show_all_columns()
{
    local -n columns=$1
    echo "Available columns:"
    for col in "${columns[@]}"
    do
        echo "- $col"
    done
}

select_all_rows()
{
    local table=$1
    local -n headers=$2
    echo "🔎 Showing all records:"
    echo "${headers[*]}" | tr ' ' ':'
    cat "${table}_data"
}

get_column_index() 
{
    local -n arr=$1
    local target="$2"
    for i in "${!arr[@]}"; do
        if [[ "${arr[i]}" == "$target" ]]; then
            echo "$i"
            return 0
        fi
    done
    return 1
}

select_column_from_table()
{
    local table=$1
    local -n headers=$2
    read -rp "Enter column name to select: " selected_col
    local index 
    index=$(get_column_index headers "$selected_col") || {
        echo "❌ Column '$selected_col' not found."
        return 1
    }

    echo "🔎 Values from column '$selected_col':"
    cut -d: -f$((index + 1)) "${table}_data"
}

select_records_by_column_value() 
{
    local table="$1"
    local -n headers=$2

    read -rp "Enter column name to filter by: " filter_col
    local index
    index=$(get_column_index headers "$filter_col") || {
        echo "❌ Column '$filter_col' not found."
        return 1
    }

    read -rp "Enter value to search for in column '$filter_col': " filter_value

    echo "🔎 Records where '$filter_col' = '$filter_value':"
    # Print headers first
    echo "${headers[*]}" | tr ' ' ':'

    # Search data for matching records (exact match on the field)
    # cut -d: -f$((index+1)) extracts the column for comparison
    awk -F: -v col=$((index+1)) -v val="$filter_value" '
        $col == val { print }
    ' "${table}_data"
}

select_data()
{
    local old_ps3=$PS3
    local table_name
    get_existing_table_name || return 1

    if is_table_empty "$table_name"; then
        echo "⚠️  Table '$table_name' is empty."
        return 0
    fi

    local -a col_names col_types
    read_table_metadata $table_name col_names col_types

    show_all_columns col_names
    echo
    PS3="choose the select type: "
    select op in select_all_rows select_column_from_table select_records_by_column_value
    do
        case $op in
            select_all_rows)
                select_all_rows $table_name col_names
                ;;

            select_column_from_table)
                select_column_from_table $table_name col_names
                ;;

            select_records_by_column_value)
                select_records_by_column_value $table_name col_names
                ;;

            select_records_by_column_value)
                select_records_by_column_value $table_name col_names
                ;;

            *)
                echo "❌ Invalid option."
                ;;
        esac
        break
    done

    PS3=$old_ps3
}
#=========================================================================

PS3="Choose table operation (press Enter to show menu again): "
select op in list_all_tables create insert select drop delete update 
do 
    case $op in 
        list_all_tables)
            list_tables
            ;;

        create)
            create_table
            ;;

        insert)
            insert_data
            ;;

        select)
            select_data
            ;;

        drop)
            ;;
        

        delete)
            ;;

        update)
            ;;

        *)
            echo "choose valid table operation"
            ;;
    esac
done