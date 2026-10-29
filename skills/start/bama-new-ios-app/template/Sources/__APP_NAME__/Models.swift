import Foundation
import SwiftData
import SwiftUI
import __APP_NAME__Kit

@Model
final class Item {
    var title: String
    var notes: String = ""
    var isStarred: Bool = false
    var createdAt: Date = Date.now
    /// A stable id for links and sync.
    var uuid: UUID = UUID()

    init(title: String) {
        self.title = title
    }
}

/// The sidebar pages. Snapshot mode walks through every case.
enum SidebarItem: String, CaseIterable, Identifiable {
    case all, starred

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All Items"
        case .starred: "Starred"
        }
    }

    var symbol: String {
        switch self {
        case .all: "tray"
        case .starred: "star"
        }
    }
}

/// App-wide state that toolbars, sheets, and views share.
@Observable
final class AppModel {
    let container: ModelContainer
    var sidebar: SidebarItem? = .all
    var selection: PersistentIdentifier?
    /// The column a compact width (the outer display, or a narrow window)
    /// shows. Wider sizes show several columns side by side.
    var compactColumn: NavigationSplitViewColumn = .sidebar
    var showSettings = false
    /// The open Settings topic, as a navigation path.
    var settingsPath: [SettingsTab] = []

    init(container: ModelContainer) {
        self.container = container
    }

    func addItem(title: String = "") {
        let item = Item(title: ItemTitle.clean(title))
        if sidebar == .starred { item.isStarred = true }
        container.mainContext.insert(item)
        selection = item.id
    }
}
