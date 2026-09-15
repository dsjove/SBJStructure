import CoreLocation
import Foundation
import Observation

/// Eager Core Location provider intended for clients that need a location
/// immediately at the point of use. It begins authorization/acquisition as soon
/// as it is created and retains the newest valid location as a cache.
@Observable
final class LocationManager: NSObject, LocationProvider, @unchecked Sendable {
	private let manager: CLLocationManager
	private(set) var authorizationStatus: CLAuthorizationStatus
	private(set) var currentLocation: CLLocation?
	let canGetLocation: Bool

	override init() {
		let manager = CLLocationManager()
		self.manager = manager
		self.authorizationStatus = manager.authorizationStatus
		self.currentLocation = Self.validLocation(manager.location)
		self.canGetLocation = CLLocationManager.locationServicesEnabled()
		super.init()

		manager.delegate = self
		manager.desiredAccuracy = kCLLocationAccuracyBest

		// Defer one turn so clients can finish constructing while still beginning
		// authorization/location acquisition at application startup.
		DispatchQueue.main.async { [weak self] in
			self?.requestAccessAndStart()
		}
	}

	@MainActor
	private func requestAccessAndStart() {
		authorizationStatus = manager.authorizationStatus
		if let cached = Self.validLocation(manager.location) {
			accept(cached)
		}

		switch authorizationStatus {
		case .authorizedAlways, .authorizedWhenInUse:
			manager.startUpdatingLocation()
		case .notDetermined:
			manager.requestWhenInUseAuthorization()
		default:
			break
		}
	}

	@MainActor
	func observeAuthorization(
		_ change: @escaping @MainActor (CLAuthorizationStatus) -> Void
	) -> ObserveToken {
		SBJFoundation.observeValue(of: self, \.authorizationStatus) { _, status in
			change(status)
		}
	}

	private static func validLocation(_ location: CLLocation?) -> CLLocation? {
		guard let location, location.horizontalAccuracy >= 0 else { return nil }
		return location
	}

	@MainActor
	private func accept(_ location: CLLocation) {
		guard let currentLocation else {
			self.currentLocation = location
			return
		}
		if location.timestamp >= currentLocation.timestamp {
			self.currentLocation = location
		}
	}
}

extension LocationManager: CLLocationManagerDelegate {
	func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		let status = manager.authorizationStatus
		let cached = Self.validLocation(manager.location)
		DispatchQueue.main.async { [weak self] in
			guard let self else { return }
			self.authorizationStatus = status
			if let cached { self.accept(cached) }
			if status == .authorizedAlways || status == .authorizedWhenInUse {
				self.manager.startUpdatingLocation()
			}
		}
	}

	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let latest = locations.last(where: { $0.horizontalAccuracy >= 0 }) else { return }
		DispatchQueue.main.async { [weak self] in
			self?.accept(latest)
		}
	}
}
