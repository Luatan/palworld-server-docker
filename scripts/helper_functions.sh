#!/bin/bash
# This file contains functions which can be used in multiple scripts

# Checks if a given path is a directory
# Returns 0 if the path is a directory
# Returns 1 if the path is not a directory or does not exists and produces an output message
dirExists() {
    local path="$1"
    local return_val=0
    if ! [ -d "${path}" ]; then
        echo "${path} does not exist."
        return_val=1
    fi
    return "$return_val"
}

# Checks if a given path is a regular file
# Returns 0 if the path is a regular file
# Returns 1 if the path is not a regular file or does not exists and produces an output message
fileExists() {
    local path="$1"
    local return_val=0
    if ! [ -f "${path}" ]; then
        echo "${path} does not exist."
        return_val=1
    fi
    return "$return_val"
}

# Checks if a given path exists and is readable
# Returns 0 if the path exists and is readable
# Returns 1 if the path is not readable or does not exists and produces an output message
isReadable() {
    local path="$1"
    local return_val=0
    if ! [ -e "${path}" ]; then
        echo "${path} is not readable."
        return_val=1
    fi
    return "$return_val"
}

# Checks if a given path is writable
# Returns 0 if the path is writable
# Returns 1 if the path is not writable or does not exists and produces an output message
isWritable() {
    local path="$1"
    local return_val=0
    if ! [ -w "${path}" ]; then
        echo "${path} is not writable."
        return_val=1
    fi
    return "$return_val"
}

# Checks if a given path is executable
# Returns 0 if the path is executable
# Returns 1 if the path is not executable or does not exists and produces an output message
isExecutable() {
    local path="$1"
    local return_val=0
    if ! [ -x "${path}" ]; then
        echo "${path} is not executable."
        return_val=1
    fi
    return "$return_val"
}

# Checks how many players are currently connected
# Outputs 0 if RCON is not enabled
# Outputs the player count if rcon is enabled
get_player_count() {
    local player_list
    if [ "${RCON_ENABLED,,}" != true ]; then
        echo 0
        return 0
    fi
    player_list=$(RCON "ShowPlayers")
    echo -n "${player_list}" | wc -l
}

#
# Log Definitions
#
export LINE='\n'
export RESET='\033[0m'       # Text Reset
export WhiteText='\033[0;37m'        # White

# Bold
export RedBoldText='\033[1;31m'         # Red
export GreenBoldText='\033[1;32m'       # Green
export YellowBoldText='\033[1;33m'      # Yellow
export CyanBoldText='\033[1;36m'        # Cyan

LogInfo() {
  Log "$1" "$WhiteText"
}
LogWarn() {
  Log "$1" "$YellowBoldText"
}
LogError() {
  Log "$1" "$RedBoldText"
}
LogSuccess() {
  Log "$1" "$GreenBoldText"
}
LogAction() {
  Log "$1" "$CyanBoldText" "****" "****"
}
Log() {
  local message="$1"
  local color="$2"
  local prefix="$3"
  local suffix="$4"
  printf "$color%s$RESET$LINE" "$prefix$message$suffix"
}

# Send Discord Message
# Level is optional variable defaulting to info
DiscordMessage() {
  local message="$1"
  local level="$2"
  if [ -n "$level" ]; then
    level="info"
  fi
  if [ -n "${DISCORD_WEBHOOK_URL}" ]; then
    /home/steam/server/discord.sh "$message" "$level" &
  fi
}

# RCON Call
RCON() {
  local args="$1"
  echo rcon-cli -c /home/steam/server/rcon.yaml "$args"
}


# Returns 0 if Update Required
# Returns 1 if Update NOT Required
# Returns 2 if Check Failed
UpdateRequired() {
LogAction "Checking for new update"

temp_file=$(mktemp)
http_code=$(curl https://api.steamcmd.net/v1/info/2394010 --output "$temp_file" --silent --location --write-out "%{http_code}")
TARGET_MANIFEST=$(grep -Po '"2394012".*"gid": "\d+"' <"$temp_file" | sed -r 's/.*("[0-9]+")$/\1/')

CURRENT_MANIFEST=$(awk '/manifest/{count++} count==2 {print $2; exit}' /palworld/steamapps/appmanifest_2394010.acf)
rm "$temp_file"

if [ "$http_code" -ne 200 ]; then
    LogError "There was a problem reaching the Steam api. Unable to check for updates!"
    DiscordMessage "There was a problem reaching the Steam api. Unable to check for updates!" "failure"
    return 2
fi

if [ -z "$TARGET_MANIFEST" ]; then
    LogError "The server response does not contain the expected BuildID. Unable to check for updates!"
    DiscordMessage "Steam servers response does not contain the expected BuildID. Unable to check for updates!" "failure"
    return 2
fi

if [ "$CURRENT_MANIFEST" != "$TARGET_MANIFEST" ]; then
  LogInfo "An Update Is Available."
  LogInfo "Current Version: $CURRENT_MANIFEST"
  LogInfo "Latest Version: $TARGET_MANIFEST."
  return 0
fi

LogSuccess "The Server is up to date!"
return 1

}

InstallServer() {
  DiscordMessage "${DISCORD_PRE_UPDATE_BOOT_MESSAGE}" "in-progress"
  /home/steam/steamcmd/steamcmd.sh +@sSteamCmdForcePlatformType linux +@sSteamCmdForcePlatformBitness 64 +force_install_dir "/palworld" +login anonymous +app_update 2394010 validate  +quit
  DiscordMessage "${DISCORD_POST_UPDATE_BOOT_MESSAGE}" "success"
}

# Returns 0 if game is installed
# Returns 1 if game is not installed
IsInstalled() {
  if  [ -e /palworld/PalServer.sh ] && [ -e /palworld/steamapps/appmanifest_2394010.acf ]; then
    return 0
  fi
  return 1
}