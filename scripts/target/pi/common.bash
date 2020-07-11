

####################
# Fixed Parameters #
####################

DEFAULT_USER="pi"
DEFAULT_PASSWORD="raspberry"
DEFAULT_NEW_PASSWORD="raspberryPi"
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
# If the default user currently has sudo rights with NOPASSWD, does nothing.
# $1 is the default user's password
sudoAuth() {

  local COUNT
  COUNT=$( sudo -l | grep -c NOPASSWD )
  if (( COUNT > 0 ))
  then
    echo "Default user already has sudo NOPASSWD rights..."
  else
    echo "$1" | sudo -S -v >/dev/null 2>/dev/null
    echo "Authenticated default user..."
  fi
}


# Echoes the exit code of the command in $1 (to stdout), suppressing any output to stdout or stderr from the command itself.
# This is done in a manner safe when running with set -e.
getExitCode() {
  quiet "$1" && true
  echo $?
}


# Echos the number of seconds since the given file was last modified.
# $1 is the path to the file
modifiedSecondsAgo() {
  # shellcheck disable=SC2086
  echo $(( "$(date +%s)" - "$(date -r ${APT_TEST} +%s)" ))
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
  hostname
}
