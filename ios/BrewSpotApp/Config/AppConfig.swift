import Foundation

enum AppConfig {
    static let supabaseURL = URL(string: "https://ahlstavrnnwydzxwwnbq.supabase.co")!
    static let supabasePublishableKey = "sb_publishable_UUFOiprjYpty5Jaa74xAzw_eRmZh5Tt"
    static let supportEmail = "deoc2088@gmail.com"
    static let websiteURL = URL(string: "https://hwang-john.github.io/brewspot/")!
    static let supportPageURL = URL(string: "https://hwang-john.github.io/brewspot/support.html")!
    static let privacyPolicyURL = URL(string: "https://hwang-john.github.io/brewspot/privacy-policy.html")!
    static let termsURL = URL(string: "https://hwang-john.github.io/brewspot/terms.html")!

    static func supportMailURL(
        subject: String = "BrewSpot 문의",
        body: String? = nil
    ) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject)
        ]

        if let body, !body.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "body", value: body))
        }

        return components.url
    }
}
