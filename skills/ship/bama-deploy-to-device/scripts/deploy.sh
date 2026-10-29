#!/bin/zsh
# Builds the app for your iPhone, signs it with your Apple ID's team,
# installs it, and opens it. Reinstalling the same bundle id is an upgrade:
# the app's data stays.
# Usage: tools/deploy.sh            install now
#        tools/deploy.sh --if-due   install only when the phone is reachable and
#                                   the signing profile expires within two days,
#                                   with a fresh profile (the launchd agent runs
#                                   this every hour)
#        tools/deploy.sh --renew    install now, with a fresh profile
#        tools/deploy.sh --status   which phone, which team, when the profile expires
# APP_PHONE picks the phone by name or UDID. APP_TEAM sets the team id.
# Copied into the project's tools/ by the bama-deploy-to-device skill.
set -euo pipefail
source "${0:A:h}/env.sh"
mode=${1:-now}
stamp="$HOME/Library/Developer/$name/deploy-stamp"
app_device="$derived/Build/Products/Debug-iphoneos/$name.app"

say() { print -r -- "$(date '+%Y-%m-%d %H:%M:%S') $*"; }
fail() {
  say "FAIL $*"
  # The agent runs unattended: tell the person.
  [[ $mode == --if-due ]] && osascript -e "display notification \"$*\" with title \"$name redeploy failed\"" 2>/dev/null
  exit 1
}

# The team id: APP_TEAM, the Apple Development certificate, or Xcode's account list.
team_id() {
  [[ -n ${APP_TEAM:-} ]] && { echo $APP_TEAM; return; }
  local ou
  ou=$(security find-certificate -a -c "Apple Development" -p 2>/dev/null \
    | openssl x509 -noout -subject 2>/dev/null | grep -m1 -oE 'OU *= *[A-Z0-9]{10}' | grep -oE '[A-Z0-9]{10}$' || true)
  [[ -n $ou ]] && { echo $ou; return; }
  defaults read com.apple.dt.Xcode IDEProvisioningTeamByIdentifier 2>/dev/null \
    | grep -m1 -oE 'teamID = "?[A-Z0-9]{10}' | grep -oE '[A-Z0-9]{10}$' || true
}

# The phone's UDID: APP_PHONE by name or UDID, or the only paired physical iPhone.
phone_udid() {
  local json=$(mktemp) i udid found=()
  xcrun devicectl list devices -j "$json" >/dev/null 2>&1 || { rm -f "$json"; return; }
  for i in {0..31}; do
    plutil -extract result.devices.$i.identifier raw -o - "$json" >/dev/null 2>&1 || break
    [[ $(plutil -extract result.devices.$i.hardwareProperties.reality raw -o - "$json" 2>/dev/null) == physical ]] || continue
    [[ $(plutil -extract result.devices.$i.hardwareProperties.platform raw -o - "$json" 2>/dev/null) == iOS ]] || continue
    udid=$(plutil -extract result.devices.$i.hardwareProperties.udid raw -o - "$json")
    if [[ -n ${APP_PHONE:-} ]]; then
      [[ $APP_PHONE == $udid || $APP_PHONE == $(plutil -extract result.devices.$i.deviceProperties.name raw -o - "$json") ]] || continue
    fi
    found+=($udid)
  done
  rm -f "$json"
  (( ${#found} == 1 )) && echo ${found[1]}
  (( ${#found} > 1 )) && say "more than one iPhone is paired: set APP_PHONE to its name or UDID" >&2
  return 0
}

# Xcode reuses a cached profile until it expires, so a redeploy alone does
# not extend a free team's 7 days. Move this app's cached profiles aside;
# the build then fetches a new one.
renew_profile() {
  local dir="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles" keep="$HOME/Library/Developer/$name/old-profiles" f id
  mkdir -p "$keep"
  for f in "$dir"/*.mobileprovision(N); do
    id=$(security cms -D -i "$f" 2>/dev/null | plutil -extract Entitlements.application-identifier raw -o - - 2>/dev/null) || continue
    [[ $id == *.$bundle ]] && mv "$f" "$keep/"
  done
  return 0
}

# When the profile in the last installed build expires, in seconds since 1970.
profile_expiry() {
  [[ -f $app_device/embedded.mobileprovision ]] || return 0
  local date
  date=$(security cms -D -i "$app_device/embedded.mobileprovision" 2>/dev/null | plutil -extract ExpirationDate raw -o - - 2>/dev/null) || return 0
  date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$date" +%s 2>/dev/null || true
}

udid=$(phone_udid)
team=$(team_id)
expires=$(sed -n 2p "$stamp" 2>/dev/null || true)

if [[ $mode == --status ]]; then
  echo "phone:   ${udid:-none paired}"
  echo "team:    ${team:-none: in Xcode > Settings > Accounts, sign in, then Manage Certificates > + > Apple Development}"
  [[ -n $expires ]] && echo "profile: expires $(date -r $expires '+%Y-%m-%d %H:%M')" || echo "profile: not deployed yet"
  exit 0
fi

if [[ $mode == --if-due ]]; then
  # Redeploy when the profile has less than two days left (a free team's
  # 7-day profile after five days). With no stamp, deploy now.
  if [[ -n $expires ]] && (( expires - $(date +%s) > 2 * 86400 )); then
    say "not due: the profile expires $(date -r $expires '+%Y-%m-%d %H:%M')"
    exit 0
  fi
fi

[[ -n $udid ]] || {
  [[ $mode == --if-due ]] && { say "phone not reachable: no paired iPhone found"; exit 0; }
  fail "no paired iPhone: connect it by cable and trust this Mac"
}
# Reachable means devicectl can talk to it, by cable or on the same Wi-Fi.
if ! xcrun devicectl device info details -d "$udid" --timeout 20 >/dev/null 2>&1; then
  [[ $mode == --if-due ]] && { say "phone not reachable: not on this Wi-Fi or asleep"; exit 0; }
  fail "the iPhone ($udid) does not answer: unlock it, and check the cable or Wi-Fi"
fi
[[ -n $team ]] || fail "no Apple ID team: in Xcode > Settings > Accounts, sign in, then Manage Certificates > + > Apple Development"

[[ $mode == --if-due || $mode == --renew ]] && renew_profile
say "building for $udid, team $team"
generate
# Xcode 27.1 cannot parse newer iOS build numbers and says so on every run; drop that line.
{ xcodebuild -quiet -project "$root/$name.xcodeproj" -scheme "$name" -configuration Debug \
    -destination "id=$udid" -derivedDataPath "$derived" \
    -allowProvisioningUpdates -allowProvisioningDeviceRegistration \
    DEVELOPMENT_TEAM=$team CODE_SIGN_STYLE=Automatic build 2>&1; } \
  | { grep -v "DVTDevice: Unable to parse" || true; } \
  || fail "build or signing failed: read the log above (an expired Xcode sign-in shows up here)"

say "installing"
xcrun devicectl device install app --device "$udid" "$app_device" >/dev/null \
  || fail "install failed: unlock the iPhone, and trust the developer in Settings > General > VPN & Device Management"

new_expiry=$(profile_expiry)
mkdir -p "${stamp:h}"
print -l -- "$(date +%s)" "${new_expiry:-}" > "$stamp"
if [[ $mode != now && -n $new_expiry && -n $expires ]] && (( new_expiry <= expires )); then
  say "WARNING the profile was not renewed: it still expires $(date -r $new_expiry '+%Y-%m-%d %H:%M')"
  [[ $mode == --if-due ]] && osascript -e "display notification \"The signing profile was not renewed. See ~/Library/Logs/$name-redeploy.log\" with title \"$name redeploy\"" 2>/dev/null
fi
[[ -n $new_expiry ]] && say "profile expires $(date -r $new_expiry '+%Y-%m-%d %H:%M')"

# The install counts even when the app cannot open.
if launched=$(xcrun devicectl device process launch --device "$udid" "$bundle" 2>&1); then
  say "DEPLOYED and opened on the iPhone"
elif [[ $launched == *"explicitly trusted"* ]]; then
  say "DEPLOYED; not opened: on the iPhone, trust the developer in Settings > General > VPN & Device Management"
elif xcrun devicectl device info lockState --device "$udid" 2>/dev/null | grep -q "passcodeRequired: true"; then
  say "DEPLOYED; not opened: the iPhone is locked"
else
  say "DEPLOYED; not opened: $(print -r -- $launched | grep -m1 -E 'NSLocalizedFailureReason|ERROR')"
fi
