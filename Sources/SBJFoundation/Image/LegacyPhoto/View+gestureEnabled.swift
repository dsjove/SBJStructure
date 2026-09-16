import SwiftUI

struct EnableGestureModifier<G: Gesture>: ViewModifier {
	let enabled: Bool
	let gesture: G

	public func body(content: Content) -> some View {
		if enabled {
			content.gesture(gesture)
		} else {
			content
		}
	}
}

extension View {
	func gesture<G: Gesture>(enabled: Bool, _ gesture: G) -> some View {
		self.modifier(EnableGestureModifier(enabled: enabled, gesture: gesture))
	}
}
