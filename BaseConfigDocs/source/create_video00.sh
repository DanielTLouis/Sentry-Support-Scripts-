#!/bin/bash
#Asentry 
#By Daniel Louis
#07/02/2025

create_video00_main()
{
  #Check to see if user is logged into root to run this scirpt
  ##If not exit the script 
  if [[ $EUID -ne 0 ]]; then
     echo "This script must be run as root"
     echo "Please use the command sudo -i to become root" 
  fi
  
  # Install perccli is not installed 
  if ! hich perccli >/dev/null 2>&1; then
    zypper install wget
    tar -xvzf /BaseConfigDocs/perccli/PERCCLI_7.1623.00_A11_Linux.tar.gz -C /tmp/BaseConfigDocs/perccli/
    zypper install /BaseConfigDocs/perccli/perccli-007.1623.0000.0000-1.noarch.rpm
    ln -s /opt/MegaRAID/perccli/perccli64 /usr/local/bin/perccli
  fi
  
  # Add the raid5 
  echo "Creating RAID 5 array with all available drives..."
  ## Get all unconfigured good drives (UGood)
  mapfile -t drives < <(perccli /c0 /eall /sall show | awk '/UGood/ {print $1}')
  ## Print array contents for verification
  drives_string=""
  for d in "${drives[@]}"; do
      drives_string+="$d,"
  done
  clean_string=$(echo "$drives_string" | sed 's/,D.*//')
  echo "$clean_string" 
  perccli /c0 add vd r5 drives="$clean_string"
  sleep 5
  #perccli /c0/v0 show
  
  # Create the partition and mount it
  parted /dev/sda --script mklabel gpt mkpart primary ext4 0% 100%
  mkfs.ext4 /dev/sda1
  partprobe
  # Create the direcroy and path to mount point 
  mkdir -p /video00
  sleep 5
  # Get the UUID of the new partition
  uuid=$(blkid -s UUID -o value /dev/sda1)
  
  # Add to /etc/fstab if not already present
  if ! grep -q "/video00" /etc/fstab; then
      echo "UUID=${uuid}  /video00  ext4  defaults  0  2" >> /etc/fstab
  fi
  sleep 2
  # Mount all entries
  mount -a
  
  # Display result
  df -h | grep video00
  
  #set up upgrade dirs on video array 
  mkdir /video00/transfer
  mkdir /video00/upgrade_package
  chown vcs:users -R /video00/transfer
  chown vcs:users -R /video00/upgrade_package 
}
