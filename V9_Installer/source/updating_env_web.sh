#!/bin/bash
## By Daniel ##

updatingEnvWeb(){

  # Store IP to a variable
  local_ip=$(hostname -I | awk '{print $1}')
  branding=""
  brandBool=""
  looping="true"
  
  # Get the Branding
  echo "Is this installation for a culterial property? (y)es or (n)o"
  while [ "$looping" == "true" ]
  do
    read brandBool
    if [ "$brandBool" == "y" ] || [ "$brandBool" == "yes" ]
    then 
      branding="Art Sentry"
      looping="false"
    elif [ "$brandBool" == "n" ] || [ "$brandBool" == "no" ]
    then
      branding="Acuity-VCT"
      looping="false"
    else
      echo "Is this installation for a culterial property? Please enter a y for yes or a n for no."
    fi
  done

  echo "NEXT_PUBLIC_API_SERVER = ${local_ip} #public ip  used outside of the container to access the proxyGateway or vcs server (cannot be localhost as it will attempt to authenticate inside the container at vcs /api/v1/authenticate)
NEXT_PUBLIC_API_HOST = https
NEXT_PUBLIC_API_PORT = 443
NEXT_PUBLIC_WS_SCHEMA = wss
NEXT_PUBLIC_API_SUB_PATH = \"\"
NEXT_PUBLIC_ALLOW_ACCESS = true

NEXT_PUBLIC_PROJECT = \"${branding}\"    # "Acuity-VCT" | "Art Sentry",

NEXTAUTH_SECRET = my_ultra_secure_nextauth_secret
NEXTAUTH_URL = http://${local_ip}:443/artsentry/api/auth
NEXTAUTH_URL_INTERNAL = http://localhost:3000
" > /home/vcs/configuration/.env.web 

}
