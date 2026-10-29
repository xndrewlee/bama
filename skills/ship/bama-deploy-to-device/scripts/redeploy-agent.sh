#!/bin/zsh
# Keeps the app alive on your iPhone: a launchd agent runs
# `tools/deploy.sh --if-due` every hour, which redeploys when the phone is
# reachable and the signing profile expires within two days. The Mac must be
# awake and you logged in. Output goes to ~/Library/Logs/<AppName>-redeploy.log;
# a failure also shows a notification.
# Usage: tools/redeploy-agent.sh install | uninstall | status
# Copied into the project's tools/ by the bama-deploy-to-device skill.
set -euo pipefail
source "${0:A:h}/env.sh"
label="com.$(id -un).${name:l}.redeploy"
plist="$HOME/Library/LaunchAgents/$label.plist"
log="$HOME/Library/Logs/$name-redeploy.log"
domain="gui/$(id -u)"

case ${1:-} in
  install)
    mkdir -p "${plist:h}" "${log:h}"
    cat > "$plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$label</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/zsh</string>
    <string>$root/tools/deploy.sh</string>
    <string>--if-due</string>
  </array>
  <key>WorkingDirectory</key><string>$root</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key><string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
  <key>StartInterval</key><integer>3600</integer>
  <key>StandardOutPath</key><string>$log</string>
  <key>StandardErrorPath</key><string>$log</string>
</dict>
</plist>
PLIST
    plutil -lint "$plist" >/dev/null
    launchctl bootout "$domain/$label" 2>/dev/null || true
    launchctl bootstrap "$domain" "$plist"
    echo "installed $label: runs tools/deploy.sh --if-due every hour"
    echo "log: $log"
    ;;
  uninstall)
    launchctl bootout "$domain/$label" 2>/dev/null || true
    rm -f "$plist"
    echo "removed $label"
    ;;
  status)
    if launchctl print "$domain/$label" >/dev/null 2>&1; then
      launchctl print "$domain/$label" | grep -E "^\s*(state|last exit code|run interval) =" || true
    else
      echo "$label is not installed"
    fi
    [[ -f $log ]] && { echo "last log lines:"; tail -5 "$log"; }
    "$root/tools/deploy.sh" --status
    ;;
  *)
    echo "usage: tools/redeploy-agent.sh install | uninstall | status"
    exit 1
    ;;
esac
