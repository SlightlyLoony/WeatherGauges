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

DEFAULT_USER="pi"
DEFAULT_PASSWORD="raspberry"
WEATHERGAUGES_HOSTNAME="weathergauges"  # hostname for "as shipped" Weather Gauges device; user may change...
APP_USER="weathergauges"                # user name that Weather Gauges runs under; user may NOT change...
APP_PASSWORD="WeatherGauges2020OhMy!"   # default password for "weathergauges" user; user may change, device reset restores...


#########################
# Function Declarations #
#########################


# Execute the command in $1 but suppress stdout and stderr, returning the exit code
quiet() {
  $1 >/dev/null 2>/dev/null
  return $?
}


# Authenticate to sudo, either by new authentication or by extending active sudo credentials.  There is no output.
# $1 is the default user's password
sudoAuth() {
  echo "$1" | sudo -S -v >/dev/null 2>/dev/null
}


# Echoes the exit code of the command in $1 (to stdout), suppressing any output to stdout or stderr from the command itself.
# This is done in a manner safe when running with set -e.
getExitCode() {
  quiet "$1" && true
  echo $?
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
  hostnamectl | sed -n '/Operating System/ s/.*(\(.*\)).*/\1/ p' | tr "[:upper:]" "[:lower:]"
}


# Outputs the host name for this machine.
hostName() {
  echo "$(hostname)"
}


# Sets the hostname to $1
changeHostName() {
  sudo hostnamectl set-hostname "$1"
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
  local USER; USER=$2
  local PWD; PWD=$3
  sudoAuth $1        # authenticate to sudo...

  # see whether we already have this user, and if not, create it...
  # returned exit code is 0 if user exists
  local RC; RC=$(getExitCode "id -u ${USER}")
  if (( RC == 0 ))
  then
    echo "User ${USER} already exists"
  else

    # the user doesn't exist, so we create it...
    RC=$(getExitCode "sudo useradd --base-dir /home --user-group --create-home ${USER}")

    # did we succeed?
    if (( RC == 0 ))
    then

      echo "Created user ${USER}"
    else

      # alarm the user, and indicate that we're bailing from the script...
      echo "Failed to create ${USER}"
      exit 1
    fi
  fi

  # change the user's password to the desired one...
  RC=$(echo ${USER}:${PWD} | sudo chpasswd >/dev/null 2>/dev/null && true; echo $?)

  # did we succeed?
  if (( RC == 0 ))
  then

    # verify that the password is usable...
    # this returns L for locked, P for usable password, or NP for no password
    local PS; PS=$(sudo passwd --status weathergauges | sed --quiet --regexp-extended  's/\w*\s*(\w*)\s*.*/\1/p')
    if [[ $PS == "P" ]]
    then
      echo "User ${USER} now has the usable password ${PWD}"
    else
      echo "Password change command succeeded, but the password for ${USER} is not usable"
    fi
  else
    echo "Failed to change password for ${USER}"
    exit 1
  fi
}


# Update the Linux OS and upgrade installed packages.  Returns 0 if everything worked correctly, or an error code if one of the commands
# failed.  If any commands fail, the commands following the failed command will not be executed.  Progress messages are output, but the stdout output
# of the apt-get commands is stored in /home/pi/apt.stdout, and the stderr output in /home/pi/apt.stderr.
# $1 is the default password.
updateOS() {

  # warn the user that we've got a slow thing happening...
  echo "Running APT update/upgrade/autoremove - may take a while..."

  # download current package information...
  sudoAuth $1
  sudo apt-get --yes --quiet update >/home/pi/apt.stdout 2>/home/pi/apt.stderr && true;
  EC=$?
  if (( EC != 0 ))  # exit immediately if there was a problem...
  then
    echo "Updating APT packages failed (see apt.stdout and apt.stderr for details)..."
    return $EC
  fi
  echo "APT packages updated..."

  # install upgrades of already-installed packages...
  sudoAuth $1
  sudo apt-get --yes --quiet --with-new-pkgs upgrade >>/home/pi/apt.stdout 2>>/home/pi/apt.stderr && true;
  EC=$?
  if (( EC != 0 ))  # exit immediately if there was a problem...
  then
    echo "Upgrading APT packages failed (see apt.stdout and apt.stderr for details)..."
    return $EC
  fi
  echo "APT packages upgraded..."

  # remove no-longer needed packages...
  sudoAuth $1
  sudo apt-get --yes --quiet autoremove >>/home/pi/apt.stdout 2>>/home/pi/apt.stderr && true;
  EC=$?
  if (( EC != 0 ))  # exit immediately if there was a problem...
  then
    echo "Automatically removing unused APT packages failed (see apt.stdout and apt.stderr for details)..."
    return $EC
  fi
  echo "Unused APT packages automatically removed..."
  return 0
}


# Add app user to sudoers with NOPASSWD.
# $1 is the default password
# $2 is the app user
tweakSudoers() {
set -x
  # make sure we're allowed...
  sudoAuth $1

  # if there's an entry already for the app user, skip this...
  AC=$( sudo cat /etc/sudoers | grep -c $2 && true ) && true
  if (( AC != 0 ))
  then
    return 0
  fi

  # add our magic line...
  echo "needs it"
}

# add weathergauges to SUDO for no password
# validate that time synchronization is running


###############
# Main script #
###############

# First we find out which OS we have, which requires no authentication, and may change some behavior in this script...
OUR_OS=$(osName)
echo "Setting up on Raspberry Pi OS ${OUR_OS^}"

# make sure we have the officially sanctioned hostname...
ensureHostName "${DEFAULT_PASSWORD}"

# make sure we have our app's user...
ensureUser "${DEFAULT_PASSWORD}" "${APP_USER}" "${APP_PASSWORD}"

# update the operating system and installed apps...
updateOS "${DEFAULT_PASSWORD}"

# update to sudoers file so that the app user needs no password for sudo...
tweakSudoers "${DEFAULT_PASSWORD}" "${APP_USER}"

# exit cleanly, with no error...
exit 0
