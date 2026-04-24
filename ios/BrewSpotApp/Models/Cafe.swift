import Foundation
import CoreLocation

struct Cafe: Identifiable {
    let id: UUID
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

    init(
        id: UUID = UUID(),
        name: String,
        address: String,
        category: String,
        city: String,
        latitude: Double,
        longitude: Double,
        rating: Double,
        reviewCount: Int,
        priceNote: String,
        signatureMenu: String,
        shortDescription: String,
        vibeTags: [String],
        features: [String],
        openHours: String
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.category = category
        self.city = city
        self.latitude = latitude
        self.longitude = longitude
        self.rating = rating
        self.reviewCount = reviewCount
        self.priceNote = priceNote
        self.signatureMenu = signatureMenu
        self.shortDescription = shortDescription
        self.vibeTags = vibeTags
        self.features = features
        self.openHours = openHours
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
