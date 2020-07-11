#!/usr/bin/env bash
set -euo pipefail

export DISPLAY=:0
export BROWSER=/usr/bin/chromium-browser
xset -dpms                                # turn off dpms blanking until next boot
xset s reset                              # force screen on
xset s off                                # turn off screensaver
xset s noblank                            # no screensaver
xset s 0                                  # disable blanking until next boot
unclutter -idle 0.1                       # turn off cursor after 0.1 seconds of no motion
