import SwiftUI

/// Two pages that meet at the iPhone Duo's fold, or at the middle without
/// one. From bama-ios-duo-design, patterns.md ("Two pages").
/// A List or ScrollView page keeps no margin on its fold side by itself:
/// give it `.contentMargins(.trailing or .leading, Space.xl, for: .scrollContent)`
/// so its cards end before the fold.
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
