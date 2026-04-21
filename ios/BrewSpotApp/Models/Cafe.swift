import Foundation
import CoreLocation

struct Cafe: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let category: String
    let city: String
    let latitude: Double
    let longitude: Double
    let rating: Double
    let reviewCount: Int
    let priceNote: String
    let signatureMenu: String
    let shortDescription: String
    let vibeTags: [String]
    let features: [String]
    let openHours: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
