#!/bin/bash
# By Daniel 
# 07/30/2025

# This script will call the Java Garbage Collection through the Java Development tools. 
## The output will be a Log file capturing the before and after of each time it runs. 
## Requeires the Java Develpment tools installed to use the commands from the jcmd library.

#Define the location of the log file. Can be changed here and updated everywhere 
LOG_DIR="/home/vcs/tmp"
LOG_FILE="$LOG_DIR/RAM.log"

# Automatically detect all running Java process PIDs and put them to an array 
PIDS=($(pgrep -f java))

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Timestamped logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Add separation marker for each run
echo "==================== RUN START $(date '+%Y-%m-%d %H:%M:%S') ====================" >> "$LOG_FILE"

# Check if jcmd library is installed 
if ! command -v jcmd &>/dev/null; then
    log "Error: jcmd command not found!"
    exit 1
fi

# Log RAM before GC
log "RAM before:"
free -h | tee -a "$LOG_FILE"

# Run GC on each detected Java PID
for pid in "${PIDS[@]}"; do
    log "Triggering GC for PID $pid"
    if ps -p "$pid" > /dev/null; then
        jcmd "$pid" GC.run >> "$LOG_FILE" 2>&1
        log "GC triggered successfully for $pid"
    else
        log "Warning: PID $pid not running"
    fi
done

# Wait for RAM to catch up for reporting
sleep 5

# Log RAM after GC
log "RAM after:"
free -h | tee -a "$LOG_FILE"

# Add separation marker for end of run
echo "==================== RUN END $(date '+%Y-%m-%d %H:%M:%S') =====================" >> "$LOG_FILE"
