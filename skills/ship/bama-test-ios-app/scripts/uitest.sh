#!/bin/zsh
# Runs the XCTest UI tests on the iPhone Duo simulator and on a non-Duo
# iPhone with iOS 27.0, and prints one line per test. The full log is in
# /tmp/<AppName>-uitest.log.
# Usage: tools/uitest.sh                          both devices
#        APP_DEVICE="iPhone Duo" tools/uitest.sh  one device
# Copied into the project's tools/ by the bama-test-ios-app skill.
set -euo pipefail
source "${0:A:h}/env.sh"
generate
log=/tmp/$name-uitest.log
devices=("${APP_DEVICE:-iPhone Duo}")
[[ -z ${APP_DEVICE:-} ]] && devices+=("iPhone 18 Pro")
destinations=()
for device in $devices; do
  destinations+=(-destination "id=$(APP_DEVICE=$device sim_udid)")
done
# -quiet would hide the results, so filter the full output instead.
if xcodebuild test -project "$root/$name.xcodeproj" -scheme "$name" "${destinations[@]}" \
     -derivedDataPath "$derived" >$log 2>&1; then
  result=PASS
else
  result=FAIL
fi
# One device prints "Test Case '-[Class test]' passed"; several print
# "Test case 'Class.test()' passed on '<device>'" and "Testing passed on".
grep -E "^Test [Cc]ase .*(passed|failed)|^Testing (passed|failed) on|error:" $log || true
echo "UITEST $result (${(j:, :)devices})"
[[ $result == PASS ]]
