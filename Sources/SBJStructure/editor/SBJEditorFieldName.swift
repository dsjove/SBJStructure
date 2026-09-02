import Foundation
import SwiftUI

struct SBJEditorFieldName: View {
    let text: String
    let isUnknown: Bool

    var body: some View {
        HStack(spacing: 5) {
            SBJEditorChangeIndicator()
            SBJEditorEmptyContentIndicator()
            if isUnknown {
                Text(text)
                    .fontWeight(.semibold)
                    .italic()
            } else {
                Text(text)
            }
        }
    }
}

