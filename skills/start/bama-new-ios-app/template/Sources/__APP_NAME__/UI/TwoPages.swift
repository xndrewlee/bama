import SwiftUI

/// Two pages side by side. Half folded, they meet at the iPhone Duo's fold,
/// one page on each half. Flat, the Duo is one wide screen and nothing has
/// to meet in the middle: the leading page takes `flatShare` of the width.
/// From bama-ios-duo-design, patterns.md ("Two pages").
/// A List or ScrollView page keeps no margin on its fold side by itself:
/// give it `.contentMargins(.trailing or .leading, Space.xl, for: .scrollContent)`
/// so its cards end before the fold.
struct TwoPages<Leading: View, Trailing: View>: View {
    /// The leading page's share of the width when there is no fold: a flat
    /// Duo, or iOS 27.0.
    var flatShare: CGFloat = 0.5
    @ViewBuilder var leading: Leading
    @ViewBuilder var trailing: Trailing
    @State private var frame: CGRect = .zero
    @State private var fold: CGRect?

    var body: some View {
        // A fold that runs top to bottom: held like a book, half folded.
        let book = fold.flatMap { $0.height > $0.width ? $0 : nil }
        HStack(spacing: book?.width ?? 0) {
            leading.frame(width: max(0, book?.minX ?? frame.width * flatShare))
            trailing.frame(maxWidth: .infinity)
        }
        .readsFold(frame: $frame, fold: $fold)
    }
}
