#! /usr/bin/bash

########use ps3 to indicate the user what to do###########

# Function to check if database exists
function get_db_name_and_if_exist() {
    read -p "Enter database name: " db_name
    if [ -d "$db_name" ]
    then
        return 0
    else
        echo "Error: Database '$db_name' does not exist."
        return 1
    fi
}

# Function to create database
function create_db() {
    read -p "Enter new database name (alphanumeric only): " db_name
    
    # Validate database name with regex
    if [[ ! $db_name =~ ^[a-zA-Z0-9_]+$ ]]
    then
        echo "Error: Invalid database name. Use only letters, numbers and underscores."
        return 1
    fi
    
    # Check if database already exists
    if [ -d "$db_name" ] 
    then
        echo "Error: Database '$db_name' already exists."
        return 1
    fi
    
    # Create database directory
    mkdir "$db_name"
    echo "Database '$db_name' created successfully."
}

# Function to list databases
function list_dbs() {
    echo "Available Databases:"
    ls -F | grep / | tr -d '/'      #tr -d '/' to remove the '/' from the end of the directory name
}

# Function to drop database
function drop_db() {
    get_db_name_and_if_exist
    if [ $? -eq 0 ]  #$? is the return value of the previous function
    then
        read -p "Are you sure you want to drop '$db_name'? (y/n): " confirm
        if [ "$confirm" = "y" ]
        then
            rm -r "$db_name"
            echo "Database '$db_name' dropped successfully."
        else
            echo "Operation cancelled."
        fi
    fi
}

# Function to connect to database
function connect_db() {
    get_db_name_and_if_exist
    if [ $? -eq 0 ]
    then
        cd "$db_name"
        echo "Connected to database '$db_name'."
        . ../table_ops.sh "$db_name"
    fi
}

# Main menu
# function main_menu() {
#     echo "DBMS Main Menu"
#     PS3="Select an option: "
#     select option in "Make DBMS Directory" "Change to DBMS Directory" "Database Operations" "Exit"
#     do
#         case $option in
#             "Make DBMS Directory")
#                 read -p "Enter DBMS directory name: " dbms_dir
#                 mkdir -p "$dbms_dir"
#                 echo "DBMS directory '$dbms_dir' created."
#                 ;;
#             "Change to DBMS Directory")
#                 read -p "Enter DBMS directory name: " dbms_dir
#                 if [ -d "$dbms_dir" ]
#                 then
#                     cd "$dbms_dir"
#                     echo "Changed to directory '$dbms_dir'."
#                     db_operations_menu
#                 else
#                     echo "Directory does not exist."
#                 fi
#                 ;;
#             "Database Operations")
#                 db_operations_menu
#                 ;;
#             "Exit")
#                 echo "Goodbye!"
#                 exit 0
#                 ;;
#             *)
#                 echo "Invalid option"
#                 ;;
#         esac
#         break
#     done
#     main_menu
# }

# Database operations menu
function db_operations_menu() {
    echo "Database Operations"
    PS3="Select an operation: "
    select operation in "Create Database" "List Databases" "Drop Database" "Connect to Database"
    do
        case $operation in
            "Create Database")
                create_db
                ;;
            "List Databases")
                list_dbs
                ;;
            "Drop Database")
                drop_db
                ;;
            "Connect to Database")
                connect_db
                ;;
            *)
                echo "Invalid option"
                ;;
        esac
        break
    done
    db_operations_menu
}

# Start the main menu
# main_menu
db_operations_menu
                
        

