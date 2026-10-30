---
name: bama-deploy-to-device
description: Install an iPhone app from the bama-new-ios-app template on the user's own iPhone from the command line, and keep it alive past a free Apple ID's 7-day profile with an hourly launchd agent. Use when the user wants the app on their phone, when the app on the phone stops opening, or when the user asks about signing or provisioning for personal use.
allowed-tools: Bash(make *) Bash(tools/*) Bash(xcrun devicectl *) Bash(security find-identity *) Read
---

# Deploy to the iPhone

No App Store. The app installs from the Mac, signed with the person's own
Apple ID. Checked on hardware on 2026-10-29: an iPhone Duo on iOS 27.2,
Xcode 27.1, and a free Apple ID, over a cable and over Wi-Fi.

## 1. Pick the tier

- **Free, any Apple ID:** up to 3 of the person's own devices; profiles
  expire after 7 days (the agent in step 5 renews them); about 10 new app
  ids a week; no push, iCloud, App Groups, or Sign in with Apple.
- **Paid Apple Developer Program, $99 a year:** one-year profiles, every
  entitlement, TestFlight, and ad hoc installs.

Default to free. Ask only when the brief needs an entitlement the free
tier lacks.

## 2. One-time setup, done by the person

Each step ends on a check you run.

1. **Sign in to Xcode**: Xcode > Settings > Accounts > + > Apple ID. This is
   the only Xcode window in the whole flow.
2. **Make a certificate**: same pane, Manage Certificates > + > Apple
   Development. Check: `security find-identity -v -p codesigning` prints
   `1 valid identities found`. The script reads the team id from it.
   - The identity is listed but `0 valid`: the Apple WWDR G3 intermediate
     is missing, often with only an old WWDR certificate that expired in
     2023. The person downloads "Worldwide Developer Relations - G3" from
     https://www.apple.com/certificateauthority/ and double-clicks it into
     the login keychain. Do not add certificates for them.
3. **Pair the phone**: connect it by cable, unlock it, tap Trust. Then
   Settings > Privacy & Security > Developer Mode, on (the phone
   restarts). Check: `xcrun devicectl list devices` shows it `connected`,
   `physical`.
4. **Wi-Fi**: after the first pairing, `devicectl` reaches the phone on the
   same Wi-Fi (transport `localNetwork` in `xcrun devicectl list devices -j -`).
   If it does not, turn on Connect via Network for the phone in Device
   Hub (not checked in Xcode 27.1).

## 3. Add the scripts

```bash
cp "${CLAUDE_SKILL_DIR}/scripts/deploy.sh" "${CLAUDE_SKILL_DIR}/scripts/redeploy-agent.sh" tools/
chmod +x tools/deploy.sh tools/redeploy-agent.sh
tools/deploy.sh --status      # phone, team, profile expiry
```

They read the app's name, bundle id, and paths from the template's
`tools/env.sh`. With more than one phone paired, set `APP_PHONE` to its
name or UDID.

## 4. First install

```bash
make deploy
```

It builds for the phone with `-allowProvisioningUpdates
-allowProvisioningDeviceRegistration`, which registers the phone and makes
the app id and a profile; installs with `devicectl device install app`; and
opens the app. About 30 seconds the first time, a few seconds after that.
If macOS asks to let `codesign` use the key, the person clicks Always
Allow.

The first time it prints `not opened: on the iPhone, trust the developer`.
The person opens Settings > General > VPN & Device Management, taps the
Apple Development profile, and taps Trust. Run `make deploy` again: it
prints `DEPLOYED and opened on the iPhone`.

## 5. Keep it alive

A free profile expires 7 days after it was made, and then the app no longer
opens. Xcode reuses a cached profile until it expires, so a plain redeploy
does not extend it (seen on hardware). `tools/deploy.sh --if-due` reads the
expiry from the installed build. With less than two days left, it moves
the app's cached profiles to `~/Library/Developer/<AppName>/old-profiles/`,
builds with a fresh profile, and installs. Otherwise it prints `not due`.
`tools/deploy.sh --renew` does the same right away.

Ask the person before you install the agent: it keeps running every hour
until they remove it.

```bash
tools/redeploy-agent.sh install     # ~/Library/LaunchAgents/com.<user>.<app>.redeploy.plist
tools/redeploy-agent.sh status      # last exit code, last log lines, profile expiry
tools/redeploy-agent.sh uninstall
```

- It runs `tools/deploy.sh --if-due` every hour (`StartInterval` 3600) and
  logs to `~/Library/Logs/<AppName>-redeploy.log`. A failure also shows a
  notification.
- The Mac must be awake with the person logged in, and the phone on the
  same Wi-Fi. A sleeping Mac skips runs; the next run after wake catches up.
- An Apple ID sign-in in Xcode can expire. Then the build fails, and the log
  and the notification say so. The person signs in again in Xcode.
- Keep the project outside Desktop, Documents, and iCloud Drive: macOS can
  stop a background job from reading those folders.

## 6. What survives a redeploy

Reinstalling the same bundle id is an upgrade. The app's Documents,
Application Support (the SwiftData store), UserDefaults, and Keychain stay;
on hardware, the store survived redeploys with new profiles. Deleting the
app or changing the bundle id loses the data. Never change the bundle id.

## A locked phone

Checked on hardware, after the phone had been unlocked once since it
started: the install works while locked, by cable and over Wi-Fi. Opening
the app fails ("the device was not, or could not be, unlocked"), and
`deploy.sh` prints `not opened: the iPhone is locked`. The install still
counts, so the hourly agent works with the phone in a pocket. Not checked:
a phone not unlocked since it restarted.

## When it fails

- `no paired iPhone`: connect the cable, unlock the phone, tap Trust.
- `does not answer`: the phone is asleep, off this Wi-Fi, or out of range.
  Unlock it, or connect the cable.
- `no Apple ID team`: step 2 is not done.
- `not opened: ... trust the developer`: step 4.
- `build or signing failed`: read the first error. An expired Xcode sign-in
  or the free tier's limit of new app ids shows up here; reuse an existing
  bundle id rather than making new ones.
- `No Accounts`: this Mac's Xcode has no Apple ID. The person signs in at
  Xcode > Settings > Apple Accounts, then quits Xcode: `xcodebuild` saw the
  account only after Xcode quit. One Apple ID works on several Macs at once.
- `WARNING the profile was not renewed`: run `tools/deploy.sh --renew`, and
  check the Xcode sign-in.
- `DVTDevice: Unable to parse valid-ish build string`: harmless. Xcode
  27.1 cannot read iOS 27.2's build number; `deploy.sh` hides the line.

Done when `make deploy` prints `DEPLOYED and opened on the iPhone`,
`tools/deploy.sh --status` shows when the profile expires, and the agent is
installed with `last exit code = 0` in `tools/redeploy-agent.sh status`, or
the person declined it.
