#!/usr/bin/env bash
set -euo pipefail

my_array=(
"100.74.217.1"
"100.113.157.85"
)

for ip in "${my_array[@]}"; do
    echo "Deploying and running on: $ip"
    echo "-----------------------------"
    scp Dell_Firmare_MG0809_Check_Up.sh "root@$ip:/tmp/"

    ssh -x -tt root@"$ip" '
      nsenter -t 1 -m -u -i -n -p -- bash -lc "
        sed -i '\''s/\r$//'\'' /tmp/Dell_Firmare_MG0809_Check_Up.sh
        bash /tmp/Dell_Firmare_MG0809_Check_Up.sh
        rc=\$?
        rm -f /tmp/Dell_Firmare_MG0809_Check_Up.sh
        echo "Removed Dell_Firmare_MG0809_Check_Up.sh"
        exit \$rc
      "
    '
    #ssh -x "root@$ip" "sed -i 's/\r$//' /tmp/Dell_Firmare_MG0809_Check_Up.sh"
    #ssh -x "root@$ip" "bash /tmp/Dell_Firmare_MG0809_Check_Up.sh"
    #ssh -tt root@"$ip" "bash -lc 'bash /tmp/Dell_Firmare_MG0809_Check_Up.sh'"
    #ssh -x "root@$ip" "rm -f /tmp/Dell_Firmare_MG0809_Check_Up.sh"
    echo
    echo
done