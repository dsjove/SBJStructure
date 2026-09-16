#if !os(watchOS)
import SwiftUI

public struct ImageTransformPreview: View {
	private let image: UIImage?
	private let transform: CroppingState
	private let opacity: Double
	private var presentCrop: Bool { opacity > 0.0 }

	public init(image: UIImage?, transform: CroppingState, opacity: Double = 0.4) {
		self.image = image
		self.transform = transform
		self.opacity = opacity
	}

	public var body: some View {
		ZStack {
			Color(.systemBackground).ignoresSafeArea()
			if let image {
				if presentCrop {
					Image(uiImage: image)
						.geometryEffect(transform, clip: false)
						.opacity(opacity)
					Image(uiImage: image)
						.geometryEffect(transform, clip: true)
				} else {
					Image(uiImage: image)
						.geometryEffect(transform, clip: false)
				}
			} else {
				Image(systemName: "photo")
					.foregroundStyle(.primary)
					.font(.largeTitle)
			}
			if presentCrop {
				Rectangle()
					.path(in: transform.crop)
					.stroke(style: StrokeStyle(lineWidth: 2, dash: [10]))
					.foregroundColor(.primary)
			}
		}
	}
}
#endif
