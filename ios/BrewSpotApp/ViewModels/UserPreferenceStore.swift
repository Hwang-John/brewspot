import Foundation

struct UserPreferenceData: Codable, Equatable {
    var preferredCity: String
    var favoriteVibeTags: [String]
    var profileNote: String

    static let empty = UserPreferenceData(
        preferredCity: "",
        favoriteVibeTags: [],
        profileNote: ""
    )

    var hasExplicitContent: Bool {
        !preferredCity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !favoriteVibeTags.isEmpty ||
        !profileNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

@MainActor
final class UserPreferenceStore: ObservableObject {
    @Published private(set) var preferences = UserPreferenceData.empty

    private var currentUserID: UUID?
    private let defaults = UserDefaults.standard

    func load(for userID: UUID?) {
        currentUserID = userID

        guard let userID else {
            preferences = .empty
            return
        }

        guard
            let data = defaults.data(forKey: storageKey(for: userID)),
            let storedPreferences = try? JSONDecoder().decode(UserPreferenceData.self, from: data)
        else {
            preferences = .empty
            return
        }

        preferences = storedPreferences
    }

    func save(preferredCity: String, favoriteVibeTags: [String], profileNote: String) {
        guard let currentUserID else { return }

        let normalized = UserPreferenceData(
            preferredCity: preferredCity.trimmingCharacters(in: .whitespacesAndNewlines),
            favoriteVibeTags: uniqueOrderedValues(from: favoriteVibeTags),
            profileNote: profileNote.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        preferences = normalized

        guard let encoded = try? JSONEncoder().encode(normalized) else { return }
        defaults.set(encoded, forKey: storageKey(for: currentUserID))
    }

    private func storageKey(for userID: UUID) -> String {
        "brewspot.user.preferences.\(userID.uuidString)"
    }

    private func uniqueOrderedValues(from values: [String]) -> [String] {
        var seen: Set<String> = []

        return values.compactMap { rawValue in
            let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !seen.contains(trimmed) else { return nil }
            seen.insert(trimmed)
            return trimmed
        }
    }
}
