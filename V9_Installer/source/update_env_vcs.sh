#!/bin/bash
## By Daniel ##

updateEnvVcs(){

  local_ip=$(hostname -I | awk '{print $1}')
  
  #echo "$local_ip" #first argument passed in (which is the ip address)
  
  ## Get user input for the mnt location 
  mnt=""
  echo "What is the name of the mnt drive?"
  read mnt
  
  if [ "${mnt:0:1}" == "/" ]; then
    mnt=$(echo "${mnt}" | cut -d '/' -f 2)
  fi
  
  local_ip=$(hostname -I | awk '{print $1}')
  
  #Hard code each line instead of looping 
  echo "APP_USER=\"vcs\"
APP_PASSWORD=\"vcs\"
DB_HOST=\"postgres\"
DB_PORT=\"5432\"
DB_NAME=\"postgres\"
SSL_CERTS=\"./nginx_ssl_certs\"
#Location of docker container configuration for multiserver-proxy and frontend
CONFIG_DIR=\"/home/vcs/configuration\"

POSTGRES_VOLUME_PGDATA=\"/${mnt}/dockerdata/postgres/pgdata\"
POSTGRES_VOLUME_CONFIG=\"./postgres/config\"
POSTGRES_VOLUME_ARCHIVE=\"/${mnt}/dockerdata/postgres/archive\"
VCS_SERVER_HTTP_URL=\"http://${local_ip}\" # cannot be localhost

META_DB_NAME=\"postgres\"
META_USER=\"metabase\"
META_PASSWORD=\"metabase\"
POSTGRES_META_VOLUME_PGDATA=\"/${mnt}/dockerdata/postgres-metabase/pgdata\"
POSTGRES_META_VOLUME_CONFIG=\"./postgres-metabase/config\"
POSTGRES_META_VOLUME_ARCHIVE=\"/${mnt}/dockerdata/postgres-metabase/archive\"

SUPERSET_DB_NAME=\"postgres\"
SUPERSET_USER=\"superset\"
SUPERSET_PASSWORD=\"superset\"
POSTGRES_SUPERSET_VOLUME_PGDATA=\"/${mnt}/dockerdata/postgres-superset/pgdata\"
POSTGRES_SUPERSET_VOLUME_CONFIG=\"./postgres-superset/config\"
POSTGRES_SUPERSET_VOLUME_ARCHIVE=\"/${mnt}/dockerdata/postgres-superset/archive\"

BACKUP_LOCATION=\"/${mnt}/video00/dev-int-1/backup\"

NEXUS_WEB_URL=\"https://deploy.artsentry.net\"
NEXUS_USERNAME=\"csupport\"
NEXUS_PASSWORD=\"micrij-cabKax-3pitxe\"
VCS_REPO=\"13.51.74.46:8083\"
VCS_HOME=\"/home/vcs/vcs_server\"
VCS_VIDEO=\"/mnt/\"
VCS_LOG=\"/mnt/video00/vcs_log\"
VCS_EXPORT=\"/vcs_export\"
#this port will need to match what is set inside the vcs settings.xml for webserver port
VCS_HTTP_PORT=19080
VCS_IP="${local_ip}"
VCS_PRIMARY_SERVER=false
VCS_WS_V2_PORT=19980

#VCS should not be using ssl (this port is where the https will be mapped to can be ignored and should need to be changed)
VCS_HTTPS_PORT=19443
#These ports are for nginx they should be the standard http and https ports
NGINX_HTTP_PORT=80
NGINX_HTTPS_PORT=443
CRATE_PORT_HTTP=4200
CRATE_PORT_TCP=4300
CRATE_PORT_PSQL=5450
CRATE_CONF=\"./crate/v5/test/conf\"
CRATE_DATA=\"/${mnt}/dockerdata/crate/data\"
CRATE_LOGS=\"/${mnt}/dockerdata/crate/logs\"
CRATE_REPOS=\"/${mnt}/dockerdata/crate/repos\"


GRAFANA_PORT=3003
GRAFANA_DATA=\"/${mnt}/dockerdata/grafana/data\"
##Wikijs-help
WIKIJS_PG_DB=\"wiki\"
WIKIJS_PG_USER=\"wikijs\"
WIKIJS_PG_PASSWORD=\"wikijsrocks\"
WIKIJS_VOLUME_DATA=\"/mnt/video00/dockerdata/wikijs\"

## AWS S3
AWS_REGION=\"us-east-2\"
BUCKET_NAME=\"vcs-server-backup\"

## Docker logging
LOGGING_DRIVER=\"json-file\"
LOGGING_OPTIONS_MAX_SIZE=\"100m\"
LOGGING_OPTIONS_MAX_FILE=\"30\"
" > /home/vcs/configuration/.env.vcs
  
}
