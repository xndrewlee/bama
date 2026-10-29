# iOS investigation

Findings for step 1 of [ios-duo-support.md](ios-duo-support.md). Write the
iOS skills from these, not from the plan's assumptions.

Checked on 2026-10-29 on an M1 Pro Mac with macOS 27.0 (26A428), Xcode 27.1
(27A9275), and the iOS 27.1 simulator runtime (24A94425). Check again after
an Xcode update.

## Toolchain

- `xcode-select -p` can still point at the Command Line Tools after Xcode is
  installed. Then `simctl`, `devicectl`, and `xcodebuild` are missing, and
  `swift build` fails on SwiftData's `@Model` ("plugin for module
  'SwiftDataMacros' not found"). Set
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` per command, or
  have the user run `sudo xcode-select -s /Applications/Xcode.app` once. The
  Mac template's `build.sh` calls plain `swift build`, so it has the same
  problem. With `DEVELOPER_DIR` set, the template builds and its tests pass.
- SDKs: `iphoneos27.1` and `iphonesimulator27.1`.
- XcodeGen is not installed by Xcode. Homebrew is: `brew install xcodegen`.

### The iOS 27.1 runtime runs only the Duo

| Runtime | Build | iPhones it runs |
| --- | --- | --- |
| iOS 27.0 | 24A434 | 33 models, iPhone 18 Pro and older. Not the Duo. |
| iOS 27.1 | 24A94425 | iPhone Duo only |

Creating an iPhone 18 Pro or 17 Pro on iOS 27.1 fails with "Incompatible
device". So 27.1 looks like a Duo-only release, like Apple's other launch
builds. That is not checked on real phones.

Decided on 2026-10-29, replacing the plan's iOS 27.1 target:
`bama-new-ios-app` sets deployment target iOS 27.0 and builds with the
iOS 27.1 SDK. The app gets the full Duo layout on the Duo and still runs on
every other iPhone. Code that uses an API new in 27.1, such as
`ReservedRegion`, goes behind `if #available(iOS 27.1, *)` with a 27.0
fallback.

## 1. The Duo simulator

- Device type: `iPhone Duo`, id `com.apple.CoreSimulator.SimDeviceType.iPhone-Duo`,
  model `iPhone19,4`. Xcode creates one for the 27.1 runtime. Find its UDID
  with `xcrun simctl list devices | grep "iPhone Duo"`.
- It has two screens. `simctl io <udid> screenshot --display=<id>` captures
  one. Without `--display` it captures screen 1.

| Screen id | Name | Pixels | Points (3x) | Size | What it is |
| --- | --- | --- | --- | --- | --- |
| 1 (`primary`) | LCD | 1398 x 2034 | 466 x 678 | 5.4 in | Outer display |
| 3 (`primary-1`) | LCD-1 | 2007 x 2853 | 669 x 951 | 7.6 in | Inner display |
| 5 (`resizable`) | Resizable | the session size | up to 1280 x 1280 | none | `appResize` sessions (below) |

Screens 2 (TV out) and 4 (CarPlay) are off.

- The outer display's left corners are nearly square (radius 8, against 59
  on the right). That edge is probably the hinge side.
- It boots closed: the outer screen shows the home screen and the inner
  screen is black.
- `xcrun devicectl device info displays -d <udid> -j -` says which screen is
  live: `active` and `backlightState` per display. Use it to confirm the
  pose before a screenshot.
- On the outer screen in portrait, iOS 27.1 stacks the status bar and the
  navigation buttons (back, toolbar items) vertically along the right edge.
  Seen in Settings and Safari. So the outer screen's safe area is not
  symmetric even closed and upright.

## 2. Poses

**Can a script open, close, rotate, or fold the Duo? Not with public tools
in Xcode 27.1.**

What was tried:

- `simctl` has no pose, hinge, or rotate subcommand.
  `simctl io <udid> screenConfig --display=1 power off` turns a screen off.
  It does not open the device: the inner screen stays black. A screenshot of
  the powered-off screen then hangs. Do not use it for poses.
- `devicectl device orientation set|rotate` rotates an iPhone 18 Pro on
  iOS 27.0. On the Duo it prints the new orientation, but `orientation get`
  still says portrait and the screen does not turn. Same with Device Hub
  running.
- There is no `devicehub` command. Device Hub is
  `Xcode.app/Contents/Applications/DeviceHub.app` (`com.apple.dt.Devices`),
  with no AppleScript dictionary. Its DeviceKit framework has Rotate Left and
  Rotate Right menu items, and nothing for open, close, fold, or hinge.
- CoreDevice can stream a real phone's hinge angle
  (`com.apple.coredevice.action.streamhingeangle`). It cannot set one.
- Inside the iOS 27.1 runtime, SpringBoard can replay recorded hinge samples
  (`SBFHingeSamplePlayback`, `SpringBoardFoundation.framework/hinge-samples.csv`),
  and UIKit has hinge-pose test hooks (`setHingePoseStateForTesting`). These
  are private and undocumented. Skills must not use them.

Not checked: Device Hub's window by eye. A person, or computer use, should
open Device Hub, pick iPhone Duo, and note which controls open, close,
rotate, and fold it, and whether a menu item or shortcut drives each one.

### What `bama-build-and-verify-ios` can do instead

`devicectl device appResize` renders the frontmost app on screen 5 at any
size, in points. That covers size classes, not the fold.

```bash
xcrun simctl launch "$UDID" "$BUNDLE_ID"     # appResize needs a foreground app
xcrun devicectl device appResize start -d "$UDID" --preferred-size 669x951 &
session=$!
xcrun simctl io "$UDID" screenshot --display=5 inner.png   # 2007 x 2853, the session size
xcrun devicectl device appResize set -d "$UDID" --preferred-size 951x669
kill -INT $session                           # ends the session ("Session ended.")
```

- `start` runs until interrupted. Without a foreground app it fails with
  error 24001. Right after a launch it often fails that way, or the device
  ends the session as the launch settles ("Session was ended by the
  device"). Wait until the app is on screen, then retry until a session
  holds.
- Its output reaches a file only when it quits. Poll
  `devicectl device info appResize` to know a session is up.
- The Resizable screen reports `active: false` even during a session. Find
  it by name.
- At 669 x 951, Settings showed its regular-width layout: sidebar and
  detail. A request for 334 x 951 came out 475 x 951 with the compact
  layout, so there is a minimum width, at least for Settings.
- It does not show the hinge, the vertical system buttons of a real pose,
  or real safe areas.

| Pose | How to get it from a script |
| --- | --- |
| `outer` | The boot state. Screenshot `--display=1`. |
| outer landscape | `appResize` at 678 x 466 (size only) |
| `inner` | `appResize` at 669 x 951 (size only) |
| `inner-landscape` | `appResize` at 951 x 669 (size only) |
| `splitview-left`, `splitview-right` | `appResize` at 475 x 669, half the inner display (size only) |
| `tabletop`, `tent` | None. Human pass in Device Hub. |

`bama-build-and-verify-ios` runs this matrix (`scripts/pose-shots.sh`).

Where the fold is: the simulator does not mark it, and the screen masks show
only rounded corners. Each half of the inner display (4.36 x 3.10 in) has
the outer display's size (4.42 x 3.04 in), so a book-style hinge crosses the
middle of the inner display's long side, 475.5 pt in: a vertical line at
951 x 669, a horizontal one at 669 x 951. That is also the smallest width
`appResize` allows, 475 pt. Inferred, not measured: confirm in Device Hub.

The verification report must say which poses had only a size check and
which need a human pass.

Also build, install, and snapshot every page, light and dark, on a non-Duo
iPhone on the iOS 27.0 runtime, such as an iPhone 18 Pro. It proves the
27.0 deployment target holds: the app launches, and every
`#available(iOS 27.1, *)` fallback renders. On the 27.0 runtime Xcode
creates an iPhone 18 Pro Max, iPhone 17, iPhone 17e, and iPhone Air, but
no iPhone 18 Pro. The template's `tools/env.sh` creates a missing device on
first use (`APP_DEVICE="iPhone 18 Pro" make snapshot`).

## 3. `devicectl` and a locked phone

**Not tested: no physical iPhone is connected.** `xcrun devicectl list
devices` shows only the simulator. Test in step 6: lock the phone, then run
`devicectl device install app` and `devicectl device process launch`, and
record what each does. `devicectl device info lockState` reports the lock
state on a real phone; simulators do not support it.

`devicectl` also drives simulators now (`Reality: simulated`): display
info, `appResize`, orientation, appearance, and simulated location,
biometrics, and status bar.

## 4. App Resizability

- It is not a command line tool. It is a prompt for Xcode's built-in chat,
  written in skill format:
  `Xcode.app/Contents/PlugIns/IDEIntelligenceChat.framework/Versions/A/Resources/app-resizability.idechatprompttemplate`.
  Five reference tasks sit next to it:
  `app-resizability-ref-{uiscreen,safe-area,orientation,idiom,scene-lifecycle}-task.md.packaged`.
  All are plain Markdown. It names getting an app ready for iPhone Duo as a
  use.
- `xcrun mcpbridge` connects outside agents to Xcode's MCP tools, but it
  needs Xcode running, which breaks the no-Xcode-GUI rule.
- To wrap it, a skill tells the agent to read these files from the installed
  Xcode (`$DEVELOPER_DIR/../PlugIns/IDEIntelligenceChat.framework/...`) and
  follow them. Do not copy Apple's text into this repo. The files can move
  in any Xcode update, so check the path exists first.
