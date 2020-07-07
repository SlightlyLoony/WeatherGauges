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


############
# Invariant parameters:
DEFAULT_USER="pi"
IMAGE_ID="Weather Gauges 1"
IMAGE_ID_PATH="/ImageID"


# Show usage of this script.
showUsage() {
  echo "DEPLOY deploys the Weather Gauges software to a target Raspberry Pi."
  echo "It requires a single argument, the IP address (or host name) of the target Raspberry Pi."
  echo "Examples:"
  echo "   ./deploy.bash 10.2.4.246"
  echo "   ./deploy.bash bjango.weathergauges.net"
}


# SSH as the given remote user to the given remote host, executing the commands from stdin.  The remote user MUST have his SSH public key installed
# on the remote host, and his SSH private key MUST be installed on the deployment machine for the user running this script.  The exit code is 255 if
# SSH couldn't connect and log in to the remote host, otherwise is the exit code of the last command executed on the host.  With set -e non-zero exit
# codes will still be returned and the script will not terminate.  All output from stderr goes to ./deploy.error.
#
# Parameters:
#    $1 is the remote user
#    $2 is the remote host
#    stdin has the commands to run on the remote host
#
# Simple example usage, using a pipe to run a single command on the remote host:
#
#    OUT=$( echo "ls -l" | _ssh pi weathergauges ) && true; EC=$?
#
# More complex example usage, with a HEREDOC to run multiple commands on the remote host:
#
#    OUT=$(_ssh pi weathergauges << SSH
#      ls -l
#      hostname
#      cd ~
#    SSH
#    ) && true; EC=$?
#
# In both examples above, the "&& true" prevents the script from terminating if the _ssh invocation returned a non-zero exit code.  Remove the
# "&& true" if termination is the behavior you want.
#
# Notes:
#  We did some tricksy things here to allow connecting to lots of machines, some of which will be on the same IPs as past machines.  This sort of
#  shenanigans would normally require user input (accepting the host, handling warnings about duplicates, etc.) and in some cases editing of the
#  known_host files.
#
#  -o BatchMode=yes                 disables all prompting, which means it disables password authentication
#  -o StrictHostKeyChecking=no      disables verification that a host is in the known hosts file (but still adds the host if it's not there)
#  -o UserKnownHostsFile=/dev/null  is a trick to prevent the actual known_hosts file from being polluted by all the deployment logins
_ssh() {
  local SSH
  read -r -d '' SSH
  ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$1"@"$2" "$SSH" 2>./deploy.error
}


# SCP files from the local host to a remote host.  The remote user MUST have his SSH public key installed on the remote host, and his SSH private key
# MUST be installed on the deployment machine for the user running this script.  The exit code is 0 if scp completed successfully, and 1..255 if it
# did not; with set -e this will terminate the script.  If there are directories in the source path, their contents will be recursively copied.  All
# output from stderr is suppressed.
#
# Parameters:
#    $1 is remote user
#    $2 is remote host
#    $3 is local source path (globbable)
#    $4 is remote destination path
_scp_to_remote() {
  scp -q -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$3" "$1"@"$2":"$4" 2>/dev/null
}


# SCP files from a remote host to the local host.  The remote user MUST have his SSH public key installed on the remote host, and his SSH private key
# MUST be installed on the deployment machine for the user running this script.  The exit code is 0 if scp completed successfully, and 1..255 if it
# did not; with set -e this will terminate the script.  If there are directories in the source path, their contents will be recursively copied.  All
# output from stderr is suppressed.
#
# Parameters:
#    $1 is remote user
#    $2 is remote host
#    $3 is remote source path (globbable)
#    $4 is local destination path
_scp_from_remote() {
  scp -q -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$1"@"$2":"$3" "$4" 2>/dev/null
}


# Verify IP address is responding (e.g., host is UP).
# $1 is IP address in dotted-quad form (like 10.2.4.246), or a valid host name.
# Returns 0 if host is up.
isHostUp() {
  ping -c 1 -W 200 -i 0.1 -q $1 >/dev/null 2>/dev/null
  return $?
}


# Make the given directory on the target machine, with no errors if the directory already exists, and creating parent directories as
# required.
# $1 is the directory path
_mkdir() {
  OUT=$( echo "mkdir -p $1" | _ssh "${DEFAULT_USER}" "${HOST}" )
}


# Copy the given local files to the given remote directory.
# $1 is the path to the local files (globbable)
# $2 is the path of the remote destination directory
_scp_to() {
  _scp_to_remote ${DEFAULT_USER} ${HOST} $1 $2
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

# attempt to read the image ID from the target host, and verify that it's the correct one...
OUT=$( echo "cat /${IMAGE_ID_PATH}" | _ssh "${DEFAULT_USER}" "${HOST}" ) && true; EC=$?
if (( EC == 0 ))  # if we connected, logged in, and read the file...
then
  if [[ $OUT == "${IMAGE_ID}" ]]
  then
    echo "Target ${HOST} has correct image to deploy to: ${OUT}"
  else
    echo "Target ${HOST} has incompatible image: ${OUT}; aborting"
    exit 1
  fi
else
  if (( EC == 255 ))  # if SSH had a problem connecting or logging in...
  then
    echo "SSH had problems connecting to or logging into ${HOST}; aborting"
  else   # otherwise, we weren't able to access the file...
    echo "Could not access ${IMAGE_ID_PATH} on ${HOST}; aborting"
  fi
  exit "${EC}"
fi

##############
# If we make it to here, we know we've got a target that we can talk to with the correct image on it.
##############

# make the deployment directories on the pi...
echo "Creating deployment directories..."
_mkdir /home/pi/deploy/pi
_mkdir /home/pi/deploy/weathergauges

# copy files to the deployment directories...
echo "Copying deployment files..."
_scp_to scripts/target/pi/* /home/pi/deploy/pi
_scp_to scripts/target/pi/.bash_profile /home/pi/deploy/pi
_scp_to scripts/target/weathergauges/* /home/pi/deploy/weathergauges

# execute the phase 1 setup file on the target...
echo "Running phase 1 setup on ${HOST}..."
echo "bash deploy/pi/setup.bash" | _ssh "${DEFAULT_USER}" "${HOST}" && true; EC=$?
if (( EC != 0 ))
then
  cat ./deploy.error
  echo "Fatal error in phase 1 setup, aborting..."
  exit $EC
fi
