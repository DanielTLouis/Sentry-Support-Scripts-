#!/bin/bash
## Asentry ##
## By Daniel Louis ##
## 12/27/2024 ##

# Make sure the source folder is where it needs to be to run the functions 
cp -r ./source/ /home/vcs/

# Creating log file for the migration. 
if [ -f "/home/vcs/source/v9_log" ]; then
  rm /home/vcs/source/v9_log 
fi
touch /home/vcs/source/v9_log

# Linking source files  
source /home/vcs/source/updating_proxy_gateway_config.sh
source /home/vcs/source/updating_settings_xml.sh
source /home/vcs/source/memory_cap.sh
source /home/vcs/source/update_env_sh.sh 
source /home/vcs/source/update_env_vcs.sh
source /home/vcs/source/updating_env_web.sh
source /home/vcs/source/remountingVidDrives.sh
source /home/vcs/source/remountingVidDrives.sh
source /home/vcs/source/font_end_permission_update.sh

# Check if user is logged in as vcs
if [ "$USER" != "vcs" ]; then
    echo "This script must be run as the 'vcs' user. Exiting."
    exit 1
fi

# Ask of the mnt point has been updated for the video drives


sudo systemctl stop vcs

# Ensure Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing Docker..."
    sudo zypper addrepo https://download.docker.com/linux/opensuse/docker-ce.repo
    sudo zypper refresh
    sudo zypper install -y docker

    # Enable and start Docker service
    sudo systemctl enable docker
    sudo systemctl start docker

    # Create Docker group and add user
    sudo groupadd docker || echo "Docker group already exists."
    sudo usermod -aG docker $USER
    echo "Docker installed and configured. Please log out and back in to apply group changes."
fi

# Ensure Docker Compose is installed
if ! [ -f "/usr/lib/docker/cli-plugins/docker-compose" ]; then
    echo "Docker Compose not found. Installing Docker Compose..."
    sudo mkdir -p /usr/lib/docker/cli-plugins
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/lib/docker/cli-plugins/docker-compose
    sudo chmod +x /usr/lib/docker/cli-plugins/docker-compose
    echo "Docker Compose installed."
fi

# Run the first step with the curl command 
echo -e "v8.2.57-10\nprimary\ncsupport\nmicrij-cabKax-3pitxe\nA" | \
sudo /bin/bash -c "$(curl -fsSL -u csupport:micrij-cabKax-3pitxe https://deploy.artsentry.net/repository/scripts/setup-server.sh)"

# Create the home directory folders required
/home/vcs/docker/initialize_docker.sh /home/vcs/docker

# Ask if it is an existing server to migrate or a new install
newInstall=""
answering="true"
while [ "$answering" == "true" ]; do
    echo -e "Are you migrating a server or installing from new? m(migration) or n(new)"
    read newInstall
    if [ "$newInstall" != "n" ] && [ "$newInstall" != "m" ]; then
        echo "Please enter m for (migration) or n for (new)."
    else
        answering="false"
    fi
done

echo "micrij-cabKax-3pitxe" | docker login https://13.51.74.46:8083 -u csupport --password-stdin
sudo chmod 666 /var/run/docker.sock

# Perform steps based on user input
if [ "$newInstall" == "n" ]; then
    #need to do all the things that the migration has in it
    #do_existing_server_steps
    # Start the service
    #/home/vcs/docker/vcs-compose.sh --server-only up -d
    echo "Please install the v8 of the Asentry Software onto this server, before running this installer. "
    echo "As of now there is no installation without migration."
elif [ "$newInstall" == "m" ]; then
    echo "Migrating Server Started..."
    
    echo "Stopping and disabling the vcs..."
    # Stop and disable the vcs service
    sudo systemctl stop vcs
    sudo systemctl disable vcs
    echo "Service has been stopped and disabled."
    
    echo "Copying the VCS to new directory..."
    # Copy the vcs folder and database to the new file locations
    sudo cp -r /usr/vcs/* /home/vcs/vcs_server/ 
    sudo cp /usr/vcs/database/* /home/vcs/docker/migration-scripts/
    sudo chown -R vcs:users /home/vcs/vcs_server/*
    echo "VCS has been moved to new directory."
    
    # Store IP to a variable
    local_ip=$(hostname -I | awk '{print $1}')
    
    # Change ownership of the directories from root to vcs
    sudo chown -R vcs:users /home/vcs/vcs_server
    sudo chown -R vcs:users /home/vcs/vcs_log
    sudo chown -R vcs:users /mnt/video00/vcs
    sudo mkdir /mnt/video00/vcs_log/ 
    sudo chown -R vcs:users /mnt/video00/vcs_log/
    sudo chown -R vcs:users /vcs_export
    sudo chmod -R u+w /home/vcs/configuration
    sudo chmod -R u+w /home/vcs/vcs_server
    sudo chown -R vcs:users /home/vcs/configuration
    sudo chown -R vcs:users /home/vcs/vcs_server 
    
    echo "updating settings.xml file..."
    # Call function updatingSettingsXml
    updatingSettingsXml 
    echo "File settigns.xml updated."
    
    echo "Adding Memory Cap..."
    # Call function memoryCap
    memoryCap
    echo "Finished Memory Cap." 
    
    echo "Remounting Video Drives..."
    #Call function remountingVidDrives
    remountingVidDrives
    echo "Finished Remounting Drives."
    
    echo "Updating env.sh file..."
    # Call function updateEnvSh
    updateEnvSh
    echo "File env.sh updated."
    
    echo "Updating .env.vcs file..."
    # Call function updateEnvVcs
    updateEnvVcs 
    echo "File .env.vcs updated."
    
    echo "Updating .env.web file..."
    # Call function updatingEnvWeb
    updatingEnvWeb 
    echo "File .env.web updated"
    
    echo "Updating ProxyGatewayConfig file..."
    # Call function updatingProxyGatewayConfig
    updatingProxyGatewayConfig 
    echo "File ProxyGatewayConfig updated."
    
    echo "Re-mounting video drives..."
    # Call Function remountingVidDrives
    remountingVidDrives
    echo "Drives re-mounted"
    
    # Grab Server Name from settings.xml
    SERVER_NAME=""
    mapfile -t MAPFILE </usr/vcs/cfg/settings.xml
    for var in "${MAPFILE[@]}"
    do
      if [[ $var == *"ServerID="* ]]
      then
        subString=`echo "$var" | cut -d'"' -f 2`
        SERVER_NAME="$subString"
        break
      fi
    done
    echo "Server Name is $SERVER_NAME."
    
    echo "Starting the service-only containers..."
    # Start the service only (Not the Server)
    /home/vcs/docker/vcs-compose.sh --primary --services-only up -d 
    wait
    echo "Services have been stood up."
    
    echo "Migrating database from sqlite to postgres..."
    #Fix the database
    sudo zypper install sqlite3
    wait
    sqlite3 "/home/vcs/docker/migration-scripts/vcs.db" "PRAGMA wal_checkpoint;"
    sudo chown -R vcs:users /home/vcs/docker/migration-scripts/*
    sudo mv /home/vcs/docker/migration-scripts/vcs.db /home/vcs/docker/migration-scripts/"$SERVER_NAME".db
    sudo chmod +x /home/vcs/docker/migration-scripts/* 
    sudo chown -R vcs:users /home/vcs/docker/migration-scripts/* 
    ./database_migration.sh docker exec -i docker-postgres-1 psql -U vcs -d postgres > migration.log 2>&1
    echo "Database has been updated."
    
    echo "Starting the Server..."
    # Start the Server 
    /home/vcs/docker/vcs-compose.sh --primary --server-only up -d 
    #/home/vcs/docker/vcs-compose.sh --primary --all logs -f
    echo "Server container stood up."
    echo "Migration Finished, Server Starting up."
fi

echo "Updating permission"
# Call font_end_permission_update 
font_end_permission_update
echo "Permissions updated"
