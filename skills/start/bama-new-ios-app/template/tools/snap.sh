#!/bin/zsh
# Snapshots of every page and Settings topic in light and dark, with seed
# data, on a fresh test store. Writes /tmp/__APP_NAME__-shots/<name>.png.
# The app shows each page and asks for it with <name>.want (Snapshot.swift);
# this script answers with a screenshot of the simulator's screen.
# Usage: tools/snap.sh                          all pages, on the iPhone Duo
#        APP_SNAPSHOT_PAGES=all,settings tools/snap.sh
#        APP_DEVICE="iPhone 18 Pro" tools/snap.sh
# It captures the screen that is on. APP_DISPLAY picks one: on the Duo, 1 is
# the outer display and 3 the inner one.
set -euo pipefail
source "${0:A:h}/env.sh"
[[ -d $app_sim ]] || "$root/tools/build.sh"
udid=$(sim_udid)
store=/tmp/$name-test.store
shots=/tmp/$name-shots
# Seed data only fills an empty store, so start from nothing.
rm -f $store $store-shm $store-wal
rm -rf $shots
mkdir -p $shots
xcrun simctl install "$udid" "$app_sim"
vars=(SIMCTL_CHILD_APP_STORE=$store SIMCTL_CHILD_APP_SEED=1 SIMCTL_CHILD_APP_SNAPSHOT=$shots)
[[ -n ${APP_SNAPSHOT_PAGES:-} ]] && vars+=(SIMCTL_CHILD_APP_SNAPSHOT_PAGES=$APP_SNAPSHOT_PAGES)
[[ -n ${APP_ACCENT:-} ]] && vars+=(SIMCTL_CHILD_APP_ACCENT=$APP_ACCENT)
env "${vars[@]}" xcrun simctl launch --terminate-running-process "$udid" "$bundle" >/dev/null
screen=${APP_DISPLAY:-$(active_display "$udid")}
display=()
[[ -n $screen ]] && display=(--display=$screen)

# Answer each request until the app says it is done.
deadline=$((SECONDS + 180))
while (( SECONDS < deadline )); do
  for want in $shots/*.want(N); do
    png=${want%.want}.png
    xcrun simctl io "$udid" screenshot "${display[@]}" --type=png "$png.part" >/dev/null 2>&1
    mv "$png.part" "$png"
    rm -f "$want"
    echo "$png"
  done
  grep -q "^SNAPSHOT done" $shots/snapshot.log 2>/dev/null && exit 0
  if grep -qE "^SNAPSHOT (refused|missed)" $shots/snapshot.log 2>/dev/null; then
    grep -E "^SNAPSHOT (refused|missed)" $shots/snapshot.log
    exit 1
  fi
  sleep 0.2
done
echo "snapshots timed out after 180 seconds. Progress: $shots/snapshot.log"
exit 1
