#!/bin/zsh
# Snapshots an app from the bama-new-ios-app template in every iPhone Duo
# pose a script can reach, then on a non-Duo iPhone on iOS 27.0, and joins
# each set into one contact sheet. Writes /tmp/<AppName>-poses/<pose>/*.png
# and /tmp/<AppName>-poses/<pose>.png (the sheet).
# Usage: pose-shots.sh [app-folder]            default: the current folder
#        APP_SNAPSHOT_PAGES=all,settings pose-shots.sh
# Only `outer` and `iphone-27.0` are real screens. The others render the app
# at the pose's size on the simulator's Resizable screen: size classes and
# layout, not the fold, the system buttons, or the safe areas of the pose.
set -euo pipefail
here=${0:A:h}
dir=${1:-$PWD}
cd "$dir"
[[ -x tools/snap.sh && -f tools/env.sh ]] || { echo "$dir has no tools/snap.sh: not from the bama-new-ios-app template"; exit 1; }
name=$(sed -n 's/^name="\(.*\)"$/\1/p' tools/env.sh)
out=/tmp/$name-poses
rm -rf $out
mkdir -p $out
sheet=$(mktemp -d)/sheet
swiftc -O "$here/sheet.swift" -o "$sheet" 2>/dev/null

tools/build.sh
# pose, size in points (empty: the real screen), and whether to shade the fold.
poses=(
  outer           ""       none
  outer-landscape 678x466  none
  inner           669x951  fold
  inner-landscape 951x669  fold
  splitview       475x669  none
)
failed=()
run() { # pose device size fold
  echo "== $1 (${2}${3:+, $3 points})"
  if APP_DEVICE=$2 APP_SIZE=$3 APP_SHOTS=$out/$1 tools/snap.sh >$out/$1.log 2>&1; then
    "$sheet" $out/$1.png $4 $out/$1/*.png
  else
    tail -3 $out/$1.log
    failed+=($1)
  fi
}
for pose size fold in "${poses[@]}"; do
  run $pose "iPhone Duo" "$size" $fold
done
run iphone-27.0 "iPhone 18 Pro" "" none

echo
echo "Human pass, in Device Hub: outer landscape, tabletop, tent, Split View"
echo "with the app on the left and on the right, and the inner display opened."
if (( ${#failed} )); then
  echo "FAIL: ${failed[*]} (logs in $out)"
  exit 1
fi
echo "PASS: every scriptable pose has snapshots. Look at each sheet in $out."
