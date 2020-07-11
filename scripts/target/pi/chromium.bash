# The name of the file that contains the pid of the last instance of chromium started in the background.
# If there is no chromium in the background, this file won't exist.
CHROMIUM_PID_FILE="chromium.pid"


# Delete the chromium PID file (to indicate that chromium is not currently running in the background).
killChromiumPidFile() {
  rm -f "${CHROMIUM_PID_FILE}"
}


# Ensure that chromium is not running.
ensureNoChromium() {

  # if there is a PID file, then chromium is running...
  if [[ -f "${CHROMIUM_PID_FILE}" ]]
  then

    # get the PID of the chromium that's running...
    local PID
    PID=$( cat "${CHROMIUM_PID_FILE}" )

    # if a process with that PID exists...
    if kill -0 "${PID}"
    then

      # terminate it (and wait)...
      kill "${PID}" && true
      while kill -0 "${PID}"
      do
        echo $?
        sleep 1
      done

      # if that didn't do the trick...
      if kill -0 "${PID}"
      then

        # kill it...
        kill -9 "${PID}"
        echo "Chromimum had to be killed; it was a bad, bad boy..."
        killChromiumPidFile

      else
        killChromiumPidFile
        echo "Chromium successfully terminated..."
      fi
    else
      killChromiumPidFile
      echo "Chromium is supposed to be running, but is not..."
    fi
  else
    echo "Chromium is not running..."
  fi
}


# Launch chromium.
# $1 is the name of the page to load
launchChromium() {
set -x
  # start chromium in the background...
  DISPLAY=:0 chromium-browser               `# the actual app`                                        \
    --noerrdialogs                          `# don't pop up any sort of error dialog`                 \
    --disable-component-update              `# don't check for updates`                               \
    --check-for-update-interval=1576800000  `# 50 year update check interval`                         \
    --kiosk                                 `# kiosk mode, no menus, toolbar, etc.`                   \
    --no-default-browser-check              `# don't check to see if chromium is the default browser` \
    http://localhost/"${1}" &

    # save the background process' PID...
    echo "$!" > "${CHROMIUM_PID_FILE}"
}


# Ensure that a new chromium instance is running.
# $1 is the name of the page to load
ensureChromium() {
  ensureNoChromium
  launchChromium "${1}"
}

# DISPLAY=:0 chromium-browser --noerrdialogs --disable-component-update --check-for-update-interval=1576800000 --kiosk --no-default-browser-check http://paradiseweather.info/weather_js.html &
