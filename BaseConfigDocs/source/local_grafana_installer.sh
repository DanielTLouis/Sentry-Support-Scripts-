#!/bin/bash
#Asentry
#By Daniel
#09/08/2025

local_grafana_installer(){
  #Check to see if user is logged into root to run this scirpt
  ##If not exit the script 
  if [[ $EUID -ne 0 ]]; then
     echo "This script must be run as root"
     echo "Please use the command sudo -i to become root" 
     return -1
  fi 
  
  # Install Docker 
  ##If docker does not exsit install it, if it does exsits continue 
  if ! command -v docker >/dev/null 2>&1; then
    zypper install -n docker
    mkdir -p /usr/lib/docker/cli-plugins
    curl -L "https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-x86_64" -o /usr/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/lib/docker/cli-plugins/docker-compose
    mkdir -p /home/vcs/docker
    touch /home/vcs/docker/compose-grafana.yml
    
    cat >  /home/vcs/docker/compose-grafana.yml <<'EOF'
x-docker-logging: &docker-logging
  logging:
    driver: "${LOGGING_DRIVER}"
    options:
      max-size: "${LOGGING_OPTIONS_MAX_SIZE}"
      max-file: "${LOGGING_OPTIONS_MAX_FILE}"

services:
  grafana:
    <<: *docker-logging
    image: grafana/grafana:10.2.4
    restart: unless-stopped
    ports:
      - "${GRAFANA_PORT}:3000"
    networks:
      - demo
    user: '0'
    environment:
      - GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource
    volumes:
      - "${GRAFANA_DATA}:/var/lib/grafana"

networks:
  demo:
    driver: bridge
EOF
  touch /home/vcs/docker/.env
  # Write env file
  cat > /home/vcs/docker/.env <<'EOF'  
## Docker logging
LOGGING_DRIVER=json-file
LOGGING_OPTIONS_MAX_SIZE=100m
LOGGING_OPTIONS_MAX_FILE=30

#Grafana 
GRAFANA_PORT=3003
GRAFANA_DATA=/mnt/video00/dockerdata/grafana/data
EOF
  echo "Docker Login-> "
  echo "   Please Enter Your Nexus Credentials: "
  docker login http://docker.deploy.artsentry.net/
  fi
  
  touch /home/vcs/docker.env.local
  cat > /home/vcs/docker.env.local <<'EOF'
## Docker logging
LOGGING_DRIVER=json-file
LOGGING_OPTIONS_MAX_SIZE=100m
LOGGING_OPTIONS_MAX_FILE=30

# Grafana
GRAFANA_PORT=3003
GRAFANA_DATA=/mnt/video00/dockerdata/grafana/data
EOF
  
  docker compose -f /home/vcs/docker/compose-grafana.yml --env-file /home/vcs/docker/.env pull
  docker compose -f /home/vcs/docker/compose-grafana.yml --env-file /home/vcs/docker/.env up -d

  
  # Install prometheaus
  ##Open ports for grafana 
  ports=(9090 9100 3003)
  for port in "${ports[@]}"; do
    firewall-cmd --zone=internal --add-port=$port/tcp --permanent
  done
  firewall-cmd --reload
  systemctl restart firewalld
  systemctl restart docker
  ##Download Prometheus
  curl -L https://github.com/prometheus/prometheus/releases/download/v3.4.1/prometheus-3.4.1.linux-amd64.tar.gz \
    -o /tmp/prometheus-3.4.1.linux-amd64.tar.gz
  ##Extract and Move Files
  tar xvf /tmp/prometheus-3.4.1.linux-amd64.tar.gz -C /tmp
  cp /tmp/prometheus-3.4.1.linux-amd64/prometheus /usr/local/bin/
  cp /tmp/prometheus-3.4.1.linux-amd64/promtool /usr/local/bin/ 
  mkdir -p /etc/prometheus /var/lib/prometheus
  cp /tmp/prometheus-3.4.1.linux-amd64/prometheus.yml /etc/prometheus/
  ##Create a Prometheus User
  useradd -rs /bin/false prometheus 
  #Set Permissions
  groupadd prometheus
  useradd -r -s /bin/false -g prometheus prometheus
  chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
  ##Create a systemd Service File
  cat > /etc/systemd/system/prometheus.service <<'EOF'
[Unit] 
Description=Prometheus Monitoring 
Wants=network-online.target 
After=network-online.target  
[Service] 
User=prometheus 
Group=prometheus 
Type=simple 
ExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus/ 
[Install]
WantedBy=multi-user.target
EOF
  ##Start and Enable Prometheus
  systemctl daemon-reexec 
  systemctl daemon-reload
  systemctl enable prometheus
  systemctl start prometheus
  ##Verify It's Running
  systemctl status prometheus
  ##Configure Prometheus (Add Targets)
  cat >> /etc/prometheus/prometheus.yml <<'EOF'

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']

  - job_name: 'vcs-spring-metrics'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['localhost:16080']
        labels:
EOF
  systemctl restart prometheus
  # Install Node Exporter 
  ##Download Node Exporter
  curl -L https://github.com/prometheus/node_exporter/releases/download/v1.9.1/node_exporter-1.9.1.linux-amd64.tar.gz \
    -o /tmp/node_exporter-1.9.1.linux-amd64.tar.gz
  ##Extract and Install
  tar xvf /tmp/node_exporter-1.9.1.linux-amd64.tar.gz -C /tmp
  cp /tmp/node_exporter-1.9.1.linux-amd64/node_exporter /usr/local/bin/
  ##Create a Dedicated User (Optional but Recommended)
  useradd -rs /bin/false node_exporter
  ##Create a systemd Service
  cat > /etc/systemd/system/node_exporter.service <<'EOF'
[Unit] 
Description=Node Exporter 
After=network.target  

[Service] 
User=node_exporter 
Group=node_exporter 
Type=simple 
ExecStart=/usr/local/bin/node_exporter  

[Install] 
WantedBy=default.target 
EOF
  ##Start and Enable the Service
  systemctl daemon-reexec 
  groupadd node_exporter
  useradd -r -s /bin/false -g node_exporter node_exporter
  id node_exporter
  chown node_exporter:node_exporter /usr/local/bin/node_exporter
  systemctl daemon-reload 
  systemctl start node_exporter 
  systemctl enable node_exporter
  ##Confirm It's Running
  systemctl status node_exporter 
  
  # Confirm it is running
  echo "-------------------------------------------------------------"
  echo "Granana is set up."
  echo "Please go to the web page with port 3003 to finish the setup."
  echo "-------------------------------------------------------------"
}
