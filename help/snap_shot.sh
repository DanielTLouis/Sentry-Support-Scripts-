#!/bin/bash
#Asentry 
#By Daniel Louis
#08/08/2025 

# Function to check if the user is root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   echo "Please use the command sudo -i to become root" 
   exit 1
fi

LOG_DIR=/var/log/
LOG_FILE=${LOG_DIR}/snap_shot.log
MAX_SIZE=$((100 * 1024 * 1024)) # 100 MB in bytes

mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

# Rotate log if >= MAX_SIZE
LOG_FILE_SIZE=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
if (( LOG_FILE_SIZE >= MAX_SIZE )); then
  ts="$(date +%F-%H%M%S)"
  mv "$LOG_FILE" "${LOG_FILE}.${ts}"
  : > "$LOG_FILE"
  gzip -f "${LOG_FILE}.${ts}" || true
fi

# Function to Log with time stamp 
# Peraamiter used $1, first thing called after log() 
## Anything called with log() will be output to $Log_File
## Also will output the same to the console
log() {
    echo "> $1" | tee -a "$LOG_FILE"  # tee takes the output and prints it to the log and screen 
}
log_basic(){
  echo "$1" | tee -a "$LOG_FILE"
}

# Create the log file if is does not exist 
touch "${LOG_FILE}"

date=$(date '+%Y-%m-%d %H:%M:%S')
echo "==================================START SNAP SHOT===========================================" >> "$LOG_FILE"
log "Snap Shot Taken ${date}" 
log_basic "$(hostnamectl)"
log_basic "$(cat /etc/os-release)" 
log_basic "$(uname -a)" 
log_basic "Server Uptime : $(uptime)"
log_basic " " 

now=$(date +%s000)
log_basic " "
log "VCS Version"
if compgen -G "/mnt/video00/vcs_log/vcs*" >/dev/null; then
  if [ $(grep -m1 'NEXT_PUBLIC_ALLOW_ACCESS' /home/vcs/configuration/.env.web | awk '{print $3}') == "true" ]; then
    log_basic "v9 installed, with Browser Interface Enabled"
  else
    log_basic "v9 installed, Dark Launched"
  fi
  latest=$(grep "stateLastUpdated" /mnt/video00/vcs_log/vcs.log \
    | grep -o 'stateLastUpdated":[0-9]*' \
    | cut -d: -f2 \
    | sort -n \
    | tail -1)

  diff_ms=$((now - latest))
  diff_s=$((diff_ms / 1000))
  days=$((diff_s / 86400))
  hours=$(( (diff_s % 86400) / 3600 ))
  mins=$(( (diff_s % 3600) / 60 ))

  log_basic "VCS-Uptime: $(date -d @$((latest/1000)) '+%Y-%m-%d %H:%M:%S') -> ${days} days, ${hours} hours, ${mins} minutes"
  log_basic "v$(awk '/VCS version is/ { sub(/.*VCS version is[[:space:]]*/, ""); print; exit }' /mnt/video00/vcs_log/vcs* 2>/dev/null)"
elif compgen -G "/home/vcs/vcs_log/vcs*" >/dev/null; then 
  if [ $(grep -m1 'NEXT_PUBLIC_ALLOW_ACCESS' /home/vcs/configuration/.env.web | awk '{print $3}') == "true" ]; then
    log_basic "v9 installed, with Browser Interface Enabled"
  else
    log_basic "v9 installed, Dark Launched"
  fi
  latest=$(grep "stateLastUpdated" /home/vcs/vcs_log/vcs.log \
    | grep -o 'stateLastUpdated":[0-9]*' \
    | cut -d: -f2 \
    | sort -n \
    | tail -1)

  diff_ms=$((now - latest))
  diff_s=$((diff_ms / 1000))
  days=$((diff_s / 86400))
  hours=$(( (diff_s % 86400) / 3600 ))
  mins=$(( (diff_s % 3600) / 60 ))

  log_basic "VCS-Uptime: $(date -d @$((latest/1000)) '+%Y-%m-%d %H:%M:%S') -> ${days} days, ${hours} hours, ${mins} minutes"
  log_basic "v$(awk '/VCS version is/ { sub(/.*VCS version is[[:space:]]*/, ""); print; exit }' /home/vcs/vcs_log/vcs* 2>/dev/null)"
elif compgen -G "/var/log/vcs*" >/dev/null; then
  latest=$(grep "stateLastUpdated" /var/log/vcs.log \
    | grep -o 'stateLastUpdated":[0-9]*' \
    | cut -d: -f2 \
    | sort -n \
    | tail -1)

  diff_ms=$((now - latest))
  diff_s=$((diff_ms / 1000))
  days=$((diff_s / 86400))
  hours=$(( (diff_s % 86400) / 3600 ))
  mins=$(( (diff_s % 3600) / 60 ))

  log_basic "VCS-Uptime: $(date -d @$((latest/1000)) '+%Y-%m-%d %H:%M:%S') -> ${days} days, ${hours} hours, ${mins} minutes"
  log_basic "v$(awk '/VCS version is/ { sub(/.*VCS version is[[:space:]]*/, ""); print; exit }' /var/log/vcs* 2>/dev/null)"
else
  log_basic "VCS Version Not Known"
fi


if docker container inspect "docker-vcs-1" >/dev/null 2>&1; then
  # shows running/exited + health if present
  log_basic "Status: $(docker inspect -f '{{.State.Status}}{{if .State.Health}} ({{.State.Health.Status}}){{end}}' docker-vcs-1)"
else
  # simple service state, no pager parsing needed
  log_basic "Status: $(systemctl is-active vcs 2>/dev/null || echo unknown)"
fi
log_basic " "

log_basic " "
log "FILESYSTEM"
log_basic "$(df -hT)"
log_basic " "

log_basic " " 
log "RAM USAGE"
log_basic "$(free -h)" 
log_basic " " 

log_basic " "
log "IP STATUS"
log_basic "$(ip -br a)"
log_basic " "

echo "================================END SNAP SHOT=============================================" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
