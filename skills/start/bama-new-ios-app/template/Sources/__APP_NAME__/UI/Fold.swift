import SwiftUI

extension View {
    /// Reports this view's width and, on an open iPhone Duo (iOS 27.1), the
    /// fold's frame in this view's coordinates, margins included. The fold
    /// is nil when the screen has none: a closed Duo, any other iPhone, or
    /// iOS 27.0.
    func readsFold(width: Binding<CGFloat>, fold: Binding<CGRect?>) -> some View {
        modifier(FoldReader(width: width, fold: fold))
    }
}

private struct FoldReader: ViewModifier {
    @Binding var width: CGFloat
    @Binding var fold: CGRect?

    func body(content: Content) -> some View {
        let measured = content.onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        if #available(iOS 27.1, *) {
            measured.onGeometryChange(for: CGRect?.self) { proxy in
                proxy.reservedRegions(kind: .division).first(where: \.isActive)?.frame
            } action: { fold = $0 }
        } else {
            measured
        }
    }
}
