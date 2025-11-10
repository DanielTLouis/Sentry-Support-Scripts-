#!/bin/bash
#Asentry 
#By Daniel Louis
#08/14/2025
# OpenSUSE Helpfull commands Script
## Will create a menu to walk through helpfull actions for the Asentry servers

#TODO Make this an alias with a manual man call for man asentry 


# Fucntion to give helpfull instructions for using docker commands 
docker_commands_explained()
{
  if [[ -e ${log_dir}  ||  -e ${log_dir_2} ]]; then
    echo -e "Breakdown of Docker Commands for calling asentry compose file: "
    echo -e "[ Note : these have to be run as the vcs user from the /home/vcs/docker directory. ]"
    echo -e "
The Compose file is a programatic way to build docker containers and will be the foundation of the commands.

   
   Start all commands interacting with Docker by calling the script that manages the compose file ./vcs-compose.sh
   
   
   After that add the flags that will modify what containers will be created
      --primary : this flag will call all relivent containers for the primary server
      --all : this flag will bring up all the containers for the serices and server but not the primary server containers
      --services-only : this flag will bing up the part of all that is for the serivces only
      --server-only : this flag will bring up the container for the asentry software (v8) only
   
   
   After the flags add the command itself: 
      start : will start the existing stopped containers
      stop : will stop existing running containers
      restart : will restart exsiting running containers
      up -d : will create and start containrs
      down : will stop and destroy all containers
   


Example of a full command:
./vcs-compose.sh --primary --all up -d \n
"
  else 
    echo "------------v9 is not installed on this server-----------"
    echo "----------------------------------------------------------"
    echo "Check v8 output here:"
    systemctl_command_breakdown
  fi
  #TODO : add a function that will call these commands as well so it has both the breakdown and the option to execute them
}

# Function to inform the user how to use systemctl to start, stop, and restart the system
systemctl_command_breakdown()
{
  if [[ -e ${log_dir}  ||  -e ${log_dir_2} ]]; then
    echo "--------------v9 is installed on this server--------------"
    echo "----------------------------------------------------------"
    echo "Please see the following to run the Asentry Software"
    docker_commands_explained
  else
    echo "Starting, Stoping, and Restarting the Asentry Software from the command line"
    echo "For Version 8 clients the system relies on openSuse's service manager"
    echo -e "
  To call the command start with the command itself : systemctl

  After that add the flag for what you would like to do to the service 
      start : will starts the serivce 
      stop : will end the service 
      restart : will restart the services 
      status : will show the startus of the service, if it is started or enabled 
      reload : will reload the dameon file if any changes were made to the serivce files themselfve 
        [Note : The reload command will very rarelly be used with the Asentry Software ]
      enable : will allow for the service to start up automatically i.e. on reboot
      disable : will allow for the service not to automatically restart i.e. on reboot

  To end the command select the service you would like to target
      For the Asentry software that services is named : vcs

An example of the Full Command: 
systemctl status vcs
  "
  fi
}

# Function that will output the file tree for the installed version of the Asentry Software
## Will output the relevlent files only to the Asentry Software 
## Outputs to the console / terminal 
print_file_tree()
{

  #v9 file structutre 
  log_dir_2="/mnt/video00/vcs_log/vcs.log"
  log_dir="/home/vcs/vcs_log/vcs.log"

  #check if v9 is installed through checking the existence of v9 log files 
  if [[ -e ${log_dir}  ||  -e ${log_dir_2} ]]; then 
  
  ## TODO use .env.vcs file to grab the log dir 
    echo -e "/home/" #0 spaces
    echo -e "└───vcs/" #4 spaces
    echo -e "    ├───docker/" #8 spaces
    tput setaf 2; echo -e "        └───vcs-compose.sh"; tput sgr0 #12 spaces
    echo -e "    ├───vcs_server/ --directroy for the vcs (all v8 files)" #8 spaces
    echo -e "        ├───cfg/" #12 spaces
    echo -e "            ├───license.lic" #16 spaces
    echo -e "            ├───settings.xm" #16 spaces
    echo -e "        └───env.sh" #12 spaces
    if [[ -e ${log_dir} ]]; then #TODO correct this 
      echo -e "     ├───vcs_log/" #8 spaces
      tput setaf 2; echo -e "         ├───vcs.log --primary vcs logs"; tput sgr0 #12 spaces
      echo -e "         ├───server.log" #12 spaces
      echo -e "         └───gc.log" #12 spaces
    fi 
    echo -e "    └───configuration/" #8 spaces
    echo -e "        ├───.env.vcs --enviroment variables set here" #12 spaces
    echo -e "        ├───.env.web --environment variables for web appl set here" #12 spaces
    echo -e "        └───proxyGatewayConfig.json" #12 spaces

    if [[ ! -e ${log_dir} ]]; then
            echo -e "/mnt/" #0 spaces
            echo -e "└───video00/" #4 spaces
            echo -e "    ├───vcs_log/" #8 spaces
            tput setaf 2; echo -e "        ├───vcs.log --primary vcs logs"; tput sgr0 #12 spaces
            echo -e "        ├───server.log" #12 spaces
            echo -e "        └───gc.log" #12 spaces
            echo -e "    ├───vcs/ --video drive"
            echo -e "    └───dockerdata/"
            echo -e "        └───postgres/"
            echo -e "            └───pgdata/ --database location"
    fi
  else 
    echo -e "/usr/"
    echo -e "└───vcs/"
    echo -e "    ├───env.sh"
    echo -e "    ├───database/"
    echo -e "        └───vcs.db"
    echo -e "    └───cfg/"
    echo -e "        ├───license.lic"
    echo -e "        └───settings.xml"
    echo -e "/var/"
    echo -e "└───log/"
    tput setaf 2; echo -e "    ├───vcs.log"; tput sgr0
    echo -e "    ├───server.log"
    echo -e "    └───gc.log"
    echo -e "/video00/"
  fi
}

snap_shot()
{
  # call snap_shot.sh in the BaseConfigDocs/source/ directroy 
  /BaseConfigDocs/source/snap_shot.sh
}

# Function to use the usefull commands from the perccli software
## Will output all to the console 
perccli_commands_breakdown()
{
  loop=true
  while "${loop}"; do
    echo "Select an option for more inforatmion:"
    echo "1. Show all controllers"
    echo "2. Show all physical disks"
    echo "3. Blink LED"
    echo "4. Shows bios"
    echo "5. Show firmware terminal log"
    echo "6. Show event log metadata"
    echo "7. Show events (model-dependent) log"
    echo "8. help"
    echo "9. Go back"

    read -p "Choose an option: " answer
    case $answer in
      1)
        perccli /call show all # Show all controllers 
        ;;
      2) 
        perccli /c0/eall/sall show # all physical disks (enclosure/slot)
        ;;
      3) 
        perccli /c0/eall/sall show # show all physical disks
        ;;
      4) 
        perccli /c0/e25/s4 start locate # blink LED
        ;;
      5) 
        perccli /c0 show termlog # firmware terminal log
        ;;
      6)
        perccli /c0 show eventloginfo # event log metadata
        ;;
      7)
        perccli /c0 show events  # events (model-dependent)
        ;;
      8) 
        perccli help
        ;;
      9)
        loop=false
        ;;
      *)
        echo "Invalid Option."
        ;;
    esac
  done
}

# Function that will call the bash script for the Asentry OM Report 
## will print the ourput to the terminal as well as create a log file in the / direectory called Omreport.log 
omreport_sh_printout()
{
  echo "Printing out the Asentry OM Report"
  /BaseConfigDocs/source/Omreport_Linux.sh || echo "Failed to load bash script from /BaseConfigDocs/source/"
}

racadm_commands_printout()
{
  echo "Racam Commands for iDrac"
  echo -e "
  Inventory / Info
      rac getversion          # iDRAC FW & RACADM versions
      rac getsysinfo          # model, svc tag, BIOS, iDRAC IPs
      rac hwinventroy         # full hardware inventory
      rac getniccfg           # current NIC / IP
   Network
      rac setniccfg -s <ip> <netmask> <gateway>   # e.g. 192.168.1.50 255.255.255.0 192.168.1.1
      rac set iDRAC.NIC.DNSRacName <hostname>     # set iDRAC hostname (optional)
   Time / NTP
      rac set iDrac.NTConfigGroup.NTPEnable 1
      rac set iDRAC.NTPConfigGroup.NTP1 pool.ntp.org
      rac set iDRAC.Time.Timezone /"US/Eastern/"
   Users
      rac getconfig -g cfgUserAdmin                 # list users (legacy group)
      rac set iDRAC.Users.2.Username admin2         # iDRAC9+ style
      rac set iDRAC.Users.2.Password 'StrongPass!'
      rac set iDRAC.Users.2.Privilege 0x1ff         # full privileges
    Power Control
      rac serveraction powerstatus
      rac serveraction powerup
      rac serveraction powerdown
      rac serveraction powercycle
   iDRAC Reset / Factory Defaults
      rac racreset soft          # restart iDRAC (non-disruptive to host)
      rac racreset hard
      rac racresetcfg            # factory reset iDRAC (⚠️ config lost)
   Logs
       rac getsel                 # System/Event Log
       rac clrsel                 # clear SEL
       rac getraclog              # iDRAC log
       rac getlcinfo              # Lifecycle Controller log summary
   Boot Once / Boot Order
      rac set BIOS.OneTimeBoot.OneTimeBootMode OneTimeBootSeq # One-time PXE (example)
      rac set BIOS.OneTimeBoot.OneTimeBootSeq NIC.Integrated.1-1-1
      rac jobqueue create BIOS.Setup.1-1 -r pwrcycle -s TIME_NOW
      rac serveraction powercycle
   Virtual Media (mount ISO over HTTP/CIFS/NFS)
       rac remoteimage -d                                   # detach if connected
       rac remoteimage -c -l http://<server>/images/os.iso  # connect ISO
       rac set BIOS.OneTimeBoot.OneTimeBootMode OneTimeBootSeq
       rac set BIOS.OneTimeBoot.OneTimeBootSeq VirtualCD
       rac jobqueue create BIOS.Setup.1-1 -r pwrcycle -s TIME_NOW
       rac serveraction powercycle
   Firmware Update (Lifecycle Controller handles it)
      rac update -f <file_or_url>                         # modern iDRAC
      rac fwupdate -g -u -a <host> -d <share> -u <user> -p <pass> -t <cifs|nfs|http|https|ftp>
      rac jobqueue view
   BIOS Settings (example tweaks)
       rac set BIOS.ProcSettings.LogicalProc Disabled      # disable HT (example)
       rac set BIOS.SysProfileSettings.SysProfile PerfOptimized
       rac jobqueue create BIOS.Setup.1-1 -r pwrcycle -s TIME_NOW
       rac serveraction powercycle
   Job Queue (when you change BIOS/boot/etc.)
       rac jobqueue view
       rac jobqueue delete --all
   Storage (quick PERC tasks via iDRAC)
       rac storage get pdisks
       rac storage get vdisks
"

}
display_menu()
{
  echo "Asentry Server Help Script"
  echo "1. Usefull Docker Commands for the Asentry Software"
  echo "2. Usefull Commands for Version 8"
  echo "3. Welcome Snap Shot"
  echo "4. Print File Tree"
  echo "5. Perccli commands"
  echo "6. OM Report"
  echo "7. Racadm Commands" # TODO add this one 
  echo "8. Firewall Safe Restart"
  echo "9. Exit"

  read -p "Choose an option to continue: " choice

  case $choice in
    1)
      clear
      echo
      echo "Usefull Docker Commands for the Asentry Software"
      docker_commands_explained
      echo 
      ;;
    2)
      clear
      echo
      echo "Swing Client Commands for the Asentry Software"
      systemctl_command_breakdown
      echo
      ;;
    3)
      clear
      echo
      echo "Taking Snap Shot"
      snap_shot
      echo
      ;;
    4)
      clear
      echo
      echo "The File Tree"
      print_file_tree
      echo
      ;;
    5)
      clear
      echo
      echo "Dell's perccli command tool"
      perccli_commands_breakdown
      echo
      ;;
    6) 
      clear
      echo
      echo "OM Report"
      omreport_sh_printout
      ;;
    7)
      clear
      echo
      racadm_commands_printout
      ;;
    8)
      clear
      echo "Restarting Firewalld"
      /BaseConfigDocs/source/firewall_restart.sh # || echo "Failed to load bash script from /BaseConfigDocs/source/"
      ;;
    9) 
      clear
      echo
      echo "Exiting..."
      exit 0
      ;;
    *)
      echo
      echo "Invalid Option."
      ;;
  esac
}

# Loop the menu until the user chooses to exit
while true; do
    display_menu
    echo ""
done
