#!/bin/bash

# Colours
Green='\033[1;32m' # Light green, we use this for successful commands
Yellow='\033[1;33m' # Yellow, we use this for information
Red='\033[0;31m' # Red, we used this for errors
NC='\033[0m' # No colour

# Current script name (used for logging)
CURRENT_SCRIPT="restart-palserver.sh"

# Tmux session names
SESSION_NAME='PalServerMonitor' # Tmux session name

# Script locations
MONITOR_SCRIPT='/path/to/your/monitor-palserver.sh'

# Function to send RCON commands
send_rcon_command() {
    ARRCON -S palworld -q "$1"
}

# Function for gracefully shutting down PalServer after 2 minutes
graceful_shutdown() {
    send_rcon_command "shutdown 130"
    send_rcon_command "broadcast Shutting_down_in_'120'_seconds"
    echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: Shutting down PalServer in 120 seconds"
    sleep 60

    send_rcon_command "broadcast Shutting_down_in_'60'_seconds"
    echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: Shutting down PalServer in 60 seconds"
    sleep 60

    send_rcon_command "save"
    send_rcon_command "broadcast Saved server"
    echo -e "$(date +"%d-%m %H:%M:%S") ${Green}$CURRENT_SCRIPT${NC}: Saved PalServer"
    send_rcon_command "broadcast Shutting_down_in_'10'_seconds"
    echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: Shutting down PalServer in 10 seconds"
    sleep 5

    for i in {5,4,3,2,1}; do
        send_rcon_command "broadcast Shutting_down_in_'$i'_seconds"
        sleep 1
    done

    echo -e "$(date +"%d-%m %H:%M:%S") ${Green}$CURRENT_SCRIPT${NC}: PalServer safely shutdown"
}

#!!# Main #!!#
# Identify the PID of monitor-palserver.sh
pid=$(pgrep -f "monitor-palserver.sh")

if [ -n "$pid" ]; then
    # Kill the monitor-palserver.sh process
    echo -e "$(date +"%d-%m %H:%M:%S") ${Green}$CURRENT_SCRIPT${NC}: Killing monitor-palserver.sh (PID: $pid)"
    kill $pid
    if [ $? -eq 0 ]; then
        echo -e "$(date +"%d-%m %H:%M:%S") ${Green}$CURRENT_SCRIPT${NC}: Killed monitor-palserver.sh (PID: $pid)"
    else
        echo -e "$(date +"%d-%m %H:%M:%S") ${Red}$CURRENT_SCRIPT${NC}: Failed to kill monitor-palserver.sh (PID: $pid)"
    fi
else
    echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: monitor-palserver.sh is not running"
fi

# Are we trying to restart a server that doesn't exist yet?
pid=$(pgrep -f "PalServer-Linux")
if [ -n "$pid" ]; then
    # Server exists, shutdown
    # Check if we already have a tmux session running
    tmux has-session -t $SESSION_NAME 2>/dev/null
    if [ $? != 0 ]; then
        # Session does not exist, create a new one
        echo -e "${Green}$CURRENT_SCRIPT${NC}: Creating new tmux session: $SESSION_NAME"
        tmux new-session -d -s "$SESSION_NAME"
    fi
    
    # Start a graceful_shutdown
    graceful_shutdown
fi

# Check if we already have a tmux session running
tmux has-session -t $SESSION_NAME 2>/dev/null
if [ $? != 0 ]; then
    # Session does not exist, create a new one
    echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: Creating new tmux session: $SESSION_NAME"
    tmux new-session -d -s "$SESSION_NAME" "$MONITOR_SCRIPT"
else
    # Starting monitor-palserver.sh on tmux session PalServerMonitor
    echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: Starting monitor-palserver.sh on tmux session: $SESSION_NAME"
    tmux send-keys -t "$SESSION_NAME" "$MONITOR_SCRIPT" Enter
fi