import SwiftData
import SwiftUI
import UIKit

/// Screenshot mode for agents. tools/snap.sh runs it on the simulator:
///   APP_STORE=/tmp/__APP_NAME__-test.store APP_SEED=1 APP_SNAPSHOT=/tmp/__APP_NAME__-shots
/// An app cannot screenshot the simulator's screen, so it asks the Mac to.
/// For every sidebar page, then every Settings topic, in light and dark, it
/// shows the page, writes <name>.want into the folder, and waits until
/// tools/snap.sh has saved <name>.png with `simctl io screenshot`. That PNG
/// holds the real screen: status bar, system buttons, and glass. Each page
/// also gets <name>-layout.json with the grid probes (tools/check-layout.swift).
/// On screen, the app writes `ready`, then starts once tools/snap.sh writes
/// `go` (an APP_SIZE run first moves the app to the Resizable screen).
/// Progress goes to snapshot.log in the folder: simctl does not pass on an
/// app's printed lines unless it waits for the app to quit.
/// APP_SNAPSHOT_PAGES=all,starred limits the pages. Add "settings" to include Settings.
/// Add APP_ACCENT=<id> to see the pages in another accent.
enum Snapshot {
    /// Sheets and screens beyond the sidebar pages: a name, how to show it,
    /// and how to put the app back. Add one for every sheet, full-screen
    /// cover, and detail a story adds; APP_OPEN uses the same names.
    private static let screens: [(name: String, show: (AppModel) -> Void, hide: (AppModel) -> Void)] = [
        ("item", { $0.selection = first($0)?.id; $0.compactColumn = .detail },
         { $0.selection = nil; $0.compactColumn = .content }),
    ]

    /// The newest item, the one the snapshots show.
    private static func first(_ model: AppModel) -> Item? {
        try? model.container.mainContext.fetch(FetchDescriptor<Item>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])).first
    }

    /// Opens one sidebar page, screen, or settings at launch, for a look on
    /// the real phone, where no script can tap: APP_OPEN=item with a test
    /// store. It waits a second: during the first layout a split view resets
    /// its columns.
    static func openIfRequested(model: AppModel) {
        guard Store.isOverridden, let name = ProcessInfo.processInfo.environment["APP_OPEN"] else { return }
        Task {
            try? await Task.sleep(for: .seconds(1))
            model.compactColumn = .content
            if let page = SidebarItem(rawValue: name) {
                model.sidebar = page
            } else if name == "settings" {
                model.showSettings = true
            } else {
                screens.first { $0.name == name }?.show(model)
            }
        }
    }

    static func runIfRequested(model: AppModel) {
        let env = ProcessInfo.processInfo.environment
        guard let dir = env["APP_SNAPSHOT"], !dir.isEmpty else { return }
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        // Snapshots never run against the real database.
        guard Store.isOverridden else {
            say("SNAPSHOT refused: set APP_STORE to a file in /tmp", in: dir)
            exit(1)
        }
        let only = env["APP_SNAPSHOT_PAGES"].map { Set($0.split(separator: ",").map(String.init)) }
        Task {
            FileManager.default.createFile(atPath: "\(dir)/ready", contents: nil)
            for _ in 0..<300 where !FileManager.default.fileExists(atPath: "\(dir)/go") {
                try? await Task.sleep(for: .milliseconds(200))
            }
            try? await Task.sleep(for: .seconds(1.5))
            // On a compact width, show the page's list, not the sidebar.
            model.compactColumn = .content
            for style in [UIUserInterfaceStyle.light, .dark] {
                setStyle(style)
                for page in SidebarItem.allCases where only?.contains(page.rawValue) ?? true {
                    model.sidebar = page
                    try? await Task.sleep(for: .seconds(0.8))
                    await capture("\(page.rawValue)-\(name(style))", in: dir)
                }
                for screen in screens where only?.contains(screen.name) ?? true {
                    screen.show(model)
                    try? await Task.sleep(for: .seconds(1))
                    await capture("\(screen.name)-\(name(style))", in: dir)
                    screen.hide(model)
                    try? await Task.sleep(for: .seconds(0.8))
                }
            }
            if only == nil || only?.contains("settings") == true {
                model.showSettings = true
                try? await Task.sleep(for: .seconds(1))
                for style in [UIUserInterfaceStyle.light, .dark] {
                    setStyle(style)
                    for tab in SettingsTab.allCases {
                        model.settingsPath = [tab]
                        try? await Task.sleep(for: .seconds(0.8))
                        await capture("settings-\(tab.rawValue)-\(name(style))", in: dir)
                    }
                }
            }
            say("SNAPSHOT done \(dir)", in: dir)
            exit(0)
        }
    }

    private static func name(_ style: UIUserInterfaceStyle) -> String {
        style == .dark ? "dark" : "light"
    }

    /// Light or dark for every window, sheets included.
    private static func setStyle(_ style: UIUserInterfaceStyle) {
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            for window in scene.windows { window.overrideUserInterfaceStyle = style }
        }
    }

    /// Asks tools/snap.sh for a screenshot and waits for it, up to 20 seconds.
    private static func capture(_ name: String, in dir: String) async {
        let png = "\(dir)/\(name).png"
        let window = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }.first
        GridProbes.shared.write(to: "\(dir)/\(name)-layout.json", window: window?.bounds.size ?? .zero)
        try? FileManager.default.removeItem(atPath: png)
        FileManager.default.createFile(atPath: "\(dir)/\(name).want", contents: nil)
        for _ in 0..<100 {
            if FileManager.default.fileExists(atPath: png) {
                say("SNAPSHOT \(png)", in: dir)
                return
            }
            try? await Task.sleep(for: .milliseconds(200))
        }
        say("SNAPSHOT missed \(name): no PNG after 20 seconds. Run snapshots with tools/snap.sh.", in: dir)
    }

    /// Prints a line and adds it to snapshot.log, which tools/snap.sh reads.
    private static func say(_ line: String, in dir: String) {
        print(line)
        let log = URL(fileURLWithPath: dir).appending(path: "snapshot.log")
        guard let handle = try? FileHandle(forWritingTo: log) else {
            try? Data((line + "\n").utf8).write(to: log)
            return
        }
        handle.seekToEndOfFile()
        handle.write(Data((line + "\n").utf8))
        try? handle.close()
    }
}
