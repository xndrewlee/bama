import SwiftUI

extension EnvironmentValues {
    /// The window's size, safe areas included. Set once at the root with
    /// `measuresWindow()`.
    @Entry var windowSize: CGSize = .zero
}

extension View {
    /// Measures the window and hands its size down as `windowSize`. Put it
    /// on the scene's root view.
    func measuresWindow() -> some View {
        modifier(WindowMeasure())
    }

    /// Reports this view's frame in the window and, on an open iPhone Duo
    /// (iOS 27.1), the fold's frame in this view's coordinates, margins
    /// included. The fold is nil when the screen has none: a closed or flat
    /// Duo, any other iPhone, or iOS 27.0.
    func readsFold(frame: Binding<CGRect>, fold: Binding<CGRect?>) -> some View {
        modifier(FoldReader(frame: frame, fold: fold))
    }
}

/// Where to split a view into two halves, in the view's own coordinates:
/// on the fold when the Duo reports one, and otherwise at the middle of the
/// window, which is where a flat Duo folds. Not the middle of the view:
/// side toolbars and safe areas push the view off center.
struct FoldSplit {
    var fold: CGRect?
    var frame: CGRect
    var window: CGSize

    /// A fold that runs top to bottom: the Duo held like a book.
    var isVertical: Bool { fold.map { $0.height > $0.width } ?? (window.width > window.height) }
    var x: CGFloat { fold?.midX ?? (window.width / 2 - frame.minX) }
    var y: CGFloat { fold?.midY ?? (window.height / 2 - frame.minY) }
    /// The fold's width across the split, margins included; 0 when flat.
    var gap: CGFloat { fold.map { isVertical ? $0.width : $0.height } ?? 0 }
}

private struct WindowMeasure: ViewModifier {
    @State private var size: CGSize = .zero

    func body(content: Content) -> some View {
        content
            .environment(\.windowSize, size)
            .background {
                // Measured inside ignoresSafeArea: outside it, the size stops
                // at the safe area, and a flat Duo keeps 84 pt on the right.
                Color.clear
                    .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
                    .ignoresSafeArea()
            }
    }
}

private struct FoldReader: ViewModifier {
    @Binding var frame: CGRect
    @Binding var fold: CGRect?

    func body(content: Content) -> some View {
        let measured = content.onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame = $0 }
        if #available(iOS 27.1, *) {
            measured.onGeometryChange(for: CGRect?.self) { proxy in
                proxy.reservedRegions(kind: .division).first(where: \.isActive)?.frame
            } action: { fold = $0 }
        } else {
            measured
        }
    }
}
