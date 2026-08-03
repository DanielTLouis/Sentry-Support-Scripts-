#!/bin/bash
#Asentry 
#By Daniel Louis
#06/12/2025

#for i in /BaseConfigDocs/source/*.sh; do
#  if [[ "$i" != "*run_base_config.sh" ]]; then
#      echo "$i"
      #/BaseConfigDocs/source/$i
#  fi
#done
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/source"
source "$SOURCE_DIR/update_hostname.sh"
source "$SOURCE_DIR/install_openManage.sh"
source "$SOURCE_DIR/config_firewall.sh"
source "$SOURCE_DIR/create_video00.sh"
source "$SOURCE_DIR/v8_install_vcs.sh"
source "$SOURCE_DIR/server_info_output.sh"
source "$SOURCE_DIR/base_config_last_steps.sh"
source "$SOURCE_DIR/setup_network_config.sh"
source "$SOURCE_DIR/local_grafana_installer.sh"
source "$SOURCE_DIR/tailscale_install.sh"

while true; do
  echo "Please select the option from the following."
  echo "  1. Install Dell Open Manage"
  echo "  2. Set Network to DHCP"
  echo "  3. Set Firewall"
  echo "  4. Create the Video Array"
  echo "  5. Update Hostname"
  echo "  6. Install v8 of the Asentry Software"
  echo "  7. Last Steps"
  echo "  8. Print Server Info"
  echo "  9. Install a Local Instance of Grafana"
  echo "  10. Install Tailscale"
  echo "  11. Exit"
  read -p "Choose an option: " answer 

  case $answer in 
    1) 
      echo "Installing Open Manage"
      install_openManage_main 
      ;;
    2)
      setup_network_config
      ;;
    3) 
      echo "Settin Firewall"
      config_firewall_main 
      ;;
    4) 
      echo "Creating video00"
      create_video00_main
      ;;
    5) 
      echo "Updating Hostname"
      update_hostname_main
      ;;
    6) 
      echo "Installing v8"
      v8_install_vcs_main
      ;;
    7) 
      echo "Starting Last Steps"
      base_config_last_steps_main
      ;;
    8) 
      echo "Printing Server Info"
      server_info_output_main
      ;;
    9)
      echo "Installing Local Grafana Instance"
      local_grafana_installer
      ;;
    10)
      echo "Installing Tail Scale"
      tailscale_install 
      ;;
    11) 
      echo "Exiting..."
      exit 1
      ;;
    *)
      echo
      echo "Invalid Option."
      ;;
  esac
done
