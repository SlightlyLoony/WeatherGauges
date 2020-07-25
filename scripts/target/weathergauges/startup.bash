#!/usr/bin/env bash
set -euo pipefail

# This script is run by the weathergauges user upon the system booting up.  It is responsible for figuring out what mode the Weather Gauges device is
# in, and responding appropriately.

DEVICE_MODE_FILE="device.mode" # the name of the file containing our current mode
DEVICE_MODE="INITIAL"          # the current mode


# Read a file.
# $1 is the name of the file to read.
readFile() {
  cat "$1"
}


# Write a file.
# $1 is the name of the file to write.
# $2 is what to write to the file.
writeFile() {
  >"$1" echo "$2"
}

#################
# Main Script
#################

# find out what mode we're in, and behave accordingly...
DONE=false
while ! $DONE
do
  DEVICE_MODE=$(readFile $DEVICE_MODE_FILE)
  DONE=true  # assume we're done, but note what happens in *)...
  case $DEVICE_MODE in

  INITIAL)
    writeFile "test.log" "Got to INITIAL"
    ;;

  HOTSPOT)
    ;;

  CONNECT)
    ;;

  CONNECTED)
    ;;

  # if we get here, then somehow our device mode has been hosed - so we reset it to INITIAL and start over...
  *)
    writeFile "${DEVICE_MODE_FILE}" "INITIAL"
    DONE=false
    ;;
  esac
done