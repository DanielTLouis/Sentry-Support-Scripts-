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
  
  # Update root password 
  ## Store service tag into a variable 
  if command sudo dmidecode -s system-serial-number && [ "$(command sudo dmidecode -s system-serial-number)" != "Not Specified" ]; then
    service_tag=$(sudo dmidecode -s system-serial-number)
    suffix=$(echo "$service_tag" | rev | cut -c1-4 | tr '[:upper:]' '[:lower:]')
    password="${service_tag}@${suffix}"
    ## Update with newly formed password 
    echo "root:$password" | sudo chpasswd
    echo "Password for user root set to standards" 
  else
    password="Asdf370)"
    echo "root:$password" | sudo chpasswd
    echo "Password for user root set to DEAFUALT"
  fi 
  
  # Install TaleScale
  #curl -fsSL https://pkgs.tailscale.com/stable/opensuse/tailscale.repo | sudo tee /etc/zypp/repos.d/tailscale.repo
  #sudo zypper refresh
  #sudo zypper install -y tailscale
  #sudo systemctl enable --now tailscaled
  #sudo tailscale up
  #tailscale status
  
  # Install perccli - Same thing as StorCLI
  if ! hich perccli >/dev/null 2>&1; then
    zypper install wget
    tar -xvzf /BaseConfigDocs/perccli/PERCCLI_7.1623.00_A11_Linux.tar.gz -C /BaseConfigDocs/perccli/
    zypper install /BaseConfigDocs/perccli/perccli-007.1623.0000.0000-1.noarch.rpm
    ln -s /opt/MegaRAID/perccli/perccli64 /usr/local/bin/perccli
  fi
  
  # Set up asentry_man alaias 
FILE=/etc/bash.bashrc.local
MARK_BEGIN='# BEGIN HELP BLOCK'
MARK_END='# END HELP BLOCK'

# Delete existing block (if any)
sudo sed -i "/$MARK_BEGIN/,/$MARK_END/d" "$FILE"

# Append the new block
sudo bash -c "cat >> '$FILE' <<'EOF'
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
  ###############################" >  /etc/motd
  echo "Message of the Day set"
}
