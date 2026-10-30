import SwiftData
import SwiftUI

/// Sidebar, list, and detail. NavigationSplitView adapts to every size:
/// one column at a time on a compact width (the outer display), the list and
/// the detail side by side on a regular width (the inner display).
struct ContentView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.windowSize) private var window
    @State private var frame: CGRect = .zero
    @State private var fold: CGRect?

    var body: some View {
        @Bindable var model = model
        NavigationSplitView(columnVisibility: $model.columns, preferredCompactColumn: $model.compactColumn) {
            sidebar
        } content: {
            ItemList(page: model.sidebar ?? .all)
                .navigationSplitViewColumnWidth(listWidth)
        } detail: {
            ItemDetail()
        }
        .readsFold(frame: $frame, fold: $fold)
        .sheet(isPresented: $model.showSettings) {
            SettingsView()
                .environment(model)
                .themed()
        }
        .task {
            SeedData.insertIfRequested(into: model)
            Snapshot.openIfRequested(model: model)
            SelfTest.runIfRequested(model: model)
            Snapshot.runIfRequested(model: model)
        }
    }

    /// The list takes the leading half, up to the fold. On an iPhone Duo
    /// held open like a book, the list and the detail each get one page and
    /// nothing sits on the fold.
    private var listWidth: CGFloat {
        let split = FoldSplit(fold: fold, frame: frame, window: window)
        return max(320, (split.isVertical ? split.x : frame.width / 2).rounded())
    }

    private var sidebar: some View {
        @Bindable var model = model
        return List(SidebarItem.allCases, selection: $model.sidebar) { page in
            NavigationLink(value: page) {
                Label(page.title, systemImage: page.symbol)
            }
        }
        .navigationTitle("__APP_NAME__")
        .toolbar {
            ToolbarItem {
                Button("Settings", systemImage: "gearshape") { model.showSettings = true }
            }
        }
    }
}

struct ItemList: View {
    @Environment(AppModel.self) private var model
    @Environment(\.modelContext) private var context
    @Query(sort: \Item.createdAt, order: .reverse) private var items: [Item]
    let page: SidebarItem

    private var visible: [Item] {
        page == .starred ? items.filter(\.isStarred) : items
    }

    var body: some View {
        @Bindable var model = model
        List(visible, selection: $model.selection) { item in
            NavigationLink(value: item.id) {
                Label(item.title, systemImage: item.isStarred ? "star.fill" : "circle")
            }
            .swipeActions {
                Button("Delete", systemImage: "trash", role: .destructive) { context.delete(item) }
            }
        }
        .overlay {
            if visible.isEmpty {
                ContentUnavailableView(
                    "No Items",
                    systemImage: page.symbol,
                    description: Text("Tap the plus button to add one.")
                )
            }
        }
        .navigationTitle(page.title)
        .toolbar {
            ToolbarItem {
                Button("New Item", systemImage: "plus") { model.addItem() }
            }
        }
    }
}

struct ItemDetail: View {
    @Environment(AppModel.self) private var model
    @Query private var items: [Item]

    var body: some View {
        if let item = items.first(where: { $0.id == model.selection }) {
            @Bindable var item = item
            Form {
                TextField("Title", text: $item.title)
                Toggle("Starred", isOn: $item.isStarred)
                TextField("Notes", text: $item.notes, axis: .vertical)
                    .lineLimit(4...)
            }
            .navigationTitle(item.title)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ContentUnavailableView("No Selection", systemImage: "sidebar.right")
        }
    }
}
