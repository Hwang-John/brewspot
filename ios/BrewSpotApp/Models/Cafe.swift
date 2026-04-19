import Foundation
import CoreLocation

struct Cafe: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let category: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
