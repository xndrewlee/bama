#!/bin/zsh
# Prints the platform of the app in a folder: mac, ios, or unknown. The reason
# goes to stderr.
# Usage: detect-platform.sh [app-folder]      default: the current folder
# Code decides first, and an iOS target wins over a Mac one: an XcodeGen
# project.yml, a Tuist Project.swift, or an .xcodeproj. A Swift package is a
# Mac app (the bama-new-mac-app template). With no code yet, the Platform line
# in docs/BRIEF.md decides.
set -euo pipefail
dir=${1:-$PWD}
[[ -d "$dir" ]] || { echo "no folder $dir" >&2; echo unknown; exit 0; }
cd "$dir"

say() { echo "$2" >&2; echo "$1"; exit 0; }

# iOS targets
[[ -f project.yml ]] && grep -qE '^\s*(platform|supportedDestinations):.*\biOS\b|^\s*iOS:\s*"?[0-9]' project.yml \
  && say ios "project.yml has an iOS target"
[[ -f Project.swift ]] && grep -qE '\.(iOS|iPhone)\b' Project.swift \
  && say ios "Project.swift has an iOS target"
for proj in *.xcodeproj(N); do
  grep -qE 'SDKROOT = iphoneos|SUPPORTED_PLATFORMS = "?iphone' "$proj/project.pbxproj" 2>/dev/null \
    && say ios "$proj builds for iphoneos"
done

# Mac targets
[[ -f Package.swift ]] && say mac "Package.swift (a Swift package Mac app)"
[[ -f project.yml ]] && grep -qE '^\s*(platform|supportedDestinations):.*\bmacOS\b' project.yml \
  && say mac "project.yml has a macOS target"
[[ -f Project.swift ]] && grep -qE '\.macOS\b' Project.swift \
  && say mac "Project.swift has a macOS target"
for proj in *.xcodeproj(N); do
  grep -qE 'SDKROOT = macosx' "$proj/project.pbxproj" 2>/dev/null \
    && say mac "$proj builds for macosx"
done

# No code yet: the brief
if [[ -f docs/BRIEF.md ]]; then
  line=$(grep -m1 -iE '^Platform:' docs/BRIEF.md || true)
  case ${line:l} in
    *iphone*) say ios "docs/BRIEF.md says ${line#*: }" ;;
    *mac*) say mac "docs/BRIEF.md says ${line#*: }" ;;
  esac
fi
say unknown "no project and no Platform line in docs/BRIEF.md"
