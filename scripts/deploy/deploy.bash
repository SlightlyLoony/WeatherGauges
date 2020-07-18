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


source scripts/deploy/common.bash

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
_scp_to "scripts/target/pi/*" /home/pi/deploy/pi
_scp_to "scripts/target/pi/.bash_profile" /home/pi/deploy/pi
_scp_to "scripts/target/weathergauges/*" /home/pi/deploy/weathergauges
_scp_to "scripts/target/weathergauges/.bash_profile" /home/pi/deploy/weathergauges

# deploy the app...
bash scripts/deploy/deployApp.bash "${HOST}"

# execute the phase 1 setup file on the target...
echo "Running phase 1 setup on ${HOST}..."
echo "bash deploy/pi/setup.bash" | _ssh "${DEFAULT_USER}" "${HOST}" && true; EC=$?

# We're expecting the last thing in phase 1 setup is a reboot, which will kill the
# SSH connection and return a 255.  If we change this someday to an ordinary termination,
# then we'll be expecting a return of 0.  So we check for both...
if (( (EC != 255) && (EC != 0) ))
then
  cat ./deploy.error
  echo "Fatal error (${EC}) in phase 1 setup, aborting..."
  exit $EC
else
  echo "Phase 1 setup on ${HOST} completed..."
fi

# Wait for the target to reboot and start accepting SSH connections...
waitForBoot "${HOST}"

# execute the phase 2 setup file on the target...
echo "bash deploy/pi/setup2.bash" | _ssh "${DEFAULT_USER}" "${HOST}" && true; EC=$?
echo $EC

# We're expecting the last thing in phase 2 setup is a reboot, which will kill the
# SSH connection and return a 255.  If we change this someday to an ordinary termination,
# then we'll be expecting a return of 0.  So we check for both...
if (( (EC != 255) && (EC != 0) ))
then
  cat ./deploy.error
  echo "Fatal error (${EC}) in phase 2 setup, aborting..."
  exit $EC
else
  echo "Phase 2 setup on ${HOST} completed..."
fi

