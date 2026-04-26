import Foundation
import CoreLocation

final class LocationStore: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var placeSummary: String?
    @Published private(set) var requestCount = 0
    @Published private(set) var isRefreshing = false
    @Published private(set) var lastRefreshDate: Date?
    @Published private(set) var lastErrorMessage: String?

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        authorizationStatus = .notDetermined
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = locationManager.authorizationStatus
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var isDeniedOrRestricted: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    func requestWhenInUseAuthorization() {
        requestCount += 1
        authorizationStatus = locationManager.authorizationStatus
        lastErrorMessage = nil
        locationManager.requestWhenInUseAuthorization()
    }

    func refreshLocationIfAuthorized() {
        guard isAuthorized else {
            lastErrorMessage = "위치 권한을 먼저 허용해 주세요."
            return
        }

        lastErrorMessage = nil
        isRefreshing = true

        // `requestLocation()` can feel flaky in Simulator, so briefly start updates
        // and then request an immediate reading for a more reliable refresh.
        locationManager.startUpdatingLocation()
        locationManager.requestLocation()
    }

    var authorizationDescription: String {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return "현재 위치 사용 허용됨"
        case .denied:
            return "위치 권한이 거부되어 있어요"
        case .restricted:
            return "기기 제한으로 위치 권한을 사용할 수 없어요"
        case .notDetermined:
            return "아직 위치 권한을 요청하지 않았어요"
        @unknown default:
            return "위치 권한 상태를 확인 중이에요"
        }
    }

    var refreshStatusText: String? {
        if isRefreshing {
            return "현재 위치를 다시 확인하고 있어요."
        }

        if let lastErrorMessage {
            return lastErrorMessage
        }

        guard let lastRefreshDate else { return nil }
        return "최근 확인: \(lastRefreshDate.formatted(date: .omitted, time: .shortened))"
    }

    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let currentLocation else { return nil }
        let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return currentLocation.distance(from: target)
    }

    func distanceText(to coordinate: CLLocationCoordinate2D) -> String? {
        guard let distance = distance(to: coordinate) else { return nil }

        if distance < 1000 {
            return "\(Int(distance.rounded()))m"
        }

        return String(format: "%.1fkm", distance / 1000)
    }

    func nearestCafe(in cafes: [Cafe]) -> Cafe? {
        guard currentLocation != nil else { return nil }

        return cafes.min { lhs, rhs in
            let lhsDistance = distance(to: lhs.coordinate) ?? .greatestFiniteMagnitude
            let rhsDistance = distance(to: rhs.coordinate) ?? .greatestFiniteMagnitude
            return lhsDistance < rhsDistance
        }
    }

    private func updatePlaceSummary(for location: CLLocation) {
        geocoder.cancelGeocode()

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self else { return }

            let locality = placemarks?.first?.locality
            let subLocality = placemarks?.first?.subLocality

            let summary = [subLocality, locality]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: " • ")

            DispatchQueue.main.async {
                self.placeSummary = summary.isEmpty ? nil : summary
            }
        }
    }
}

extension LocationStore: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus

            if self.isAuthorized {
                self.lastErrorMessage = nil
                self.locationManager.requestLocation()
            } else if self.authorizationStatus == .denied || self.authorizationStatus == .restricted {
                self.currentLocation = nil
                self.placeSummary = nil
                self.isRefreshing = false
                self.lastErrorMessage = "설정에서 위치 권한을 허용하면 내 주변 카페를 볼 수 있어요."
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        DispatchQueue.main.async {
            self.currentLocation = location
            self.isRefreshing = false
            self.lastRefreshDate = Date()
            self.lastErrorMessage = nil
        }

        manager.stopUpdatingLocation()
        updatePlaceSummary(for: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        manager.stopUpdatingLocation()

        DispatchQueue.main.async {
            self.isRefreshing = false

            if let clError = error as? CLError {
                switch clError.code {
                case .locationUnknown:
                    self.lastErrorMessage = "위치를 아직 찾지 못했어요. 시뮬레이터 위치를 선택한 뒤 다시 시도해 주세요."
                case .denied:
                    self.lastErrorMessage = "위치 권한이 거부되어 있어요."
                default:
                    self.lastErrorMessage = "현재 위치를 불러오지 못했어요. 잠시 후 다시 시도해 주세요."
                }
            } else {
                self.lastErrorMessage = "현재 위치를 불러오지 못했어요. 잠시 후 다시 시도해 주세요."
            }
        }
    }
}
