---
name: bama-build-and-verify-ios
description: Build a SwiftUI iPhone app from the command line and check light and dark snapshots of every page in every iPhone Duo pose a script can reach, plus a non-Duo iPhone on iOS 27.0, before calling a change done. Use after any UI change in an iPhone app, when an iOS build fails, or when the user asks to run, screenshot, or check the iPhone app.
allowed-tools: Bash(make *) Bash(tools/*) Bash(*/pose-shots.sh*) Read
---

# Build and verify on iPhone

## What a script can reach

Checked against Xcode 27.1 (BAMA's `docs/ios-investigation.md`). Do not
repeat the search:

- No command opens, closes, rotates, or folds the Duo simulator.
  `devicectl device orientation set` prints success on the Duo and changes
  nothing. Device Hub has no scripting dictionary.
- The Duo boots closed. The outer display is the one real pose a script
  gets.
- `devicectl device appResize` renders the app at any size on the
  simulator's Resizable screen. The app gets a right-hand system column, a
  camera region, and safe areas like the outer display's, and size classes
  from its width. The screenshot has no status bar, and there is no fold.
- Everything else is a human pass in Device Hub.

A change is done when five things are true:

1. `make build-sim` finishes with no errors or warnings.
2. The pose script prints PASS.
3. You looked at every sheet and found none of the failures in step 4.
4. `make check` and `make selftest` pass.
5. Your report names the poses that still need a human pass.

This skill drives the `bama-new-ios-app` template's `tools/snap.sh`. For
another iPhone app, copy the template's `Snapshot.swift` and `tools/` in
first.

## 1. Build

```bash
make build-sim
```

Read the errors, fix the first one first, and build again. A new file "not
in scope": `make generate`, then build.

## 2. Snapshot every pose

```bash
"${CLAUDE_SKILL_DIR}/scripts/pose-shots.sh" <app-folder>
```

It takes about four minutes. It runs `tools/snap.sh` once per set, with
seed data, light and dark, every page and Settings topic, and joins each
pose into one sheet: `/tmp/<AppName>-poses/<pose>.png`. The single PNGs are
in `/tmp/<AppName>-poses/<pose>/`.

| Pose | Size in points | Screen | Story poses it covers |
| --- | --- | --- | --- |
| `outer` | 466 x 678 | real, the closed Duo | `outer` |
| `inner` | 669 x 951 | size only, fold shaded | `inner`, and `tabletop` (fold across) |
| `inner-landscape` | 951 x 669 | size only, fold shaded | `inner-landscape`, held like a book (fold down) |
| `splitview` | 475 x 669 | size only | `splitview-left`, `splitview-right` |
| `iphone-27.0` | iPhone 18 Pro, iOS 27.0 | real | every non-Duo iPhone |

The fold sits across the middle of the inner display's long side, 475.5 pt
in. Each half of the inner display matches the outer display's size, so
that is where a book-style hinge sits; the simulator does not mark it.
Partly folded, the fold is a 40 pt band, margins included, so the sheet
shades 20 pt on each side. Flat, it has no width. Split View halves are
475 pt wide, the smallest width `appResize` allows.

Outer landscape is not in the table: a real outer display in landscape is
compact width and compact height, but `appResize` at that size gives a
regular width. It stays in the human pass.

While you iterate on one page, `make snapshot` (the outer display only) and
`APP_SNAPSHOT_PAGES=all make snapshot` are faster. Run the pose script
before you call the change done.

## 3. Check the grid and the self-test

```bash
make check       # grid lint and layout probes: PASS
make selftest    # SELFTEST PASS
```

On a grid FAIL, call the Skill tool with `bama-layout-grid`.

## 4. Look

Open every sheet with the Read tool, and a single PNG when something looks
off. The change fails on any of these:

- **The fold.** In `inner` and `inner-landscape`, a fixed control, a
  title, or a face in a photo crosses the red band. Backgrounds, dividers,
  empty space, and scrolling content may cross it. So may the system's own
  sheets, alerts, menus, and toolbar buttons: on a real Duo the system moves
  them off the fold. A two-page layout puts its column edge on the band.
- **The status bar and camera.** In `outer`, iOS 27.1 stacks the status bar
  and the navigation buttons along the right edge. Content under that column,
  or text cut off at the top, fails.
- **Clipping.** Text cut without an ellipsis, or a control cut by a screen
  edge or a rounded corner. The outer display's right corners are round,
  its left corners nearly square.
- **The wrong layout for the size.** Compact widths (`outer`,
  `splitview`) show one column at a time. `inner-landscape` shows the list
  and the detail side by side, the list's edge on the fold. `inner` may lay
  the list over a dimmed detail, as iOS does at that width. A
  regular width that shows only an empty detail ("No Selection") with the
  list hidden behind a button fails: fix it with `bama-ios-duo-design`. So
  do two sidebar pages whose snapshots look the same.
- **iOS 27.0.** Every page in `iphone-27.0` renders, and every
  `#available(iOS 27.1, *)` fallback looks finished.
- **Light and dark.** Dark mode is readable, with no fixed white or black
  surfaces.
- **The story.** The page matches the story or the reference screenshot,
  and the `bama-ios-duo-design` rules hold.

Describe what you see in one or two sentences per pose, and name the sheet
paths so the user can open them.

## 5. Human pass

These poses need a person in Device Hub, or computer use driving it:
outer landscape, the opened inner display with its real system buttons,
`tabletop`, `tent`, `splitview-left`, and `splitview-right`. The left and
right Split View halves differ in which side the system buttons sit on: the
most common Duo layout bug.

Ask the user to open Device Hub
(`Xcode.app/Contents/Applications/DeviceHub.app`), pick iPhone Duo, and put
it in each pose. Take each screenshot yourself:

```bash
xcrun simctl io booted screenshot --display=1 outer.png   # 3 for the inner display
```

Check them against the list in step 4. A pose nobody checked stays in the
report as "needs a human pass", and its stories stay open.

## 6. Report

One line per pose: the sheet path, PASS or FAIL, and "size only" where it
applies. Then the human-pass list, each pose marked checked or not.

## When something fails

- **A pose run fails with "the appResize session ended early".** The app
  lost its Resizable screen mid-run. Run the pose script again.
- **"SNAPSHOT missed".** Nothing answered the app's request: run snapshots
  through `tools/snap.sh` or the pose script, never by launching the app by
  hand.
- **Black snapshots.** The script captured the dark inner screen of a
  closed Duo. `tools/snap.sh` picks the screen that is on; set
  `APP_DISPLAY=1` if a run still comes out black.
- **"no installed iOS runtime runs".** The iOS 27.1 runtime runs only the
  Duo; the iPhone 18 Pro runs on 27.0. Install the 27.0 runtime in Xcode.

## 7. Commit

When the build is clean and the sheets look right, commit with a message
that says what the user can now do.

Done when the five conditions at the top hold, the report lists the human
pass, and the change is committed.
