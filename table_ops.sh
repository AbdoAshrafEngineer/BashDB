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



get_existing_table_name()
{
    while true;
    do
        read -rp "Enter table name to insert into: " table_name
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
validate_value() 
{
    local value="$1"
    local type="$2"

    case "$type" in
        integer)
            [[ "$value" =~ ^[0-9]+$ ]] && return 0
            ;;
        string)
            [[ -n "$value" ]] && return 0
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

#=========================================================================

PS3="Choose table operation (press Enter to show menu again): "
select op in list_all_tables create insert drop select delete update 
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

        drop)
        ;;
        select)
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