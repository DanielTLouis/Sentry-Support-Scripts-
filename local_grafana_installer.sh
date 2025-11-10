#!/bin/bash
#Asentry
#By Daniel
#09/08/2025

# if docker is not installed, install it
if ! command -v docker >/dev/null 2>&1; then
  sudo zypper install -n docker
  sudo mkdir -p /usr/lib/docker/cli-plugins
  sudo curl -L "https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-x86_64" -o /usr/lib/docker/cli-plugins/docker-compose
  sudo chmod +x /usr/lib/docker/cli-plugins/docker-compose
  mkdir /home/vcs/docker
  touch /home/vcs/docker/compose-grafana.yml
  
  echo -e "x-docker-logging: &docker-logging
  logging:
    driver: \"${LOGGING_DRIVER}\"
    options:
      max-size: \"${LOGGING_OPTIONS_MAX_SIZE}\"
      max-file: \"${LOGGING_OPTIONS_MAX_FILE}\"

services:
  grafana:
    <<: *docker-logging
    image: grafana/grafana:10.2.4
    restart: unless-stopped
    ports:
      - ${GRAFANA_PORT}:3000
    networks:
      - demo
    user: '0'
    environment:
      - GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource
    volumes:
      - ${GRAFANA_DATA}:/var/lib/grafana

networks:
  demo:
    driver: bridge" > /home/vcs/docker/compose-grafana.yml
    
    touch /home/vcs/docker/.env
    
    echo -e "## Docker logging
LOGGING_DRIVER=\"json-file\"
LOGGING_OPTIONS_MAX_SIZE=\"100m\"
LOGGING_OPTIONS_MAX_FILE=\"30\"

#Grafana 
GRAFANA_PORT=3003
GRAFANA_DATA=\"/mnt/video00/dockerdata/grafana/data\""

docker login http://docker.deploy.artsentry.net/
fi

touch /home/vcs/docker.env.local
echo -e "CRATE_DATA=\"/home/erik/vcs/dockerdata/crate/data\"
CRATE_LOGS=\"/home/erik/vcs/dockerdata/crate/logs\"
CRATE_REPOS=\"/home/erik/vcs/dockerdata/crate/repos\"
CRATE_PORT_HTTP=4201
CRATE_PORT_TCP=4301

GRAFANA_DATA=\"/home/erik/vcs/dockerdata/grafana/data\""

docker compose -f /home/vcs/docker /compose-grafana.yml pull
docker compose -f /home/vcs/docker /compose-grafana.yml up -d

#TODO Install prometheaus
#TODO Install Node Exporter 
