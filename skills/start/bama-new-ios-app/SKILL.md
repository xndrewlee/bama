---
name: bama-new-ios-app
description: Create a native iPhone SwiftUI app, ready for iPhone Duo, from a working template (XcodeGen project, SwiftData, Makefile, snapshot mode, git), with no Xcode GUI. Use when the user wants to start a new iPhone or iPhone Duo app or scaffold an iOS project.
argument-hint: "<AppName> <bundle-id> [parent-folder]"
allowed-tools: Bash(*/new-app.sh *) Bash(git *) Bash(make *) Bash(*xcodebuild -version) Read Write Edit
---

# New iPhone app

The template builds and runs as is, on the iPhone Duo simulator and on any
other iPhone simulator. The first build proves the toolchain works before
you write feature code.

## What the template is

An XcodeGen spec for one iPhone app target, plus a Makefile that wraps
`xcodebuild` and `simctl`. An agent can read and edit every file. The
`.xcodeproj` is generated and never committed.

```text
<AppName>/
  project.yml            XcodeGen: iOS 27.0 target, iOS 27.1 SDK, Swift 6, main-actor default isolation
  Makefile               generate, build-sim, run-sim, snapshot, selftest, test, check, build-device, deploy
  CLAUDE.md              build, check, platform, and design rules for agents
  Icon/AppIcon.icon      the app icon: Icon Composer file, JSON plus SVG layers
  Kit/                   Swift package: rules and logic, tested on the Mac with `swift test`
  Sources/<AppName>/
    App.swift            scene and database location
    Models.swift         SwiftData models, sidebar pages, AppModel
    ContentView.swift    NavigationSplitView: sidebar, list, detail; Settings sheet
    Snapshot.swift       APP_SNAPSHOT mode: asks tools/snap.sh to screenshot every page and Settings topic, light and dark
    SelfTest.swift       --selftest: PASS or FAIL per check, exit 0 or 1
    SeedData.swift       APP_SEED=1: sample items for snapshots
    SettingsView.swift   Settings: one page per topic
    Assets.xcassets      images and colors
    UI/Theme.swift       accent colors, saved choice, accent tokens
    UI/AppearanceSettings.swift  Settings: accent picker
    UI/Grid.swift        the 4 pt spacing scale, layout probes, grid overlay
    UI/Fold.swift        readsFold, FoldSplit, measuresWindow: where the iPhone Duo folds, for splits
    UI/TwoPages.swift    two pages that meet at the fold (bama-ios-duo-design, "Two pages")
  tools/
    env.sh               Xcode toolchain, paths, simulator lookup (creates a missing one)
    build.sh run.sh snap.sh selftest.sh   what the Makefile calls
    grid-lint.sh check-layout.swift       the grid checks, as in the Mac template
    icon_review.sh icon_sheet.swift       the icon in every iOS look (bama-app-icon)
```

## Steps

1. Check the toolchain. The tools use Xcode even while `xcode-select`
   points at the Command Line Tools.

   ```bash
   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -version   # Xcode 27.1 or later
   command -v xcodegen                                                             # XcodeGen
   ```

   Without XcodeGen, ask the user, then run `brew install xcodegen`.

2. Find the platform in `docs/BRIEF.md`: `Platform: iphone` or
   `Platform: iphone-duo`. Without that line, ask once: optimize for iPhone
   Duo, or iPhone only? Default to Duo when the user owns one. Write the
   line into the brief. Both get the same template; the Duo answer decides
   how much of `bama-ios-duo-design` the stories use.

3. Pick the name (one UpperCamelCase word) and the bundle id (reverse DNS,
   like `com.yourname.reader`). If `docs/BRIEF.md` exists, use its name.
   Tell the user the bundle id must never change once the app is on their
   phone: a new id is a new app, and the old app's data stays behind.

4. Run the script with the parent folder. It copies the template, fills in
   the name and bundle id, runs `git init`, and commits. It keeps a folder
   that holds only a brief.

   ```bash
   "${CLAUDE_SKILL_DIR}/scripts/new-app.sh" Reader com.yourname.reader ~/Developer
   ```

5. Build and open it on the iPhone Duo simulator:

   ```bash
   cd ~/Developer/Reader && make run-sim
   ```

   It prints `BUILD SUCCEEDED (sim)` and the simulator's UDID. Device Hub
   shows the screen, if the user wants to watch.

6. Run the checks the template ships with, then look at the snapshots
   (`bama-build-and-verify-ios` skill):

   ```bash
   make test                                    # Kit unit tests on the Mac
   make selftest                                # SELFTEST PASS
   make snapshot                                # the Duo, light and dark
   APP_DEVICE="iPhone 18 Pro" make snapshot     # a non-Duo iPhone on iOS 27.0
   ```

7. If `docs/BRIEF.md` exists, rename `Item` to the brief's main type and the
   sidebar pages to the brief's pages. Nothing else: features go through
   `bama-improve-loop`, one story at a time. Build, snapshot, commit.

## How snapshots work on iPhone

An app cannot screenshot the simulator's screen, so the app and
`tools/snap.sh` take turns, through files in `/tmp/<AppName>-shots`. The
app writes `ready` once it is on screen and waits for the script's `go`.
Then, per page, it writes `<name>.want`; the script saves the screen as
`<name>.png` with `simctl io screenshot` and deletes the request. The app
writes `SNAPSHOT done` to `snapshot.log` at the end. The PNGs hold the real
screen: status bar, system buttons, and glass. `APP_SIZE=<w>x<h>` renders
the app at that size instead (`devicectl appResize`), for size classes.

The closed Duo shows apps on its outer screen. The script captures the
screen that is on (`devicectl device info displays`). Without `--display`,
`simctl` can capture the dark inner screen. Inner sizes and poses belong to
`bama-build-and-verify-ios`.

## iOS versions

The app targets iOS 27.0 and builds with the iOS 27.1 SDK. The iOS 27.1
simulator runtime runs only the iPhone Duo; every other iPhone runs 27.0.
Put any API new in 27.1 behind `if #available(iOS 27.1, *)` with a 27.0
fallback, and check both simulators.

## Signing

The simulator needs no signing. `make build-device` compiles for a real
iPhone without signing, to prove it builds. To install on the user's phone,
call the Skill tool with `bama-deploy-to-device`: it adds `tools/deploy.sh`,
which `make deploy` runs.

## When the build fails

- `XcodeGen is missing`: `brew install xcodegen`, after asking.
- `Xcode is not installed`: the user installs Xcode 27.1 or later.
- `cannot find 'X' in scope` after adding a file: the build regenerates the
  project when the file list changes. Run `make generate` and build again.
- `no installed iOS runtime runs "<device>"`: install that runtime in Xcode,
  or pick a device from `xcrun simctl list devicetypes`.
- Concurrency errors: call the Skill tool with `bama-swift-swiftui`.

Done when `make run-sim` opens the app on the iPhone Duo simulator,
`make selftest` passes, the snapshots show every page in light and dark on
the Duo and on a non-Duo iPhone, and the first commit exists.
