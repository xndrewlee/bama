---
name: bama-ios-duo-design
description: Design rules for a SwiftUI iPhone app on iPhone Duo and every other iPhone, from size classes and poses to the fold, navigation, sheets, asymmetric safe areas, corners, and a second display. Use when building or reviewing any iPhone screen, when a pose snapshot fails, or when the user asks for a better iPhone or Duo layout.
---

# iPhone and iPhone Duo design

Design for a range of sizes, not for devices. The same app runs closed on
the 5.4-inch outer display, open on the 7.6-inch inner display, half
folded, in Split View, and on every other iPhone. The system's containers
already adapt to all of them. Use them, and let size classes decide the
rest.

- Copyable SwiftUI and UIKit code, and the pattern catalog:
  [patterns.md](patterns.md). Every snippet builds against the iOS 27.1 SDK.
- Checking the result in every pose: call the Skill tool with
  `bama-build-and-verify-ios`.
- Tokens, spacing, how a feature works and what it says: call the Skill
  tool with `bama-design-system`, `bama-layout-grid`, or `bama-ux-design`.

Sources: Apple's iPhone Duo talks and the "Designing for iPhone Duo" HIG
page, the duology skills by kimeur, and measurements from the iPhone Duo
simulator in Xcode 27.1 and a real iPhone Duo on iOS 27.2. Every API here
was checked against the SDK.

## 1. Sizes, not devices

- Lay out from `@Environment(\.horizontalSizeClass)` and the view's own
  size. Never from the device model, the idiom, the orientation, or
  `UIScreen.main`.
- Every fold, unfold, rotation, and Split View change resizes the app.
  Keep the selection, the scroll position, and the text being typed.
- The inner display ignores the app's supported orientations.
- The app targets iOS 27.0 and builds with the 27.1 SDK. The Duo APIs
  below are 27.1: put them behind `if #available(iOS 27.1, *)` with a
  27.0 fallback.

## 2. Poses

| Pose (story word) | Display | Points | Width / height class | The person is | Design for |
| --- | --- | --- | --- | --- | --- |
| `outer` | outer, portrait | 466 x 678 | compact / regular | using one hand, quick tasks | one column; actions in thumb reach |
| outer, rotated | outer, landscape | 678 x 466 | compact / compact | watching, typing | short screen; keep the key action visible |
| `inner-landscape` | inner, held like a book | 951 x 669 | regular / regular | reading, comparing | one more level of hierarchy: list and detail, two pages |
| `inner` | inner, rotated | 669 x 951 | regular / regular | reading long content | a split stacks top and bottom |
| `tabletop` | inner, half folded on a table | 669 x 951, fold across | regular / regular | on a call, watching | media on the top half, controls on the stable bottom half |
| `tent` | outer, landscape, standing on its edges | 678 x 466 | compact / compact | watching from a distance | landscape media, large targets |
| `splitview-left`, `splitview-right` | half the inner display | 475 x 669 | compact / regular | using two apps | one column; system buttons on the outer edge |

Do not build one layout per pose. An optional tabletop layout keeps every
control and the same hierarchy. User stories name the poses they were
checked in with the words in the first column.

## 3. Navigation

- **List and detail: `NavigationSplitView`.** Closed, it is one stack.
  Open, it shows the list and the detail side by side, with the split on
  the fold (the template's `ContentView.swift`). At 669 pt wide iOS may lay
  the list over a dimmed detail, and so does a real Duo lying flat at any
  width, `.balanced` style or not; half folded, it tiles them on the fold.
  All of that is fine. A regular width that shows
  only an empty detail, with the list behind a button, is not: start with
  `columnVisibility` at `.doubleColumn`.
- **A few separate areas: `TabView`.** With `.tabViewStyle(.sidebarAdaptable)`
  and `.defaultTabBarPlacement(.sidebar)`, the tab bar becomes a sidebar on
  the inner display. Up to five tabs, one-word labels, an SF Symbol each.
  Tabs navigate; they never act. The sidebar lists the same pages in the
  same order.
- **Bars go vertical.** In every pose except the inner display in
  portrait, the navigation and toolbar buttons stack along one side. From
  the top: Back or Close (`.cancellationAction`), then the one prominent
  action (`.topBarPinnedTrailing`). Give every item a title even when it
  shows only a symbol. Only a split view's detail column gets a vertical
  bar. Read the side with `@Environment(\.toolbarVerticalEdge)`; turn it
  off with `.toolbarVerticalBehavior(.disabled)` only when a bar must stay
  horizontal.
- **Search.** On the closed Duo, `.searchable` in its default placement
  showed no field at all. When search is one of the page's jobs, use
  `.searchable(text:placement: .navigationBarDrawer(displayMode: .always))`:
  the field stays under the title in every pose.
- **Sheets.** One task per sheet: Cancel leading, Done or Save trailing,
  medium and large detents. On the outer display a sheet keeps its bar on
  top, and a long form scrolls Cancel and Save away with it: put the fields
  people fill first at the top, and keep the form short. On the inner
  display sheets center; half folded, the system slides them off the fold. `.presentationPlacement(.leading)`
  puts a sheet beside the content instead of over it.

## 4. The fold

The fold is a reserved region of kind `.division`. Half folded, it is a
40 pt band (margins included) across the middle of the inner display's
long side. Flat, there is no region at all, and the fold is the middle of
the window. Read it with `GeometryProxy.reservedRegions(kind: .division)`;
the template wraps both cases in `FoldSplit` (`UI/Fold.swift`):

```swift
@Environment(\.windowSize) private var window   // from measuresWindow() on the root view
@State private var frame: CGRect = .zero
@State private var fold: CGRect?   // nil: closed, flat, another iPhone, or iOS 27.0

content.readsFold(frame: $frame, fold: $fold)
let split = FoldSplit(fold: fold, frame: frame, window: window)
// split.x, split.y: where to split, in this view's coordinates
// split.gap: the band to keep clear, 0 when flat
```

Flat, the Duo is one wide screen, and people expect it to look like one:
a grid runs evenly across it, and a player takes more room than its chat.
Split into halves only when the fold region appears, as the Duo starts to
fold. The template's `TwoPages` does both: `flatShare` sets the leading
page's width while there is no fold. A split that must sit where a flat Duo
folds measures from the window's middle, not the view's: a sidebar, a
toolbar, or the 84 pt system column pushes the view off center. Measure
the window inside `.ignoresSafeArea()`. Outside it, a flat Duo's window
measures 867 x 635, and its middle misses the fold by 42 pt.

1. **Keep fixed things off it.** Controls, titles, and faces in photos
   never sit on the fold band. Scrolling content may pass over it; never
   move scrolling content to dodge it.
2. **Split on it once it folds.** Half folded, two equal columns meet at
   the fold. A grid uses an even number of columns, with extra space at the
   fold. Held like a book, the 84 pt system column makes the right page
   narrower: give both pages the narrower width and put the rest at the
   fold, or the right page's cards come out smaller. A screen built around
   one centered group (a timer, a player) gives each half one part, left
   and right when held like a book, top and bottom on a table. Flat, there
   is no fold to meet: lay the screen out as one.
3. **Move a little.** A custom control near the middle shifts to one side,
   alone or with its group. The rest of the screen stays put.
4. **Let the system move its own parts.** Sheets, alerts, menus, and
   toolbar buttons move off the fold by themselves.
5. **The hinge angle is for effects.** `onHingeChange` (SwiftUI) and
   `UIHingeInteraction` (UIKit) may drive an animation, never a layout.
6. **Occlusions.** Regions of kind `.occlusion` mark what covers the screen.
   On the closed Duo: the front camera, a 37 pt circle at the top right,
   and the 84 pt system column down the right edge. Custom edge-to-edge UI
   reads them.

The layout patterns for the fold (list-detail, supporting pane, two-page,
dual view, extended canvas, feed reflow, tabs to sidebar, displacement)
are in [patterns.md](patterns.md).

## 5. Safe areas

- Foreground content stays inside the safe area. Backgrounds run past it
  with `.ignoresSafeArea()` or `.backgroundExtensionEffect()`.
- Insets are not symmetric. The closed Duo in portrait measures 0 top,
  0 leading, 34 bottom, and 84 trailing, and so does the open Duo held like
  a book. Pad each side from its own inset.
  Never compute `width - insets.leading * 2`.
- In Split View the system buttons sit on the app's outer edge, so the app
  on the left and the app on the right get different insets. Check both.
- Touch targets are at least 44 by 44 points, 8 points apart.

## 6. Corners and Liquid Glass

- A card or control near a screen corner uses `ConcentricRectangle()`
  (UIKit: `UICornerConfiguration`), so its corner follows the screen's and
  the container's. The outer display's left corners are nearly square and
  its right corners round, so a fixed radius looks wrong on one side.
- Liquid Glass works as on the Mac (`bama-mac-design`): glass belongs to
  floating controls, never to content. Bars get glass by themselves; give
  them no custom background. One prominent button per bar.
- What does not carry over from the Mac: menu bar commands, window chrome,
  hover, and pointer-sized targets.

## 7. Two displays and scenes

- The Duo runs more than one scene. New windows open only on the inner
  display. Handle a refused scene request. `UIWindowSceneActivationAction`
  hides itself when a new window is not possible.
- Open a second scene only for a second thing the person works on at the
  same time: two documents, a reference beside a draft. Most apps need one.
- `.sceneAccessory { CameraCaptureAccessory { ... } }` shows extra content
  on the other display, like a preview for the person being photographed.
  The system decides when it can show; follow `onAvailabilityChange`.
- Read the screen from the view: `traitCollection.displayScale` and
  `view.window?.windowScene?.screen`, never `UIScreen.main`.

## 8. Text and input

- Text styles only. Labels wrap; stacks turn vertical at accessibility
  sizes; nothing people need is cut off. Check the largest size once per
  milestone: `xcrun simctl ui booted content_size accessibility-extra-extra-extra-large`.
- Every swipe action is also in the context menu, destructive last among
  the app's items (iOS 27 adds Ask Siri after them). Undo
  for every delete.
- With a hardware keyboard: Command-N, Command-F, Delete, Command-Z, and
  arrow keys that move the selection.

## 9. Checklist per story

`bama-improve-loop` runs this for every story with a screen:

- [ ] Layout comes from size classes and the view's size: no idiom,
      orientation, device model, or `UIScreen.main`.
- [ ] Compact widths show one column, with the main action in thumb reach.
- [ ] Regular widths show the list; held like a book, the split is on the fold.
- [ ] Nothing fixed sits on the fold band. Grids use even columns.
- [ ] Each side is padded from its own safe-area inset; backgrounds run to the edges.
- [ ] Every 27.1 API sits behind `#available`, and the iOS 27.0 iPhone looks finished.
- [ ] Targets are 44 pt; the largest text size still fits.
- [ ] The story names its poses, the pose snapshots pass, and the human
      pass is listed.

Done when every item on the checklist holds for the screen, the pose
snapshots show it, and the story lists the poses it was checked in.
