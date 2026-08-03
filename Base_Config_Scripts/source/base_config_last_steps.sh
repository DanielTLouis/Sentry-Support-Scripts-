#!/bin/bash
#Asentry 
#By Daniel Louis
#06/12/2025

# TODO Break this up into different functions 

base_config_last_steps_main()
{
  #Check to see if user is logged into root to run this scirpt
  ##If not exit the script 
  if [[ $EUID -ne 0 ]]; then
     echo "This script must be run as root"
     echo "Please use the command sudo -i to become root" 
     return -1
  fi

  
  # Set up asentry_man alaias 
  FILE=/etc/bash.bashrc.local
  MARK_BEGIN='# BEGIN HELP BLOCK'
  MARK_END='# END HELP BLOCK'

  # Delete existing block (if any)
  sed -i "/$MARK_BEGIN/,/$MARK_END/d" "$FILE"

  # Append the new block
  bash -c "cat >> '$FILE' <<'EOF'
$MARK_BEGIN
alias asentry_man=\"/BaseConfigDocs/help.sh\"
$MARK_END
EOF"
  ## reload the system bashrc (which sources .local on openSUSE)
  # Load local customizations if present
  if [ -f /etc/bash.bashrc.local ]; then
      . /etc/bash.bashrc.local
  fi
  type asentry_man
  echo "Help Alias set" 
  
  
  echo "
  ###############################
  ##       For Help Enter      ##
  ##         asentry_man       ##
  ##  File Location:           ##
  ##  BaseConfigDocs/help.sh   ##
  ###############################" >  /etc/motd
  echo "Message of the Day set"
}

