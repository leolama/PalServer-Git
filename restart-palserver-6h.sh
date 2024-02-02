#!/bin/bash

# Colours
Green='\033[1;32m' # Light green, we use this for successful commands
Yellow='\033[1;33m' # Yellow, we use this for information
Red='\033[0;31m' # Red, we used this for errors
NC='\033[0m' # No colour

# Current script name (used for logging)
CURRENT_SCRIPT="restart-palserver-6h.sh"

# Tmux session names
SESSION_NAME='PalServerMonitor' # Tmux session name

# Script locations
MONITOR_SCRIPT='/path/to/your/monitor-palserver.sh'

# Function to send RCON commands
send_rcon_command() {
    ARRCON -S palworld -q "$1"
}

# Function for gracefully shutting down PalServer after 5 minutes
graceful_shutdown() {
    # Shutting down in 310 seconds intead of 300 seconds seems to be perfect timing?
    send_rcon_command "shutdown 310"
    send_rcon_command "broadcast Server_has_been_online_for_6_hours"
    send_rcon_command "broadcast Restarting_for_performance"
    send_rcon_command "broadcast Shutting_down_in_'300'_seconds"
    echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: Shutting down PalServer in 300 seconds"
    sleep 60

    for i in {240,180,120,60}; do
        send_rcon_command "broadcast Shutting_down_in_'$i'_seconds"
        echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: Shutting down PalServer in $i seconds"
        sleep 60
    done

    send_rcon_command "save"
    send_rcon_command "broadcast Saved server"
    send_rcon_command "broadcast Shutting_down_in_'10'_seconds"
    echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: Shutting down PalServer in 10 seconds"
    sleep 5

    for i in {5,4,3,2,1}; do
        send_rcon_command "broadcast Shutting_down_in_'$i'_seconds"
        sleep 1
    done

    echo -e "$(date +"%d-%m %H:%M:%S") ${Green}$CURRENT_SCRIPT${NC}: PalServer safely shutdown"
}

# Main
graceful_shutdown