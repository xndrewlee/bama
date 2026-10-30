#!/bin/zsh
# Drives the app on the simulator through its debug bridge (DebugBridge.swift)
# and prints the app's state as JSON.
# Usage: tools/bridge.sh start              fresh test store, app launched with the bridge
#        tools/bridge.sh status
#        tools/bridge.sh <command>[:<argument>]    for example add:Milk, page:starred
# Copied into the project's tools/ by the bama-test-ios-app skill.
set -euo pipefail
source "${0:A:h}/env.sh"
dir=/tmp/$name-bridge
udid=$(sim_udid)

if [[ ${1:-status} == start ]]; then
  [[ -d $app_sim ]] || "$root/tools/build.sh"
  store=/tmp/$name-bridge.store
  rm -f $store $store-shm $store-wal
  rm -rf $dir
  mkdir -p $dir
  xcrun simctl install "$udid" "$app_sim"
  SIMCTL_CHILD_APP_STORE=$store SIMCTL_CHILD_APP_BRIDGE=$dir \
    xcrun simctl launch --terminate-running-process "$udid" "$bundle" >/dev/null
else
  [[ -d $dir ]] || { echo "the bridge is not running: tools/bridge.sh start"; exit 1; }
  print -r -- "${1:-status}" > $dir/command
  rm -f $dir/status.json
  # devicectl cannot post Darwin notifications to a simulator; notifyutil inside it can.
  xcrun simctl spawn "$udid" notifyutil -p "$bundle.bridge"
fi
for tick in {1..75}; do [[ -f $dir/status.json ]] && break; sleep 0.2; done
[[ -f $dir/status.json ]] || { echo "no answer from the app: run tools/bridge.sh start"; exit 1; }
cat $dir/status.json
echo
