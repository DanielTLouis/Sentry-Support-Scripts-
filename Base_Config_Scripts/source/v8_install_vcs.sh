#!/bin/bash 
#Asentry
#By Daniel
#01/07/2025
 
#This script will install v8 of the Asentry Software onto OpenSuse Operating System
##This script needs to be run as root for proper permissions 
##This will be an automatic installation and does not need any intervention apon running 

# TO run the script from the command line call the main function 
# :~# . /BaseConfigDocs/source/v8_install_vcs.sh && v8_install_vcs_main

v8_install_vcs_main()
{
  SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"

  # Check if the User is not Root and exit if not root 
  if [ "$USER" != "root" ]; then
      echo "This script must be run as the 'root' user. Exiting."
      exit 1
  fi
  #if [ -d "$SCRIPT_DIR/vcs_version" ]; then
  #    ehco "BaseConfigDocsExist"
  #else
  #    echo "Makeing Dir"
  #    sudo mkdir -p "$SCRIPT_DIR/vcs_version"
  #fi 
  #scp "root@192.168.2.70:/BaseConfigDocs/vcs_version/server_install.jar" /tmp/BaseConfigDocs/vcs_vesrion 
  
  #wait
  
  # Copy license file to vcs 
  ## Licnse needs to be copied to tmp beforehand 
  echo "Copying license"
  sudo mkdir -p /usr/vcs/cfg
  # Check if file exists before trying to copy
  license_file=$(find /tmp -tpye f -name "*.lic" | head -n 1)
  license_file2=$(find /usr/vcs/cfg/ -tpye f -name "*.lic" | head -n 1)
  if [[ -f "$license_file" ]]; then
    sudo mv /tmp/*.lic /usr/vcs/cfg/license.lic
    echo "Licnese has been moved to /usr/vcs/cfg/ "
  elif [[ -f "$license_file" ]]; then
    echo "License has been found, continuing."
  else:
    echo -e "No licnese found in /tmp, Please make sure the license file in uploaded to\n /usr/vcs/cfg/ "
  fi

  echo "Updating Firewall"
  #TODO check if port is not open 
  sudo firewall-cmd --zone=internal --add-port=19980/tcp
  
  wait
  
  echo "$SOURCE_DIR/vcs_version/server_install.jar"
  if [[ -f "$SOURCE_DIR/vcs_version/server_install.jar" ]]; then
    cp "$SOURCE_DIR/vcs_version/server_install.jar" /usr/vcs
  fi
  if [[ ! -f "/usr/vcs/server_install.jar" ]]; then
    echo "Failed to copy server_install.jar, exiting..."
    exit 1
  fi
  
  wait
  
  echo "Installing the jar"
  java -jar /usr/vcs/server_install.jar 
  
  wait
  
  echo "Checking for licnese.lic"
  # Check if the license.lic is  in the /usr/vcs/cfg folder before starting the service 
  # TODO check if any license exist in the folder and change it to license.lic if there, Add if else to only ask for upload if it is missing
  while [ ! -f /usr/vcs/cfg/license.lic ]; do
    # if file.lic exists changes it to license.lic
  
    #else ask the user to upload the file 
    echo "License is missing. Please add the license file to continue."
    echo "Upload it to /usr/vcs/cfg/. Press Enter to check again..."
    read
  done
  
  echo "License has been found."
  
  echo "updating env.sh"
  # remove any exsiting env.sh
  rm /usr/vcs/env.sh
  # create a fresh env.sh and update it with the proper vars 
  touch /usr/vcs/env.sh
  echo -e "#Instalation directory must be set to the path that vcs is installed. The installer will automatically set this
OTHER_APP_OPTS=\"--ffmpeg=true\"
export INSTALL_DIR=/usr/vcs
export ACKNOWLEDGE_IOS_LICENSE=true
export APPLICATION_BRAND=artsentry
NEXT_PUBLIC_WS_API_PORT=19980
NEXT_PUBLIC_WS_API_VERSION=2" > /usr/vcs/env.sh
  echo "env.sh updated"
  
  wait
  
  echo "Configuring ffmpeg"
  # run ffmped downloads 
  #sh /usr/vcs/ffmpeg.sh #This will not put the files into the correct dir rather to whatever dir this is in 
  JAR_PATH=/usr/vcs/extlib
  mkdir $JAR_PATH
  #curl https://repo1.maven.org/maven2/org/bytedeco/ffmpeg/6.0-1.5.9/ffmpeg-6.0-1.5.9-linux-x86_64-gpl.jar -o $JAR_PATH/ffmpeg-6.0-1.5.9-linux-x86_64-gpl.jar
  #curl https://repo1.maven.org/maven2/org/bytedeco/ffmpeg/6.0-1.5.9/ffmpeg-6.0-1.5.9-macosx-x86_64-gpl.jar -o $JAR_PATH/ffmpeg-6.0-1.5.9-macosx-x86_64-gpl.jar
  
  wait
  
  echo "Configuring Server" 
  /usr/vcs/configure_server 
  
  systemctl start vcs
  systemctl status vcs
}
