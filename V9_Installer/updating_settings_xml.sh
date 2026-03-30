#!/bin/bash
# updateSettingsXmlForV9.sh #
## By Daniel ##
## This script will modify the settings.xml file located /home/vcs/vcs_server/cfg/ ##
### This will update the paramitars to work with version 9 of the Asentry Software ###
### This script will run while updating the server ###
## EDIT SETTINGS.XML ##
updatingSettingsXml(){
  
  #Start The Script
  mapfile -t </home/vcs/vcs_server/cfg/settings.xml
  rm /home/vcs/vcs_server/cfg/settings.xml
  touch /home/vcs/vcs_server/cfg/settings.xml
    for var in "${MAPFILE[@]}"
    do
      if [[ $var == *"WebServerPort="* ]]
      then
        subString=`echo "$var" | cut -d '"' -f 2`
        var=${var//"$subString"\"/}
        var="${var}19080\""
      elif [[ $var == *"WebServerSSLPort="* ]]
      then
        subString=`echo "$var" | cut -d '"' -f 2`
        var=${var//"$subString"\"/}
        var="${var}443\""
      elif [[ $var == *"WebServerSSL="* ]]
      then
        subString=`echo "$var" | cut -d '"' -f 2`
        var=${var//"$subString"\"/}
        var="${var}false\""
      elif [[ $var == *"DatabaseLocation="* ]]
      then
        subString=`echo "$var" | cut -d '"' -f 2`
        var=${var//"$subString"\"/}
        var="${var}/vcs_user_dir/database/vcs.db\""
      elif [[ $var == *"ArchiveDirectory="* ]]
      then
        subString=`echo "$var" | cut -d '"' -f 1`
        var="$subString\"/video/video00/vcs/archive\""
      elif [[ $var == *"></General>"* ]]
      then
        var="></General>\n"
        # Read the XML file and extract unique videoXX values
        unique_videos=($(grep -oP 'video\d+' /home/vcs/vcs_server/cfg/settings.xml | sort -u))
        
        # Print the array (for testing)
        echo "Unique video entries: ${unique_videos[@]}"
        
        # Access individual elements
        for video in "${unique_videos[@]}"; do
            var+="<Disk
        MountPoint=\"/video/$video/vcs\"
        Enabled=\"true\"
></Disk>\n"
        done
      elif [[ $var == *"<Disk"* ]]
      then
        var=""
      elif [[ $var == *"MountPoint"* ]]
      then
        var=""
      elif [[ $var == *"Enabled"* ]]
      then
        var=""
      elif [[ $var == *"></Disk>"* ]]
      then
        var=""
      fi
      if [[ $var != "" ]]
      then
        sudo echo -e "$var" >> /home/vcs/vcs_server/cfg/settings.xml
      fi
    done

} 
