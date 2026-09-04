import Foundation

public extension Error {
	func printAsNSError() {
		let nsError = self as NSError
		print("• error: \(self)")
		print("• code: \(nsError.code)")
		print("• domain: \(nsError.domain)")
		print("• userInfo: \(nsError.userInfo)")
		print("• description: \(nsError.localizedDescription)")
		print("• reason: \(nsError.localizedFailureReason ?? "")")
		print("• options: \(nsError.localizedRecoveryOptions ?? [])")
		print("• suggestion: \(nsError.localizedRecoverySuggestion ?? "")")
	}
}

public extension ProcessInfo {
	static var isRunningOnAnyMac: Bool {
		#if os(macOS)
		return true
		#else
		let info = ProcessInfo.processInfo
		return info.isMacCatalystApp || info.isiOSAppOnMac
		#endif
	}
}
