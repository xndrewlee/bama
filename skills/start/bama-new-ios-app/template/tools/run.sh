#!/bin/zsh
# Builds __APP_NAME__, installs it on the simulator, and opens it with its
# real database. APP_DEVICE="iPhone 18 Pro" tools/run.sh picks another device.
set -euo pipefail
source "${0:A:h}/env.sh"
"$root/tools/build.sh"
udid=$(sim_udid)
xcrun simctl install "$udid" "$app_sim"
xcrun simctl launch --terminate-running-process "$udid" "$bundle" >/dev/null
echo "running on ${APP_DEVICE:-iPhone Duo} ($udid)"
developer=${DEVELOPER_DIR:-$(xcode-select -p)}
echo "to watch it: open \"${developer:h}/Applications/DeviceHub.app\""
