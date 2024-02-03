# Pal Server Monitoring with Bash

My own (probably bad) Bash scripts to start, monitor, backup and restart a PalServer for Palworld (through a command line). I shouldn't have to say that this is obviously for fun.

## Usage

### Dependencies:
- [ARRCON](https://github.com/radj307/ARRCON)
- [tmux](https://github.com/tmux/tmux/wiki/Installing)
- Some ability to read and change variables in a .sh file

### Features
Restarts the server every 6 hours along with a backup every 6 hours

### Variable changing:
I've tried to make the scripts easy to change with variables, for example:
- In `backup.palserver.sh` - you'll have to change `BACKUP_SCRIPT`, `BACKUP_FILE` and `PALSERVER_SAVED` to your own paths

### ARRCON
The script uses the command `ARRCON -S palworld -q "$1"` to run RCON commands. You'll have to use `ARRCON --host <host> --port <port> --pass <password> --save-host palworld` to get RCON working

### Starting the server
Make sure you've given **each** file execute permissions: `sudo chmod +x <yourscript>`, and then simply run `./monitor-palserver.sh`
Run `tmux attach -t PalServerMonitor` to...monitor the server for RAM usage and current players

### Stopping the server
`tmux attach -t PalServerMonitor` > Ctrl + C
`ARRCON -S palworld save`
`ARRCON -S palworld "shutdown 5`
The server will start shutting down in 5 seconds
