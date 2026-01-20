#!/bin/bash

# change prompt environment
export PS3="Database>"

# declare the colors
RESET="\033[0m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"

# Success Status
SUCCESS=1

# Error Status
EMPTY_INPUT=-1
INVALID_INPUT=-2
UNDERSCORE_ONLY_INPUT=-3
START_WITH_NUM_INPUT=-4
EXISTS=-5
NOT_FOUND=-6
INVALID_TYPE_INT=-7
INVALID_TYPE_STRING=-8
PK_EXISTS=-9

# Codes
EMPTY_CODE=101
INVALID_CHARS_CODE=102
UNDERSCORE_ONLY_CODE=103
START_WITH_NUM_CODE=104
EXISTS_CODE=105
NOT_FOUND_CODE=106
INVALID_INT__TYPE_CODE=202
INVALID_STRING__TYPE_CODE=203
PK_EXISTS_CODE=204
# Enable extended pattern matching for advanced data validation
shopt -s extglob

# create DBMS
if [[ ! -d ~/.DBMS ]]; then
	echo "Create .DBMS Directory .............."
	sleep 1
	mkdir ~/.DBMS
fi

# validate the input of database name
input_validation() {
	local input=$1

	case "$input" in
	"")
		echo "$EMPTY_INPUT"
		;;
	[0-9]*)
		echo "$START_WITH_NUM_INPUT"
		;;
	"_")
		echo "$UNDERSCORE_ONLY_INPUT"
		;;
	*([a-zA-Z0-9_]))
		echo "$SUCCESS"
		;;
	*)
		echo "$INVALID_INPUT"
		;;
	esac
}

# Print Errors
print_error() {
	local code=$1
	case $code in
	"$EMPTY_INPUT")
		echo -e "${RED}Error ${EMPTY_CODE}: Input cannot be empty.${RESET}"
		;;
	"$START_WITH_NUM_INPUT")
		echo -e "${RED}Error ${START_WITH_NUM_CODE}: Cannot start with a number.${RESET}"
		;;
	"$UNDERSCORE_ONLY_INPUT")
		echo -e "${RED}Error ${UNDERSCORE_ONLY_CODE}: Cannot be underscore only.${RESET}"
		;;
	"$INVALID_INPUT")
		echo -e "${RED}Error ${INVALID_CHARS_CODE}: Invalid characters detected.${RESET}"
		;;
	"$EXISTS")
		echo -e "${RED}Error ${EXISTS_CODE}: Database already exists.${RESET}"
		;;
	"$NOT_FOUND")
		echo -e "${RED}Error ${NOT_FOUND_CODE}: Database not found.${RESET}"
		;;
	"$INVALID_TYPE_INT")
		echo -e "${RED}Error ${INVALID_INT__TYPE_CODE}: Value must be integer.${RESET}"
		;;
	"$INVALID_TYPE_STRING")
		echo -e "${RED}Error ${INVALID_STRING__TYPE_CODE}: Invalid string (Empty or contains ':').${RESET}"
		;;
	"$PK_EXISTS")
		echo -e "${RED}Error ${PK_EXISTS_CODE}: Primary Key already exists!${RESET}"
		;;
	esac
}
################### DATABASES ###################

# create database
create_db() {
	local db_name=$1
	local validation_res

	validation_res=$(input_validation "$db_name")

	if [[ "$validation_res" == "$SUCCESS" ]]; then
		if [[ -d ~/.DBMS/"$db_name" ]]; then
			echo "$EXISTS"
		else
			mkdir -p ~/.DBMS/"$db_name"
			echo "$SUCCESS"
		fi
	else
		echo "$validation_res"
	fi
}

# List databases
list_db() {
	local -n arr=$1
	local -n status=$2

	if [[ ! -d ~/.DBMS ]] || [[ -z "$(ls -A ~/.DBMS 2>/dev/null)" ]]; then
		status="$NOT_FOUND"
	else
		arr=()
		for db in ~/.DBMS/*/; do
			if [[ -d "$db" ]]; then
				arr+=("$(basename "$db")")
			fi
		done
		status="$SUCCESS"
	fi
}

# connect to database
connect_db() {
	local db_name=$1
	local validation_res

	validation_res=$(input_validation "$db_name")

	if [[ "$validation_res" != "$SUCCESS" ]]; then
		echo "$validation_res"
		return
	fi

	if [[ -d ~/.DBMS/"$db_name" ]]; then
		echo "$SUCCESS"
	else
		echo "$NOT_FOUND"
	fi
}

# drop database
drop_db() {

	local db_name=$1
	local validation_res

	validation_res=$(input_validation "$db_name")

	if [[ "$validation_res" != "$SUCCESS" ]]; then
		echo "$validation_res"
		return
	fi

	if [[ -d ~/.DBMS/"$db_name" ]]; then
		rm -r ~/.DBMS/"$db_name"
		echo "$SUCCESS"
	else
		echo "$NOT_FOUND"
	fi

}

################################# TABLES #################################

# 1-
################################# Create Table #################################
create_data_file() {
	local tableName=$1

	if [[ -f "$tableName" ]]; then
		echo "$EXISTS"
	else
		touch "$tableName"
		chmod 644 "$tableName"
		echo "$SUCCESS"
	fi
}

create_metadata_file() {
	local tableName=$1
	local cols=$2
	local types=$3
	local pk=$4

	echo "$cols" >".$tableName.meta"
	echo "$types" >>".$tableName.meta"
	echo "$pk" >>".$tableName.meta"

	echo "$SUCCESS"
}

create_table() {
	local tableName=$1
	local colsMetadata=$2
	local typesMetadata=$3
	local pkName=$4

	result=$(input_validation "$tableName")

	if [[ $result == "$SUCCESS" ]]; then
		result=$(create_data_file "$tableName")
		if [[ $result == "$SUCCESS" ]]; then
			result=$(create_metadata_file "$tableName" "$colsMetadata" "$typesMetadata" "$pkName")
			echo "$result"
		else
			echo "$result"
		fi
	else
		echo "$result"
	fi

}

# 2-
################################# List Table #################################

get_tables_list() {
	local -n tablesArr=$1
	local -n opStatus=$2

	local files=(*)

	if [[ "${files[0]}" == "*" ]]; then
		opStatus="$NOT_FOUND"
		return
	fi

	tablesArr=()
	for f in "${files[@]}"; do
		if [[ -f "$f" ]]; then
			tablesArr+=("$f")
		fi
	done

	if [[ ${#tablesArr[@]} -gt 0 ]]; then
		opStatus="$SUCCESS"
	else
		opStatus="$NOT_FOUND"
	fi
}

# 3-
################################# Drop Table #################################

validate_table_existence() {
    local tableName=$1

    if [[ -f "$tableName" ]]; then
        echo "$SUCCESS"
    else
        echo "$NOT_FOUND"
    fi
}

drop_table() {
	local tableName=$1

    rm "$tableName"
    rm ".$tableName.meta" 2>/dev/null
    
    echo "$SUCCESS"
}

# 4-
################################# Insert Into Table #################################

# ================= TABLE HELPERS =================

get_table_columns() {
	local tableName=$1
	awk 'NR==1 {print $0}' ".$tableName.meta"
}

get_table_types() {
	local tableName=$1
	awk 'NR==2 {print $0}' ".$tableName.meta"
}

get_table_pk() {
	local tableName=$1
	awk 'NR==3 {print $0}' ".$tableName.meta"
}

check_value_exists() {
	local tableName=$1
	local colIndex=$2
	local value=$3

	if awk -F: -v col="$colIndex" -v val="$value" '$col == val {exit 0} END {exit 1}' "$tableName"; then
		echo "$EXISTS"
	else
		echo "$NOT_FOUND"
	fi
}

validate_insert() {
	local val=$1
	local type=$2
	local tableName=$3
	local colIndex=$4
	local isPK=$5

	if [[ "$type" == "int" ]]; then
		if [[ ! "$val" =~ ^[0-9]+$ ]]; then
			echo "$INVALID_TYPE_INT"
			return
		fi
	elif [[ "$type" == "string" ]]; then
		if [[ -z "$val" || "$val" == *":"* ]]; then
			echo "$INVALID_TYPE_STRING"
			return
		fi
	fi

	if [[ "$isPK" == "true" ]]; then
		local exists
		exists=$(check_value_exists "$tableName" "$colIndex" "$val")

		if [[ "$exists" == "$EXISTS" ]]; then
			echo "$PK_EXISTS"
			return
		fi
	fi

	echo "$SUCCESS"
}
insert_into_table() {
	local tableName=$1
	local rowData=$2

	if [[ ! -f "$tableName" ]]; then
		echo "$NOT_FOUND"
	else
		if echo "$rowData" >>"$tableName"; then
			echo "$SUCCESS"
		else
			# ممكن نعمل كود خطأ جديد للكتابة، بس حالياً نرجع ده
			echo "$INVALID_INPUT"
		fi
	fi

}

# 5-
################################# Update Table #################################

update_from_table() {
	read -r -p "Enter Table Name: " tName

	if [[ ! -f "$tName" ]]; then
		print_error "$NOT_FOUND"
		return
	fi

	pkName=$(get_table_pk "$tName")
	read -r -p "Enter $pkName value to update: " pkVal

	if ! grep -q "^$pkVal:" "$tName"; then
		print_error "$NOT_FOUND"
		return
	fi

	# Delete old row
	sed -i "/^$pkVal:/d" "$tName"

	echo -e "${YELLOW}Enter new values:${RESET}"

	# Reuse insert logic
	rawCols=$(get_table_columns "$tName")
	rawTypes=$(get_table_types "$tName")

	IFS=':' read -r -a cols <<<"$rawCols"
	IFS=':' read -r -a types <<<"$rawTypes"

	rowData=""

	for ((i = 0; i < ${#cols[@]}; i++)); do
		colName=${cols[$i]}
		colType=${types[$i]}

		isPK="false"
		if [[ "$colName" == "$pkName" ]]; then
			isPK="true"
		fi

		valid=false
		while ! $valid; do
			read -r -p "$colName ($colType): " inputVal
			valResult=$(validate_insert "$inputVal" "$colType" "$tName" $((i + 1)) "$isPK")

			if [[ "$valResult" == "$SUCCESS" ]]; then
				valid=true
			else
				print_error "$valResult"
			fi
		done

		if [[ $i -eq 0 ]]; then
			rowData="$inputVal"
		else
			rowData="$rowData:$inputVal"
		fi
	done

	insert_into_table "$tName" "$rowData"
	echo -e "${GREEN}Row updated successfully.${RESET}"
}

# 6-
################################# Select Table #################################

select_from_table() {
	read -r -p "Enter Table Name: " tName

	if [[ ! -f "$tName" ]]; then
		print_error "$NOT_FOUND"
		return
	fi

	cols=$(get_table_columns "$tName")
	echo -e "${BLUE}--- TABLE DATA ---${RESET}"

	# Print header
	echo "$cols" | tr ':' '|' | column -t -s '|'

	# Print data
	if [[ -s "$tName" ]]; then
		column -t -s ':' "$tName"
	else
		echo -e "${YELLOW}Table is empty.${RESET}"
	fi
}

# 7-
################################# Delete From Table #################################

delete_from_table() {
	read -r -p "Enter Table Name: " tName

	if [[ ! -f "$tName" ]]; then
		print_error "$NOT_FOUND"
		return
	fi

	pkName=$(get_table_pk "$tName")
	read -r -p "Enter $pkName value to delete: " pkVal

	if ! grep -q "^$pkVal:" "$tName"; then
		print_error "$NOT_FOUND"
		return
	fi

	sed -i "/^$pkVal:/d" "$tName"
	echo -e "${GREEN}Row deleted successfully.${RESET}"
}



tables_menu() {
	local db_name=$1

	echo -e "${YELLOW}Entered Database: $db_name${RESET}"

	PS3="DB($db_name)> " # Change the propmt

	select _ in "Create Table" "List Tables" "Drop Table" "Insert" "Select" "Update" "Delete" "Back to Main Menu"; do
		case $REPLY in
		1 | "create table")
			read -r -p "Enter Table Name: " tName

			read -r -p "Enter Columns (space separated): " colsInput
			read -r -p "Enter Types (space separated): " typesInput
			read -r -p "Enter Primary Key Name: " pkInput

			if [[ -z "$colsInput" || -z "$typesInput" || -z "$pkInput" ]]; then
				print_error "$EMPTY_INPUT"
				continue
			else

				colsMeta=$(echo "$colsInput" | tr -s ' ' ':')
				typesMeta=$(echo "$typesInput" | tr -s ' ' ':')

				IFS=':' read -r -a colsArr <<<"$colsMeta"
				IFS=':' read -r -a typesArr <<<"$typesMeta"

				if [[ ${#colsArr[@]} -ne ${#typesArr[@]} ]]; then
					echo -e "${RED}Error: Column count (${#colsArr[@]}) does not match Type count (${#typesArr[@]}).${RESET}"
					continue
				fi

				pkExists="false"
				for col in "${colsArr[@]}"; do
					if [[ "$col" == "$pkInput" ]]; then
						pkExists="true"
						break
					fi
				done

				if [[ "$pkExists" == "false" ]]; then
					echo -e "${RED}Error: Primary Key '$pkInput' must be one of the columns.${RESET}"
					continue
				fi
			fi

			result=$(create_table "$tName" "$colsMeta" "$typesMeta" "$pkInput")

			if [[ $result == "$SUCCESS" ]]; then
				echo -e "${GREEN}Table created successfully.${RESET}"
			elif [[ $result == "$EXISTS" ]]; then
				echo -e "${RED}Error ${EXISTS}: Table already exists.${RESET}"
			else
				print_error "$result"
			fi
			;;
		2 | "list tables")
			declare -a tList
			declare tStatus

			get_tables_list tList tStatus

			if [[ "$tStatus" == "$SUCCESS" ]]; then
				echo -e "${BLUE}=== Existing Tables ===${RESET}"
				for table in "${tList[@]}"; do
					echo -e "-> $table"
				done
				echo -e "${BLUE}=======================${RESET}"
			else
				echo -e "${YELLOW}No tables found in database '$db_name'.${RESET}"
			fi
			;;
		3 | "drop table")
			read -r -p "Enter Table Name to Drop: " tName

            checkResult=$(validate_table_existence "$tName")

            if [[ "$checkResult" == "$SUCCESS" ]]; then
                
                read -r -p "Are you sure you want to delete table '$tName'? (y/n): " confirm
                
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    drop_table "$tName"
                    echo -e "${GREEN}Table '$tName' dropped successfully.${RESET}"
                else
                    echo -e "${YELLOW}Operation Cancelled.${RESET}"
                fi

            else
                print_error "$checkResult"
            fi
            ;;
		4 | "insert")
			read -r -p "Enter Table Name: " tName

			if [[ ! -f "$tName" ]]; then
				print_error "$NOT_FOUND"
			else
				rawCols=$(get_table_columns "$tName")
				rawTypes=$(get_table_types "$tName")
				pkName=$(get_table_pk "$tName")

				IFS=':' read -r -a cols <<<"$rawCols"
				IFS=':' read -r -a types <<<"$rawTypes"

				rowData=""
				colCount=${#cols[@]}

				for ((i = 0; i < colCount; i++)); do
					colName=${cols[$i]}
					colType=${types[$i]}

					isPK="false"
					if [[ "$colName" == "$pkName" ]]; then
						isPK="true"
					fi

					echo -e "${BLUE}Enter value for '$colName' ($colType):${RESET}"

					valid=false

					while ! $valid; do
						read -r -p "> " inputVal

						# --- استدعاء المفتش (Validation Function) ---
						valResult=$(validate_insert "$inputVal" "$colType" "$tName" $((i + 1)) "$isPK")

						if [[ "$valResult" == "$SUCCESS" ]]; then
							valid=true
						else
							print_error "$valResult"
						fi
					done

					# تجميع السطر (Concatenation)
					if [[ $i -eq 0 ]]; then
						rowData="$inputVal"
					else
						rowData="$rowData:$inputVal"
					fi
				done

				# 4. الحفظ النهائي (Final Persistence)
				result=$(insert_into_table "$tName" "$rowData")

				if [[ "$result" == "$SUCCESS" ]]; then
					echo -e "${GREEN}Row inserted successfully.${RESET}"
					echo "---------------------------------"
				else
					echo -e "${RED}Error saving data to file.${RESET}"
				fi
			fi
			;;
		5 | "select")
			select_from_table
			;;
		6 | "update")
			update_from_table
			;;
		7 | "delete")
			delete_from_table
			;;
		8 | "back to tain menu")
			export PS3="Database> "
			break
			;;
		*)
			echo -e "${RED}Invalid option.${RESET}"
			;;
		esac
	done
}

# put the menu of database options
menu=("create database" "list database" "connect database" "drop database" "exit")
select _ in "${menu[@]}"; do

	case $REPLY in
	1 | "create database")
		read -r -p "Enter Database Name: " dbNameInput

		result=$(create_db "$dbNameInput")

		if [[ $result == "$SUCCESS" ]]; then
			echo -e "${GREEN}Database created successfully.${RESET}"
		else
			print_error "$result"
		fi
		;;

	2 | "list database")

		list_db dbs status

		if [[ $status == "$SUCCESS" ]]; then
			echo -e "${BLUE}Databases:${RESET}"
			for db in "${dbs[@]}"; do
				echo "- $db"
			done
		else
			print_error "$status"
		fi
		;;
	3 | "connect database")
		read -r -p "Enter Database Name to Connect: " dbNameInput

		result=$(connect_db "$dbNameInput")

		if [[ "$result" == "$SUCCESS" ]]; then
			cd ~/.DBMS/"$dbNameInput" 2>/dev/null || exit

			tables_menu "$dbNameInput"

			cd ../.. 2>/dev/null # Back to the menu of databaes after user finish

			echo -e "${YELLOW}Back to Main Menu.${RESET}"
		else
			print_error "$result"
		fi
		;;
	4 | "drop database")
		read -r -p "Enter Database Name to drop: " dbNameInput

		read -r -p "Are you sure you want to delete '$dbNameInput'? (y/n): " confirm
		if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then

			result=$(drop_db "$dbNameInput")

			if [[ "$result" == "$SUCCESS" ]]; then
				echo -e "${GREEN}Database Dropped Successfully.${RESET}"
			else
				print_error "$result"
			fi

		else
			echo -e "${YELLOW}Operation Cancelled.${RESET}"
		fi
		;;
	5 | "exit")
		echo -e "${GREEN}Exiting...!${RESET}"
		break
		;;
	*)
		echo -e "${RED}Invalid option. Please select 1-5.${RESET}"
		;;
	esac

done
