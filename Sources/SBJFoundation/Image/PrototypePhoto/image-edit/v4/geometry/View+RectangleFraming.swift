import SwiftUI
import UIKit

//MARK: Gesture

public struct RectangleFramingGestureModifier: ViewModifier {
	private let model: RectangleFraming
	private let enabled: Bool
	private let minScale: CGFloat = 1.0
	private let maxScale: CGFloat = 8.0

	@State private var lastScale: CGFloat = 1.0
	@State private var lastOffset: CGSize = .zero

	init(model: RectangleFraming, enabled: Bool) {
		self.model = model
		self.enabled = enabled
	}

	public func body(content: Content) -> some View {
		content
			.contentShape(Rectangle())
			.onAppear {
				lastScale = model.magnify
				lastOffset = model.containedOffset
			}
			.onChange(of: model.magnify) { _, newValue in
				lastScale = newValue
				lastOffset = model.containedOffset
			}
			.gesture(enabled: enabled, transformGestures(model))
	}

	private func transformGestures(_ model: RectangleFraming) -> some Gesture {
		let drag = DragGesture()
			.onChanged { self.onDrag($0) }
			.onEnded { _ in self.endDrag() }
		let pinch = MagnificationGesture()
			.onChanged { self.onMagnifyChanged($0) }
			.onEnded { _ in self.onMagnifyEnded() }
		let doubleTap = TapGesture(count: 2)
			.onEnded { model.resetPosition() }
		return SimultaneousGesture(
			SimultaneousGesture(drag, pinch),
			doubleTap
		)
	}

	private func onDrag(_ value: DragGesture.Value) {
		let value = value.translation
		let test = CGSize(width: lastOffset.width + value.width, height: lastOffset.height + value.height)
		model.containedOffset = test
	}

	private func endDrag() {
		lastOffset = model.containedOffset
	}

	private func onMagnifyChanged(_ raw: CGFloat) {
		let test = lastScale * raw
		if test < minScale {
			model.magnify = minScale
		}
		else if test > maxScale {
			model.magnify = maxScale
		} else {
			model.magnify = test
		}
	}

	private func onMagnifyEnded() {
		lastScale = model.magnify
	}
}

public extension View {
	func gesture(_ model: RectangleFraming, enabled: Bool) -> some View {
		modifier(RectangleFramingGestureModifier(model: model, enabled: enabled))
	}
}

private extension Comparable {
	func clamped(to r: ClosedRange<Self>) -> Self { min(max(self, r.lowerBound), r.upperBound) }
}

//MARK: View Modifier

public struct RectangleFramingModifier: ViewModifier {
	let model: RectangleFraming
	let clip: Bool

	public func body(content: Content) -> some View {
		content
			.frame(width: model.positionedSize.width, height: model.positionedSize.height)
			.scaleEffect(x: model.mirror.horizontal ? -1 : 1, y: model.mirror.vertical ? -1 : 1)
			.scaleEffect(model.magnify)
			.rotationEffect(model.rotation)
			.offset(model.containedOffset)
	}
}

public extension View {
	func apply(_ model: RectangleFraming, clip: Bool = false) -> some View {
		modifier(RectangleFramingModifier(model: model, clip: clip))
	}
}

//MARK: Diagram

public struct RectangleFramingDiagram: View {
	let model: RectangleFraming
	public var body: some View {
		ZStack {
		// Background
			Color.gray.opacity(0.25).ignoresSafeArea()
		// Guides
			Path { path in
				path.addRect(model.containerRect)
			}
			.stroke(Color.blue.opacity(1.0), lineWidth: 5)
			Path { path in
				path.addRect(model.frameRect)
			}
			.stroke(Color.red.opacity(1.0), lineWidth: 3)
		// Framed Structure
			Path { path in
				let pts = model.framePoints
				path.move(to: pts[0])
				for p in pts.dropFirst() {
					path.addLine(to: p)
				}
				path.closeSubpath()
				let bounds = path.boundingRect
				let point = pts[model.mirror.idx]
				let size = (model.frameSize.width + model.frameSize.height) / 20
				path.addEllipse(in: CGRect(
					origin: CGPoint(x: point.x - size/2, y: point.y - size/2),
					size: CGSize(width: size, height: size)))
				let offsetX = model.containerSize.width / 2 - bounds.midX
				let offsetY = model.containerSize.height / 2 - bounds.midY
				path = path.offsetBy(dx: offsetX, dy: offsetY)
			}
			.stroke(Color.green.opacity(0.9), style: StrokeStyle(lineWidth: 2))
		// Positioned Shadow
			Path { path in
				let pts = model.positionedPoints
				guard pts.count == 4 else { return }

				path.move(to: pts[0])
				for p in pts.dropFirst() {
					path.addLine(to: p)
				}
				path.closeSubpath()
				let bounds = path.boundingRect
				let dragged = model.containedOffset
				let offsetX = model.containerSize.width / 2 - bounds.midX + dragged.width
				let offsetY = model.containerSize.height / 2 - bounds.midY + dragged.height
				path = path.offsetBy(dx: offsetX, dy: offsetY)
			}
			.fill(Color.green.opacity(0.2))
		// Source Info
			VStack {
				Text("Source").italic()
				Text("\(Int(model.sourceSize.width))x\(Int(model.sourceSize.height))")
				Text("\(Int(model.rotation.degrees.rounded()))° \(model.sourceMode.description)")
				Text("\(Int(model.sourceRect.minX))  \(Int(model.sourceRect.minY))  \(Int(model.sourceRect.width))  \(Int(model.sourceRect.height))")
			}
		}
		.allowsHitTesting(false)
	}
}
