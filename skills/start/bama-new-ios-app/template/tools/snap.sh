#!/bin/zsh
# Snapshots of every page and Settings topic in light and dark, with seed
# data, on a fresh test store. Writes /tmp/__APP_NAME__-shots/<name>.png.
# The app shows each page and asks for it with <name>.want (Snapshot.swift);
# this script answers with a screenshot of the simulator's screen.
# Usage: tools/snap.sh                          all pages, on the iPhone Duo
#        APP_SNAPSHOT_PAGES=all,settings tools/snap.sh
#        APP_DEVICE="iPhone 18 Pro" tools/snap.sh
#        APP_SIZE=951x669 APP_SHOTS=/tmp/__APP_NAME__-inner tools/snap.sh
# It captures the screen that is on. APP_DISPLAY picks one: on the Duo, 1 is
# the outer display and 3 the inner one.
# APP_SIZE renders the app at that size in points on the simulator's
# Resizable screen (devicectl appResize). That checks size classes and
# layout, not the fold, the system buttons, or the safe areas of a real pose.
set -euo pipefail
source "${0:A:h}/env.sh"
[[ -d $app_sim ]] || "$root/tools/build.sh"
udid=$(sim_udid)
store=/tmp/$name-test.store
shots=${APP_SHOTS:-/tmp/$name-shots}
# Seed data only fills an empty store, so start from nothing.
rm -f $store $store-shm $store-wal
rm -rf $shots
mkdir -p $shots
xcrun simctl install "$udid" "$app_sim"
vars=(SIMCTL_CHILD_APP_STORE=$store SIMCTL_CHILD_APP_SEED=1 SIMCTL_CHILD_APP_SNAPSHOT=$shots)
[[ -n ${APP_SNAPSHOT_PAGES:-} ]] && vars+=(SIMCTL_CHILD_APP_SNAPSHOT_PAGES=$APP_SNAPSHOT_PAGES)
[[ -n ${APP_ACCENT:-} ]] && vars+=(SIMCTL_CHILD_APP_ACCENT=$APP_ACCENT)
env "${vars[@]}" xcrun simctl launch --terminate-running-process "$udid" "$bundle" >/dev/null

# The app writes `ready` once it is on screen.
for tick in {1..150}; do [[ -e $shots/ready ]] && break; sleep 0.2; done

if [[ -n ${APP_SIZE:-} ]]; then
  # appResize moves the frontmost app. Right after launch it often finds
  # none, or the device ends the session as the launch settles. Try again
  # until a session has held for two seconds.
  resize=
  trap '[[ -n $resize ]] && kill -INT $resize 2>/dev/null' EXIT
  sleep 2
  for attempt in {1..20}; do
    xcrun devicectl device appResize start -d "$udid" --preferred-size "$APP_SIZE" >$shots/resize.log 2>&1 &
    resize=$!
    # devicectl's own output reaches the log only when it quits, so ask the device.
    for tick in {1..10}; do
      kill -0 $resize 2>/dev/null || break
      if xcrun devicectl device info appResize -d "$udid" >/dev/null 2>&1; then
        sleep 2
        xcrun devicectl device info appResize -d "$udid" >/dev/null 2>&1 && break 2
        break
      fi
      sleep 0.5
    done
    kill -INT $resize 2>/dev/null || true
    resize=
    sleep 1
  done
  [[ -n $resize ]] || { echo "no appResize session at $APP_SIZE:"; cat $shots/resize.log; exit 1; }
  screen=$(display_id "$udid" Resizable)
else
  screen=${APP_DISPLAY:-$(display_id "$udid")}
fi
display=()
[[ -n $screen ]] && display=(--display=$screen)
# The screen is ready: the app starts its pages.
touch $shots/go

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
  if grep -q "^SNAPSHOT done" $shots/snapshot.log 2>/dev/null; then
    # Every page must have had the requested size, or the session dropped.
    if [[ -n ${APP_SIZE:-} ]]; then
      for layout in $shots/*-layout.json(N); do
        got=$(plutil -extract window.width raw -o - $layout)x$(plutil -extract window.height raw -o - $layout)
        [[ $got == $APP_SIZE ]] || { echo "${layout:t}: the app was ${got}, not $APP_SIZE: the appResize session ended early"; exit 1; }
      done
    fi
    exit 0
  fi
  if grep -qE "^SNAPSHOT (refused|missed)" $shots/snapshot.log 2>/dev/null; then
    grep -E "^SNAPSHOT (refused|missed)" $shots/snapshot.log
    exit 1
  fi
  sleep 0.2
done
echo "snapshots timed out after 180 seconds. Progress: $shots/snapshot.log"
exit 1
