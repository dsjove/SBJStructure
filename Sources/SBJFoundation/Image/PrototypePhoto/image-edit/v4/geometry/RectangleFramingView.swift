import SwiftUI

public struct RectangleFramingView<Content: View>: View {
	let model: RectangleFraming
	let content: () -> Content

	public var body: some View {
		GeometryReader { proxy in
			Color.clear
				.overlay {
					content()
					.frame(
						width: proxy.size.width,
						height: proxy.size.height
					)
				}
				.onAppear {
					model.containerSize = proxy.size
				}
				.onChange(of: proxy.size) { _, newSize in
					model.containerSize = proxy.size
				}
		}
	}
}

#Preview("RectangleFramingView Preview") {
	let model: RectangleFraming = .init(sourceSize: .init(width: 400, height: 200))
	RectangleFramingView(model: model) {
		RectangleFramingDiagram(model: model)
	}
}
