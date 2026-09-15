import Foundation
import CoreLocation
import Observation

/// Eager location provider intended for clients that need a location immediately
/// at the point of use. It begins authorization/acquisition as soon as it is
/// created and retains the newest valid location as a cache.
@Observable
public final class LocationManager: NSObject, @unchecked Sendable {
	private let manager: CLLocationManager
	public private(set) var authorizationStatus: CLAuthorizationStatus
	public private(set) var currentLocation: CLLocation?
	public let canGetLocation: Bool

	public override init() {
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
	public func requestAccessAndStart() {
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
	public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
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

	public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let latest = locations.last(where: { $0.horizontalAccuracy >= 0 }) else { return }
		DispatchQueue.main.async { [weak self] in
			self?.accept(latest)
		}
	}
}
