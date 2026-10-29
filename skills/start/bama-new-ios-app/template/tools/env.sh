# Shared by the tools: the app's names and paths, the Xcode toolchain, and
# the simulator. Each tool sources it: source "${0:A:h}/env.sh"
name="__APP_NAME__"
bundle="__BUNDLE_ID__"
root=${${(%):-%x}:A:h:h}
# Build output lives outside the repo (and outside Dropbox or iCloud).
derived="$HOME/Library/Developer/$name/build"
app_sim="$derived/Build/Products/Debug-iphonesimulator/$name.app"

# xcodebuild, simctl, and SwiftData need Xcode. xcode-select can still point
# at the Command Line Tools after Xcode is installed.
if [[ -z ${DEVELOPER_DIR:-} && $(xcode-select -p 2>/dev/null) != *.app/* ]]; then
  xcode=/Applications/Xcode.app
  [[ -d $xcode ]] || xcode=$(ls -d /Applications/Xcode*.app 2>/dev/null | tail -1)
  [[ -n $xcode ]] || { echo "Xcode is not installed. Install Xcode 27.1 or later." >&2; exit 1; }
  export DEVELOPER_DIR="$xcode/Contents/Developer"
fi

# Writes __APP_NAME__.xcodeproj from project.yml. --use-cache skips the work
# when neither the spec nor the file list changed.
generate() {
  command -v xcodegen >/dev/null || { echo "XcodeGen is missing: brew install xcodegen" >&2; exit 1; }
  (cd "$root" && xcodegen generate --use-cache --quiet)
}

# Prints the UDID of the simulator to use, booted. APP_DEVICE picks it by
# name (default "iPhone Duo"). A missing device is created on the newest iOS
# runtime that runs it.
sim_udid() {
  local want=${APP_DEVICE:-iPhone Duo} udid type runtime
  udid=$(xcrun simctl list devices available | grep -E "^ +${want} \(" | grep -m1 -oE '[0-9A-F-]{36}' || true)
  if [[ -z $udid ]]; then
    type=$(xcrun simctl list devicetypes | grep -E "^${want} \(" | grep -oE 'com\.apple\.CoreSimulator\.SimDeviceType\.[^)]+' | head -1)
    [[ -n $type ]] || { echo "no simulator type named \"$want\" (xcrun simctl list devicetypes)" >&2; exit 1; }
    for runtime in $(xcrun simctl list runtimes available | grep -oE 'com\.apple\.CoreSimulator\.SimRuntime\.iOS-[0-9-]+' | sort -t- -k2,2nr -k3,3nr); do
      udid=$(xcrun simctl create "$want" "$type" "$runtime" 2>/dev/null) && break
    done
    [[ -n $udid ]] || { echo "no installed iOS runtime runs \"$want\"" >&2; exit 1; }
  fi
  xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1
  echo "$udid"
}

# Prints a screen id for `simctl io screenshot --display`: the screen that is
# on, or with a second argument, the screen whose name contains it
# ("Resizable"). The Duo has two screens and shows apps on one; without
# --display, simctl can capture the dark one. Prints nothing on a one-screen
# iPhone.
display_id() {
  local json=$(mktemp) i id
  xcrun devicectl device info displays -d "$1" -j "$json" >/dev/null 2>&1 || { rm -f "$json"; return 0; }
  for i in {0..7}; do
    id=$(plutil -extract result.displays.$i.displayId raw -o - "$json" 2>/dev/null) || break
    if [[ -n ${2:-} ]]; then
      [[ $(plutil -extract result.displays.$i.name raw -o - "$json" 2>/dev/null) == *$2* ]] || continue
    else
      [[ $(plutil -extract result.displays.$i.active raw -o - "$json" 2>/dev/null) == true ]] || continue
    fi
    echo "$id"
    break
  done
  rm -f "$json"
}
