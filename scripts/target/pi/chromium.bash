# The name of the file that contains the pid of the last instance of chromium started in the background.
# If there is no chromium in the background, this file won't exist.
CHROMIUM_PID_FILE="chromium.pid"


# Delete the chromium PID file (to indicate that chromium is not currently running in the background).
killChromiumPidFile() {
  rm -f "${CHROMIUM_PID_FILE}"
}


# Ensure that chromium is not running.  The chromium process' PID is in chromium.pid
ensureNoChromium() {

  # if there is a PID file, then chromium is running...
  if [[ -f "${CHROMIUM_PID_FILE}" ]]
  then

    # get the PID of the chromium that's running...
    local PID
    PID=$( cat "${CHROMIUM_PID_FILE}" )

    # make sure it's not running...
    if ensureNotRunning "${PID}"

    # log the possible outcomes...
    then
      echo "Chromium was terminated normally, or was no longer running..."
    else
      echo "Chromium had to be killed; it was a bad, bad boy..."
    fi

    # make sure the PID file is gone...
    killChromiumPidFile

  else
    echo "Chromium was not running..."
  fi
}


# Launch chromium.
# $1 is the name of the page to load
launchChromium() {

  # make certain we have a display defined...
  export DISPLAY=:0

  echo "Starting chromium..."
  # start chromium in the background...
  nohup chromium-browser                    `# the actual app`                                        \
    --noerrdialogs                          `# don't pop up any sort of error dialog`                 \
    --disable-component-update              `# don't check for updates`                               \
    --check-for-update-interval=1576800000  `# 50 year update check interval`                         \
    --kiosk                                 `# kiosk mode, no menus, toolbar, etc.`                   \
    --no-default-browser-check              `# don't check to see if chromium is the default browser` \
    --app=http://localhost:8888/"${1}"      `# launch our app`                                        \
    &>/home/pi/chromium.out
}


# Ensure that a new chromium instance is running.
# $1 is the name of the page to load
ensureChromium() {
  ensureNoChromium
  launchChromium "${1}"

  echo "Chromium started..."
}
