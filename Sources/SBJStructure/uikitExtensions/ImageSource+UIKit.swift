#if canImport(UIKit)
import Foundation
import UIKit

public extension ImageSource {
    var image: UIImage? {
        switch self {
        case .none:
            nil
        case .bundled(let name, let bundle):
            UIImage(named: name, in: bundle, compatibleWith: nil)
        case .system(let name):
            UIImage(systemName: name)
        case .file(let url):
            UIImage(url: url)
        }
    }

    var data: Data? {
        image?.pngData()
    }
}
#endif
