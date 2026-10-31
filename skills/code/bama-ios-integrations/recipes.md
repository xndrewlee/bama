# iPhone integration recipes

For an app from the `bama-new-ios-app` template (`<App>` is its name,
`<bundle-id>` its bundle id). Every recipe builds against the iOS 27.1 SDK
with an iOS 27.0 deployment target. After a `project.yml` change, `make
build-sim` regenerates the project.

## Contents

- [Widget and Live Activity extension](#widget-and-live-activity-extension)
- [App Intents](#app-intents)
- [URL scheme](#url-scheme)
- [Background refresh](#background-refresh)
- [Video and Picture in Picture](#video-and-picture-in-picture)
- [Notifications](#notifications)
- [App lock with Face ID](#app-lock-with-face-id)
- [Camera on iPhone Duo](#camera-on-iphone-duo)
- [Files and photos](#files-and-photos)
- [Spotlight](#spotlight)

## Widget and Live Activity extension

A second target in `project.yml`, embedded in the app. Code both targets
need (the Live Activity's attributes) goes in `Sources/Shared/`.

```yaml
targets:
  <App>:
    sources:
      - path: Sources/<App>
      - path: Sources/Shared
      - path: Icon/AppIcon.icon
    dependencies:
      - package: <App>Kit
      - target: <App>Widgets           # builds and embeds the extension
    settings:
      base:
        INFOPLIST_KEY_NSSupportsLiveActivities: YES
  <App>Widgets:
    type: app-extension
    platform: iOS
    sources:
      - path: Widgets
      - path: Sources/Shared
    info:
      path: Widgets/Info.plist
      properties:
        CFBundleDisplayName: <App>
        NSExtension:
          NSExtensionPointIdentifier: com.apple.widgetkit-extension
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: <bundle-id>.widgets
        MARKETING_VERSION: "0.1"
        CURRENT_PROJECT_VERSION: "1"
        TARGETED_DEVICE_FAMILY: "1"
        SWIFT_VERSION: "6.0"
        GENERATE_INFOPLIST_FILE: YES
        CODE_SIGN_STYLE: Automatic
```

`Sources/Shared/TimerAttributes.swift`:

```swift
import ActivityKit
import Foundation

struct TimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var endsAt: Date
    }
    var title: String
}
```

`Widgets/Widgets.swift`:

```swift
import ActivityKit
import SwiftUI
import WidgetKit

struct CountEntry: TimelineEntry {
    let date: Date
    let count: Int
}

struct CountProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountEntry { CountEntry(date: .now, count: 3) }
    func getSnapshot(in context: Context, completion: @escaping (CountEntry) -> Void) {
        completion(placeholder(in: context))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CountEntry>) -> Void) {
        completion(Timeline(entries: [placeholder(in: context)], policy: .after(.now.addingTimeInterval(3600))))
    }
}

struct CountWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Count", provider: CountProvider()) { entry in
            Text("\(entry.count) items")
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Items")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerAttributes.self) { context in
            Text(context.state.endsAt, style: .timer)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) { Text(context.attributes.title) }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                Text(context.state.endsAt, style: .timer)
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}

@main
struct AppWidgets: WidgetBundle {
    var body: some Widget {
        CountWidget()
        TimerLiveActivity()
    }
}
```

Start the activity from the app:

```swift
let state = TimerAttributes.ContentState(endsAt: .now.addingTimeInterval(180))
_ = try Activity.request(attributes: TimerAttributes(title: "Tea"), content: .init(state: state, staleDate: nil))
```

Check: the built app holds `PlugIns/<App>Widgets.appex`.

## App Intents

```swift
import AppIntents

struct AddItemIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Item"
    @Parameter(title: "Title") var title: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Call the same function the app's + button calls.
        .result(dialog: "Added \(title)")
    }
}

struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: AddItemIntent(), phrases: ["Add an item in \(.applicationName)"],
                    shortTitle: "Add Item", systemImageName: "plus")
    }
}
```

Check: the built app holds `Metadata.appintents`.

## URL scheme

```yaml
  <App>:
    info:
      path: Sources/<App>/Info.plist
      properties:
        CFBundleURLTypes:
          - CFBundleURLName: <bundle-id>
            CFBundleURLSchemes: [<app>]
```

```swift
ContentView()
    .onOpenURL { url in model.open(url) }   // <app>://item/add?title=Milk
```

`xcrun simctl openurl booted "<app>://item/add?title=Milk"` shows
"Open in <App>?" first, and the link arrives after a tap on Open.

## Background refresh

```yaml
    info:
      properties:
        BGTaskSchedulerPermittedIdentifiers: [<bundle-id>.refresh]
        UIBackgroundModes: [fetch]
```

```swift
WindowGroup { ContentView() }
    .backgroundTask(.appRefresh("<bundle-id>.refresh")) {
        await refresh()
        await scheduleRefresh()   // the next one is never automatic
    }

func scheduleRefresh() async {
    let request = BGAppRefreshTaskRequest(identifier: "<bundle-id>.refresh")
    request.earliestBeginDate = .now.addingTimeInterval(3600)
    // submit(_:) is deprecated in iOS 27.0.
    try? await BGTaskScheduler.shared.submitTaskRequest(request)
}
```

iOS decides when it runs, if at all. Never put work people wait for here.

## Video and Picture in Picture

Audio in the background and Picture in Picture need the `audio` background
mode. It has no `INFOPLIST_KEY_` build setting, so give it a small plist
outside the sources folder; Xcode merges the generated keys into it. It
works with a free Apple ID.

```yaml
        GENERATE_INFOPLIST_FILE: YES
        INFOPLIST_FILE: Support/Info.plist   # holds only UIBackgroundModes: [audio]
```

```swift
import AVKit

// In the App's init: plays with the silent switch on and in the background.
try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)

/// The system player: its controls, AirPlay, and Picture in Picture.
struct PlayerView: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.allowsPictureInPicturePlayback = true
        // Swiping home while it plays starts Picture in Picture.
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {}

    func makeCoordinator() -> FullScreen { FullScreen(player: player) }

    /// Leaving the player's own full screen with its close button pauses it.
    final class FullScreen: NSObject, AVPlayerViewControllerDelegate {
        let player: AVPlayer
        private var wasPlaying = false
        init(player: AVPlayer) { self.player = player }

        func playerViewController(_ controller: AVPlayerViewController,
                                  willBeginFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator) {
            wasPlaying = player.timeControlStatus != .paused
        }

        func playerViewController(_ controller: AVPlayerViewController,
                                  willEndFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator) {
            coordinator.animate(alongsideTransition: nil) { [weak self] context in
                guard let self, !context.isCancelled, self.wasPlaying else { return }
                self.player.play()
            }
        }
    }
}
```

Checked on a real iPhone Duo:

- A player with video pauses when the phone locks. Set
  `player.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible` to keep
  the sound going; the home gesture starts Picture in Picture instead.
- The player's full screen covers the view that holds it, and SwiftUI calls
  that view's `onDisappear`. Never stop the player there: stop it in the
  close button, or let it go with the view's state. On a pushed player page,
  stop it when the page leaves the top of its stack (`path.last` changes),
  not on `onDisappear`.
- Going home, iOS lays the app out again at other sizes for the app
  switcher. A player view that moves to another branch of an `if` there is
  made again: the `AVPlayerViewController` in Picture in Picture goes, and
  the video is paused when the person comes back. Hold the layout while
  `scenePhase` is not `.active`, and pick the branch from the held value.
  This only shows on a real phone: the simulator did not start Picture in
  Picture from the home button.
- A feed of full-height videos (`ScrollView`, each page
  `.containerRelativeFrame(.vertical)`, `.scrollPosition(id:anchor: .top)`):
  one player, for the page on screen. When the page changes, close the old
  page's model so a stream that arrives after the swipe stays off, and
  cancel its start. `.clipped()` the scroll view, or the next page shows
  under the home indicator. Stop the feed when the app goes to the
  background and leave Picture in Picture off there; the full player page
  keeps it.
- Rotating such a feed left the page 68 pt off on a real phone. Snap with
  `.scrollTargetBehavior(.viewAligned(limitBehavior: .always))`, not
  `.paging`: paging snaps to a height of its own, which stopped matching
  the pages after the rotation. The size and safe area change several
  times while the rotation runs, and a scroll during it is undone when it
  ends: after `onGeometryChange` of size and `safeAreaInsets` stops for
  about 350 ms, `scrollTo` the page once, without animation (animated, it
  slid in from the page before), and hide the other pages until then.
  The simulator does not rotate the Duo from a UI test: check on the phone.
- A list of live items goes stale. When an item turns out to be over (the
  server's 404), take it out and let the next one take its place, and ask
  about the next item ahead so it leaves before it is reached. A network
  failure keeps the item.
- To see what the player does on the phone, log its steps to a file in
  `URL.temporaryDirectory` and copy it off with `devicectl device copy from`
  (`bama-build-and-verify-ios`). Log `makeUIViewController` and
  `dismantleUIViewController`: a player made twice explains a lost video.
- An HLS playlist plays as is: `AVPlayerItem(url:)`. When the server sends
  one playlist per quality and no multivariant playlist, the player cannot
  adapt, and a high one stalls on Wi-Fi (1080p60 needs 9 Mbps; the phone got
  4). Build a multivariant playlist from them, best quality under 2 Mbps
  first, and hand it over with an `AVAssetResourceLoaderDelegate` on a
  made-up URL scheme. Keep the loader in a property: AVFoundation holds it
  weakly. A quality menu still offers each one alone.

```swift
nonisolated final class PlaylistLoader: NSObject, AVAssetResourceLoaderDelegate, Sendable {
    static let url = URL(string: "app-playlist://live/master.m3u8")!
    private let playlist: Data
    init(_ playlist: Data) { self.playlist = playlist }

    func resourceLoader(_ loader: AVAssetResourceLoader,
                        shouldWaitForLoadingOfRequestedResource request: AVAssetResourceLoadingRequest) -> Bool {
        guard request.request.url?.scheme == Self.url.scheme else { return false }
        request.contentInformationRequest?.contentType = "public.m3u-playlist"
        request.contentInformationRequest?.contentLength = Int64(playlist.count)
        request.contentInformationRequest?.isByteRangeAccessSupported = false
        request.dataRequest?.respond(with: playlist)
        request.finishLoading()
        return true
    }
}
// let asset = AVURLAsset(url: PlaylistLoader.url)
// asset.resourceLoader.setDelegate(loader, queue: .main)
// "#EXT-X-STREAM-INF:BANDWIDTH=<bps>,RESOLUTION=<w>x<h>" then the variant's https URL, per quality
```

In snapshots and tests, show a drawn frame instead of the player.

## Notifications

```swift
import UserNotifications

/// Fires at `date`. Count the seconds after the permission prompt returns:
/// the first time, the person may take a while to answer it.
func remind(_ title: String, at date: Date) async throws {
    let center = UNUserNotificationCenter.current()
    guard try await center.requestAuthorization(options: [.alert, .sound, .badge]) else { return }
    let seconds = date.timeIntervalSinceNow
    guard seconds > 0 else { return }
    let content = UNMutableNotificationContent()
    content.title = title
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
    try await center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger))
}
```

## App lock with Face ID

`INFOPLIST_KEY_NSFaceIDUsageDescription` in `project.yml`, or the first
check crashes. Ask with `.deviceOwnerAuthentication`, not the biometrics
policy: it falls back to the passcode, so a face that fails or a refused
Face ID permission still opens the app. Make a new `LAContext` for every
check; a used one can pass again without asking.

```swift
import LocalAuthentication

func authenticate(_ reason: String) async -> Bool {
    let context = LAContext()
    return (try? await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)) ?? false
}

/// nil: the iPhone has no passcode. Then open the app instead of locking,
/// or a person who removes the passcode is locked out of their own app.
var hasFaceID: Bool? {
    let context = LAContext()
    guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else { return nil }
    return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        && context.biometryType == .faceID
}
```

The rules, kept apart from LocalAuthentication so a unit test can run them:

- Lock on `.background`, never on `.inactive`. Control Center, the
  notification shade, and the Face ID sheet itself make the scene inactive.
- Ask by itself once per launch or return. The Face ID sheet makes the
  scene inactive and then active again, so asking on every `.active` asks
  forever after a cancel. After a cancel, wait for an unlock button.
- A delay ("after 1 minute") lets the app open without asking when it comes back
  in time, but only if it was open when it left. Measure it with
  `ContinuousClock`: it counts while the phone sleeps and ignores the
  phone's clock.
- Turn the lock on only after a check passes.
- In a video app, count time in Picture in Picture as time in the app:
  the video stays on screen in the small window, and Face ID on the way
  back from it feels broken to people. Report `didStart` and `didStop` from
  the `AVPlayerViewControllerDelegate`; they can come before or after the
  scene's background change, so handle both orders. Start the time away
  when the small window closes from another app
  (`UIApplication.shared.applicationState == .background` at `didStop`).
  Offer a setting for people who want it locked anyway.

The cover:

- Put it in a `UIWindow` of its own at `.alert + 1` in the app's scene,
  shown and hidden with `isHidden`. An overlay on the root view sits under
  alerts, sheets, menus, and confirmation dialogs, so they show through it.
  Find the scene from a `UIViewRepresentable` in the root view
  (`didMoveToWindow`, then `window?.windowScene`).
- The keyboard has a window above it: resign the first responder on lock.
- Keep the app's views under the cover. Swapping the root view for a lock
  screen rebuilds every page: a player stops and Picture in Picture ends.
- With the lock on, show the cover whenever the scene is not active, so
  the app switcher shows no content. Skip that while the app's own Face ID
  sheet is up, and until the scene turns active after it, or the cover
  flashes over the page that asked.
- Set `accessibilityViewIsModal` on the cover's view.

Test it with a stand-in for Face ID that a launch variable sets up
(`APP_LOCK=no,yes` answers no, then yes), and with times passed in. A UI
test sends the app to the background by opening another app,
`XCUIApplication(bundleIdentifier: "com.apple.Preferences").activate()`,
then waits for `app.wait(for: .runningBackgroundSuspended, timeout:)` and
calls `app.activate()`. Pressing home is not enough: the iPhone Duo
simulator's home button leaves the app in the foreground. A disabled
unlock button while the stand-in answers needs
`wait(for: \.isEnabled, toEqual: true, timeout:)` before the tap. Check the
real Face ID on the phone.

## Camera on iPhone Duo

The Duo has a front ultra-wide camera on each display. Pick one when the
feature needs it, and fall back on other iPhones and on iOS 27.0:

```swift
import AVFoundation

func frontCamera(inner: Bool) -> AVCaptureDevice? {
    if #available(iOS 27.1, *),
       let duo = AVCaptureDevice.default(inner ? .builtInInnerUltraWideCamera : .builtInOuterUltraWideCamera,
                                         for: .video, position: .front) {
        return duo
    }
    return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
}
```

To show the person being photographed a preview on the other display, add
a scene accessory (iOS 27.1). The system decides when it can show:

```swift
struct MirrorAccessory: ViewModifier {
    @Binding var mirror: Bool
    @Binding var canMirror: Bool

    func body(content: Content) -> some View {
        if #available(iOS 27.1, *) {
            content.sceneAccessory {
                CameraCaptureAccessory(isEnabled: $mirror) {
                    PreviewView()
                }
                .onAvailabilityChange { available in canMirror = available }
            }
        } else {
            content
        }
    }
}
```

Rotate previews and photos with `AVCaptureDevice.RotationCoordinator`.

## Files and photos

```swift
.fileImporter(isPresented: $importing, allowedContentTypes: [.plainText]) { result in
    if case .success(let url) = result, url.startAccessingSecurityScopedResource() {
        defer { url.stopAccessingSecurityScopedResource() }
        model.importText(from: url)
    }
}

PhotosPicker("Add Photo", selection: $photo, matching: .images)   // import PhotosUI; no permission
```

To show the app's Documents folder in the Files app:

```yaml
        INFOPLIST_KEY_UIFileSharingEnabled: YES
        INFOPLIST_KEY_LSSupportsOpeningDocumentsInPlace: YES
```

## Spotlight

```swift
import CoreSpotlight

func index(_ item: Item) {
    let attributes = CSSearchableItemAttributeSet(contentType: .text)
    attributes.title = item.title
    let entry = CSSearchableItem(uniqueIdentifier: item.uuid.uuidString, domainIdentifier: "items", attributeSet: attributes)
    CSSearchableIndex.default().indexSearchableItems([entry])
}
```
