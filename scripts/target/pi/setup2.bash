#!/usr/bin/env bash
set -euo pipefail

# Phase 2 of the setup for a Raspberry Pi, for Weather Gauges.
# Assumptions:
#   1.  The deploy.bash script ran and successfully executed the setup.bash (phase 1 setup).

# Include common stuff.
source deploy/pi/common.bash


# Cleanup after deployment...
cleanupDeployment() {

  # delete the deploy directory...
  sudo rm -rf /home/pi/deploy
}

###############
# Main script #
###############

# Tell the user what's happening...
echo "Starting phase 2 setup of Raspberry Pi for WeatherGauges..."

# cleanup the deployment files...
cleanupDeployment

# reboot the target to get all these changes to take effect...
sudo shutdown -r now && true

# exit cleanly, with no error...
echo "Exiting phase 2 setup..."
exit 0
