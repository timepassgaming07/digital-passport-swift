import Foundation
import CoreLocation

// MARK: – Real Location Service
// Uses CoreLocation to get actual device GPS coordinates.
// No simulation — returns nil if location is unavailable.

@MainActor
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isResolving = false

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<ProductLocation?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }

    // MARK: – Request Permission

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    // MARK: – Get Current Location (async)

    /// Returns a real ProductLocation from GPS + reverse geocode.
    /// Returns nil if location unavailable or permission denied.
    func resolveCurrentLocation() async -> ProductLocation? {
        let status = manager.authorizationStatus
        if status == .notDetermined {
            requestPermission()
            // Wait briefly for user to respond
            try? await Task.sleep(for: .seconds(2))
        }

        let updatedStatus = manager.authorizationStatus
        guard updatedStatus == .authorizedWhenInUse || updatedStatus == .authorizedAlways else {
            return nil
        }

        isResolving = true
        defer { isResolving = false }

        // Set up continuation BEFORE requesting location to avoid race condition
        let location = await withCheckedContinuation { (cont: CheckedContinuation<CLLocation?, Never>) in
            self.locationContinuation = cont
            self.manager.requestLocation()
        }

        guard let location else { return nil }

        // Reverse geocode to get city/country
        let geocoder = CLGeocoder()
        let placemarks = try? await geocoder.reverseGeocodeLocation(location)
        let placemark = placemarks?.first

        let city = placemark?.locality ?? "Unknown"
        let country = placemark?.country ?? "Unknown"
        let state = placemark?.administrativeArea ?? ""
        let formatted = [city, state, country].filter { !$0.isEmpty }.joined(separator: ", ")

        return ProductLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            city: city,
            country: country,
            formattedAddress: formatted
        )
    }

    // MARK: – CLLocationManagerDelegate

    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let loc = locations.last
        Task { @MainActor in
            self.currentLocation = loc
            self.locationContinuation?.resume(returning: loc)
            self.locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.locationContinuation?.resume(returning: nil)
            self.locationContinuation = nil
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
        }
    }
}
