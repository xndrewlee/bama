#!/bin/zsh
# Builds __APP_NAME__ with xcodebuild, after writing the Xcode project from
# project.yml. Output: ~/Library/Developer/__APP_NAME__/build.
# Usage: tools/build.sh           for the simulator
#        tools/build.sh device    for a real iPhone, unsigned: proves it compiles
#                                 (bama-deploy-to-device signs and installs)
set -euo pipefail
source "${0:A:h}/env.sh"
generate
if [[ ${1:-sim} == device ]]; then
  dest="generic/platform=iOS"
  signing=(CODE_SIGNING_ALLOWED=NO)
else
  dest="generic/platform=iOS Simulator"
  signing=()
fi
# -quiet prints only warnings and errors. Fix the warnings too.
if xcodebuild -quiet -project "$root/$name.xcodeproj" -scheme "$name" -configuration Debug \
     -destination "$dest" -derivedDataPath "$derived" "${signing[@]}" build; then
  echo "BUILD SUCCEEDED (${1:-sim})"
else
  echo "BUILD FAILED (${1:-sim}): read the first error above"
  exit 1
fi
