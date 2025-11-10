#!/bin/bash
#Asentry 
#By Daniel Louis
#06/11/2025

#try to start the wicked service if not running 
sudo system enable --now wicked

#Save the status of wicked service, will return "active" if active 
wicked_status=$(systemctl is-active wicked)

# check if wicked is running 
if [[ "$wicked_status" != "active" ]]; then
    echo "Please manually start Wicke" 
    exit 
fi

for iface in $(ls /sys/class/net/ | grep -E '^e(n|th)'); do
    echo "$iface"
    #sudo echo -e "$var" >> /etc/sysconfig/network/
done 

#TODO work in progress. 
