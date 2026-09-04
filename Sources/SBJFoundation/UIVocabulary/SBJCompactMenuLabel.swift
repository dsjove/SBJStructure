import SwiftUI

/// Shared compact menu presentation for dense controls.
///
/// The value remains visually compact while the paired up/down chevrons make
/// the menu affordance explicit without requiring a large picker-style control.
@MainActor
public struct SBJCompactMenuLabel: View {
    public let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .lineLimit(1)
            Image(.system("chevron.up.chevron.down"))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}
