#!/bin/bash 
#Asentry
#By Daniel
#05/015/2025

#Automated script to migrade existing Telport connections to the new Node Based solution Tailscale 

# List of teleport hostnames mapped to a list 
mapfile -t teleport_users < <(tsh ls | awk 'NF && $1 !~ /Node/ { print $1 }')

# List of teleport hostnames | Manually added
#teleport_users=(
#  ""
#)
CutOver_Users=(
  "Bridgeport-Main-7CYQKD3"
  "Addison-Alarm-6S4V7B3"
  "Addison-Peabody-HZXQGT3"
  "Addison-Surv-B5QZNF3"
  "Heritage-serv2-9TH6Z44"
  "Cincinnati-Art-Museum-Serv1-CHK1JV2"
  "Cincinnati-Art-Museum-Serv2-CHKWHV2"
  "Cincinnati-Art-Museum-Serv3-BQJK903"
  "Cincinnati-Art-Museum-Serv4-9XK8QR3"
  "Solon-Lewis-BVS1FZ3"
  "Beachwood-Bryden-Serv5-FVLRDZ3"
  "Beachwood-District-GJS01R3"
  "Beachwood-HS-4HLFJH2"
  "Beachwood-Hilltop-Serv4-DVLRDZ3"
  "Beachwood-MS-GT101R3"
  "Bridgeport-Main-7CYQKD3"
  "BuffaloAKG-2CLW5S3-VCS3"
  "BuffaloAKG-G72Y5S3-VCS1"
  "BuffaloAKG-HHKFPR3-VCS2"
  "BuffaloAKG-J72Y5S3-VCS4"
  "Butler-Museum-Serv1-H72Y5S3"
  "Butler-Museum-Serv3-94KW4K3"
  "Butler-Museum-Serv4-G4KW4K3"
  "ClevelandMuseumOfNaturalHistory-svr1-F91JK74"
  "Clinton-Massie-Serv1-GS90WX3"
  "Clinton-Massie-Serv2-5R1S7X2"
  "Clinton-Massie-Serv3-6GWBWX3"
  "Dali-Srv1-HXHBW54"
  "DallasMoA-Server1-CVS1FZ3"
  "DallasMoA-Server2-4200PZ3"
  "DallasMoA-Server3-9VS1FZ3"
  "Heritage-serv2-9TH6Z44"
  "Northmont-CampusOutdoor-18VR704"
  "Northmont-Englewood-48VR704"
  "Northmont-HS1-JYM7FW2"
  "Northmont-HS2-JYM7JV2"
  "Northmont-HS3-B4V6PF3"
  "Northmont-HS4-13NM5S3"
  "Northmont-KELC-FT101R3"
  "Northmont-MiddleSchool-B4V5PF3"
  "Northmont-Northmoor-J7VR704"
  "Northmont-Northwood-28VR704"
  "Northmont-Union-38VR704"
  "Parthenon-H0YW624"
  "Girard-College-Serv1-H6C50R3"
  "Hartley-Dodge-Serv1-G6FN0350080Q"
  "Menil-DrawingInstitute-3BGJHK2"  
  "Menil-EnergyHouse-3BGDHK2"
  "Menil-Richmond-Hall-2V47PY2"
  "Menil-RiverOaks-GGYJNW3"
  "Menil-Srv1-1ZL5XP3"
  "Menil-Srv2-FGYJNW3"
  "New-Lebanon-Serv1-4YJX7Y3"
  "St-Bernadette-Serv1-3YJX7Y3"
  "Frist-IP1-GPQ32Z3"
  "Frist-IP2-7JVWQN3"
  "Frist-Srv1-JV1WP54"
  "WeirFarm"
  "winterthur-serv1-2B0B6X3"
  "MontgomeryMFA-Server1-JZXQGT3"
  "MontgomeryMFA2-Server2-859Z044"
  "VeroBeach"
  "Point-Retreat-Serv1-FBC6853"
)

# Loop through each teleport node
for hostname in "${teleport_users[@]}"; do
  found=false
  for element in "${CutOver_Users[@]}"; do
    if [[ "$hostname" == "$element" || ! "$element" =~ ^[a-zA-Z] ]]; then
       found=true
       break
    fi
  done
  if ! $found; then
    echo "Processing: $hostname"
  
    # Refresh package manager metadata
    tsh ssh "$hostname" 'sudo zypper refresh'
  
    # Try installing Tailscale via the install script
    tsh ssh "$hostname" 'curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up --auth-key=tskey-auth-k8SAuTwZd511CNTRL-CpFCZhirwi6xGMP47NU6j68a8ZepY5C9L'
  
    # Ensure tailscale is explicitly installed in case the script fails silently
    tsh ssh "$hostname" 'sudo zypper install -y tailscale'
  
    tsh ssh "$hostname" 'sudo systemctl enable --now tailscaled'
    #tsh ssh "$hostname" 'sudo systemctl start tailscaled'
    tsh ssh "$hostname" 'sudo systemctl status tailscaled'
  
    # Start tailscale with your auth key
    tsh ssh "$hostname" 'sudo tailscale up --auth-key=tskey-auth-k8SAuTwZd511CNTRL-CpFCZhirwi6xGMP47NU6j68a8ZepY5C9L'
  
    echo "✔ Completed setup for $hostname"
    echo "------------------------------------"
  fi 
done

Commands to automate:
Single install in one command:

curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up sudo tailscale up --auth-key=tskey-auth-k8SAuTwZd511CNTRL-CpFCZhirwi6xGMP47NU6j68a8ZepY5C9L
If that failed use

sudo zypper in -y tailscale
sudo systemctl enable --now tailscaled  
sudo systemctl status tailscaled 
sudo tailscale up --auth-key=tskey-auth-k8SAuTwZd511CNTRL-CpFCZhirwi6xGMP47NU6j68a8ZepY5C9L
Errors
Error : curl: (60) SSL certificate problem: unable to get local issuer certificate | Error : Failed to start tailscaled.service: Unit var.mount is masked.
Error : curl: (60) SSL certificate problem: unable to get local issuer certificate
Means that the CA Certificates are mismatched or outdated causing curl to fail

(tick) Solution:

Try to restart the service in user mode

sudo systemctl stop tailscaled
sudo tailscaled --tun=userspace-networking --state=/tmp/tailscale.state &
sudo tailscale up --auth-key=tskey-auth-kWqa6LFVGo11CNTRL-D7NNYPhaj3cwpeaPvQ1b3ceN57H3egV78
Error : Failed to start tailscaled.service: Unit var.mount is masked.
var mount does not let anything writing to it. This seems to be most commonly a runtime mask and not a systemctl mask

(tick) Solution:

Use the commands to remove the runtime mask

sudo systemctl unmask --runtime var.mount
if that removes the mask follow up with the commands:

sudo systemctl reset-failed
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now tailscaled  
sudo systemctl status tailscaled 
sudo tailscale up --auth-key=tskey-auth-kWqa6LFVGo11CNTRL-D7NNYPhaj3cwpeaPvQ1b3ceN57H3egV78
