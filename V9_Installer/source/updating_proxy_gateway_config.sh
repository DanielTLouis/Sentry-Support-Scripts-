#!/bin/bash
#By Daniel Louis

# Function to call updatingProxyGatewayConfig
updatingProxyGatewayConfig() {

  ## ASK IF IT IS A MULTI SERVER HEAD ## 
  while true; do
    read -p "Is this a multi-server setup? (yes/no): " MULTI_SERVER
    if [[ "$MULTI_SERVER" == "yes" || "$MULTI_SERVER" == "no" ]]; then
      break
    else
      echo "Invalid input. Please answer 'yes' or 'no'."
    fi
  done

  SERVER_DETAILS=()

  if [[ "$MULTI_SERVER" == "yes" ]]; then
    echo "Entering multi-server configuration..."
    echo "Only enter details for additional servers, not this one."

    while true; do
      read -p "Enter server name: " SERVER_NAME
      read -p "Enter server IP: " SERVER_IP
      SERVER_DETAILS+=("$SERVER_NAME:$SERVER_IP")

      while true; do
        read -p "Do you want to add another server? (yes/no): " CONTINUE
        if [[ "$CONTINUE" == "yes" || "$CONTINUE" == "no" ]]; then
          break
        else
          echo "Invalid input. Please answer 'yes' or 'no'."
        fi
      done

      if [[ "$CONTINUE" != "yes" ]]; then
        break
      fi
    done
  fi

  # Get the IP address of the machine
  IP_ADDRESS=$(hostname -I | awk '{print $1}')
  echo "The IP address of the machine is: $IP_ADDRESS"

  serverId=""
  mapfile -t MAPFILE </home/vcs/vcs_server/cfg/settings.xml
  for var in "${MAPFILE[@]}"
  do
    if [[ $var == *"ServerID="* ]]
    then
      subString=`echo "$var" | cut -d'"' -f 2`
      serverId="$subString"
      break
    fi
  done

  echo "Server ID extracted: $serverId"

  # Construct the JSON content
  JSON_CONTENT="{\n  \"servers\": [\n    {\n      \"ip\": \"$IP_ADDRESS\",\n      \"id\": \"$serverId\"\n    }"

  for SERVER in "${SERVER_DETAILS[@]}"; do
    SERVER_IP=$(echo "$SERVER" | cut -d':' -f2)
    SERVER_NAME=$(echo "$SERVER" | cut -d':' -f1)
    JSON_CONTENT+="\n    ,{\n      \"ip\": \"$SERVER_IP\",\n      \"id\": \"$SERVER_NAME\"\n    }"
  done

  JSON_CONTENT+="\n  ],\n  \"secretKey\": \"secretKey\",\n  \"listeningPort\": 3090,\n  \"allowedOrigins\": [\"*\"]\n}"

  # Write to proxyGatewayConfig.json
  echo -e "$JSON_CONTENT" > /home/vcs/configuration/proxyGatewayConfig.json
  
}
