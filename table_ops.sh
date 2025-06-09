#! /usr/bin/bash

#=========================================================================
check_table_is_exist()
{
    if [[ -f "${1}_data" ]] || [[ -f "${1}_meta_data" ]]; then
        return 0
    else 
        return 1
    fi
}


get_table_name() 
{
    while true; do
        read -p "Enter table name: " table_name

        # Check for valid name (alphanumeric, no spaces)
        if [[ ! "$table_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
            echo "❌ Invalid table name."
            continue
        fi

        if check_table_is_exist $table_name; then
            echo "❌ Table '$table_name' already exists."
            continue
        fi

        echo "✅ Table '$table_name' is created"
        break
    done
    return 0
}
get_number_of_columns() 
{
    while true; do
        read -p "Enter number of columns: " num_cols
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
            read -p "enter primary key col_name: " col_name
        else
            read -p "Enter column $i name: " col_name
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
    echo "✅ Table '$table_name' meta data is now have columns"
    PS3=$old_ps3
}

#=========================================================================


#=========================================================================

PS3="Choose table operation (press Enter to show menu again): "
select op in list_all_tables create drop insert select delete update 
do 
    case $op in 
        list_all_tables)
            echo "Existing Tables:"
            ls *_meta_data 2>/dev/null | sed 's/_meta_data$//'
        ;;

        create)
            create_table
            ;;

        drop)

        ;;

        insert)
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