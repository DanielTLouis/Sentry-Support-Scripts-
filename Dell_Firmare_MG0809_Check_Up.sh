#!/usr/bin/env bash
set -u

#Check if smartctl is installed 
if ! command -v smartctl >/dev/null 2>&1; then
    echo "smartctl not installed. Install with: zypper install smartmontools"
    exit 1
fi
#Check if the Users is root, exit if not
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as the 'root' user. Exiting."
    exit 1
fi

hostname=$(hostname)

echo "whoami=$(whoami)"
echo "PATH=$PATH"
echo "smartctl=$(command -v smartctl)"
ls -l /dev/sd* /dev/bus/0 /dev/megaraid* 2>/dev/null || true
scan_bool=1

echo "Scanning for MegaRAID drives..."
scan_output=$(sudo smartctl --scan)
if [[ -z "$scan_output" ]]; then
    echo "smartctl --scan returned nothing; trying --scan-open..."
    scan_output=$(sudo smartctl --scan-open  || true)
fi

if [[ -z "$scan_output" ]]; then
    echo "No drives detected by smartctl on $hostname"
    scan_bool=0
fi 

if [ "$scan_bool" -eq 1 ]; then
    #Outputs everything to streen 
    printf '%s\n' "$scan_output" | awk '/megaraid,[0-9]+/ {print $1, $3}' | while read -r dev dtype; do
        echo "Checking $hostname"
        echo "------Checking $dev -d $dtype"

        raw=$(smartctl -i -d "$dtype" "$dev" 2>/dev/null || true)

        model=$(printf '%s\n' "$raw" | awk -F: '/Product|Device Model/ {
            gsub(/^[ \t]+/, "", $2)
            print $2
            exit
        }')

        [ -z "${model:-}" ] && model="unknown"

        if [[ "$model" == *MG08* ]]; then
            echo "------$dev -d $dtype = MG08 ($model)"
        elif [[ "$model" == *MG09* ]]; then
            echo "------$dev -d $dtype = MG09 ($model)"
        else
            echo "------$dev -d $dtype = Not MG08/MG09 ($model)"
        fi
    done
else 
    echo "Available block/sg devices:"
    ls -l /dev/sd* /dev/sg* /dev/bus/* 2>&1 || true

   echo "Probing for MegaRAID drives..."

    for dev in /dev/sd* /dev/sg* /dev/bus/*; do
      [ -e "$dev" ] || continue
      echo "Trying base device: $dev"

      for id in {0..63}; do
        raw=$(smartctl -i -d megaraid,$id "$dev" 2>&1)
        rc=$?

        [ "$rc" -ne 0 ] && continue

        model=$(printf '%s\n' "$raw" | awk -F: '
          /Product|Device Model|Model Number/ {
            gsub(/^[ \t]+/, "", $2)
            print $2
            exit
          }')

        [ -z "$model" ] && continue

        echo "------$dev -d megaraid,$id = $model"
      done
    done
fi
