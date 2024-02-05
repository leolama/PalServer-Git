#!/bin/bash

# Colours
Green='\033[1;32m' # Light green, we use this for successful commands
Yellow='\033[1;33m' # Yellow, we use this for information
Red='\033[0;31m' # Red, we use this for errors
NC='\033[0m' # No colour

# Current script name (used for logging)
CURRENT_SCRIPT="setup-palserver.sh"

# Error tracking
errors=0

# We need tmux
echo -e "${Yellow}$CURRENT_SCRIPT${NC}: Installing tmux"
sudo apt install tmux
if [ $? == 0 ]; then
    echo -e "${Green}$CURRENT_SCRIPT${NC}: tmux has been installed successfully"
else
    echo -e "${Red}$CURRENT_SCRIPT${NC}: tmux installation failed"
    ((errors += 1))
fi

# We need SteamCMD
sudo add-repository multiverse; sudo dpkg --add-architecture i386; sudo apt update
sudo apt install steamcmd
if [ $? == 0 ]; then
    echo -e "${Green}$CURRENT_SCRIPT${NC}: SteamCMD has been installed successfully"
else
    echo -e "${Red}$CURRENT_SCRIPT${NC}: SteamCMD installation failed"
    ((errors += 1))

fi

# We need ARRCON
wget https://github.com/radj307/ARRCON/releases/download/3.3.7/ARRCON-3.3.7-Linux.zip
unzip ARRCON-3.3.7-Linux.zip
sudo mv ARRCON /usr/local/bin
rm ARRCON-3.3.7-Linux.zip
if [ $? == 0 ]; then
    echo -e "${Green}$CURRENT_SCRIPT${NC}: ARRCON has been installed"
else
    echo -e "${Red}$CURRENT_SCRIPT${NC}: ARRCON installation failed"
    ((errors += 1))
fi
# Make ARRCON executable
sudo chmod +x /usr/local/bin/ARRCON
if [ $? == 0 ]; then
    echo -e "${Green}$CURRENT_SCRIPT${NC}: ARRCON has execution rights"
else
    echo -e "${Red}$CURRENT_SCRIPT${NC}: Failed to give ARRCON execution rights"
    ((errors += 1))
fi

# Install PalServer
steamcmd +login anonymous +app_update 2394010 validate +quit
if [ $? == 0 ]; then
    echo -e "${Green}$CURRENT_SCRIPT${NC}: PalServer has been installed successfully"
else
    echo -e "${Red}$CURRENT_SCRIPT${NC}: PalServer installation failed"
    ((errors += 1))
fi

if [ $errors -ge 1 ]; then
    echo -e "${Red}$CURRENT_SCRIPT${NC}: Setup had $errors error(s) :( You may be missing some important parts"
else
    echo -e "${Green}$CURRENT_SCRIPT${NC}: Setup completed successfully! You can now run ${Yellow}monitor-palserver.sh${NC}"
fi