#!/bin/bash

# Colours
Green='\033[1;32m' # Light green, we use this for successful commands
Yellow='\033[1;33m' # Yellow, we use this for information
Red='\033[0;31m' # Red, we used this for errors
NC='\033[0m' # No colour

# Current script name (used for logging)
CURRENT_SCRIPT="monitor-palserver.sh"

# PalServer Process name
SERVER_PROCESS_NAME='PalServer-Linux' # What the process is called (like in htop)

# Script locations
MONITOR_SCRIPT='/path/to/your/monitor-palserver.sh' # Monitor script
RESTART_SCRIPT='/path/to/your/restart-palserver.sh'  # Restart script
RESTART_SCRIPT_SIX='/path/to/your/restart-palserver-6h.sh' # Restart script after 6 hours
START_SCRIPT='/path/to/your/start-palserver.sh' # Start script
BACKUP_SCRIPT='/path/to/your/backup-palserver.sh' # Backup script

# Tmux session names
STARTING_SESSION_NAME='PalServerSteamCMD' # Tmux session name for the SteamCMD session
BACKUP_SESSION_NAME='PalServerBackup' # Tmux session name for the backup script
MONITOR_SESSION_NAME='PalServerMonitor' # Tmux session name that we want for this script

# Init counter
counter=0

# Function to check if the server process is running
is_server_running() {
    pgrep -f $SERVER_PROCESS_NAME > /dev/null
}

# Function to check memory usage of a process
get_memory_usage() {
    process_name=$1

    # Get the PID of the process
    pid=$(pgrep -o "$process_name")

    # Check if the process is running
    if [ -z "$pid" ]; then
        if [ counter == 0]; then
            echo -e "$(date +"%d-%m %H:%M:%S") ${Red}$CURRENT_SCRIPT${NC}: Can't seem to find PalServer-Linux, it's possible it hasn't started yet"
        fi
        echo -e "$(date +"%d-%m %H:%M:%S") ${Red}$CURRENT_SCRIPT${NC}: Can't seem to find PalServer-Linux, has it changed?"
        return 1
    fi

    # Use smem to get memory usage
    mem_usage_kb=$(smem -r -P "$process_name" | awk 'NR==2 {print $5}')

    # Convert memory usage to gigabytes
    mem_usage_gb=$(echo "scale=2; $mem_usage_kb / 1024 / 1024" | bc)

    echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: Memory usage for process $process_name (PID $pid): $mem_usage_gb GB"
}

# Function to get online players using ARRCON and filter them down to their name and steamid
get_showplayers_rcon() {
    # Get online player information through ARRCON
    showplayersraw=$(ARRCON -S palworld showplayers)

    # Filter the data down to the first and third column
    showplayersfiltered=$(echo "$showplayersraw" | awk -F ',' 'NR>2{print $1","$3}')

    # Filter the data down again to remove any empty lines and trailing commas
    showplayersfiltered=$(echo "$showplayersfiltered" | awk 'NF{print} END{if(NF) print}' | sed '/,$/d')

    # Show the terminal our lovely filtered data
    echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: Current players:"
    # Use a while loop to iterate through lines and echo each one
    while IFS= read -r line; do
        echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: $line"
    done <<< "$showplayersfiltered"
}

# Function to restart the server after 6 hours
restart_server_6hours() {
    echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: Server has been online for more than 6 hours, restarting..."
    $RESTART_SCRIPT_SIX 
}

# Function to gracefully shutdown the server
start_server() {
    tmux has-session -t "$STARTING_SESSION_NAME" 2>/dev/null

    if [ $? == 0 ]; then
        # The expected tmux session exists, run start-palserver.sh
        echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: The ${Yellow}$STARTING_SESSION_NAME${NC} tmux session exists, running start-palserver.sh in it"
        tmux send-keys -t "$STARTING_SESSION_NAME" "$START_SCRIPT" C-m
    else
        # The expected tmux session does not exist, create and run start-palserver.sh
        echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: The ${Yellow}$STARTING_SESSION_NAME${NC} tmux session does not exist, starting a new session called $STARTING_SESSION_NAME and running start-palserver.sh in it"
        tmux new-session -d -s "$STARTING_SESSION_NAME" "$START_SCRIPT"
        # Error handling
        if [ $? -eq 0 ]; then
            echo -e "$(date +"%d-%m %H:%M:%S") ${Green}$CURRENT_SCRIPT${NC}: The ${Yellow}$STARTING_SESSION_NAME${NC} tmux session was created successfully"
        else
            echo -e "$(date +"%d-%m %H:%M:%S") ${Red}$CURRENT_SCRIPT${NC}: The ${Yellow}$STARTING_SESSION_NAME${NC} tmux session was not created"
        fi
    fi
}

# Function to backup the server (used every 6 hours)
backup_server() {
    tmux has-session -t "$BACKUP_SESSION_NAME" 2>/dev/null

    if [ $? -eq 0 ]; then
        # The expected tmux session exists, run backup-palserver.sh
        echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: The ${Yellow}$BACKUP_SESSION_NAME${NC} tmux session exists, running backup-palserver.sh in it"
        tmux send-keys -t "$BACKUP_SESSION_NAME" "$BACKUP_SCRIPT" C-m
    else
        # The expected tmux session does not exist, create and run backup-palserver.sh
        echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: The ${Yellow}$BACKUP_SESSION_NAME${NC} tmux session does not exist, starting a new session called $BACKUP_SESSION_NAME and running backup-palserver.sh in it"
        tmux new-session -d -s "$BACKUP_SESSION_NAME" "$BACKUP_SCRIPT"
        # Error handling
        if [ $? -eq 0 ]; then
            echo -e "$(date +"%d-%m %H:%M:%S") ${Green}$CURRENT_SCRIPT${NC}: The ${Yellow}$BACKUP_SESSION_NAME${NC} tmux session was created successfully"
        else
            echo -e "$(date +"%d-%m %H:%M:%S") ${Red}$CURRENT_SCRIPT${NC}: The ${Yellow}$BACKUP_SESSION_NAME${NC} tmux session was not created"
        fi
    fi
}

#!!# Tmux session checking #!!#
echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: Checking tmux session"

# Check if we are in a tmux session
if [ -n "$TMUX" ]; then
    # We are in a tmux session
    current_session=$(tmux display-message -p '#S')

    if [ "$current_session" == "$MONITOR_SESSION_NAME" ]; then
        # We are in the expected tmux session, run monitor-palserver.sh
        echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: We're in the ${Yellow}$MONITOR_SESSION_NAME${NC} tmux session"
    else
        # We are in a different tmux session, detach and start over
        echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: We're in a different tmux session, detaching and starting over"
        tmux detach
        exec "$0" # Restart the script
    fi
else
    # We are not in a tmux session
    # Check if the expected tmux session exists
    tmux has-session -t "$MONITOR_SESSION_NAME" 2>/dev/null

    if [ $? == 0 ]; then
        # The expected tmux session exists, run monitor-palserver.sh
        echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: The ${Yellow}$MONITOR_SESSION_NAME${NC} tmux session exists, running monitor-palserver.sh in it"
        tmux send-keys -t "$MONITOR_SESSION_NAME" "$MONITOR_SCRIPT" C-m
        sleep 1
        exit 0
    else
        # The expected tmux session does not exist, create and run monitor-palserver.sh
        echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: The ${Yellow}$MONITOR_SESSION_NAME${NC} tmux session does not exist, starting a new session called ${Yellow}$MONITOR_SESSION_NAME${NC} and running monitor-palserver.sh in it"
        tmux new-session -d -s "$MONITOR_SESSION_NAME" "$MONITOR_SCRIPT"
        # Error handling
        if [ $? -eq 0 ]; then
            echo -e "$(date +"%d-%m %H:%M:%S") ${Green}$CURRENT_SCRIPT${NC}: The ${Yellow}$MONITOR_SESSION_NAME${NC} tmux session was created successfully"
        else
            echo -e "$(date +"%d-%m %H:%M:%S") ${Red}$CURRENT_SCRIPT${NC}: The ${Yellow}$MONITOR_SESSION_NAME${NC} tmux session was not created"
        fi
        sleep 1
        exit 0
    fi
fi

#!!# Main loop #!!#
while true; do
    if ! is_server_running; then
        # Check we aren't already trying to start the server
        # Find the PID of start-palserver.sh (if it exists) and wait until it no longer exists
        echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: Checking we aren't trying to start the server already"
        while pgrep -f "start-palserver.sh" >/dev/null; do
            pid=$(pgrep -f "start-palserver.sh")
            echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: start-palserver.sh exists with PID $pid, waiting for it to finish"
            sleep 10
        done

        echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: start-palserver.sh does not exist, continuing..."
        
        # Start the server 
        start_server
        # Make sure the counter is at 0
        counter=0
    fi
    echo "---"
    # Check memory usage of the server for visual purposes, data isn't used
    get_memory_usage "PalServer-Linux"
    get_showplayers_rcon
    echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: Server has been online for $counter / $AUTO_RESTART_TIMER seconds"

    # Sleep for a short duration before checking again
    sleep $MONITOR_INTERVAL

    # Increment the counter
    ((counter += $MONITOR_INTERVAL))

    # Check if we need to get a backup
    if [ $((counter % AUTO_BACKUP_TIMER)) -eq 0 ]; then
        # Backup necessary files and restart the server
        echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: Server has been online for $AUTO_BACKUP_TIMER seconds, getting a backup"
        backup_server
    fi

    # Check if we need to restart
    if [ $counter -ge $AUTO_RESTART_TIMER ]; then
        # Backup necessary files and restart the server
        echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: Server has been online for $AUTO_RESTART_TIMER seconds, starting a graceful restart"
        restart_server_6hours
        counter=0  # Reset the counter after shutdown
    fi
done
#!!# End loop #!!#