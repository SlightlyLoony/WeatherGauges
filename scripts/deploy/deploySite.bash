#!/usr/bin/env bash
set -euo pipefail


######################
# Deploy Weather Gauges site to a target Raspberry Pi
# USAGE:
#    ./deploySite.bash <ip address of Raspberry Pi>
#
# EXAMPLE:
#    ./deploySite.bash 10.2.4.25
#
# ASSUMPTIONS:
#   1.  This script is run after deploy.bash (and also at the end of deploy.bash).
#
######################


source scripts/deploy/common.bash

APP_USER="weathergauges"
TARGET="${1}"


# Deploy site code
_scp_to_remote "${APP_USER}" "${TARGET}" "site/*" "/home/${APP_USER}/app"

echo "Web site deployed..."
