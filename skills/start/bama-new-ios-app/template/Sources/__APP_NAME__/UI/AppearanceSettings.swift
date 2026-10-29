import SwiftUI

/// Settings > Appearance: the accent color. Light and dark mode follow the iPhone.
struct AppearanceSettings: View {
    @Bindable private var store = ThemeStore.shared

    var body: some View {
        Section {
            AccentPreview()
                .padding(.vertical, Space.xs)
        }
        Section {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: Space.sm)], spacing: Space.sm) {
                ForEach(Theme.all) { theme in
                    AccentSwatch(theme: theme, selected: store.themeID == theme.id) {
                        store.themeID = theme.id
                    }
                }
            }
            .padding(.vertical, Space.xs)
        } header: {
            Text("Accent Color")
        } footer: {
            Text(store.theme.name)
        }
    }
}

/// A small sample in the chosen accent: two tasks, a tag, a button, and a
/// switch. It redraws as people pick a color. Swap the sample words for
/// ones from this app.
private struct AccentPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text("Inbox").font(.headline)
                Spacer()
                Text("1 left").font(.caption).foregroundStyle(Palette.accentText)
            }
            task("Pick a color", done: true)
            task("Ship the first build", done: false, tag: "Today")
            // Drawn, not real controls: the preview is a picture.
            HStack {
                Label("Add Task", systemImage: "plus")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(Palette.onAccent)
                    .padding(.horizontal, Space.md)
                    .frame(height: 32)
                    .background(Palette.accent, in: Capsule())
                Spacer()
                Text("Focus").font(.caption).foregroundStyle(.secondary)
                Capsule()
                    .fill(Palette.accent)
                    .frame(width: 44, height: 24)
                    .overlay(alignment: .trailing) {
                        Circle().fill(.white).padding(2).shadow(color: .black.opacity(0.2), radius: 1, y: 1)
                    }
            }
            .padding(.top, Space.xs)
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Preview of the accent color")
    }

    private func task(_ title: String, done: Bool, tag: String? = nil) -> some View {
        HStack(spacing: Space.sm) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(done ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary))
            Text(title)
                .strikethrough(done)
                .foregroundStyle(done ? .secondary : .primary)
            Spacer()
            if let tag {
                Text(tag)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Palette.accentText)
                    .padding(.horizontal, Space.sm)
                    .padding(.vertical, 2)
                    .background(Palette.accent.opacity(0.15), in: Capsule())
            }
        }
        .font(.callout)
    }
}

/// One color dot with a 44 pt touch target.
private struct AccentSwatch: View {
    let theme: Theme
    let selected: Bool
    let choose: () -> Void

    var body: some View {
        Button(action: choose) {
            Circle()
                .fill(fill)
                .frame(width: 28, height: 28)
                .overlay {
                    if selected {
                        Circle().fill(theme.onAccent).frame(width: 12, height: 12)
                    }
                }
                .overlay(Circle().strokeBorder(.primary.opacity(0.15), lineWidth: 1))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(theme.name)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    /// "System" shows the brand color, or iOS blue.
    private var fill: Color {
        theme.tint ?? ThemeStore.brand?.tint ?? .blue
    }
}
