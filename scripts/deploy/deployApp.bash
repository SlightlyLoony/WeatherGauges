#!/usr/bin/env bash
set -euo pipefail


######################
# Deploy Weather Gauges app to a target Raspberry Pi
# USAGE:
#    ./deployApp.bash <ip address of Raspberry Pi>
#
# EXAMPLE:
#    ./deploy.bash 10.2.4.25
#
# ASSUMPTIONS:
#   1.  This script is run after deploy.bash (and also at the end of deploy.bash).
#
######################


source scripts/deploy/common.bash

APP_USER="weathergauges"
TARGET="${1}"


# Deploy app code
_scp_to_remote "${APP_USER}" "${TARGET}" "out/artifacts/*" "/home/${APP_USER}/app"
