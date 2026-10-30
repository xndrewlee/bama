import Foundation
import SwiftData

/// A command channel for agents, on the simulator in debug builds.
/// tools/bridge.sh starts the app with APP_BRIDGE=/tmp/<App>-bridge and a
/// test store. To send a command, it writes it to <dir>/command and posts
/// the Darwin notification "<bundle id>.bridge" (`simctl spawn notifyutil`);
/// the app runs it and writes <dir>/status.json.
///   tools/bridge.sh status
///   tools/bridge.sh add:Milk
/// Add a case for every action, with the same name as its button and URL.
enum DebugBridge {
    private static var dir: String? {
        ProcessInfo.processInfo.environment["APP_BRIDGE"].flatMap { $0.isEmpty ? nil : $0 }
    }
    private static var model: AppModel?

    static func startIfRequested(model: AppModel) {
        #if DEBUG
        guard dir != nil, Store.isOverridden else { return }
        Self.model = model
        let name = (Bundle.main.bundleIdentifier ?? "app") + ".bridge"
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), nil, { _, _, _, _, _ in
            Task { @MainActor in DebugBridge.handle() }
        }, name as CFString, nil, .deliverImmediately)
        report(command: "start")
        #endif
    }

    private static func handle() {
        guard let dir, let model else { return }
        let command = (try? String(contentsOfFile: "\(dir)/command", encoding: .utf8))?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "status"
        let parts = command.split(separator: ":", maxSplits: 1).map(String.init)
        let argument = parts.count > 1 ? parts[1] : ""
        var error: String?
        switch parts.first ?? "status" {
        case "status": break
        case "add": model.addItem(title: argument)
        case "page": model.sidebar = SidebarItem(rawValue: argument) ?? .all
        case "settings": model.showSettings.toggle()
        default: error = "unknown command \(command)"
        }
        report(command: command, error: error)
    }

    private static func report(command: String, error: String? = nil) {
        guard let dir, let model else { return }
        let items = (try? model.container.mainContext.fetch(FetchDescriptor<Item>())) ?? []
        var status: [String: Any] = [
            "command": command,
            "items": items.count,
            "page": model.sidebar?.rawValue ?? "",
            "selected": model.selection != nil,
            "settingsOpen": model.showSettings,
        ]
        if let error { status["error"] = error }
        if let data = try? JSONSerialization.data(withJSONObject: status, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: URL(fileURLWithPath: "\(dir)/status.json"), options: .atomic)
        }
    }
}
