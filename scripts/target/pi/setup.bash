#!/usr/bin/env bash
set -euo pipefail

# Phase 1 of the setup for a Raspberry Pi, for Weather Gauges.
# Assumptions:
#   1.  Operating system has been installed, and the only normal user installed is the default user with the default password.
#   2.  SSH is enabled on the target Raspberry Pi
#   3.  This script has been copied to the /home/<default user> directory, and executed from there (logged in as the default user)

# Include common stuff.
source deploy/pi/common.bash

# Sets the hostname to $1
changeHostName() {
  sudo hostnamectl set-hostname "$1"
}


# Ensures the hostname has been set to the proper value.  Outputs status messages only.
ensureHostName() {
  if [[ $(hostName) != "$WEATHERGAUGES_HOSTNAME" ]]
  then
    changeHostName "${WEATHERGAUGES_HOSTNAME}"
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


# Change the given user's password to the given new password.
# $1 is the user to change
# $2 is the new password
changePassword() {

  local RC

  # change the user's password to the desired one...
  RC=$(echo "${1}":"${2}" | sudo chpasswd >/dev/null 2>/dev/null && true; echo $?)

  # did we succeed?
  if (( RC == 0 ))
  then

    # verify that the password is usable...
    # this returns L for locked, P for usable password, or NP for no password
    local PS; PS=$(sudo passwd --status "${1}" | sed --quiet --regexp-extended  's/\w*\s*(\w*)\s*.*/\1/p')
    if [[ $PS == "P" ]]
    then
      echo "User ${1} now has the usable password ${2}"
      return 0
    else
      echo "Password change command succeeded, but the password for ${1} is not usable"
      return 1
    fi
  else
    echo "Failed to change password for ${1}"
    return 2
  fi
}


# Ensures that the specified user exists.
# $1 is the user to ensure
# $2 is that user's default password
ensureUser() {
  local USER; USER=$1
  local PWD; PWD=$2

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
  changePassword "${USER}" "${PWD}"
  RC=$?
  if (( RC != 0 ))
  then
    exit 1
  fi

  # set up public SSH keys in app user...

  # save UID and GID of our new user...
  local APP_USER_UID
  local APP_USER_GID
  APP_USER_UID=$(grep "${USER}" /etc/passwd | sed -n 's/[^:]*:[^:]*:\([^:]*\).*/\1/p')
  APP_USER_GID=$(grep "${USER}" /etc/passwd | sed -n 's/[^:]*:[^:]*:[^:]*:\([^:]*\).*/\1/p')

  # setup .ssh directory for app user...
  if [[ ! -d "/home/${USER}/.ssh" ]]
  then
    sudo mkdir "/home/${USER}/.ssh"
    sudo chown "${APP_USER_UID}":"${APP_USER_GID}" "/home/${USER}/.ssh"
    sudo chmod 700 "/home/${USER}/.ssh"
  fi

  # copy authorized_keys and id_rsa.pub over...
  sudo cp "/home/${DEFAULT_USER}/.ssh/id_rsa.pub" "/home/${USER}/.ssh/id_rsa.pub"
  sudo cp "/home/${DEFAULT_USER}/.ssh/authorized_keys" "/home/${USER}/.ssh/authorized_keys"
  sudo chown "${APP_USER_UID}":"${APP_USER_GID}" "/home/${USER}/.ssh/id_rsa.pub"
  sudo chown "${APP_USER_UID}":"${APP_USER_GID}" "/home/${USER}/.ssh/authorized_keys"
}


# Update the APT package information.
updatePackageInfo() {

  echo "Updating APT package information; this could take a while..."

  # delete our apt history files, if they exist...
  if [[ -f /home/pi/apt.stdout ]]; then rm /home/pi/apt.stdout; fi
  if [[ -f /home/pi/apt.stderr ]]; then rm /home/pi/apt.stderr; fi

  # download current package information...
  # shellcheck disable=SC2024
  sudo DEBIAN_FRONTEND=noninteractive apt-get --yes --quiet update >>/home/pi/apt.stdout 2>>/home/pi/apt.stderr && true;
  EC=$?
  if (( EC != 0 ))  # exit immediately if there was a problem...
  then
    echo "Updating APT packages failed (see apt.stdout and apt.stderr for details)..."
    return $EC
  fi
  echo "APT packages updated..."
}


# Update the Linux OS and upgrade installed packages.  Returns 0 if everything worked correctly, or an error code if one of the commands
# failed.  If any commands fail, the commands following the failed command will not be executed.  Progress messages are output, but the stdout output
# of the apt-get commands is stored in /home/pi/apt.stdout, and the stderr output in /home/pi/apt.stderr.
updateOS() {

  # if we've updated within a day, skip this...
  local APT_TEST
  APT_TEST="apt.flag"
  if [[ -f "${APT_TEST}" ]]
  then
    local MOD_SECS
    MOD_SECS=$(modifiedSecondsAgo "${APT_TEST}")
    if (( MOD_SECS < 86400 ))
    then
      echo "Skipping APT upgrade and autoremove, as we've done it within the day..."
      return 0
    fi
  fi

  # warn the user that we've got a slow thing happening...
  echo "Running APT upgrade and autoremove - may take a while..."

  # install upgrades of already-installed packages...
  # shellcheck disable=SC2024
  sudo DEBIAN_FRONTEND=noninteractive apt-get --yes --quiet --with-new-pkgs upgrade >>/home/pi/apt.stdout 2>>/home/pi/apt.stderr && true;
  EC=$?
  if (( EC != 0 ))  # exit immediately if there was a problem...
  then
    echo "Upgrading APT packages failed (see apt.stdout and apt.stderr for details)..."
    return $EC
  fi
  echo "APT packages upgraded..."

  # remove no-longer needed packages...
  # shellcheck disable=SC2024
  sudo DEBIAN_FRONTEND=noninteractive apt-get --yes --quiet autoremove >>/home/pi/apt.stdout 2>>/home/pi/apt.stderr && true;
  EC=$?
  if (( EC != 0 ))  # exit immediately if there was a problem...
  then
    echo "Automatically removing unused APT packages failed (see apt.stdout and apt.stderr for details)..."
    return $EC
  fi
  echo "Unused APT packages automatically removed..."
  touch "${APT_TEST}"
  return 0
}


# Install the given APT package if has not already been installed.
# $1 is the package name to install
ensurePackage() {

  local PKG
  PKG=$1

  # the package has been installed alredy...
  if dpkg -s "${PKG}" &>/dev/null
  then
    echo "Package ${PKG} is already installed..."
  # otherwise, we need to actually install it...
  else
    # shellcheck disable=SC2024
    sudo DEBIAN_FRONTEND=noninteractive apt-get --yes --quiet --no-install-recommends install "${PKG}" \
        >>/home/pi/apt.stdout 2>>/home/pi/apt.stderr && true;
    EC=$?
    if (( EC != 0 ))  # exit immediately if there was a problem...
    then
      echo "Installing package xserver-xorg failed (see apt.stdout and apt.stderr for details)..."
      return $EC
    fi
    echo "Installed package ${PKG}..."
  fi
  return 0
}


# Install the minimum GUI components: XWindows and associated bits, OpenBox window manager, and the Chromium browser...
ensureGUI() {

  # ensure all the packages we need are installed...
  echo "Ensuring all needed GUI components are installed..."
  ensurePackage xserver-xorg
  ensurePackage x11-xserver-utils
  ensurePackage xinit
  ensurePackage openbox
  ensurePackage chromium-browser
  echo "All needed GUI components are installed..."
}


# Add app user to sudoers with NOPASSWD.
# $1..n are the users to add NOPASSWD lines for
ensureSudoers() {

  local THIS_USER AC
  for THIS_USER in "$@"
  do

    # if there's an entry already for the app user, don't do it again...
    AC=$( sudo cat /etc/sudoers | grep -c "${THIS_USER}" && true ) && true
    if (( AC != 0 ))
    then
      echo "The user ${THIS_USER} already has a NOPASSWD line in sudoers..."
    else

      # add our NOPASSWD line...
      echo "${THIS_USER} ALL=(ALL) NOPASSWD: ALL" | sudo EDITOR='tee -a' visudo >/dev/null
      echo "Added ${THIS_USER} to sudoers file as NOPASSWD"

    fi
  done
}


# Disable password logins to SSH for the given users
# $1..n are the users to disable
ensureSSHPasswordLoginDisabled() {

  local THIS_USER MATCH_SPEC ADDED_LINES
  ADDED_LINES=false
  for THIS_USER in "$@"
  do

      # build the match specification we expect to see in sshd_config
      MATCH_SPEC="Match User ${THIS_USER}"

      # does sshd_config already contain this match specification?
      AC=$( sudo cat /etc/ssh/sshd_config | grep -c "^${MATCH_SPEC}" && true ) && true
      if (( AC != 0 ))
      then
        echo "Password SSH login already disabled for ${THIS_USER}..."
      else
        # add the disable password login lines to sshd_config...
        echo "${MATCH_SPEC}" | sudo tee -a /etc/ssh/sshd_config >/dev/null
        echo "    PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config >/dev/null
        ADDED_LINES=true
        echo "Disabled password SSH login for ${THIS_USER}"
      fi

  done

  # if we've added any lines to sshd_config, add a trailing "Match all" and bounce it...
  if [[ "${ADDED_LINES}" ]]
  then

    # add the trailing "Match all"...
    echo "Match all" | sudo tee -a /etc/ssh/sshd_config >/dev/null

    # bounce the SSH service to enable the above changes...
    sudo service ssh restart
  fi
}


# Copy deployment files to app user.
# $1 is app user
copyAppFiles() {
  sudo cp --preserve=mode --recursive deploy/"${1}/."/* /home/"${1}"
  sudo chown --recursive "${1}:${1}" "/home/${1}"
}


# Ensure that the /boot/config.txt file contains the lines that force HDMI output on.
ensureBootConfig() {

  # have we already configured this file?
  local AC
  AC=$( sudo cat /boot/config.txt | grep -c "^hdmi_force_hotplug=1" && true ) && true
  if (( AC != 0 ))
  then
    echo "The boot config file (/boot/config.txt) is already configured to force HDMI on..."
  else

    # add the HDMI configuration lines...
    echo "# always force HDMI output and enable HDMI sound" | sudo tee -a /boot/config.txt >/dev/null
    echo "hdmi_force_hotplug=1" | sudo tee -a /boot/config.txt >/dev/null
    echo "hdmi_drive=2" | sudo tee -a /boot/config.txt >/dev/null
    echo "Configured boot config file (/boot/config.txt) to force HDMI on..."
  fi
}


# Check to make sure time synchronization is running.
checkTimeSync() {

  local COUNT
  COUNT=$( sudo ps axu | grep -c "[t]imesyncd" )
  if (( COUNT > 0 ))
  then
    echo "Time synchronization is running..."
  else
    echo "Time synchronization is NOT running..."
    exit 1
  fi
}


# Ensure that we have the en_US.UTF-8 locale...
ensureLocale() {

  # do we already have the en_US.UTF-8 locale?
  # the file "locale.flag" exists if we've already done this...
  local LOCALE_FLAG
  LOCALE_FLAG="locale.flag"
  if [[ -f "${LOCALE_FLAG}" ]]
  then
    echo "The locale en_US\.utf8 has already been generated..."
  else
    echo "Generating en_US.UTF-8 locale (this might take a while)..."
    sudo cp "/home/${DEFAULT_USER}/deploy/pi/locale.gen" /etc/locale.gen
    sudo chown root:root /etc/locale.gen
    sudo locale-gen >/dev/null
    touch "${LOCALE_FLAG}"
    echo "Finished generating en_US.UTF-8 locale..."
  fi
}


# Create a bash profile for the given users.
# $1..n are the users
createBashProfile() {

  local THIS_USER
  for THIS_USER in "$@"
  do
    sudo cp /home/"${DEFAULT_USER}"/deploy/pi/.bash_profile /home/"${THIS_USER}"/.bash_profile
    sudo chown "${THIS_USER}":"${THIS_USER}" /home/"${THIS_USER}"/.bash_profile
    # shellcheck disable=SC1090
    echo "Set up bash profile for ${THIS_USER}..."
  done
}


# Configures the Raspberry Pi for automatic login to the pi user.
ensureAutoLogin() {

  # link the file for the getty service (for a CLI); this is taken from the raspi-config script...
  sudo ln -fs /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@tty1.service

  # create the autologin file; this is taken from the raspi-config script...
  cat | sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf >/dev/null << EOF
  [Service]
  ExecStart=
  ExecStart=-/sbin/agetty --autologin $USER --noclear %I \$TERM
EOF

}


# Ensure Openbox autostart file is in place...
ensureOpenboxAutostart() {
  sudo cp --preserve=mode --recursive deploy/pi/autostart /home/pi/.config/openbox
  sudo chown --recursive "pi:pi" "/home/pi/.config/openbox"
}



###############
# Main script #
###############

# First we find out which OS we have, which requires no authentication, and may change some behavior in this script...
OUR_OS=$(osName)
echo "Starting phase 1 setup of Raspberry Pi OS ${OUR_OS^} for WeatherGauges..."

# update to sudoers file so that the app user needs no password for sudo...
sudoAuth "${DEFAULT_PASSWORD}"
ensureSudoers "${DEFAULT_USER}" "${APP_USER}"

# change default user's password, so we don't see annoying messages about still having the default...
changePassword "${DEFAULT_USER}" "${DEFAULT_NEW_PASSWORD}"

# make sure we have the officially sanctioned hostname...
ensureHostName

# make sure we have our app's user, with SSH public key...
ensureUser "${APP_USER}" "${APP_PASSWORD}"

# generate our locale, forcing it to American English...
ensureLocale

# create a bash profile for the default user and the app user, and load it...
createBashProfile "${DEFAULT_USER}" "${APP_USER}"

# make sure time synchronization is running...
checkTimeSync

# update APT package information...
updatePackageInfo

# install minimal GUI components...
ensureGUI

# update the operating system and installed apps...
updateOS

# update to sshd_config to disable SSH password login for the default user and the app user...
ensureSSHPasswordLoginDisabled  "${DEFAULT_USER}" "${APP_USER}"

# copy application deployment files
copyAppFiles "${APP_USER}"

# ensure that the /boot/config.txt file will force HDMI output on...
ensureBootConfig

# ensure that automatic login to pi is enabled...
ensureAutoLogin

# ensure that Openbox autostart is in place...
ensureOpenboxAutostart

# reboot the target to get all these changes to take effect...
sudo shutdown -r now && true

# exit cleanly, with no error...
exit 0


# export DISPLAY=:0
# raspi-config advanced options full KMS GL driver


#       if ! sed -n "/\[pi4\]/,/\[/ !p" $CONFIG | grep -q "^dtoverlay=vc4-kms-v3d" ; then
#         ASK_TO_REBOOT=1
#       fi
#       sed $CONFIG -i -e "s/^dtoverlay=vc4-fkms-v3d/#dtoverlay=vc4-fkms-v3d/g"
#       sed $CONFIG -i -e "s/^#dtoverlay=vc4-kms-v3d/dtoverlay=vc4-kms-v3d/g"
#       if ! sed -n "/\[pi4\]/,/\[/ !p" $CONFIG | grep -q "^dtoverlay=vc4-kms-v3d" ; then
#         printf "[all]\ndtoverlay=vc4-kms-v3d\n" >> $CONFIG
#       fi
#       STATUS="The full KMS GL driver is enabled."
#       ;;

# $CONFIG == "/boot/config.txt"
