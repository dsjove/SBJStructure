import SwiftUI
import Testing
@testable import SBJFoundation

@Suite("Shared UI API")
struct SharedUIAPITests {
    @MainActor
    @Test func imageNameInitializersRetainEstablishedSurface() {
        _ = Image(.system("star"))
        _ = Image(.bundled("logo"))
        _ = Label("Favorite", image: .system("star"))
    }

    @MainActor
    @Test func applyIfRetainsEstablishedSurface() {
        _ = Text("Value").applyIf("Label") { view, label in
            view.accessibilityLabel(label)
        }
    }

    @MainActor
    @Test func pendingAlertViewModifierRetainsEstablishedSurface() {
        _ = Text("Value").pendingAlert(Binding<PendingAlert?>.constant(nil))
    }

    @MainActor
    @Test func accessibleViewModifierRetainsEstablishedSurface() {
        let item: any Accessible = AccessibleItem(
            label: "Name",
            hint: "Enter a name",
            value: "Current"
        )
        _ = Text("Name").accessibility(item)
        _ = Text("Name").accessibility(label: "Name", hint: "Hint", value: "Value")
    }
}
