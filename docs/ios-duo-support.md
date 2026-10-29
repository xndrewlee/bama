# Add iPhone (and iPhone Duo) support to BAMA

**Spec for an agent working in the `daveebbelaar/bama` repository (or a fork of it).**
Read this whole file, then read `AGENTS.md`, `README.md`, `.claude-plugin/`, and every `skills/*/*/SKILL.md` before changing anything. BAMA's own writing rules for skills apply to everything you add.

---

## 1. Goal

BAMA ("Build Any Mac App") is a set of agent skills that take a native macOS app from idea to the Dock using Swift + SwiftUI, local data, and no Xcode GUI. Extend it so the same pipeline can produce a **native iPhone app**, with first-class support for **iPhone Duo**, Apple's foldable iPhone (released October 23, 2026, runs iOS 27.1).

The end state: a user can say

```
Build me a reading-list app for my iPhone Duo with BAMA.
```

and the agent scaffolds an iOS project, designs for both Duo displays and all fold poses, builds and snapshots it on the iPhone Duo simulator from the command line, and installs it on the user's physical phone for personal use — without opening Xcode.

## 2. Non-negotiable constraints

0. **Prefix every skill with `bama-` and make the link script safe.** Upstream's generic names (`research`, `clone`, `performance`, …) collide with other skill packs, and `scripts/link-skills.sh` overwrites any same-named installed skill without asking. Rename every skill directory and its frontmatter `name` to `bama-<name>` (the router stays `bama`), update every cross-reference inside the SKILL.md files, the README table, the plugin manifest, and the `--skill=` examples. Make `link-skills.sh` refuse to overwrite a link that points outside this repo. Implement both yourself; do not `git cherry-pick` from any fork. The fork `hmaddocks/bama` did the same rename — read it only as a reference for the naming scheme and the link-script behavior, then write it fresh in this repo.
1. **Do not break the Mac path.** Every existing skill must keep working unchanged for macOS projects. Add; don't replace.
2. **Keep the "no Xcode GUI" promise.** Everything must run from the shell: `xcodebuild`, `xcrun simctl`, `xcrun devicectl`, `codesign`, `swift`. The only permitted GUI step is the one-time Apple ID sign-in inside Xcode so `-allowProvisioningUpdates` works; document it, don't automate it.
3. **One skill per concern, same format as the existing skills.** Follow the frontmatter, length, and voice of the existing `SKILL.md` files. Reuse their phrasing where the content is identical.
4. **Detect platform, don't ask twice.** A project is iOS if it has an iOS target (see §4.1). The `bama` router should detect this and route to the iOS variant of a skill automatically. Only ask the user "Mac or iPhone?" at project creation.
5. **Verify every claim about Apple tooling against the installed toolchain** (`xcodebuild -version`, `xcrun simctl list`, `xcrun devicectl --help`). Where this spec says "investigate", the answer is not known yet — find it, then write the skill from what actually works.
6. **Swift 6.2, iOS 27.1 SDK, Xcode 27.1 or later.** Add this to the Requirements section of the README for the iOS path.

## 3. What changes and what doesn't

| Existing skill | iOS treatment |
|---|---|
| `start/bama` (router) | **Modify**: detect iOS vs macOS project, route to the iOS variants below. |
| `start/app-brief` | Unchanged. Add one line: the brief records target platform (mac / iphone / iphone-duo). |
| `start/new-mac-app` | **Add sibling** `start/new-ios-app`. |
| `plan/research` | **Modify lightly**: when the platform is iOS, the "macOS APIs" researcher becomes an "iOS APIs" researcher and adds an "iPhone Duo layout" researcher. |
| `plan/clone` | **Modify**: add an iOS route — screenshot an iPhone app running in the iPhone Duo simulator or via iPhone Mirroring on the Mac (computer use), in every pose. |
| `plan/user-stories` | Unchanged, except acceptance criteria for iOS stories must name the pose(s) they apply to (see §5.3). |
| `code/swift-swiftui` | **Modify**: factor the AppKit-bridge section so there is a parallel UIKit-bridge section (`UIViewRepresentable`, `UIViewControllerRepresentable`). Everything else (Swift 6 concurrency, state, SwiftData, compiler errors) is shared. |
| `code/os-integrations` | **Add sibling** `code/ios-integrations` (§5.5). The Mac one stays as is. |
| `code/performance` | **Modify**: add the iOS/simulator Instruments flow (`xcrun xctrace`), note that GPU compositing advice differs on iOS. |
| `code/improve-architecture`, `code/agent-cli` | Unchanged. (`agent-cli` is Mac-only by nature; the router should skip it for iOS projects.) |
| `design/ux-design` | **Modify**: iOS presentation vocabulary (sheet, full-screen cover, popover, split view columns, tabs/sidebar) replaces the Mac one when the platform is iOS. |
| `design/mac-design` | **Add sibling** `design/ios-duo-design` (§5.4). |
| `design/design-system`, `design/layout-grid`, `design/design-kit`, `design/design-from-app` | Unchanged in spirit; verify any Mac-specific assumptions (window chrome, 4 pt grid probes in snapshot mode) and make them platform-aware. |
| `design/app-icon` | Unchanged — Icon Composer files serve iOS too. Verify the asset catalog wiring for iOS targets. |
| `ship/build-and-verify` | **Add sibling** `ship/build-and-verify-ios` (§5.2). |
| `ship/test-mac-app` | **Add sibling** `ship/test-ios-app` (§5.6). |
| `ship/improve-loop` | Unchanged. |
| *(new)* | `ship/deploy-to-device` (§5.7). |

Also update: `README.md` (skills table, requirements, quick start example for iPhone), `.claude-plugin/` manifest, `scripts/link-skills.sh` if it enumerates skills, and `specs/` (add at least one iPhone Duo spec, §6).

## 4. Background the agent must internalize

### 4.0 Prior art: the `hmaddocks/bama` fork

https://github.com/hmaddocks/bama is a fork that already builds iPhone and iPad apps from the CLI. Read it before writing any iOS skill, **as reference only** — never `git cherry-pick`, `git merge`, or copy files wholesale from it. Its commits are tangled with an AppKit/UIKit rewrite and MCP-coupled planning skills we are not adopting. Read the relevant files, understand how they solve each problem, then implement the equivalent in this repo on top of upstream's SwiftUI + SwiftData base. **Learn from it:**

- The `bama-` prefix and the non-clobbering `link-skills.sh` (§2.0).
- `bama-new-app`'s iOS plumbing: XcodeGen `project.yml`, the build script that uses Xcode's toolchain even when the Command Line Tools are selected, the iOS target layout, git setup.
- `bama-build-and-verify`'s simulator route: boot, install, launch in snapshot mode, screenshot in light and dark.
- The platform-neutral parts of `bama-ios-design`: size classes, navigation, sheets, touch targets, Dynamic Type, iPad keyboard.
- Its README "Requirements" wording for iOS (Xcode toolchain, XcodeGen via Homebrew, free Apple ID + cable for device installs).

**Do not port:**

- Its switch to AppKit/UIKit + Core Data. This spec stays on upstream's SwiftUI + SwiftData, because Apple's iPhone Duo guidance (`NavigationSplitView`, `ReservedRegion`, size-class environment, adaptive `TabView`) is SwiftUI-first. Translate its UIKit snippets into SwiftUI where the concept carries over; keep UIKit only in the `UIViewRepresentable` bridge section.
- Its planning skills (`bama-app-brief`, `bama-feature-spec`, `bama-user-stories`), which write to the author's personal notes app and task manager over MCP. Upstream's file-based brief/backlog stays.
- Its iOS 26 baseline. We target iOS 27.1 for Duo.

Credit the fork in README Credits as the source of the naming scheme, the link-script fix, and the XcodeGen/simulator approach, even though the code here is written fresh.

### 4.1 Why iOS can't reuse the Mac template

`new-mac-app` scaffolds a Swift package, builds it with `swift build`, and wraps the binary into an `.app` bundle by script. iOS cannot do that:

- iOS apps need an Xcode project (`.xcodeproj`) or workspace and are built with `xcodebuild`.
- They run on a simulator (`xcrun simctl`) or a signed physical device (`xcrun devicectl`).
- Device installs require code signing: a certificate + provisioning profile from Apple.

**Decision: XcodeGen** (`project.yml` → `.xcodeproj`, `brew install xcodegen`). The hmaddocks fork proved this works for the no-GUI loop; copy its `project.yml` shape and adjust targets/deployment versions. Do not reopen this choice.

Platform detection for the router: an iOS project has a `project.yml`/`Project.swift` with an iOS target, or an `.xcodeproj` whose scheme builds for `iphoneos`/`iphonesimulator`. Write a small `scripts/detect-platform.sh` and have the router call it.

### 4.2 iPhone Duo facts (from Apple's "Prepare your app for iPhone Duo" Tech Talk and companions)

- Two displays: a 5.4-inch **outer** display and a 7.6-inch **inner** display. The device has **poses**: closed, open, rotated, and partially folded (tent / tabletop). Every pose change **resizes the app**.
- SDK tiers: apps built with older SDKs run letterboxed; the iOS 27 SDK extends the app left of the status bar on the inner display; the **iOS 27.1 SDK** reaches the screen edges and lays navigation/toolbar buttons out vertically. Build with 27.1.
- **Size classes, not orientation or idiom.** Outer display: compact-width/regular-height in portrait, compact/compact in landscape (like any iPhone). Inner display: regular/regular in both dimensions (iPad-like). The inner display does **not** honor the app's supported interface orientations. Read `@Environment(\.horizontalSizeClass)` in SwiftUI or `traitCollection.horizontalSizeClass` in UIKit.
- **Never reference `UIScreen.main`** on a two-display device; it is ambiguous and slated for deprecation. Use the scene's bounds, `traitCollection.displayScale`, or `window?.windowScene?.screen`.
- **Adaptive containers**: `NavigationSplitView` / `UISplitViewController` and `TabView` / `UITabBarController` adapt to every pose. Columns collapse when closed, tile or overlay when open. On the inner display opt into a sidebar with `.defaultTabBarPlacement(.sidebar)` (SwiftUI) or `tabBarController.sidebar.preferredPlacement = .sidebar` (UIKit).
- **Safe areas and layout margins are asymmetric** on Duo (vertical buttons can sit on the left in landscape and in Split View). Handle each side independently; never compute `width - inset.left * 2`.
- **Corners**: `ConcentricRectangle` (SwiftUI) / `UICornerConfiguration` (UIKit), iOS 26 APIs updated for Duo's screen shapes.
- **Reserved regions** (new in iOS 27.1): `ReservedRegion` (SwiftUI) / `UIViewReservedRegion` (UIKit) let custom bars and edge-to-edge UI claim space without colliding with system UI or the fold.
- `UIRequiresFullScreen` is honored, but the app still resizes on open/close.
- **Tooling**: Xcode 27.1 ships an iPhone Duo simulator inside **Device Hub**, with on-screen controls to open, close, rotate, and fold. Xcode 27.1 also renames the "app modernization" agent skill to **App Resizability**, now covering SwiftUI and Duo — see whether it can be invoked from the CLI and, if so, wrap it.
- Companion Tech Talks to read before writing `ios-duo-design`: "Strike a pose with adaptive layouts on iPhone Duo", "Leverage multiple displays and scenes on iPhone Duo", "Raise the bar with iPhone Duo", "Design for iPhone Duo", "Build a great camera experience for iPhone Duo". All on https://developer.apple.com/iphone-duo/ .
- There is an existing community skill set, **"duology"** (creator `kimeur`, listed on skillsmp.com), covering Duo-specific SwiftUI layout patterns (list-detail, supporting pane, two-page, dual view, extended canvas, feed reflow, tabs-to-sidebar, displacement off the fold). Review it; borrow patterns with attribution in Credits rather than duplicating.

### 4.3 Installing on a physical iPhone for personal use

No App Store needed. Two relevant tiers:

- **Free Personal Team** (any Apple ID): install on up to 3 of your own devices. Provisioning profiles expire every **7 days**; after expiry the app won't launch until re-deployed. No push, iCloud/CloudKit, App Groups, Sign in with Apple, or other entitlements. Roughly 10 app IDs per week.
- **Paid Apple Developer Program** ($99/yr): one-year profiles, all entitlements, TestFlight (90-day builds, over-the-air install, up to 100 internal testers), ad hoc (100 devices/yr).

**Re-signing does not reset the app.** Reinstalling the same bundle ID is an in-place upgrade; the sandbox (Documents, Application Support / SwiftData store, UserDefaults, Keychain) survives. Only deleting the app or changing the bundle ID wipes data. The 7-day clock starts when the profile is generated, so redeploying every ≤6 days keeps the app alive indefinitely.

CLI install flow (verify flags against the installed Xcode):

```bash
xcodebuild -scheme "$APP" -destination "id=$UDID" -allowProvisioningUpdates \
  -derivedDataPath build build
xcrun devicectl device install app --device "$UDID" \
  "build/Build/Products/Debug-iphoneos/$APP.app"
xcrun devicectl device process launch --device "$UDID" "$BUNDLE_ID"
```

Wireless pairing: connect by USB once, enable "Connect via network" in Xcode's Devices window; afterwards `xcrun devicectl list devices` shows the phone whenever it is on the same Wi-Fi.

## 5. Deliverables

### 5.1 `skills/start/new-ios-app/SKILL.md`

Scaffold a working iPhone app from a template, mirroring `new-mac-app`:

- Project generator config (XcodeGen `project.yml` unless investigation says otherwise), one iOS app target, deployment target iOS 27.1, Swift 6.2 with strict concurrency.
- SwiftUI `App` entry, `NavigationSplitView` root, SwiftData model container, asset catalog with an Icon Composer icon slot.
- `Makefile` or `scripts/` with targets: `generate`, `build-sim`, `run-sim`, `snapshot`, `build-device`, `deploy`, `test`. Each is a thin shell wrapper the other skills call.
- **Snapshot mode**: the same idea as the Mac template — a launch argument/env var that makes the app render a named page and exit, so `build-and-verify-ios` can screenshot every page. Investigate how the Mac template does it and keep the interface identical.
- Git init, `.gitignore` for `build/`, `*.xcodeproj` (if generated), DerivedData.
- Bundle ID convention and a note that it must never change once deployed (data loss).
- Ask the user once: iPhone-only, or iPhone + Duo-optimized? Record in the brief. Default to Duo-optimized if they own a Duo.

### 5.2 `skills/ship/build-and-verify-ios/SKILL.md`

Build, install on the simulator, snapshot every page in light and dark mode **and in every Duo pose**, then look at the snapshots.

- Boot the iPhone Duo simulator: `xcrun simctl boot "<iPhone Duo device name>"` (find the exact name in `xcrun simctl list devicetypes`).
- Install/launch: `xcrun simctl install`, `xcrun simctl launch` with the snapshot-mode arguments.
- Screenshot: `xcrun simctl io <udid> screenshot <file>`.
- Appearance: `xcrun simctl ui <udid> appearance light|dark`.
- **Poses — investigate.** Determine whether Device Hub's open/close/rotate/fold controls are scriptable (`xcrun simctl` subcommands, `xcrun devicehub`, an AppleScript/accessibility hook, or an environment override). If scriptable: snapshot matrix = {outer-portrait, outer-landscape, inner-open, inner-rotated, tabletop, tent} × {light, dark}. If **not** scriptable: fall back to (a) outer and inner as two simulator sizes if the simulator exposes them, and (b) an explicit "poses need a human pass" note in the verification report, plus computer-use driving of Device Hub as an optional route. Document the finding at the top of the skill so the next person doesn't repeat the investigation.
- Also snapshot Split View multitasking on the inner display with the app on the left and on the right (asymmetric safe areas are the #1 Duo layout bug).
- Fail the step if any snapshot shows content under the fold line, under the camera, or clipped by the status bar. Describe how to detect these from the image (the agent looks at the PNGs).

### 5.3 User-story acceptance criteria for iOS

Add to `plan/user-stories`: every UI story for an iOS project must state which poses it was verified in, using a fixed vocabulary: `outer`, `inner`, `inner-landscape`, `tabletop`, `tent`, `splitview-left`, `splitview-right`. A story with a layout change is not done until all applicable poses have a snapshot.

### 5.4 `skills/design/ios-duo-design/SKILL.md`

The iPhone/Duo counterpart of `mac-design`. Content, in this order:

1. Design for a **continuum of sizes**, not devices. Size classes decide layout; never orientation, idiom, or screen dimensions.
2. The pose table from §4.2 with the size classes each produces and what the user is likely doing in each (one-handed on outer; reading/two-pane on inner; media/calls in tabletop; tent for landscape viewing).
3. Navigation: `NavigationSplitView` for list-detail apps, `TabView` with sidebar placement on the inner display, when to use each. Sheets center on the inner display and get vertical buttons on the outer.
4. The fold: keep interactive controls and primary text off the hinge; two-page and dual-view patterns; `ReservedRegion` for custom edge-to-edge UI. Borrow the pattern catalog from duology with credit.
5. Safe areas: foreground inside, background `ignoresSafeArea()`, asymmetric insets handled per side, test in Split View on both sides.
6. Concentric corners, Liquid Glass on iOS 27 (what carries over from `mac-design`, what differs).
7. Multi-scene/multi-display: when an app should open a second scene on the other display (from "Leverage multiple displays and scenes").
8. A checklist the `improve-loop` can run per story.

### 5.5 `skills/code/ios-integrations/SKILL.md`

The iOS counterpart of `os-integrations`: widgets and Live Activities, App Intents / Shortcuts, share and action extensions, URL schemes and universal links, background tasks, notifications (note: local only on the free tier), Camera (with the Duo camera Tech Talk), Files/document picker, permissions and their `Info.plist` keys. Keep it as compact as the Mac one.

### 5.6 `skills/ship/test-ios-app/SKILL.md`

Swift Testing for logic, XCTest UI tests where needed, run via `xcodebuild test -destination 'platform=iOS Simulator,name=<Duo>'`. Port the Mac in-app self-test and debug-bridge ideas if they rely only on launch arguments, URL schemes, or a local socket — all of which work on the simulator.

### 5.7 `skills/ship/deploy-to-device/SKILL.md`

Install on the user's physical iPhone for personal use, and keep it alive.

- Explain the free vs paid tiers (§4.3) in three lines and let the user pick; default free.
- The one GUI step: sign in to Xcode with the Apple ID. Then `-allowProvisioningUpdates` handles profiles from the CLI.
- First install over USB (trust the computer, trust the developer cert in Settings → General → VPN & Device Management), then enable wireless pairing.
- Write `scripts/deploy.sh` into the project (the flow in §4.3) with a reachability check via `xcrun devicectl list devices --json-output` and a "last deployed" stamp so it only redeploys when the phone is on the network **and** the profile is older than 5 days.
- Write a `launchd` agent (`~/Library/LaunchAgents/com.<user>.<app>.redeploy.plist`, `StartInterval` 3600) that runs the script hourly, logs to a file, and notifies on failure (`osascript -e 'display notification …'`). Document that the Mac must stay awake and that `-allowProvisioningUpdates` can fail silently when Apple invalidates the Xcode session — the log is where that shows up.
- Note explicitly: redeploying is an in-place upgrade; app data is preserved; never change the bundle ID.
- **Investigate**: whether `devicectl` installs succeed while the phone is locked. Record the answer in the skill.

### 5.8 Router changes (`skills/start/bama/SKILL.md`)

- Call `scripts/detect-platform.sh`.
- For iOS projects, map: `new-mac-app → new-ios-app`, `mac-design → ios-duo-design`, `os-integrations → ios-integrations`, `build-and-verify → build-and-verify-ios`, `test-mac-app → test-ios-app`; add `deploy-to-device` after the first green milestone; skip `agent-cli`.
- For a brand-new, empty folder, ask once: "Mac app or iPhone app?"

## 6. Specs

Add `specs/duo-reading-list.md` (or similar): a small app that exercises every Duo pose — a library list on the outer display, list-detail on the inner display, two facing pages when open and held like a book, controls below the fold in tabletop. It should be buildable end-to-end with the new skills and serve as the integration test for this work.

## 7. Order of work

0. Rename everything to `bama-*` and fix `link-skills.sh`. Do it directly: `git mv` each skill directory, update frontmatter `name`, update every cross-reference (grep for the old names across `skills/`, `README.md`, `AGENTS.md`, `.claude-plugin/`, `scripts/`), then rewrite the link script. Verify with `grep -rn` that no un-prefixed skill name remains outside the router. Commit this alone, first — it touches every file and should not be mixed with feature work.
1. Investigations, write findings into a scratch `docs/ios-investigation.md`: Duo simulator device name, pose scripting, `devicectl` locked-device behavior, App Resizability CLI availability. Do not write skills on assumptions. (Project generator is decided: XcodeGen.)
2. `detect-platform.sh` + router.
3. `new-ios-app` with a template that builds and runs on the Duo simulator.
4. `build-and-verify-ios` with the snapshot matrix.
5. `ios-duo-design`.
6. `deploy-to-device` — test on a real phone if one is available; otherwise mark the skill as untested on hardware.
7. `ios-integrations`, `test-ios-app`, the light modifications to shared skills.
8. README, plugin manifest, Credits (Apple Tech Talks, duology), the Duo spec.
9. Run the Duo spec end-to-end with the new skills. Fix what breaks.

One story or skill per commit, same as BAMA's own loop. Before each commit: the Mac template still builds, and the iOS template builds and snapshots on the simulator.

## 8. Acceptance

- [ ] Every skill is named `bama-*` (router excepted); `link-skills.sh` never overwrites a link it didn't create.
- [ ] `git clone` of the Mac template builds exactly as before.
- [ ] `new-ios-app` produces a project that builds, runs on the iPhone Duo simulator, and renders every page in snapshot mode from the CLI.
- [ ] `build-and-verify-ios` emits a snapshot set covering light/dark and every scriptable pose, plus Split View left/right.
- [ ] `ios-duo-design` contains the size-class table, the fold rules, asymmetric safe-area rule, and the navigation guidance, with code snippets for SwiftUI and the UIKit bridge.
- [ ] `deploy-to-device` installs on a physical iPhone from the CLI and ships a working `deploy.sh` + launchd plist.
- [ ] The router picks the right variants without being told.
- [ ] README and plugin manifest list the new skills; Credits name Apple's Duo Tech Talks and duology.
- [ ] `specs/duo-reading-list.md` builds end-to-end.

## 9. References

- Apple, "Prepare your app for iPhone Duo" (Tech Talk 111461): https://developer.apple.com/videos/play/tech-talks/111461/
- Apple, iPhone Duo developer page (all five Tech Talks, "Designing for iPhone Duo", Device Hub docs): https://developer.apple.com/iphone-duo/
- Apple WWDC26, "Modernize your UIKit app" (adaptive layout principles the Duo talk builds on): https://developer.apple.com/videos/play/wwdc2026/278
- duology skills for iPhone Duo (kimeur): https://skillsmp.com/creators/kimeur/duology
- BAMA (upstream): https://github.com/daveebbelaar/bama
- hmaddocks/bama fork (bama- prefix, safe link script, XcodeGen iOS plumbing, iOS design skill): https://github.com/hmaddocks/bama
