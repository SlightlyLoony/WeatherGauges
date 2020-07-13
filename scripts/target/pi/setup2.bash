#!/usr/bin/env bash
set -euo pipefail

# Phase 2 of the setup for a Raspberry Pi, for Weather Gauges.
# Assumptions:
#   1.  The deploy.bash script ran and successfully executed the setup.bash (phase 1 setup).

# Include common stuff.
source deploy/pi/common.bash
source deploy/pi/chromium.bash

###############
# Main script #
###############

# Tell the user what's happening...
echo "Starting phase 2 setup of Raspberry Pi for WeatherGauges..."

# Launch chromium with our kiosk page...
#killChromiumPidFile
#ensureChromium "kiosk.html"

# exit cleanly, with no error...
echo "Exiting phase 2 setup..."
exit 0
