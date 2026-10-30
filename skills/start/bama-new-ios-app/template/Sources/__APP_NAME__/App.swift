import SwiftData
import SwiftUI

// __APP_NAME__ on iPhone. The Makefile runs it on the simulator; on the
// simulator, give each variable a SIMCTL_CHILD_ prefix (the tools do this).
//   APP_STORE=<file>          use another database (tests, experiments); a bare name lands in the app's temporary folder
//   APP_SNAPSHOT=<dir>        show every sidebar page and Settings topic in light and dark mode for tools/snap.sh, then quit
//   APP_SEED=1                fill an empty test store with sample items (tools/snap.sh)
//   APP_OPEN=<page>           open a sidebar page, or settings, on a test store (a look on the real phone)
//   --selftest                run the self-test on a test store and quit with 0 or 1 (tools/selftest.sh)
//   APP_ACCENT=<id>           run with another accent from Theme.all (UI/Theme.swift)
//   APP_GRID=1                draw the 8 pt grid and the layout probes over the app

@main
struct __APP_NAME__App: App {
    @State private var model = AppModel(container: Store.makeContainer())

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
                .themed()
                .measuresWindow()
                .overlay { if GridOverlay.enabled { GridOverlay().ignoresSafeArea() } }
        }
        .modelContainer(model.container)
    }
}

/// Where the data lives: Application Support/__APP_NAME__.store in the app's
/// sandbox. Reinstalling the same bundle id keeps it; deleting the app or
/// changing the bundle id loses it.
enum Store {
    /// True when APP_STORE points somewhere else (tests, snapshots, seed data).
    static var isOverridden: Bool {
        !(ProcessInfo.processInfo.environment["APP_STORE"] ?? "").isEmpty
    }

    static var url: URL {
        if let path = ProcessInfo.processInfo.environment["APP_STORE"], !path.isEmpty {
            // A bare file name goes in the app's temporary folder: on a
            // phone, /tmp is outside the sandbox.
            return path.contains("/") ? URL(fileURLWithPath: path) : URL.temporaryDirectory.appending(path: path)
        }
        let dir = URL.applicationSupportDirectory
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appending(path: "__APP_NAME__.store")
    }

    static func makeContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: Item.self, configurations: ModelConfiguration(url: url))
        } catch {
            fatalError("Could not open the database at \(url.path): \(error)")
        }
    }
}
