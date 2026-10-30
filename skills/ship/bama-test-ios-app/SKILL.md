---
name: bama-test-ios-app
description: Test an iPhone app at four levels, from Swift Testing unit tests and an in-app self-test to XCTest UI tests on the iPhone Duo simulator and a debug bridge that lets an agent drive the running app and read its state. Use when adding logic, fixing a bug, before a release, or when the user asks for tests, end-to-end checks, or "make sure it works" in an iPhone app.
---

# Test an iPhone app

Four levels, cheapest first. Each new story gets the cheapest level that
can prove its acceptance criteria. A bug fix starts with a test that fails.
For an app from the `bama-new-ios-app` template.

| Level | Proves | Speed |
| --- | --- | --- |
| Unit tests (Swift Testing, on the Mac) | Rules, parsing, data | Seconds |
| Self-test (`--selftest`, on the simulator) | The app's real functions on a test store | Half a minute |
| Debug bridge (on the simulator) | State after an action, without the screen | Seconds per command |
| UI tests (XCTest, on the simulator) | Taps, sheets, navigation, alerts | A minute per device |

Snapshots (`bama-build-and-verify-ios` skill) prove how it looks. This
skill proves how it behaves.

## 1. Unit tests

Logic lives in the `Kit` package with no SwiftUI, so its tests run on the
Mac without a simulator:

```swift
import Testing
@testable import ReaderKit

@Test("Reading time", arguments: [(0, 0), (250, 1), (2_600, 11)])
func minutes(words: Int, expected: Int) {
    #expect(ReadingTime.minutes(words: words) == expected)
}
```

```bash
make test
```

Fix the clock and the store path in every test. Use table tests for
anything with many cases.

## 2. Self-test

`Sources/<App>/SelfTest.swift` runs the functions the UI calls on a store
in `/tmp`, prints PASS or FAIL per check, and quits with 0 or 1:

```bash
make selftest
# PASS New Item adds one item
# SELFTEST PASS 5 checks
```

Add a check for every story with logic. It runs on the simulator, so it
covers SwiftData, the model, and the app's own code, not taps. On a
simulator `simctl launch` passes variables only with a `SIMCTL_CHILD_`
prefix; the tools do this.

## 3. Debug bridge

For checks between a self-test and a UI test: run an action in the running
app, then read its state. Add it once:

```bash
cp "${CLAUDE_SKILL_DIR}/template/DebugBridge.swift" Sources/<App>/
cp "${CLAUDE_SKILL_DIR}/scripts/bridge.sh" tools/
```

Then call `DebugBridge.startIfRequested(model: model)` in `ContentView`'s
`.task`, next to the self-test. It compiles in debug builds only.

```bash
tools/bridge.sh start          # fresh /tmp store, app launched with the bridge
tools/bridge.sh add:Milk       # runs an action, prints the state as JSON
tools/bridge.sh page:starred
tools/bridge.sh status
```

The script writes the command to `/tmp/<App>-bridge/command` and posts a
Darwin notification inside the simulator (`simctl spawn <udid> notifyutil
-p <bundle-id>.bridge`); the app writes `status.json` next to it. Add a case
per action, with the same name as its button and URL. Two dead ends:
`devicectl device notification post` does not work on simulators, and
`simctl openurl` stops at an "Open in <App>?" alert.

## 4. UI tests

Real taps, through XCTest. Add the target to `project.yml` and the test
file from this skill:

```yaml
targets:
  <App>:
    scheme:
      testTargets: [<App>UITests]
  <App>UITests:
    type: bundle.ui-testing
    platform: iOS
    sources:
      - path: UITests
    dependencies:
      - target: <App>
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: <bundle-id>.uitests
        TARGETED_DEVICE_FAMILY: "1"
        SWIFT_VERSION: "6.0"
        GENERATE_INFOPLIST_FILE: YES
        CODE_SIGN_STYLE: Automatic
```

```bash
mkdir -p UITests
sed "s/__APP_NAME__/<App>/g" "${CLAUDE_SKILL_DIR}/template/UITests/AddItemUITests.swift" > UITests/AddItemUITests.swift
cp "${CLAUDE_SKILL_DIR}/scripts/uitest.sh" tools/
tools/uitest.sh
# Test case 'AddItemUITests.testAddItemShowsIt()' passed on 'iPhone Duo - ...'
# UITEST PASS (iPhone Duo, iPhone 18 Pro)
```

It runs on the iPhone Duo and on an iPhone 18 Pro with iOS 27.0, and
prints one line per test; the full log is in `/tmp/<App>-uitest.log`.

- Each test sets `app.launchEnvironment["APP_STORE"]` to a new file in
  `/tmp`, so it starts empty and never touches real data.
- A compact width (the closed Duo) opens on the selected sidebar page's
  list, not on the sidebar. To reach another page, tap `BackButton`, then
  the page.
- Find elements by an `.accessibilityIdentifier`, never by position. A row
  with a title and a subtitle is one element whose label joins both
  ("Piranesi, Susanna Clarke"): give it an identifier and query
  `app.buttons["<identifier>"]`. A layout that moves with the pose must
  still find it.
- A failure shows only "failed" in the log. Read the reason from the result
  bundle the log names:
  `xcrun xcresulttool get test-results tests --path <bundle>.xcresult`.
- To see what the test sees, print `app.debugDescription` and read it in
  `/tmp/<App>-uitest.log`.
- `-quiet` hides the results: read them from the log, as the script does.
  The lines about `invalidDigitCount` come from Xcode 27.1 and are harmless,
  and so is `unable to find utility "simctl"` after a failure while
  `xcode-select` points at the Command Line Tools.

## 5. Things only a person can check

Poses a script cannot reach (`bama-build-and-verify-ios`, human pass), a
permission prompt's first answer, and anything on the user's real phone
(`bama-deploy-to-device`). Write each as a named manual check in the story.

## Debug output

`print` from an app on the simulator does not reach the terminal unless
`simctl launch --console-pty` waits for it, as the self-test does. For a
running app, write debug lines to a file in `/tmp` behind an environment
flag, as the snapshot mode does with `snapshot.log`.

Done when every acceptance line of the story maps to a passing test,
self-test check, bridge command, UI test, or named manual check, and a bug
fix has a test that failed before the fix.
