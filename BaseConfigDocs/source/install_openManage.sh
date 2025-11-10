#!/bin/bash
#Asentry 
#By Daniel Louis
#05/14/2025

install_openManage_main()
{
  # Check if user is logged in as vcs
  if [ "$USER" != "root" ]; then
      echo "This script must be run as the 'vcs' user. Exiting."
      return -1
  fi
  
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
}
