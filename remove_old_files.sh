#!/bin/bash
#Asentry 
#By Daniel Louis
#array of files to be removed | Warning: Bash does not use comma seperation just blank space in the array
#files=("jinput-*.dll" "ServerID.csv" "vcsversion" "VCSUpdate.jar" "VCSLauncher.jar" "Msvcr71d.dll" "Logo.gif" ".installationinformation" "runclient")
date=$(date +%m-%d-%Y)
#for loop to step through the array of files
for var in "${files[@]}"
do
        path=''
        echo "The file to remove is $var"
        #Find the path and assign it to a variable
        path=$(find / -name "$var"  2>/dev/null) #Supressed permission denied errors from find command
        #if the path and file were found do the following
        if [ -n  "$path" ];
        then
                #While loop to accept user input for user conformation before removeing the file that was found at $path
                answering="true"
                while [ "$answering" == "true" ]
                do
                    #Ask for user input and read the input into $answer
                    echo -e "Do you want to remove $path? \n yes(y) or no(n)"
                    read answer
                    #verify if the user entered yes to remove the file
                    if [ "$answer" == "y" ] || [ "$answer" == "yes" ]
                    then 
                        mkdir /tmp/vcs_cleanup 2> /dev/null
                        touch /tmp/vcs_cleanup/log 
                        dateOfFile=$(stat -c "%w" "$path")
                        echo "$path || created $dateOfFile || moved on $date" >> /tmp/vcs_cleanup/log
                        #move the file to a tmp folder 
                        mv "$path" "/tmp/vcs_cleanup/$var"
                        #print that the file has been removed
                        echo "File has been moved to clearn up folder /tmp/vcs_cleanup"
                        answering="false"
                    #verify if the user entered no, they want to keep the file
                    elif [ "$answer" == "n" ] || [ "$answer" == "no" ]
                    then
                        echo "Entered NO | Skipping file"
                        answering="false"
                    #catch all if the user has entered an non valid input and warn them to enter a valid one
                    else 
                        echo "Not a Valid input, please respond with y, yes, n, or no"
                    fi
                done
        else
                echo "File not Found"
        fi
done
mv ./remove_old_files.sh /tmp/vcs_cleanup/remove_old_files.sh
