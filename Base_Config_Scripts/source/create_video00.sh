#!/bin/bash
#Asentry 
#By Daniel Louis
#07/02/2025

#Function create_video00 
## Will create the partition for video00 and mount it at /mnt/video00
## Will take user input to select what drive to use for the mount point 
create_video00()
{
  echo "Unmounted disks :"
  mapfile -t disks < <(
    lsblk -b -dn -o NAME,SIZE,TYPE,MOUNTPOINT |
    awk '$3=="disk" && $4=="" {
        printf "/dev/%s %.2f TB\n", $1, $2/1000000000000
    }'
  )
  if [[ ${#disks[@]} -eq 0 ]]; then
    echo "No unmounted disks found. Exiting..."
    return 3
  fi
  disks+=("Cancel")
  echo -e "Please Select a unmounted disk to use as video00"
  PS3="Enter your choice: "
  select selected in "${disks[@]}"; do
    if [[ -n "$selected" ]]; then
        disk="${selected%% *}"    # Extract "/dev/sdX" from the selection
        echo
        echo "Selected disk: $disk"
        break
    else
        echo "Invalid selection. Please try again."
    fi
  done
  if [[ $disk == "Cancel" ]]; then
    return 3
  fi

  #Make the mounting folder
  mkdir -p /mnt/video00

  #Create the partion inside the disk
  parted -s "$disk" \
    mklabel gpt \
    mkpart primary ext4 0% 100%
  #Creat the filesystem 
  mkfs.ext4 "${disk}1"

  #Mount the file system 
  mount "${disk}1"  /mnt/video00
  
  echo "Video drive has been mounted"
  df -h
}

create_database()
{
  echo "Unmounted disks :"
  mapfile -t disks < <(
    lsblk -b -dn -o NAME,SIZE,TYPE,MOUNTPOINT |
    awk '$3=="disk" && $4=="" {
        printf "/dev/%s %.2f TB\n", $1, $2/1000000000000
    }'
  )
  if [[ ${#disks[@]} -eq 0 ]]; then
    echo "No unmounted disks found. Exiting..."
    return 3
  fi
  disks+=("Cancel")
  echo -e "Please Select a unmounted disk to use as database"
  PS3="Enter your choice: "
  select selected in "${disks[@]}"; do
    if [[ -n "$selected" ]]; then
        disk="${selected%% *}"    # Extract "/dev/sdX" from the selection
        echo
        echo "Selected disk: $disk"
        break
    else
        echo "Invalid selection. Please try again."
    fi
  done
  if [[ $disk == "Cancel" ]]; then
    return 3
  fi

  #Make the mounting folder
  mkdir -p /database

  #Create the partion inside the disk
  parted -s "$disk" \
    mklabel gpt \
    mkpart primary ext4 0% 100%
  #Creat the filesystem 
  mkfs.ext4 "${disk}1"

  #Mount the file system 
  mount "${disk}1"  /database
  
  echo "Video drive has been mounted"
  df -h
}

create_video00_main()
{
  #Main loop
  while true; do
    echo -e "please selecet what to do:\n   1. Create Video00\n   2. Create Database Drives\n   3. Exit"
    read -p "choose an option: " answer 

    case $answer in 
      1)
        echo "Creating Video00..."
        create_video00 
        ;; 
      2) 
        echo "Creating Database Drives..."
        create_database 
        ;;
      3)
        echo "Exiting..."
        return 1
        ;;
      *)
        echo
        echo "Invalid Option. Please enter a number 1,2, or 3."
        ;;
      esac
  done
}