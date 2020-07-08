#!/usr/bin/env bash
set -euo pipefail

export DISPLAY=:0
export BROWSER=/usr/bin/chromium-browser
xset -dpms       # Turn off dpms blanking until next boot
xset s activate  # Force screen blank

chromium-browser                         `# run the chromium browser IN THE BACKGROUND...`      \
  --noerrdialogs                         `# don't pop up error dialogs...`                      \
  --disable-component-update             `# disable upgrade checks...`                          \
  --check-for-update-interval=1576800000 `# seconds between update checks (50 years)...`        \
  --kiosk                                `# kiosk mode (full screen)...`                        \
  file:///home/pi/deploy/pi/test.html &   # the starting page

sleep 10                                  # allow time for booting and starting browser. Adjust as necessary
xset s reset                              # force screen on
xset s noblank                            # no screensaver
xset s 0                                  # disable blanking until next boot
unclutter -idle 0.1                       # turn off cursor after 0.1 seconds of no motion
