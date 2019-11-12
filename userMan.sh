#!/bin/bash
###########################################################
# Name: MCOMD3PST ASSIGNMENT 1 | ./userMan.sh
# Purpose:	Systems Administrator Tool for User Management
# Author:	Samuel Steven David Herring
# UserID:	sh1042
# Creation Date: 29/10/2019
# Modified Date: 12/11/2019
# Related Files: userMan-Help | example.csv | users.csv
###########################################################

#Function --> Main program entry point - handles scripts flags and arguments upon calling
function main()
{	
	local OPTIND OPTARG

	while getopts ": g: v e k h "-help"" opt; do
		case ${opt} in
		    g)
		    	generateUsers $OPTARG
		    	exit 0
		    ;;
		    v)
		    	viewUserProcesses
		    	exit 0
		    ;;
		    e)
		    	exportUserProcesses
		    	exit 0
		    ;;
		    k)
		    	killUserProcesses
		    	exit 0
		    ;;
		    h)
		    	man ./userMan-Help
		    	exit 0
		    ;;
		    \?)
		    	echo "Invalid option: '-$OPTARG'. See script help with './userMan.sh --help'" >&2
				exit 1
		    ;;
		    :)
		    	echo "Option -$OPTARG requires an argument. See script help with './userMan.sh --help'" >&2
				exit 1
		    ;;
		esac
	done
	
	shift $(( OPTIND - 1 ))
	
	if [ ! -z $1 ] ;
	then
		echo "Unexpected argument. See script help with './userMan.sh --help'"
		echo "Unexpected argument." >&2 # Output to STDERR as well as STDOUT when an invalid argument used
		exit 0
	fi
	
 	mainMenuGUI
	
	exit 0
}

#Function --> Provides GUI to prevent error if no argument provided to script
function mainMenuGUI()
{
	local $CSV_FILE #Define $CSV_FILE as local variable to prevent validation errors later in script
	
	selection=$(whiptail --title "SysAdmin User Manager" --backtitle "Select a Utility" --menu "Choose an option" 15 70 0 \
    "1" "Generate Users from .CSV File (-g)" \
    "2" "View Current Account Creation Processes (-v)" \
    "3" "Export Current Account Creation Processes (-e)" \
    "4" "Kill Current Account Creation Processes (-k)" \
    "5" "Help (-h)" \
    "6" "Exit" 3>&1 1>&2 2>&3)
        
    case $selection in
        1)
		fileBrowser "Select .CSV File"
			exitstatus=$?
			if [ $exitstatus -eq 0 ]; then
			    if [ "$selection" == "" ]; then
			        echo "No file selected. Exiting."
			        exit 0
			    else
			    	echo "File Selected: $filepath/$filename"
			        CSV_FILE="$filepath/$filename"
			    fi
			else
			    echo "No file selected. Exiting."
			    exit 1
			fi
            $0 -g "$CSV_FILE"
        ;;
        2)
            $0 -v
        ;;
        3)
        	$0 -e
        ;;
        4)
            $0 -k
        ;;
        5)
        	man ./userMan-Help
        	mainMenuGUI
        ;;
        6)
        	exit 0
        ;;
    esac
}

###		START GENERAL PROCESSES		###

function generateUsers()
{
	validateFile $1
	fileReader $CSV_FILE &
}

function viewUserProcesses()
{
	processes=$(pgrep -f "$0 -g") #PGREP looks for any call of the script that includes a generation flag
	if [ "$processes" == "" ]
	then
    	echo "No Current Account Creation Processes"
    else
    	echo "--Current Account Creation Processes--"
    	echo $processes
    fi
}

function exportUserProcesses()
{
	echo "Account Creation Process PIDs exported. See Logs folder."
	createLog "processExport" "Account Creation PIDs: $(pgrep -f "$0 -g" | xargs)"
}

function killUserProcesses()
{
	pgrep -f "$0 -g" | xargs kill >&/dev/null
	echo "Account Creation Processes terminated."
	createLog "userCreation" "All Current User Creation Processes Killed"
}

###		END GENERAL PROCESSES		###

function fileBrowser()
{

	# Parameter 1 --> Menu Title
	# Parameter 2 --> Optional Starting Directory
	filext=".csv" #Accepted file extension

    if [ -z $2 ] ; then
        directory=$(ls -lhp  | awk -F ' ' ' { print $9 " " $5 } ')
    else
        cd "$2"
        directory=$(ls -lhp  | awk -F ' ' ' { print $9 " " $5 } ')
    fi

    currentDirectory=$(pwd)
    if [ "$currentDirectory" == "/" ] ; then  # Check if the current directory is the root
        selection=$(whiptail --title "$1" \
                              --menu "Select $filext File\n$currentDirectory" 0 0 0 \
                              --cancel-button Cancel \
                              --ok-button Select $directory 3>&1 1>&2 2>&3)
    else   # If not root directory, show '../ PARENT' Option 
        selection=$(whiptail --title "$1" \
                              --menu "Select $filext File\n$currentDirectory" 0 0 0 \
                              --cancel-button Cancel \
                              --ok-button Select ../ PARENT $directory 3>&1 1>&2 2>&3)
    fi

    OPTION=$?
    if [ $OPTION -eq 1 ]; # Check if User Selected Cancel
    then
       return 1
    elif [ $OPTION -eq 0 ];
    then
       if [[ -d "$selection" ]]; # Check if Directory Selected
       then
          fileBrowser "$1" "$selection"
       elif [[ -f "$selection" ]]; # Check if File Selected
       then
	        if [[ $selection == *$filext ]]; # Check if selected File has the provided extension
		    then
		        if (whiptail --title "Confirm Selection" --yesno "DirPath : $currentDirectory\nFileName: $selection" 0 0 \
		                     --yes-button "Confirm" \
		                     --no-button "Retry");
		        then
		            filename="$selection"
		            filepath="$currentDirectory"    # Return full filepath and filename as selection variables
		        else
		            fileBrowser "$1" "$currentDirectory"
		        fi
	        else   # Not correct extension so Inform User and restart
		         whiptail --title "ERROR: File Must have $filext Extension" \
		                  --msgbox "$selection\nYou Must Select a $filext file" 0 0
		         fileBrowser "$1" "$currentDirectory"
	        fi
       else
          # No file detected. Recall function.
          whiptail --title "ERROR: Selection Error" \
                   --msgbox "Error Changing to Path $selection" 0 0
          fileBrowser "$1" "$currentDirectory"
       fi
    fi
}

function validateFile()
{
	#Parameter 1 --> CSV File for Validation

	#Check if File Provided. If not, use WhipTail File Browser Function
	if [ -z $1 ]
	then
		echo "No File Provided as an Argument."
		
		fileBrowser "Select .CSV File"
		exitstatus=$?
		if [ $exitstatus -eq 0 ]; then
		    if [ "$selection" == "" ]; then
		        echo "No file selected. Exiting."
		        exit 0
		    else
		    	echo "File Selected: $filepath/$filename"
		        CSV_FILE="$filepath/$filename"
		    fi
		else
		    echo "No file selected. Exiting."
		    exit 0
		fi
	else 
		CSV_FILE=$1
		echo "File Selected: $pwd/$CSV_FILE"
	fi
	
	#Check File Type
	if [[ $CSV_FILE == *.csv ]]
	then
		echo "'.CSV' File Detected."
	else
		echo "Invalid File Type Detected. Use '.CSV' Format."
		createLog "validationException" "Invalid File Type Detected. Execution Halted. File: ${CSV_FILE}"
		exit 0
	fi
	
	#Count column fields across each row and ensure the column values are correct.
	if [ $(head -1 $CSV_FILE | sed 's/[^,]//g' | wc -c ) == ${#COLUMN_FIELDS[@]} ]
	then
		echo "'.CSV' Column Format Correct."
	else
		echo "'.CSV' Column Format Invalid"
		createLog "validationException" "'.CSV' Column Format Invalid. Execution Halted. File: ${CSV_FILE}"
		exit 0
	fi
	
	#Checks for no inappropriate whitespace, certain special characters that would prevent successful duplicate name account creation and for additional invalid column fields.
	invalidEntries=$(grep -E -n '(^,|,,|,$|^[[:space:]]|[0-9]|*#|*\\|([^,]*,){4}[^,]*)' $CSV_FILE)

	if [ $invalidEntries == ""] &> /dev/null
	then
		echo "'.CSV' Entries Valid."
	else
		echo "Invalid '.CSV' Entries Found."
		echo "Following Entries Invalid:"
		echo $invalidEntries
		createLog "validationException" "Invalid '.CSV' Entries Found. Execution Halted. File: ${CSV_FILE}"
		
		shortPath=$(echo $CSV_FILE | rev | cut -f1 -d'/' | rev)
		if (whiptail --title "Invalid Entries Found in '${shortPath}'" --yesno "Using an invalid '.CSV' file may result in errors.\nNo numbers or whitespace in entries.\n\nPlesae review entries:\n${invalidEntries//[$'\t\r ']}" 0 0 \
	                 --yes-button "Edit ${shortPath}" \
	                 --no-button "Cancel"); 
	    then
		    createLog "validationException" "'.CSV' File Live Editing Mode entered. File: ${CSV_FILE}"
	    	vim $CSV_FILE
	    	createLog "validationException" "Revalidating '.CSV' File. File: ${CSV_FILE}"
	    	validateFile $CSV_FILE
	    else
	        echo "Invalid file selected. Exiting."
	        exit 0
	    fi
	fi
}

function fileReader()
{
	#Parameter 1 --> Validated CSV File for Reading and Account Creation
	
	OLDIFS=$IFS
	IFS=","
	sed 1d $1 | while read name email department manager 
		do
		userCreator $name $email $department $manager & # Create accounts in sub shell
		sleep 1.0
	done
	IFS=$OLDIFS
}

function userCreator()
{
	#Parameter 1 --> Name
	#Parameter 2 --> Email
	#Parameter 3 --> Department
	#Parameter 4 --> Manager
	
	#Verbose User Creation Output. Uncomment for debugging
#     echo -e "Username: $1 \n\
# 	--------------------\n\
#     Email :\t $2\n\
#     Department :\t $3\n\
#     Manager :\t $4\n"
	
	local name=$1
	local usrCount=$(echo $name | sed 's/[^0-9]*//g')
	
	if [ -d Users/$name ] #Check if user exists
    then
	    
	    if [[ $usrCount == "" || $usrCount == 0 ]] #User exists without extension 
	    then
	    	createLog "userException" "User $name already exists. Adding Username Extension."
		    name="${name}#1"
		    userCreator $name $2 $3 $4
		else #User exists with extension 
			createLog "userException" "User $name already exists with extension. Incrementing Username Extension."
			((usrCount++))
			name=$(echo $name | cut -f1 -d"#")
 		    name="${name}#$usrCount"
 		    userCreator $name $2 $3 $4
		fi
	else
 		createLog "userCreation"  "User $name created."
		mkdir -p Users/$name/Documents Users/$name/Pictures Users/$name/Videos
		name=$(echo $name | cut -f1 -d"#")
	    printf "Welcome to the business, $name.\nWe are pleased to have you working in the $3 department.\nIf you have any questions, please speak to your manager,$4\nYour email address is $2\n" > Users/$name/Documents/Welcome.txt
	    sleep 30 #Simulate complex process for account creation.
	fi
}

function createLog()
{	
	#Parameter 1 --> Log Type
	#Parameter 2 --> Log Message
	
	if [ ! -f "Logs" ]
	then
		mkdir -p "Logs" &> /dev/null
	fi
	
	if [ -z $1 ]
	then
		echo "Log creation error. Error: '$2'"
	elif [ $1 == "validationException" ]
	then		
		echo $2 | addTimeStamp >> Logs/validationExceptionLog-$( date +"%F" ).log
	elif [ $1 == "userException" ]
	then		
		echo $2 | addTimeStamp >> Logs/userExceptionLog-$( date +"%F" ).log
	elif [ $1 == "userCreation" ]
	then
		echo $2 | addTimeStamp >> Logs/userCreationLog-$( date +"%F" ).log
	elif [ $1 == "processExport" ]
	then
		echo $2 | addTimeStamp >> Logs/processExportLog-$( date +"%F" ).log
	else
		echo echo "Log creation error. Error: '$2'"
	fi
}

#Function --> Adds Timestamp in set format to any piped string
function addTimeStamp() {
    while IFS= read -r line; do
        echo "[$(date +"%d/%m/%Y %T")]" "$line"
    done
}

COLUMN_FIELDS=("Name" "Email" "Department" "Manager") # Define Colunmns for '.CSV' validation 
main "$@" # Call Main Function and pass all arguments