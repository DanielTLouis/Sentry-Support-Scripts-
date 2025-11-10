#!/bin/bash
#Asentry 
#By Daniel Louis
#10/29/2024

#Check to see if user is logged into root to run this scirpt
##If not exit the script 
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   echo "Please use the command sudo -i to become root" 
   return -1
fi 

#Function update_hostname 
update_hostname()
{
  #ask for input to change name to
  answer=""
  answering="true"
  if command -v dmidecode >/dev/null 2>&1; then
    serial=$(sudo -n dmidecode -s system-serial-number 2>/dev/null | awk 'NF{print; exit}')
    if [[ -n "$serial" && "$serial" != "Not Specified" ]]; then
      tag=$(sudo dmidecode -s system-serial-number)
    else 
      tag="VM"
    fi
  else
    tag="VM"
  fi
  while [ "$answering" == "true" ]
  do
      #Ask for user input and read the input into $answer
      echo -e "Please enter a hostname (name will automatically include -ServerTag at end)"
      read -p "Enter Hostname: " answer
      #verify if the user entered a string
      if [ "$answer" == "" ]; then 
          echo "A hostname cannot be blank"
      else
          answering="false"
      fi
      ### Add more gaurds ###
  done
  
  #update /etc/hostname file
  rm /etc/hostname 
  touch /etc/hostname
  echo "${answer}-${tag}" > /etc/hostname  
  #update /etc/hosts file | Sed has commands to delete 12th line '12d' and insert '12i '
  sed -i  '12d' /etc/hosts
  sed -i  "12i 127.0.0.1       localhost       ${answer}-${tag}" /etc/hosts
  #sed -i means to save the changes
  #sed -i '12s/$/ <string>' will put it string at the end of the 12th line
  
  #run command hostname with new string 
  hostname "${answer}-${tag}"
  
  echo "hostname updated to ${answer}-${tag}"

  echo "Exiting..."
}

#Function: main controller function 
update_hostname_main()
{
  ##Ask if the user wants to update the name or let them exit safely
  while true; do
    
    echo "Please choose to update the hostname or exit."
    echo "    1. Update Hostname"
    echo "    2. Exit"
    read -p "Choose an option: " answer
    
    if [ $answer == "1" ]; then
        update_hostname
    elif [ $answer == "2" ]; then
      echo "Exiting..."
      break
    else 
      echo 
      echo "Please select one of the two choices by entering either a 1 or 2."
    fi
  
  done
  return 0
}
