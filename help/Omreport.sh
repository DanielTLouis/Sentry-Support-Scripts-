#!/bin/bash
#By Andre, Edited by Daniel 
#08/18/2025

# Out put form this script will create a log file and output to the console 

# Serial number and timestamp
sn=$(dmidecode -s system-serial-number)
current_datetime=$(date "+%Y-%m-%d %H:%M:%S")
LOG_FILE="/tmp/Omreport.log"

if [[ -e "${LOG_FILE}" ]]; then
        rm "${LOG_FILE}"
fi
touch "${LOG_FILE}"

echo "OpenManage Report for serial number ${sn}" | tee -a "${LOG_FILE}"
echo "Date and Time of Report: ${current_datetime}" | tee -a "${LOG_FILE}"
echo | tee -a "${LOG_FILE}"

# Generate reports

echo "####################" | tee -a "${LOG_FILE}"
echo "     Alert Log" | tee -a "${LOG_FILE}"
echo "####################" | tee -a "${LOG_FILE}"
# run this whole pipeline with pipefail so grep/omreport failures propagate
( set -o pipefail
  omreport system alertlog \
  | grep -e Critical -e Warning \
  | tee -a "${LOG_FILE}" 
  exit "$rc"
) || echo "Failed to get alertlog." | tee -a "${LOG_FILE}"


echo | tee -a "${LOG_FILE}"
echo "####################" | tee -a "${LOG_FILE}"
echo "      ESM Log" | tee -a "${LOG_FILE}"
echo "####################" | tee -a "${LOG_FILE}"
( set -o pipefail
  out="$(omreport system esmlog 2>&1)"; rc=$?
  printf '%s\n' "$out" | tee -a "$LOG_FILE"
  exit "$rc"        # ← make the subshell fail if omreport failed
) || echo  "Failed to get esmlog." | tee -a "${LOG_FILE}" 

echo | tee -a "${LOG_FILE}"
echo "####################" | tee -a "${LOG_FILE}"
echo "   Chassis Report" | tee -a "${LOG_FILE}"
echo "####################" | tee -a "${LOG_FILE}"
( set -o pipefail
  omreport chassis \
  | tee -a "${LOG_FILE}" 
  exit "$rc"
) || echo "Failed to get chassis report." | tee -a "${LOG_FILE}" 

echo | tee -a "$LOG_FILE"
echo "###########################" | tee -a "${LOG_FILE}"
echo " Storage Controller Report" | tee -a "${LOG_FILE}"
echo "###########################" | tee -a "${LOG_FILE}"
( set -o pipefail
  omreport storage controller \
  | tee -a "${LOG_FILE}"
  exit "$rc"
) || echo "Failed to get storage controller report." | tee -a "${LOG_FILE}"

echo | tee -a "$LOG_FILE"
echo "####################" | tee -a "${LOG_FILE}"
echo "     Disk Report" | tee -a "${LOG_FILE}"
echo "####################" | tee -a "${LOG_FILE}"
( set -o pipefail
  omreport storage pdisk controller=0 \
  | grep -e State -e Name -e Status -e "Failure Predicted" \
  | tee -a "${LOG_FILE}"
  exit "$rc"
) || echo "Failed to get disk report." | tee -a "${LOG_FILE}"

echo | tee -a "$LOG_FILE"
echo "####################" | tee -a "${LOG_FILE}"
echo "     Disk Usage" | tee -a "${LOG_FILE}"
echo "####################" | tee -a "${LOG_FILE}"
( set -o pipefail
  df -h \
  | tee -a "${LOG_FILE}"
  exit "$rc"
) || echo "Failed to get disk usage." | tee -a "${LOG_FILE}"

echo | tee -a "${LOG_FILE}"
echo "####################" | tee -a "${LOG_FILE}"
echo "     NTP Status" | tee -a "${LOG_FILE}"
echo "####################" | tee -a "$LOG_FILE"
( set -o pipefail
  timedatectl status \
  | tee -a "${LOG_FILE}"
  exit "$rc"
) || echo "Failed to get NTP status." | tee -a "${LOG_FILE}"

echo "OpenManage report complete." | tee -a "${LOG_FILE}" 
echo | tee -a "${LOG_FILE}"
echo "Log file created in ${LOG_FILE}" 
