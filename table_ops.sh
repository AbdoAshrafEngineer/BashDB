#! /usr/bin/bash

PS3="Choose table operation: "
select op in list_all_tables create drop insert select delete update 
do 
    case $op in 
        list_all_tables)
        ;;

        create)
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