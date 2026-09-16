#if !os(watchOS)
import SwiftUI

typealias ShareItems = (activityItems: [Any], applicationActivities: [UIActivity]?)

struct ShareButtonOld: View {
	let noun: String
	let items: ()->ShareItems
	let appear: (()->())?
	let dismissed: (()->())?

	@State private var showingShareSheet = false
	@State private var cache: ShareItems? = nil

	public init(
		_ noun: String,
		items: @escaping ()->ShareItems,
		appear: (()->())? = nil,
		dismissed: (()->())? = nil) {
		self.noun = noun
		self.items = items
		self.appear = appear
		self.dismissed = dismissed
	}

	public var body: some View {
		ActionButton("Share \(noun)", image: .system("square.and.arrow.up")) {
			cache = items()
			appear?()
			self.showingShareSheet.toggle()
		}
		//TODO: if button is transitory this will never show
		.sheet(isPresented: $showingShareSheet, onDismiss: {
			cache = nil
			dismissed?()
		}) {
			let p = cache ?? items()
			ShareSheet(activityItems: p.activityItems, applicationActivities: p.applicationActivities, dismissed: nil)
		}
	}
}
#endif
