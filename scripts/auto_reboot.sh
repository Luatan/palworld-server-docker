#!/bin/bash
# shellcheck source=scripts/helper_functions.sh
source "/home/steam/server/helper_functions.sh"

if [ "${RCON_ENABLED,,}" != true ]; then
    LogWarn "Unable to reboot. RCON is required."
    exit 0
fi

if [ -z "${AUTO_REBOOT_WARN_MINUTES}" ]; then
    LogError "Unable to auto reboot, AUTO_REBOOT_WARN_MINUTES is empty."
    exit 0
fi

if [ "${AUTO_REBOOT_EVEN_IF_PLAYERS_ONLINE,,}" != true ]; then
  players_count=$(get_player_count)
  if [ "$players_count" -gt 0 ]; then
    LogWarn "There are ${players_count} players online. Skipping auto reboot."
    exit 0
  fi
fi

if [[ "${AUTO_REBOOT_WARN_MINUTES}" =~ ^[0-9]+$ ]]; then
    for ((i = "${AUTO_REBOOT_WARN_MINUTES}" ; i > 0 ; i--)); do
        broadcast_command "The Server will reboot in ${i} minutes"
        sleep "1m"
    done
    RCON save
    RCON "shutdown 1"
    exit 0
fi

LogError "Unable to auto reboot, AUTO_REBOOT_WARN_MINUTES is not an integer: ${AUTO_REBOOT_WARN_MINUTES}"