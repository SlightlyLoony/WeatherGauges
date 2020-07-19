# This script is executed from .bash_profile IF a non-SSH session is loaded.  This should happen exactly once after booting on the kiosk,
# because the pi user is automatically logged in and there is no other way for a local session to be initiated.

source deploy/pi/common.bash
source deploy/pi/chromium.bash

killChromiumPidFile  # we might have ended dirty last time...

# If the X server has not already been started, start it...
if [[ $( ps ux | grep -c "[X]org" ) -eq 0 ]]
then
  startx -- -nocursor
  # NOTE: we will never get here, as startx never exits...
fi
