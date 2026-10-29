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
- [Notifications](#notifications)
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

## Notifications

```swift
import UserNotifications

func remind(_ title: String, in seconds: TimeInterval) async throws {
    let center = UNUserNotificationCenter.current()
    guard try await center.requestAuthorization(options: [.alert, .sound, .badge]) else { return }
    let content = UNMutableNotificationContent()
    content.title = title
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
    try await center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger))
}
```

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
