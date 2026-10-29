---
name: bama-ios-integrations
description: iPhone integrations for a native app, such as widgets and Live Activities, App Intents and Shortcuts, URL schemes and links, background refresh, notifications, the camera on iPhone Duo, Files, sharing, and the Info.plist key each permission needs, with what a free Apple ID allows. Use when an iPhone app must reach outside its own screens.
---

# iPhone integrations

An iPhone app reaches people through the Home Screen, the Lock Screen,
Shortcuts, the share sheet, and Files, not only its own screens. This skill
picks the API for each entry point, the permission it costs, and whether a
free Apple ID can sign it. Code for every row is in [recipes.md](recipes.md);
it builds in the `bama-new-ios-app` template.

## Pick the API

| Want | API | Free Apple ID | Permission (Info.plist key) |
| --- | --- | --- | --- |
| Home Screen and Lock Screen widget | WidgetKit extension target | Yes. Reading the app's data needs an App Group: paid | None |
| A timer or delivery on the Lock Screen and Dynamic Island | ActivityKit `Activity.request`, drawn by the widget extension | Yes, updated from the app. Push updates: paid | `NSSupportsLiveActivities` |
| Shortcuts, Siri, Spotlight actions | `AppIntent` + `AppShortcutsProvider` | Yes | None |
| Find the app's content in Spotlight | Core Spotlight `CSSearchableIndex` | Yes | None |
| Send to other apps | `ShareLink` | Yes | None |
| Receive from other apps' share sheet | Share extension target | Yes, but handing the item to the app's store needs an App Group: paid | None |
| Links from Notes, Safari, scripts | `CFBundleURLTypes` + `.onOpenURL` | Yes | None |
| `https` links that open the app | Associated Domains + `apple-app-site-association` | Paid | None |
| Work in the background | `.backgroundTask(.appRefresh(id))` + `BGTaskScheduler.submitTaskRequest` | Yes | `BGTaskSchedulerPermittedIdentifiers`, `UIBackgroundModes` |
| Notifications scheduled on the phone | `UNUserNotificationCenter` | Yes | Asks once |
| Push notifications | APNs | Paid | Asks once |
| Camera | `AVCaptureSession`; on Duo `.builtInOuterUltraWideCamera` and `.builtInInnerUltraWideCamera` (iOS 27.1) | Yes | `NSCameraUsageDescription` |
| A camera preview on the Duo's other display | `.sceneAccessory { CameraCaptureAccessory { } }` (iOS 27.1) | Yes | `NSCameraUsageDescription` |
| Pick photos | `PhotosPicker` | Yes | None |
| Read the whole photo library | PhotoKit | Yes | `NSPhotoLibraryUsageDescription` |
| Open and save files | `.fileImporter`, `.fileExporter` | Yes | None |
| Show the app's Documents folder in Files | `UIFileSharingEnabled`, `LSSupportsOpeningDocumentsInPlace` | Yes | None |
| Location | Core Location | Yes | `NSLocationWhenInUseUsageDescription` |
| Microphone | `AVAudioSession` | Yes | `NSMicrophoneUsageDescription` |
| Contacts, calendars | Contacts, EventKit | Yes | `NSContactsUsageDescription`, `NSCalendarsFullAccessUsageDescription` |
| Face ID to unlock the app | LocalAuthentication | Yes | `NSFaceIDUsageDescription` |
| Haptics | `.sensoryFeedback` | Yes | None |
| Sync between devices | SwiftData with CloudKit | Paid | None |

Prefer the row with no permission when two rows solve the same job:
`PhotosPicker` before PhotoKit, local notifications before push.

## Free Apple ID limits

A free team signs no App Groups, iCloud, push, Associated Domains, or Sign
in with Apple. An extension needs no entitlement, but without an App Group
it cannot see the app's store: on the free tier a widget shows only what it
can work out alone. Tell the user before a story depends on a paid row.

## Permissions

- Ask at the moment of use, with one line on what breaks without it.
- Every `NS...UsageDescription` key must be in Info.plist before the first
  request, or the app crashes. In the template, add it to `project.yml` as
  `INFOPLIST_KEY_NSCameraUsageDescription: Take a photo of an item.`
- Keys that hold arrays (URL types, background task ids) go under the
  target's `info: properties:` in `project.yml`. Xcode merges them with the
  generated keys.
- Show a denied permission's state where the feature lives, with a button
  that opens the app's page in Settings: `UIApplication.openSettingsURLString`.

## Widgets and Live Activities

- A widget shows one idea from the app's purpose, with content that
  changes through the day. A tap deep-links to the exact place. Buttons and
  toggles in it run App Intents. Never a whole app squeezed into a widget.
- A Live Activity follows one event with an end: a timer, a delivery, a
  match. End it when the event ends.

## Make every feature reachable three ways

Each feature gets a button in the app, a URL (`<app>://<action>`), and an
App Intent. The same action enum backs all three. On the simulator,
`xcrun simctl openurl booted "<app>://..."` asks "Open in <App>?" before the
link arrives, so scripts that test the app drive it another way
(`bama-test-ios-app`).

Done when every entry point in the brief's "System hooks" works from a
clean install on the simulator, every permission it uses has its
Info.plist key, and the story says which rows need a paid Apple ID.
