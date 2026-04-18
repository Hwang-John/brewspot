import Foundation

struct AppUser: Identifiable, Codable {
    let id: UUID
    let nickname: String
    let email: String?
    let profileImageURL: String?
    let status: String

    enum CodingKeys: String, CodingKey {
        case id
        case nickname
        case email
        case profileImageURL = "profile_image_url"
        case status
    }
}
