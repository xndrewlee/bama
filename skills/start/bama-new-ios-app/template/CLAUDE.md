# __APP_NAME__

A native iPhone app in SwiftUI, made for iPhone Duo and every other iPhone
on iOS 27. It keeps its data on the phone in SwiftData, with no server.

## Layout

- `Sources/__APP_NAME__/` the app. `App.swift` has the scene and the database location.
- `Kit/` a Swift package with rules and data logic and no SwiftUI. Tests in `Kit/Tests/`.
- `project.yml` the XcodeGen spec. The `.xcodeproj` is generated from it and stays out of git. Edit `project.yml`, never the `.xcodeproj`.
- `Makefile` every step from the shell. The scripts live in `tools/`.
- `Icon/AppIcon.icon` the app icon, an Icon Composer file (JSON plus SVG layers). Xcode compiles it into the app.
- `docs/` the brief, the screen index, and the user stories, when they exist.

## Build and check

- Build for the simulator: `make build-sim`. Build output lives in `~/Library/Developer/__APP_NAME__/build`. Fix warnings too.
- Run it on the iPhone Duo simulator: `make run-sim`. Another device: `APP_DEVICE="iPhone 18 Pro" make run-sim`.
- Unit tests on this Mac: `make test`.
- Self-test (the app's real functions on a /tmp store): `make selftest`. Every check prints PASS. Add a check for every story with logic in `SelfTest.swift`.
- After every UI change, take snapshots with sample data and look at them: `make snapshot`.
  It writes `/tmp/__APP_NAME__-shots/<page>-light.png` and `-dark.png` for every sidebar page, and `settings-<topic>-light.png` and `-dark.png` for every Settings topic. `APP_SNAPSHOT_PAGES=all,settings make snapshot` limits the pages.
  For a new sheet, full-screen cover, or detail, add it to `screens` in `Snapshot.swift`: a name, how to show it, and how to hide it. `APP_OPEN` uses the same names.
  `APP_SIZE=951x669 make snapshot` renders the app at that size in points (size classes only, no fold). The bama-build-and-verify-ios skill runs every iPhone Duo pose this way.
- Snapshots, seed data, and the self-test refuse to run without `APP_STORE` in /tmp. Never test against the app's real database.
- Then check the grid: `make check`. Both checks print PASS.
- Compile for a real iPhone, unsigned: `make build-device`. Installing on the phone is `make deploy`, which the bama-deploy-to-device skill sets up. On the phone, `APP_STORE=demo.store APP_SEED=1 APP_OPEN=<page>` opens a page on a demo store (bama-build-and-verify-ios, human pass).
- A change is done when the build has no errors or warnings, the self-test and grid checks pass, and you looked at the light and dark snapshots on the Duo and on a non-Duo iPhone (`APP_DEVICE="iPhone 18 Pro" make snapshot`).

## Platform rules

- Deployment target iOS 27.0, built with the iOS 27.1 SDK. An API new in 27.1 (such as `ReservedRegion`) goes behind `if #available(iOS 27.1, *)`, with a 27.0 fallback.
- The bundle id `__BUNDLE_ID__` never changes once the app is on a phone. A new id is a new app, and the old one's data stays behind.
- Layout follows size classes, never the device, the idiom, or the orientation. The Duo's outer display is compact width, its inner display regular width, and every fold or rotation resizes the app.
- Never use `UIScreen.main`. Read sizes from the view or the scene.
- Safe areas are not symmetric on the Duo: system buttons can sit on one side. Pad each side on its own.

## Design rules

- Use Apple's controls and system styles. Only the accent color is custom: `UI/Theme.swift` (`ThemeStore.defaultID`). People change it in Settings > Appearance. Light and dark mode follow the iPhone.
- Views use `.tint`, `Palette.accent`, `Palette.accentText` (accent-colored text), and `Palette.onAccent` (text on an accent fill). Never hard-code colors, radii, or durations in views.
- Compare accents: `APP_ACCENT=<id> make snapshot`.
- Spacing comes from `Space` in `UI/Grid.swift`, on a 4 pt grid. Mark custom pages and cards with `.gridArea` and `.gridProbe`.
- Touch targets are at least 44 by 44 points.
- Settings: one page per topic in `SettingsView.swift`, one grouped Form per page. Add a case to `SettingsTab` for a new page.
- Navigation bars, toolbars, sheets, and tab bars stay system.
- Colors: `.primary`, `.secondary`, `.tint`, and system colors. Never fixed grays or white for text.
- `Label` for icon and text pairs. SF Symbols for icons.
- `ContentUnavailableView` for empty states.
- Liquid Glass belongs to floating controls only, never to content.

## Skills

The bama plugin has a skill for each step: `bama-ios-duo-design` (design
rules for every Duo pose), `bama-design-system` (accent and tokens),
`bama-layout-grid`, `bama-ux-design`, `bama-swift-swiftui`,
`bama-ios-integrations`, `bama-performance`, `bama-build-and-verify-ios`,
`bama-test-ios-app`, `bama-deploy-to-device`, `bama-app-icon`,
`bama-user-stories`, and `bama-improve-loop`. Use them.

## Git

- Commit after each working change, with a message that says what the user can now do.
