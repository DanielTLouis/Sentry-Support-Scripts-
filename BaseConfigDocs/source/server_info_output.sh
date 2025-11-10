#!/bin/bash
#Asentry
#By Daniel Louis
#06/12/2025

server_info_output_main()
{
  clear
  #Check to see if user is logged into root to run this scirpt
  ##If not exit the script
  if [[ $EUID -ne 0 ]]; then
     echo "This script must be run as root"
     echo "Please use the command sudo -i to become root"
     return -1
  fi
  
  echo ""
  echo "Service Tag: $(sudo dmidecode -s system-serial-number)"
  echo "VCS SN: VCS-$(sudo dmidecode -s system-serial-number)"
  echo "OS Version: $(cat /etc/os-release | grep "PRETTY_NAME" | cut -d '=' -f2)"
  
  echo "IP:"
  echo "    $(ip -4 -o addr show up | awk '$2 ~ /^eth/ {print $4}')"
  
  echo "Server Info:"
  # use cut to remove tags
  ## -d will determin where to cut up the string creating two parts in this instance
  ## -f2 will select the second of the 2 parts of the cut
  echo "    Brand: $(sudo dmidecode -t system | grep -E 'Manufacturer' | cut -d ':' -f2)"
  echo "    Model: $(sudo dmidecode -t system | grep -E 'Product Name'| cut -d ':' -f2)"
  echo "    CPU: $(cat /proc/cpuinfo | grep -E 'model name' | uniq | cut -d ':' -f2)"
  
  echo "iDrac: "
  # awk -F' = ' — splits by = and returns the value.
  # head -n1: Ensures you only get the primary IP address line (ignoring others like "Static IP Address", if any).
  echo "    IP: $(racadm getniccfg | grep 'IP Address' | awk -F' = ' '{print $2}' | head -n1)"
  echo "    DHCP: $(racadm getniccfg | grep 'DHCP' | awk -F' = ' '{print $2}' | head -n1)"
  echo "    iDrac Type: $(racadm get iDRAC.NIC | grep '^\[Key=' | cut -d '=' -f2 | cut -d '#' -f1 | cut -d '.' -f2)"
  echo "    Subnet Mask: $(racadm getniccfg | grep 'Static Subnet Mask' | awk -F' = ' '{print $2}' | head -n1)"
  echo "    Gateway: $(racadm getniccfg | grep 'Gateway' | awk -F' = ' '{print $2}' | head -n1)"
  echo "    MAC Address: $(racadm get iDRAC.NIC | grep '#MACAddress' | cut -d '=' -f2)"
  
  echo "Memory: "
  sudo dmidecode --type 17 | grep -E 'Size|Serial Number' | while read -r line; do
    if [[ $line != Size:\ No* ]]; then
      echo -e "    $line"
    fi
    if [[ $line == Logic* ]]; then
      echo ""
    fi
  done
  
  echo "HDDs: "
  # shell pipeline
  ## awk Processes and formats the raw output
  ## /^Name/ {name=$0; sub(/^Name[[:space:]]*:[[:space:]]*/, "", name) Matches Lines beginning with Name and Assign the whole line to name
  ### Use sub to remove the prefix "Name : " from the line, leaving only the disk name like "Physical Disk 0:0".
  omreport storage pdisk controller=0 | awk '
  /^Vendor ID/ {vendor=$0; sub(/^Vendor ID[[:space:]]*:[[:space:]]*/, "", vendor)}
  /^ID/ {id=$0; sub(/^ID[[:space:]]*:[[:space:]]*/, "", id)}
  /^Serial No/ {serial=$0; sub(/^Serial No\.[[:space:]]*:[[:space:]]*/, "", serial)}
  /^$/ {
      if (vendor && id && serial) { #check if each has an entry
          printf "    %s: %s: %s\n", vendor, id, serial #Prints the patters %s is each after ,
          vendor = ""
          id = ""
          serial = ""
      }
  }
  '
  
  echo "NICs: "
  omreport system summary | awk '
  /^Network Interface/ {iface=$3}
  /^MAC Address/ {
      mac=$NF;
      printf "    Network Interface %s:  MAC: %s\n", iface, mac
  }
  '
}
