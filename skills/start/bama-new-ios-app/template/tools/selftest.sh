#!/bin/zsh
# Runs the in-app self-test on the simulator against a fresh store in /tmp.
# Exit code 0 when every check passed.
set -euo pipefail
source "${0:A:h}/env.sh"
[[ -d $app_sim ]] || "$root/tools/build.sh"
udid=$(sim_udid)
store=/tmp/$name-self.store
rm -f $store $store-shm $store-wal
xcrun simctl install "$udid" "$app_sim"
# --console-pty waits for the app to quit and prints what it printed.
out=$(SIMCTL_CHILD_APP_STORE=$store xcrun simctl launch --console-pty --terminate-running-process \
  "$udid" "$bundle" --selftest 2>&1 | tr -d '\r')
print -r -- "$out" | grep -E "^(PASS|FAIL|SELFTEST)"
[[ $out == *"SELFTEST PASS"* ]]
