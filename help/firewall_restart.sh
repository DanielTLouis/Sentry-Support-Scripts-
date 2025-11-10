#!/bin/bash
#Asentry
#By Daniel Louis
#06/12/2025

answer=""
while [[ "$answer" != 'Y' ]]; do
  echo "Have you asked the customer if is it safe to restart the Asentry Software?(Y/n)"
  read answer
  if [[ "$answer" == 'n' || "$answer" == 'N' ]]; then
    echo "Please get the customer's permission before restarting their software."
    exit 1
  elif [[ "$answer" != 'Y' ]]; then
    echo
    echo "Please provide either a Y for Yes or a n for no, Capitalization matters"
    echo
  fi
done

# if v9 is installed and running restart the software as well as docker 
# TODO have if find if docker ps have vcs up 
if docker ps --filter "name=^docker-vcs-1$" --filter "status=running" --format '{{.Names}}' | grep -qx docker-vcs-1; then
  echo "v9 found and will be restarting software as well"
  /home/vcs/docker/vcs-compose.sh --primary --all down 
  wait 5
  sudo systemctl restart firewalld 
  echo "firewalld restarting"
  sudo systemctl restart docker
  echo "Docker restarting"
  # primary is checked in .env.vcs with variable VCS_PRIMARY_SERVER=
  line=$(grep -m1 'VCS_PRIMARY_SERVER' /home/vcs/configuration/.env.vcs) || { echo "not found"; exit 1; }
  value=${line#*=}                  # drop everything up to '='
  value=${value%%#*}                # strip inline comment starting with '#'
  value=$(xargs <<<"$value")        # trim whitespace
  value=${value%\"}; value=${value#\"}  # remove surrounding quotes if present
  echo "$line"
  echo "$value"
  if [[ "$value" == "true" ]]; then
    /home/vcs/docker/vcs-compose.sh --primary --all up -d
  else
    /home/vcs/docker/vcs-compose.sh --all up -d
  fi
# if docker is installed but not v9, just restart docker with it
elif command -v docker >/dev/null 2>&1; then
  echo "Docker found but no running v9 detected."
  sudo systemctl restart firewalld 
  echo "firewalld restarted"
  sudo systemctl restart docker
  echo "Docker restarted"

# if no docker installed on the server, no need to worry about anything but restarting firewalld 
else
  echo "No Docker found on the system"
  sudo systemctl restart firewalld 
  echo "firewalld restarted"
fi
