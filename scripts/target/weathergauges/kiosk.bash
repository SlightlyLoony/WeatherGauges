#!/usr/bin/env bash
set -euo pipefail

export DISPLAY=:0
export BROWSER=/usr/bin/chromium-browser
NOBLANK=''
xset -dpms       # Turn off dpms blanking until next boot
xset s activate  # Force screen blank
chromium-browser --noerrdialogs --disable-infobars --kiosk file:///home/pi/test.html & #<<< The & is important
sleep 10         # Allow time for booting and starting browser. Adjust as necessary
xset s reset     # Force screen on
xset s noblank   # No screensaver
xset s 0         # Disable blanking until next boot

