#! /usr/bin/bash

check_table_is_exist()
{
    [ -f "${1}_data" ] || [ -f "${1}_meta_data" ]
}

validate_table_name() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo "ERROR: Table name cannot be empty."
        return 1
    fi
    
    if [[ ! "$name" =~ ^[a-zA-Z_] ]]; then
        echo "ERROR: Table name must start with a letter or underscore."
        return 1
    fi
    
    if [[ ! "$name" =~ ^[a-zA-Z0-9_]+$ ]]; then
        echo "ERROR: Table name can only contain letters, numbers, and underscores."
        return 1
    fi
    
    return 0
}

#=========================================================================

PS3="Choose table operation: "
select op in list_all_tables create drop insert select delete update 
do 
    case $op in 
        list_all_tables)
            echo "Existing Tables:"
            ls *_data 2>/dev/null | sed 's/_data$//'
        ;;

        create)
            
            # Loop until the table name is unique
            while true
            do
                read -p "Enter table name: " name
                if ! validate_table_name "$name"
                then
                    continue
                fi

                if check_table_is_exist "$name"
                then
                    echo "ERROR: Table '$name' already exists."
                else
                    touch "${name}_data"
                    touch "${name}_meta"
                    echo "Table '$name' is created"
                    break
                fi

            done
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
    esac
done