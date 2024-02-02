#!/bin/bash

# Colours
Green='\033[1;32m' # Light green, we use this for successful commands
Yellow='\033[1;33m' # Yellow, we use this for information
Red='\033[0;31m' # Red, we used this for errors
NC='\033[0m' # No colour

# Current script name (used for logging)
CURRENT_SCRIPT="start-palserver.sh"

PALSERVER_SH_LOCATION="/path/to/your/PalServer/PalServer.sh"

## Login to steam anonymously, check for updates to PalWorld, validate the files and quit
echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: Checking for updates and validating PalServer"
steamcmd +login anonymous +app_update 2394010 validate +quit
if [ $? -eq 0 ]; then
    echo -e "$(date +"%d-%m %H:%M:%S") ${Green}$CURRENT_SCRIPT${NC}: PalServer is updated and validated"
else
    echo -e "$(date +"%d-%m %H:%M:%S") ${Red}$CURRENT_SCRIPT${NC}: Failed to update and validate files"
fi

# Start the server
echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: Starting PalServer"
$PALSERVER_SH_LOCATION -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS