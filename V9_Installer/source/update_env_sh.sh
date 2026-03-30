#!/bin/bash
## By Daniel ##

updateEnvSh(){
  
  rm /home/vcs/vcs_server/env.sh
  touch /home/vcs/vcs_server/env.sh
  chown -R vcs:users /home/vcs/vcs_server/env.sh
  echo -e "JAR_PATH=/app
INSTALL_DIR=/vcs_user_dir
LOG_DIR=/log
DOCKER=true
export HLS_DIRECTORY=/video/video00/vcs/hls-streams
OTHER_JVM_OPTS=\"-Ddatabase.type=postgres\"
export DATABASE_USER=vcs
export DATABASE_PASSWORD=vcs
export DATABASE_URL=jdbc:postgresql://postgres:5432/postgres
export ACKNOWLEDGE_IOS_LICENSE=true
OTHER_APP_OPTS=\"--ffmpeg=true\"
NEXT_PUBLIC_WS_API_PORT=19980
NEXT_PUBLIC_WS_API_VERSION=2" > /home/vcs/vcs_server/env.sh

## export DATABASE_URL=jdbc:postgresql://postgres:5432/postgres will need to be updated for Multi Servers ##
}
