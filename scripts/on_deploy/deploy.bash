#!/usr/bin/env bash
set -euo pipefail

######################
# Deploy Weather Gauges to a target Raspberry Pi
# USAGE:
#    ./deploy.bash <ip address of Raspberry Pi>
#
# EXAMPLE:
#    ./deploy.bash 10.2.4.25
#
# ASSUMPTIONS:
#   1.  Operating system has been installed, and the only normal user installed is the default user (pi) with the default password (raspberry).
#   2.  SSH is enabled on the target Raspberry Pi.
#   3.  This script is running on OSX.
#
# Exit codes:
#   0   Successfully completed
#   1   Number of arguments to the script was not 1
#   2   Supplied IP address (or host name) was invalid, or host did not respond to ping
######################


# Show usage of this script.
showUsage() {
  echo "DEPLOY deploys the Weather Gauges software to a target Raspberry Pi."
  echo "It requires a single argument, the IP address (or host name) of the target Raspberry Pi."
  echo "Examples:"
  echo "   ./deploy.bash 10.2.4.246"
  echo "   ./deploy.bash bjango.weathergauges.net"
}


# Verify IP address is responding (e.g., host is UP).
# $1 is IP address in dotted-quad form (like 10.2.4.246), or a valid host name.
# Returns 0 if host is up.
isHostUp() {
  ping -c 1 -W 200 -i 0.1 -q $1 >/dev/null 2>/dev/null
  return $?
}


####################
# Main script...

# first we make sure that we have a single command line argument...
if [[ $# -ne 1 ]]
then
  showUsage
  exit 1
fi

# capture our script argument
HOST=$1;

# make sure that the target host is actually up before we start this whole process...
if ! isHostUp "${HOST}"
then
  echo "Host $HOST is either invalid, or is not responding to ping."
  echo ""
  showUsage
  exit 2
fi