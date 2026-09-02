import SwiftUI

/// Original public search field API.
public struct SearchField<S: SearchProtocol>: View {
    private let titleKey: LocalizedStringKey
    @Binding private var searching: S

    public init(_ titleKey: LocalizedStringKey = "Search", searching: Binding<S>) {
        self.titleKey = titleKey
        self._searching = searching
    }

    public var body: some View {
        TextField(titleKey, text: $searching.text)
            .oneLiner()
#if !os(watchOS)
            .autocapitalization(.none)
#endif
            .disableAutocorrection(true)
            .padding(8)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        style: StrokeStyle(
                            lineWidth: searching.isEmpty ? 0 : 2,
                            lineCap: .round,
                            dash: [6, 3]
                        )
                    )
                    .foregroundStyle(searching.isEmpty ? Color.clear : Color.blue)
            )
    }
}

