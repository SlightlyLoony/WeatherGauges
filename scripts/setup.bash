#!/usr/bin/env bash
set -euo pipefail

# Set up a Raspberry Pi for Weather Gauges.
# Assumptions:
#   1.  Operating system has been installed, and the only normal user installed is the default user with the default password.
#   2.  SSH is enabled on the target Raspberry Pi
#   3.  This script has been copied to the /home/<default user> directory, and executed from there (logged in as the default user)


####################
# Fixed Parameters #
####################

WEATHERGAUGES_HOSTNAME="weathergauges"  # hostname for "as shipped" Weather Gauges device; user may change...
APP_USER="weathergauges"                # user name that Weather Gauges runs under; user may NOT change...
APP_PASSWORD="WeatherGauges2020OhMy!"   # default password for "weathergauges" user; user may change, device reset restores...


#########################
# Function Declarations #
#########################


# Authenticate to sudo, either by new authentication or by extending active sudo credentials.  There is no output.
# $1 is the default user's password
sudoAuth() {
  PWD=$1
  exec 6>&1;                   # save stdout to file descriptor 6...
  exec 7>&2;                   # save stderr to file descriptor 7...
  exec 1>/dev/null;            # redirect sdtout to /dev/null to suppress output here...
  exec 2>/dev/null;            # redirect sdterr to /dev/null to suppress output here...
  echo "${PWD}" | sudo -S -v;  # attempt to extend sudo credentials; logging in if necessary...
  exec 1>&6 6>&-               # restore stdout and close file descriptor 6...
  exec 2>&7 7>&-               # restore stderr and close file descriptor 7...
}


# Outputs the name (in all lower case) of the Raspberry Pi operating system (Jessie, Stretch, Buster, etc.).
osName() {
  # hostnamectl output looks something like this:
  #      Static hostname: raspberrypi
  #          Icon name: computer
  #         Machine ID: 66d688d42ac14dabb77c6ab537a8ed27
  #            Boot ID: 1d0ee895eeb94784aede60f4a2d29a5a
  #   Operating System: Raspbian GNU/Linux 10 (buster)
  #             Kernel: Linux 4.19.118-v7+
  #       Architecture: arm
  # sed selects only lines containing "Operating System", then replaces the entire line with just what was inside parentheses and prints the results
  # tr converts any uppercase characters into lowercase
  hostnamectl | sed -n '/Operating System/ s/.*(\(.*\)).*/\1/ p' | tr [:upper:] [:lower:]
}


# Outputs the default password for our default user ("raspberry" on all versions "buster" and before, but may change).
# $1 is our operating system name
osPassword() {
  echo "raspberry"
}


# Outputs the host name for this machine.
hostName() {
  echo "$(hostname)"
}


# Sets the hostname to $1
changeHostName() {
  NEW_HOSTNAME=$1
  sudo hostnamectl set-hostname "${NEW_HOSTNAME}"
}


# Ensures the hostname has been set to the proper value.  Outputs status messages only.
# $1 is the default user's password
ensureHostName() {
  sudoAuth $1  # authenticate to sudo...
  if [[ $(hostName) != "$WEATHERGAUGES_HOSTNAME" ]]
  then
    changeHostName ${WEATHERGAUGES_HOSTNAME}
    if [[ $(hostName) != "$WEATHERGAUGES_HOSTNAME" ]]
    then
      echo "Failed to change target hostname to ${WEATHERGAUGES_HOSTNAME}"
      exit 1
    else
      echo "Changed hostname to ${WEATHERGAUGES_HOSTNAME}"
    fi
  else
    echo "Hostname has already been changed to ${WEATHERGAUGES_HOSTNAME}"
  fi
}


# Ensures that the specified user exists.
# $1 is the default user's password
# $2 is the user to ensure
# $3 is that user's default password
ensureUser() {
  USER=$2
  PWD=$3
  STATUS=""
  BAIL=false
  sudoAuth $1        # authenticate to sudo...

  # suppress extraneous output...
  exec 6>&1;                   # save stdout to file descriptor 6...
  exec 7>&2;                   # save stderr to file descriptor 7...
  exec 1>/dev/null;            # redirect sdtout to /dev/null to suppress output here...
  exec 2>/dev/null;            # redirect sdterr to /dev/null to suppress output here...

  # see whether we already have this user...
  id -u "${USER}"
  if [[ $? == 0 ]]
  then
    STATUS="User ${USER} has already been created"
  else

    # first we try creating the user with his password...
    echo "${PWD}" | passwd "${USER}" --stdin

    # did we succeed?
    if [[ $? == 0 ]]
    then
      STATUS="User ${USER} was created, with password ${PWD}"
    else
      STATUS="Failed to create ${USER}"
      BAIL=true
    fi
  fi

  # restore normal output...
  exec 1>&6 6>&-               # restore stdout and close file descriptor 6...
  exec 2>&7 7>&-               # restore stderr and close file descriptor 7...

  # print our status...
  echo "${STATUS}"

  # if we had a problem, time to bail out...
  if [[ "${BAIL}" == true ]]
  then
    exit 1;
  fi
}


###############
# Main script #
###############

# First we find out which OS we have, which requires no authentication, and may change some behavior in this script...
OUR_OS=$(osName)
echo "Setting up on Raspberry Pi OS ${OUR_OS^}"

# Now we set our password, which is the default Raspberry Pi OS' default password...
OUR_PASSWORD=$(osPassword OUR_OS)

# make sure we have the officially sanctioned hostname...
ensureHostName "${OUR_PASSWORD}"

# make sure we have our app's user...
ensureUser "${OUR_PASSWORD}" "${APP_USER}" "${APP_PASSWORD}"
