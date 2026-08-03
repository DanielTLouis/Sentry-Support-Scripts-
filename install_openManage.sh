#!/bin/bash
#Asentry 
#By Daniel Louis
#05/14/2025

source /etc/os-release

install_openManage()
{
 # Check if user is logged in as vcs
  if [ "$USER" != "root" ]; then
      echo "This script must be run as the 'root' user. Exiting."
      return 1
  fi

  #find OS version 
  if (( ${VERSION_ID%%.*} >= 16 )); then
    echo "OS-Version is 16, installing..."
    echo "Adding Dell repository..."
    curl -fsSL https://linux.dell.com/repo/hardware/dsu/bootstrap.cgi | bash

    echo "Adjusting Dell repo from suse to sles..."
    if [[ -f /etc/zypp/repos.d/dell-system-update_dependent.repo ]]; then
        sed -i 's/suse/sles/g' /etc/zypp/repos.d/dell-system-update_dependent.repo
    fi

    echo "Importing Dell GPG keys..."
    curl -fsSL https://linux.dell.com/repo/hardware/dsu/copygpgkeys.sh | bash

    echo "Refreshing repositories..."
    if ! zypper refresh; then
        echo "Repo refresh failed. Disabling GPG checks for Dell repos and retrying..."
        zypper mr -G dell-system-update_dependent || true
        zypper mr -G dell-system-update_independent || true
        zypper refresh
    fi

    echo "Installing Dell OpenManage packages..."
    zypper install -y dell-system-update dsu srvadmin-all

    echo "Starting OMSA services..."
    /opt/dell/srvadmin/sbin/srvadmin-services.sh start

    echo "Enabling OMSA services at boot..."
    systemctl enable dataeng || true
    systemctl enable dsm_sa_datamgrd || true

    echo "Opening firewall port 1311..."
    if command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --zone=public --add-port=1311/tcp --permanent
        firewall-cmd --reload
    else
        echo "firewall-cmd not found; skipping firewall configuration."
    fi

    echo "Done."
    echo "Open OMSA at: https://SERVER_IP:1311"

  else
    echo "OS-Version Below 16, installing from tar..."
    sudo mkdir /usr/Dell_OpenManage
    sudo cp /BaseConfigDocs/open_manage/OM-SrvAdmin-Dell-Web-LX-11.0.1.0-5494.SLES15.x86_64_A00.tar.gz /usr/Dell_OpenManage/OM-SrvAdmin-Dell-Web-LX-11.0.1.0-5494.SLES15.x86_64_A00.tar.gz
    sudo tar -xzf /usr/Dell_OpenManage/OM-SrvAdmin-Dell-Web-LX-11.0.1.0-5494.SLES15.x86_64_A00.tar.gz -C /usr/Dell_OpenManage/
    sudo rpm -ivh --force --nodeps /usr/Dell_OpenManage/linux/RPMS/supportRPMS/srvadmin/SLES15/x86_64/*.rpm
    
    wait
    
    /opt/dell/srvadmin/sbin/srvadmin-services.sh start  
    
    sudo systemctl list-unit-files | grep srvadmin 
    sudo systemctl list-unit-files | grep dsm
    
    sudo systemctl enable instsvcdrv.service 
    sudo systemctl enable dsm_sa_datamgrd.service 
    sudo systemctl enable dsm_sa_eventmgrd.service 
    sudo systemctl enable dsm_sa_snmpd.service 
    sudo systemctl enable dsm_om_connsvc.service
    
    sudo systemctl start instsvcdrv.service 
    sudo systemctl start dsm_sa_datamgrd.service 
    sudo systemctl start dsm_sa_eventmgrd.service 
    sudo systemctl start dsm_sa_snmpd.service 
    sudo systemctl start dsm_om_connsvc.service
    
    export PATH=$PATH:/opt/dell/srvadmin/bin
    source /etc/bash.bashrc
    
    sudo systemctl status dsm_sa_datamgrd.service 
    sudo systemctl status dsm_om_connsvc.service 
  fi
}

restart_openManage()
{
  sudo systemctl restart instsvcdrv.service 
  sudo systemctl restart dsm_sa_datamgrd.service 
  sudo systemctl restart dsm_sa_eventmgrd.service 
  sudo systemctl restart dsm_sa_snmpd.service 
  sudo systemctl restart dsm_om_connsvc.service

  sudo systemctl status dsm_sa_datamgrd.service 
  sudo systemctl status dsm_om_connsvc.service 
}

install_openManage_main()
{
  while true; do 
    echo ""
    echo "  1. Install Open Manage."
    echo "  2. Restart Open Manage."
    echo "  3. Exit."
    read -p "Choose an option: " choice
    
    case $choice in 
      1)
        echo "Installing Open Manage..."
        install_openManage
        ;;
      2) 
        echo "Restarting Open Manage..."
        restart_openManage
        ;;
      3)
        echo "...Exiting"
        break
        ;;
      *) 
        echo "Invailid input"
    esac
  done 
}

install_openManage_main