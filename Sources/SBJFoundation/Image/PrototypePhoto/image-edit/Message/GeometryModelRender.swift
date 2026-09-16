import SwiftUI
import Observation

extension View {
	@ViewBuilder
	func apply(_ model: GeometryModel, clip: Bool = false) -> some View {
		let transformed = self
			.scaleEffect(model.scale)
			.rotationEffect(model.rotation)
			.scaleEffect(x: model.mirror.horizontal ? -1 : 1, y: model.mirror.vertical ? -1 : 1)
			.offset(model.realizedOffset)
		transformed
			.aspectRatio(contentMode: .fit)
			.frame(width: model.frameSize.width, height: model.frameSize.height)
			.modifier(ConditionalClip(clip: clip))
	}

	func gesture(_ model: GeometryModel, enabled: Bool) -> some View {
		self.gesture(enabled: enabled, transformGestures(model))
	}

	private func transformGestures(_ model: GeometryModel) -> some Gesture {
		let drag = DragGesture()
			.onChanged { model.onDrag($0) }
			.onEnded { _ in model.endDrag() }
		let pinch = MagnificationGesture()
			.onChanged { model.magnify($0) }
			.onEnded { _ in model.endMagnify() }
		let doubleTap = TapGesture(count: 2)
			.onEnded { model.resetZoom() }
		return SimultaneousGesture(
			SimultaneousGesture(drag, pinch),
			doubleTap
		)
	}
}
