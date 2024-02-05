#!/bin/bash

# Colours
Green='\033[1;32m' # Light green, we use this for successful commands
Yellow='\033[1;33m' # Yellow, we use this for information
Red='\033[0;31m' # Red, we used this for errors
NC='\033[0m' # No colour

# Current script name (used for logging)
CURRENT_SCRIPT="backup-palserver.sh"

# Script locations
BACKUP_SCRIPT='/path/to/your/backup-palserver.sh'

# Backup name setup
BACKUP_DATE=$(date +"%d-%m-%H-%M-%S")
BACKUP_FILE="/path/to/your/PalServerBackup_${BACKUP_DATE}.tar.gz"

# PalServer 'Saved' location
PALSERVER_SAVED="/path/to/your/PalServer/Pal/Saved"

# Tmux session names
BACKUP_SESSION_NAME='PalServerBackup'

#!!# Tmux session checking #!!#
echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: Checking tmux session"

# Check if we are in a tmux session
if [ -n "$TMUX" ]; then
    # We are in a tmux session
    current_session=$(tmux display-message -p '#S')

    if [ "$current_session" == "$BACKUP_SESSION_NAME" ]; then
        # We are in the expected tmux session, run backup-palserver.sh
        echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: We're in the ${Yellow}$BACKUP_SESSION_NAME${NC} tmux session"
    else
        # We are in a different tmux session, detach and start over
        echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: We're in a different tmux session, detaching and starting over"
        tmux detach
        exec "$0" # Restart the script
    fi
else
    # We are not in a tmux session
    # Check if the expected tmux session exists
    tmux has-session -t "$BACKUP_SESSION_NAME" 2>/dev/null

    if [ $? == 0 ]; then
        # The expected tmux session exists, run backup-palserver.sh
        echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: The ${Yellow}$BACKUP_SESSION_NAME${NC} tmux session exists, running backup-palserver.sh in it"
        tmux send-keys -t "$BACKUP_SESSION_NAME" "$BACKUP_SCRIPT" C-m
        # Error handling
        if [ $? -eq 0 ]; then
            echo -e "$(date +"%d-%m %H:%M:%S") ${Green}$CURRENT_SCRIPT${NC}: The ${Yellow}$BACKUP_SESSION_NAME${NC} tmux session was created successfully"
        else
            echo -e "$(date +"%d-%m %H:%M:%S") ${Red}$CURRENT_SCRIPT${NC}: The ${Yellow}$BACKUP_SESSION_NAME${NC} tmux session was not created"
        fi
        sleep 1
        exit 0
    else
        # The expected tmux session does not exist, create and run backup-palserver.sh
        echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: The ${Yellow}$BACKUP_SESSION_NAME${NC} tmux session does not exist, starting a new session called ${Yellow}$BACKUP_SESSION_NAME${NC} and running backup-palserver.sh in it"
        # Add this line to print the current working directory for debugging
        tmux new-session -d -s "$BACKUP_SESSION_NAME" "$BACKUP_SCRIPT"
        # Error handling
        if [ $? -eq 0 ]; then
            echo -e "$(date +"%d-%m %H:%M:%S") ${Green}$CURRENT_SCRIPT${NC}: The ${Yellow}$BACKUP_SESSION_NAME${NC} tmux session was created successfully"
        else
            echo -e "$(date +"%d-%m %H:%M:%S") ${Red}$CURRENT_SCRIPT${NC}: The ${Yellow}$BACKUP_SESSION_NAME${NC} tmux session was not created"
        fi
        sleep 1
        exit 0
    fi
fi

echo -e "$(date +"%d-%m %H:%M:%S") ${Yellow}$CURRENT_SCRIPT${NC}: Backing up PalServer Saved into .tar.gz"

tar -czf "${BACKUP_FILE}" $PALSERVER_SAVED
if [ $? -eq 0 ]; then
    echo -e "$(date +"%d-%m %H:%M:%S") ${Green}$CURRENT_SCRIPT${NC}: Saved as ${BACKUP_FILE}"
else
    echo -e "$(date +"%d-%m %H:%M:%S") ${Red}$CURRENT_SCRIPT${NC}: Failed to backup server files"
fi