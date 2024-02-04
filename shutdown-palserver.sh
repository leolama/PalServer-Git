#!/bin/bash

# Colours
Green='\033[1;32m' # Light green, we use this for successful commands
Yellow='\033[1;33m' # Yellow, we use this for information
Red='\033[0;31m' # Red, we used this for errors
NC='\033[0m' # No colour

# Current script name (used for logging)
CURRENT_SCRIPT="shutdown-palserver.sh"

# Function to send RCON commands
send_rcon_command() {
    ARRCON -S palworld -q "$1"
}

# This script assumes you're ready to shutdown the server
# Kill monitor-palserver.sh
echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: Killing tmux session ${Yellow}PalServerMonitor${NC}"
tmux kill-session -t "PalServerMonitor"
if [ $? -eq 0 ]; then
    echo -e "$(date +"%d-%m %H:%M:%S") ${Green}$CURRENT_SCRIPT${NC}: Killed tmux session ${Yellow}PalServerMonitor${NC}"
else
    echo -e "$(date +"%d-%m %H:%M:%S") ${Red}$CURRENT_SCRIPT${NC}: Failed to kill tmux session ${Yellow}PalServerMonitor${NC}"
    echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: Assuming the tmux session doesn't exist, continuing..."
fi

# Shutdown the server
echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: Gracefully shutting down PalServer"
send_rcon_command "save"
send_rcon_command "shutdown 1" # Shutdown the server in 1 second
sleep 1
echo -e "$(date +"%d-%m %H:%M:%S") ${Green}$CURRENT_SCRIPT${NC}: PalServer has shutdown"