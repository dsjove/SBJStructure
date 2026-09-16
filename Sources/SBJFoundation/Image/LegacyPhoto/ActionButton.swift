import SwiftUI

@MainActor
struct ActionButton : View {
	let item: AccessibleImage
	let action: () -> Void

	public init(
			_ item: AccessibleImage,
			action: @escaping () -> Void) {
		self.item = item
		self.action = action
	}

	public init(
			_ label: String,
			labeled: Bool = false,
			accessibilityLabel: String? = nil,
			image: ImageReference = .none,
			action: @escaping () -> Void) {
		self.init(AccessibleImageItem(image: image, labeled: labeled, label: label, hint: nil, value: nil), action: action)
	}

	public var body: some View {
		Button {
			action()
		} label: {
			if item.image.isEmpty {
				Text(item.label)
					.accessibility(item)
			} else if item.label.isEmpty {
				Label(item.label, image: item.image)
					.labelStyle(.iconOnly)
					.accessibility(item)
			} else if item.labeled {
				Label(item.label, image: item.image)
					.labelStyle(.titleAndIcon)
					.accessibility(item)
			} else {
				Label(item.label, image: item.image)
					.labelStyle(.iconOnly)
					.accessibility(item)
			}
		}
	}
}

@MainActor
@ViewBuilder
func AddButton(_ noun: String, labeled: Bool = false, add: @escaping () -> Void) -> some View {
	ActionButton(
		labeled ? noun : "Add \(noun)",
		labeled: labeled,
		accessibilityLabel: "Add \(noun)",
		image: .system("plus.circle"),
		action: add)
}

@MainActor
@ViewBuilder
func DismissButton(dismiss: @escaping () -> Void) -> some View {
	ActionButton("Dismiss", image: .system("checkmark.circle"), action: dismiss)
}

@MainActor
@ViewBuilder
func CancelButton(canceling: @escaping () -> Void) -> some View {
	ActionButton("Cancel", image: .system("x.circle"), action: canceling)
}

@MainActor
@ViewBuilder
func EditButton(_ noun: String, edit: @escaping () -> Void) -> some View {
	ActionButton("Edit \(noun)", image: .system("pencil"), action: edit)
}
