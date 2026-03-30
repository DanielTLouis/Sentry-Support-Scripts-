# Function to check if the user is root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   echo "Please use the command sudo -i to become root" 
   exit 1
fi

if compgen -G "/mnt/video00/vcs_log/vcs*" >/dev/null; then
  echo "VCS Version is v9"
  file_path_to_settingsXML='/home/vcs/vcs_server/cfg/settings.xml'
  html_path='/home/vcs/vcs_server/status/server.html'
  report_path='/home/vcs/vcs_server/status/serverReport.csv'
  server_id=$(grep -o 'ServerID="[^"]*"' /home/vcs/vcs_server/cfg/settings.xml | sed 's/ServerID="//;s/"//')
elif compgen -G "/home/vcs/vcs_log/vcs*" >/dev/null; then 
  echo "VCS Version is v9"
  file_path_to_settingsXML='/home/vcs/vcs_server/cfg/settings.xml'
  html_path='/home/vcs/vcs_server/status/server.html'
  report_path='/home/vcs/vcs_server/status/serverReport.csv'
  server_id=$(grep -o 'ServerID="[^"]*"' /home/vcs/vcs_server/cfg/settings.xml | sed 's/ServerID="//;s/"//')
elif compgen -G "/var/log/vcs*" >/dev/null; then
  echo "VCS Version is v8"
  file_path_to_settingsXML='/usr/vcs/cfg/settings.xml'
  html_path='/usr/vcs/status/server.html'
  report_path='/usr/vcs/status/serverReport.csv'
  server_id=$(grep -o 'ServerID="[^"]*"' /usr/vcs/cfg/settings.xml | sed 's/ServerID="//;s/"//')
else
  echo "VCS Version Not Known"
  exit 0
fi
host_name=$(cut -d'-' -f1 /etc/hostname)
#cameras=$(
#  sed -n '/Camera Information/,/System Alarms/p' "$html_path" \
#  | sed 's#</td>#</td>\n#g' \
#  | grep -oP '(?s)<td[^>]*>.*?</td>' \
#  | sed -e 's/<[^>]*>//g' \
#        -e 's/&nbsp;/ /g' \
#        -e 's/^[ \t]*//; s/[ \t]*$//' \
#  | awk '
#      NF { c[++n]=$0 }
#      END {
#        # 20 columns per camera row:
#        # 1 Nbr, 2 Name, 3 Model, 4 Codec, 5 IP, ...
#        for (i=1; i<=n-19; i+=20) {
#          name  = c[i+1]
#          model = c[i+2]
#          ip    = c[i+4]
#          if (ip ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/)
#            printf "%s,%s,%s;\n", name, model, ip
#        }
#      }
#    '
#)
if [[ ! -s "$report_path" ]]; then
  echo "CSV report not found or empty: $report_path"
  exit 1
fi

cameras="$(
  awk -F',' '
    NR==1 {
      for (i=1; i<=NF; i++) h[$i]=i
      # required columns
      if (!h["CAM-IP Address"] || !h["CAM-Camera Model"] || !h["CAM-Name"]) {
        print "Missing expected CAM columns in header" > "/dev/stderr"
        exit 2
      }
      next
    }
    {
      ip    = $(h["CAM-IP Address"])
      model = $(h["CAM-Camera Model"])
      name  = $(h["CAM-Name"])
      driver = (h["CAM-Driver"] ? $(h["CAM-Driver"]) : "")

      # Only Axis cameras (match on model or driver)
      lmodel = tolower(model)
      ldrv   = tolower(driver)

      if (ip ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/ && (lmodel ~ /axis/ || ldrv ~ /axis/)) {
        printf "%s,%s,%s;\n", name, model, ip
      }
    }
  ' "$report_path"
)"
read -p "Please Enter the Cameras' Username(root): " uname  
read -s -p "Please Enter the Camearas' Password: " passwrd 
echo
if [[ ${uname} == "" ]]; then
  uname="root"
fi 
if [ ! -d "/tmp/${host_name}" ]; then
    mkdir -p "/tmp/${host_name}"
fi
out="/tmp/${host_name}/${server_id}_axis_basicdeviceinfo.txt"
: > "$out"

# Query Axis basicdeviceinfo; if down, print dummy JSON (vapix-like shape)
fetch_basicdeviceinfo_or_dummy() {
  local ip="$1"
  local uname="$2"
  local passwrd="$3"

  local tmp_body tmp_err http_code curl_exit

  tmp_body="$(mktemp)"
  tmp_err="$(mktemp)"

  curl_exit=0
  http_code="$(
    curl --silent --show-error --fail \
      --request POST \
      --anyauth \
      --user "${uname}:${passwrd}" \
      --header "Content-Type: application/json" \
      --connect-timeout 3 \
      --max-time 8 \
      --output "$tmp_body" \
      --write-out "%{http_code}" \
      "http://${ip}/axis-cgi/basicdeviceinfo.cgi" \
      --data '{
        "apiVersion": "1.0",
        "context": "my context",
        "method": "getAllProperties"
      }' 2>"$tmp_err"
  )" || curl_exit=$?

  # Auth failure: Axis typically returns 401/403 for bad creds
  if [[ "$http_code" == "401" || "$http_code" == "403" ]]; then
    rm -f "$tmp_body"
    return 42
  fi
    
  # "Down" if curl failed OR non-2xx OR empty body
  if [[ $curl_exit -ne 0 || ! "$http_code" =~ ^2 || ! -s "$tmp_body" ]]; then
    cat <<EOF
{"apiVersion": "1.3", "data": {"propertyList": {"Architecture": "", "ProdNbr": "", "HardwareID": "", "ProdFullName": "", "Version": "", "ProdType": "", "SocSerialNumber": "", "Soc": "", "Brand": "AXIS", "WebURL": "http://www.axis.com", "ProdVariant": "", "SerialNumber": "UNREACHABLE", "ProdShortName": "", "BuildDate": ""}}, "context": "my context"}
EOF
  else
    cat "$tmp_body"
  fi

  rm -f "$tmp_body" "$tmp_err"
  return 0
}




while IFS= read -r rec; do
  [[ -z "$rec" ]] && continue
  ip="${rec##*,}"     # last field "ip;"
  ip="${ip%;}"        # drop trailing ;

  {
    echo "IP: ${ip}"
    passwrd_for_loop="${passwrd}"
    count=1
    while true; do
      echo "Atempt: ${count}"
      json="$(fetch_basicdeviceinfo_or_dummy "$ip" "$uname" "$passwrd_for_loop")"
      rc=$?

      if [[ $rc -eq 42 ]]; then
        echo "Authentication failed for ${ip}. Please re-enter password."
        echo "Type 'Next' to move on to the next camera"
        read -s -p "Password: " passwrd_for_loop < /dev/tty
        echo > /dev/tty
        ((count++))
        if [[ $passwrd_for_loop == "Next" ]]; then
          echo "Skippig ${ip}. Moving to next Camera."
          break
        fi
        continue
      fi

      echo "$json"
      break
    done
    echo
    echo "----------"
  } | tee -a "$out"

done <<< "$cameras"


echo "${cameras}"

echo 
echo 
echo ""
echo "Output has been saved, Please copy it back to the Support Server to complete the SHS"
echo "Copy output to /opt/API_Integration/sites/${host_name}/${server_id}_axis_basicdeviceinfo.txt on office network 192.168.2.70"
echo ">>>>>>>>>Change the \"server#\" to the correct server name"   
echo "Output to ${host_name}/${server_id}_axis_basicdeviceinfo.txt"
