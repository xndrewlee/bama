# iPhone Duo patterns and code

The pattern names follow the duology skills by kimeur
(github.com/Kimeur/duology). The code is BAMA's, written for the
`bama-new-ios-app` template (`readsFold`, `FoldSplit`, and
`measuresWindow` are in its `UI/Fold.swift`), and
builds against the iOS 27.1 SDK with an iOS 27.0 deployment target.

## Pick a pattern

Start from the system containers. Reach for a custom layout only when they
cannot show the content.

| Pattern | What it is | Use it for |
| --- | --- | --- |
| List-detail | `NavigationSplitView`, list beside detail when open | items whose detail stands on its own: mail, notes, tasks |
| Tabs to sidebar | `TabView` that turns into a sidebar on the inner display | a few separate areas of the app; try this first |
| Supporting pane | `ArrangementView` split beside the main view, a sheet when closed | a second view that only makes sense next to the first: comments, a transcript |
| Two-page | a custom split on the fold's frame | paged content: books, slides, a spread |
| Dual view | the same data two ways side by side, on one model | a list and a map, a table and a chart |
| Extended canvas | one full-size surface, tools placed away from the fold | drawing, maps, photo editing |
| Feed reflow | a grid whose column count follows the width, even when open | a grid of equal items: photos, products |
| Displacement | a custom control near the middle moves a little to one side | any screen with a floating control near the center |

Never nest `ArrangementView` and `NavigationSplitView` in either
direction. For a pane beside list-detail, use `.inspector`.

## Size classes

```swift
struct SizeClassExample: View {
    @Environment(\.horizontalSizeClass) private var width

    var body: some View {
        if width == .regular {
            HStack { Text("List"); Text("Detail") }
        } else {
            Text("List")
        }
    }
}
```

## List-detail split on the fold

From the template's `ContentView.swift`: start with list and detail
showing, and give the list the leading half, or exactly up to the fold.

```swift
NavigationSplitView(columnVisibility: $model.columns, preferredCompactColumn: $model.compactColumn) {
    sidebar
} content: {
    ItemList(page: model.sidebar ?? .all)
        .navigationSplitViewColumnWidth(listWidth)
} detail: {
    ItemDetail()
}
.readsFold(frame: $frame, fold: $fold)

private var listWidth: CGFloat {
    let split = FoldSplit(fold: fold, frame: frame, window: window)
    return max(320, (split.isVertical ? split.x : frame.width / 2).rounded())
}
```

Flat or half folded, the list gets the same width, so nothing jumps as the
Duo folds. Flat, a real Duo floats the list over the detail; half folded,
it tiles them.

## Two pages

```swift
struct TwoPages<Leading: View, Trailing: View>: View {
    @ViewBuilder var leading: Leading
    @ViewBuilder var trailing: Trailing
    @Environment(\.windowSize) private var window
    @State private var frame: CGRect = .zero
    @State private var fold: CGRect?

    var body: some View {
        let split = FoldSplit(fold: fold, frame: frame, window: window)
        HStack(spacing: split.gap) {
            leading.frame(width: max(0, split.x - split.gap / 2))
            trailing.frame(maxWidth: .infinity)
        }
        .readsFold(frame: $frame, fold: $fold)
    }
}
```

To spread a detail over both pages, hide the list from a button:
`columnVisibility = .detailOnly`. Set in the first `.task`, it does not hold:
the split view resets its columns during its first layout.

A `List` or `ScrollView` page keeps no margin on its fold side, so its cards
run into the fold and meet the other page's cards at the center. Give each
page a margin there. Half folded, the gap between the pages shows what is
behind them, a white stripe beside grouped lists, so give the pages their
background too:

```swift
TwoPages {
    List { BookCard(book: book) }
        .contentMargins(.trailing, 20, for: .scrollContent)
} trailing: {
    List { NotesSection(book: book) }
        .contentMargins(.leading, 20, for: .scrollContent)
}
.background(Color(.systemGroupedBackground))
```

Check it with layout probes: `.gridArea("left-page")` on each page writes its
frame to the snapshot's layout file, so you can see where the pages meet.

## Tabs to sidebar

```swift
TabView {
    Tab("Library", systemImage: "books.vertical") { LibraryView() }
    Tab("Reading", systemImage: "book") { ReadingView() }
}
.tabViewStyle(.sidebarAdaptable)
.defaultTabBarPlacement(.sidebar)
```

## Supporting pane

`ArrangementView` is iOS 27.1. On 27.0, show the pane as a sheet.

```swift
if #available(iOS 27.1, *) {
    ArrangementView {
        ChapterView()
    } secondary: {
        NotesView()
    }
    .arrangementViewStyle(.split.axes(.horizontal))
} else {
    ChapterView()
        .sheet(isPresented: $showNotes) { NotesView() }
}
```

`.split` tiles the two views and moves them off the fold; `.overlay` floats
the secondary over the primary.

## Vertical toolbars

```swift
@available(iOS 27.1, *)
struct EditorView: View {
    @Environment(\.toolbarVerticalEdge) private var barEdge   // nil: the bar is horizontal

    var body: some View {
        Text("Editor")
            .padding(barEdge == .leading ? .trailing : .leading, 16)
    }
}
```

Opt one screen out with `.toolbarVerticalBehavior(.disabled)`.

## A sheet beside the content

```swift
.sheet(isPresented: $show) {
    FiltersView()
        .presentationPlacement(.leading)
}
```

## Hinge angle, for an effect

```swift
let cover = Text("Cover").opacity(opening)
if #available(iOS 27.1, *) {
    cover.onHingeChange { _, new in
        guard let hinge = new.hinge else { return }
        opening = min(1, hinge.angle.degrees / 180)
    }
} else {
    cover
}
```

## Concentric corners

```swift
Text("Now Playing")
    .padding(16)
    .background(.thinMaterial, in: ConcentricRectangle())
    .padding(8)
    .containerShape(RoundedRectangle(cornerRadius: 24))
```

## Safe areas, one side at a time

```swift
GeometryReader { proxy in
    Text("Page")
        .padding(.leading, proxy.safeAreaInsets.leading + 16)
        .padding(.trailing, proxy.safeAreaInsets.trailing + 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.indigo.opacity(0.2).ignoresSafeArea())
}
```

## UIKit bridge

Inside a `UIViewRepresentable` or `UIViewControllerRepresentable`, the
same rules apply through UIKit's names.

```swift
final class FoldAwareView: UIView {
    var foldFrame: CGRect? {
        guard #available(iOS 27.1, *) else { return nil }
        return reservedRegions(kind: .division).first(where: \.isActive)?.frame
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Lay out two pages around foldFrame, or split bounds in half.
    }
}

final class HingeViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 27.1, *) {
            let interaction = UIHingeInteraction { [weak self] _, update in
                guard let hinge = update.hinge else { return }
                self?.view.alpha = hinge.status == .closed ? 0.5 : 1
            }
            view.addInteraction(interaction)
        }
    }

    // Instead of UIScreen.main:
    var screenScale: CGFloat { traitCollection.displayScale }
    var screen: UIScreen? { view.window?.windowScene?.screen }
}
```

UIKit names for the rest: `UIArrangementViewController` (supporting pane),
`tabBarController.sidebar.preferredPlacement = .sidebar` (tabs to sidebar),
`UISheetPresentationController.preferredPlacement` (sheet beside the
content), `verticalBarEdge` (which side the bar is on), and
`UICornerConfiguration` (concentric corners).
