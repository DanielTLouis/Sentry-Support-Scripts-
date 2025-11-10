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
source /BaseConfigDocs/source/update_hostname.sh
source /BaseConfigDocs/source/install_openManage.sh
source /BaseConfigDocs/source/config_firewall.sh
source /BaseConfigDocs/source/create_video00.sh
source /BaseConfigDocs/source/v8_install_vcs.sh
source /BaseConfigDocs/source/update_hostname.sh
source /BaseConfigDocs/source/server_info_output.sh
source /BaseConfigDocs/source/base_config_last_steps.sh

while true; do
  echo "Please select the option from the following."
  echo "  1. Install Dell Open Manage"
  echo "  2. Set Firewall"
  echo "  3. Create the Video Array"
  echo "  4. Update Hostname"
  echo "  5. Install v8 of the Asentry Software"
  echo "  6. Last Steps"
  echo "  7. Print Server Info"
  echo "  8. Exit"
  read -p "Choose an option: " answer 

  case $answer in 
    1) 
      echo "Installing Open Manage"
      install_openManage_main 
      ;;
    2) 
      echo "Settin Firewall"
      config_firewall_main 
      ;;
    3) 
      echo "Creating video00"
      create_video00_main
      ;;
    4) 
      echo "Updating Hostname"
      update_hostname_main
      ;;
    5) 
      echo "Installing v8"
      v8_install_vcs_main
      ;;
    6) 
      echo "Starting Last Steps"
      base_config_last_steps_main
      ;;
    7) 
      server_info_output_main
      ;;
    8) 
      echo "Exiting..."
      exit 1
      ;;
    *)
      echo
      echo "Invalid Option."
      ;;
  esac
done
