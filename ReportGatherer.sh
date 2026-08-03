
my_array=("100.99.135.18")
folder="Dali"

mkdir "$folder"

for ip in "${my_array[@]}"; do
  echo "Deploying and running on: $ip"
  scp Omreport.sh "root@$ip:/upgrade_pkg/"
  ssh "root@$ip" "bash /upgrade_pkg/Omreport.sh"
  scp "root@$ip:/tmp/Omreport.log" "$folder/OMReport_$ip.log"
  scp "root@$ip:/usr/vcs/status/server.html" "$folder/server_$ip.html"
done


