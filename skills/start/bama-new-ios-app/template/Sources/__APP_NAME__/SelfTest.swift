import Foundation
import SwiftData
import __APP_NAME__Kit

/// Self-test for agents: runs the app's real functions on a test store,
/// prints PASS or FAIL per check, and quits with exit code 0 or 1.
/// tools/selftest.sh launches it on the simulator with --selftest and
/// APP_STORE in /tmp. Add a check for every story with logic.
@MainActor
enum SelfTest {
    static var requested: Bool { CommandLine.arguments.contains("--selftest") }
    private static var failures = 0
    private static var count = 0

    static func runIfRequested(model: AppModel) {
        guard requested else { return }
        // Print each line at once, so a crash keeps the lines before it.
        setvbuf(stdout, nil, _IOLBF, 0)
        guard Store.isOverridden else {
            print("SELFTEST refused: set APP_STORE to a file in /tmp")
            exit(1)
        }
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            let context = model.container.mainContext
            func items() -> [Item] { (try? context.fetch(FetchDescriptor<Item>())) ?? [] }

            let before = items().count
            model.addItem()
            check("New Item adds one item", items().count == before + 1)
            check("the new item is selected", model.selection != nil)

            if let item = items().first(where: { $0.id == model.selection }) {
                item.isStarred.toggle()
                check("starring an item marks it starred", item.isStarred)
                context.delete(item)
                try? context.save()
                check("deleting the item removes it", items().count == before)
            }
            check("titles are cleaned", ItemTitle.clean("  Buy   milk ") == "Buy milk")

            print(failures == 0 ? "SELFTEST PASS \(count) checks" : "SELFTEST FAIL \(failures) of \(count) checks")
            // An iPhone app never quits itself, except in this test mode.
            exit(failures == 0 ? 0 : 1)
        }
    }

    private static func check(_ name: String, _ ok: Bool, _ detail: String = "") {
        count += 1
        if !ok { failures += 1 }
        print(ok ? "PASS \(name)" : "FAIL \(name)\(detail.isEmpty ? "" : ": \(detail)")")
    }
}
