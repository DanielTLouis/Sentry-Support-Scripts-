#!/bin/bash
#By Daniel Louis
##For use with the Asentry Sowfware v9 installation 

fontEndPermissionUpdate() {
  
  # Store IP to a variable
  local_ip=$(hostname -I | awk '{print $1}')
  
  #ask for username and password 
  ## if not then auto one will be admin system
  username="admin"
  password="system"
  answering="true"
  while [ answering == "true" ]; do
  
  done

  #if single server local_ip should just be ip
  #if multi-server local_ip should have /gateway added to the following 
  ## http://$local_ip/gateway/
  
  # Store the JWT response from curl
  token=$(curl -s --location "http://$local_ip/api/v1/authenticate" \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' \
    --data '{
      "password": "system",
      "username": "admin"
    }' | jq -r '.jwt')

  curl --location --request PATCH 'http://$local_ip/api/v1/admin/permissions/user/admin' \
  --header 'Content-Type: application/json' \
  --header 'Authorization: Bearer $token' \
  --data '{
      "WEB_APP_SETTINGS_CAMERA": true,
      "WEB_APP_SETTINGS": true,
      "WEB_APP_SETTINGS_ACKNOWLEDGEMENT_REASON": true,
      "Web App Settings Customer Configuration" : true,
      "VIEW_WEB_APP_LIVE_VIEW": true,
      "Web App Alarm Archive": true,
      "View Dashboard": true
  
  }'

}
