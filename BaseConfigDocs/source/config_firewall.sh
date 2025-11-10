#!/bin/bash
#Asentry 
#By Daniel Louis
#05/14/2025

# OpenSUSE Firewall Configuration Script

# Function to check if the user is root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "This script must be run as root."
        return -1
    fi
}

# Function to display the current firewall configuration
display_firewall() {
    echo "Current Firewall Rules:"
    firewall-cmd --list-all-zones
}

# Function to configure required rules and move eth devices to internal zone
configure_firewall() {
    eth_devices=$(ls /sys/class/net | grep '^eth')
    for device in $eth_devices; do
        firewall-cmd --zone=internal --change-interface=$device --permanent
    done
    
    ports=(22 80 8000 1311 5698 19980 19080 16080 443)
    for port in "${ports[@]}"; do
        firewall-cmd --zone=internal --add-port=$port/tcp --permanent
    done
    
    firewall-cmd --reload
    echo "Configured required ports: ${ports[@]}"
    echo "Moved devices: $eth_devices to internal zone."

    echo "Restarting firewall..."
    systemctl restart firewalld
}

# Ensure the firewall is enabled
ensure_firewall_enabled() {
    systemctl start firewalld
    systemctl enable firewalld
    echo "Firewall enabled and running."
}

# Main menu 
## Add to the menu for Display to display only internal not all zones 
### firewall-cmd --zone=internal --list-all
display_menu() {
    echo "OpenSUSE Firewall Management Script"
    echo "1. Display current firewall configuration"
    echo "2. Configure firewall rules and devices"
    echo "3. Exit"

    read -p "Choose an option: " choice

    case $choice in
        1)
            display_firewall
            return 2 # Keep looping 
            ;;
        2)
            configure_firewall
            return 2 # Keep looping 
            ;;
        3)
            echo "Exiting..."
            return 0 # zero => caller will stop 
            ;;
        *)
            echo "Invalid option."
            return 2 # Keep looping 
            ;;
    esac
}

#Function: main to handle the funtion calls
config_firewall_main()
  {
  # Ensure the script is run as root
  check_root
  
  # Ensure the firewall is enabled
  ensure_firewall_enabled
  
  # Loop the menu until the user chooses to exit
  while true; do
      display_menu
        rc=$? # Grab the return status 
        if [ $rc -eq 0 ]; then # if return == 0
            # User chose Exit — return to the caller (driver script)
            return 0
        fi
        # Else if return != 0 keep looping 
        echo ""
      echo ""
  done

  return 0 #Clean exit to return control to the calling script
}
