#if !os(watchOS)
import SwiftUI
import UIKit
import SwiftData

public struct PhotoDisplayView<Source: PhotoSource>: View {
	var source: Source
	let showMenu: Bool
	
	public init(source: Source, showMenu: Bool = true) {
		self.source = source
		self.showMenu = showMenu
	}
	
	public var body: some View {
		ZStack(alignment: .topTrailing) {
			source.displayView
			if showMenu {
				PhotoImportMenu(image: Binding {
					source.photoImage
				} set: {
					source.photoImage = $0
				})
				.padding(6)
				.background(
					RoundedRectangle(cornerRadius: 10, style: .continuous)
						.fill(.thinMaterial)
				)
				.overlay(
					RoundedRectangle(cornerRadius: 10, style: .continuous)
						.stroke(.secondary.opacity(0.2), lineWidth: 1)
				)
				.shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
				.padding(8)
			}
		}
	}
}
#endif
