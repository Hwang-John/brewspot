import Foundation
import Supabase

struct AuthService {
    private let client = SupabaseClientProvider.client
    private let userProfileService = UserProfileService()

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
        _ = try await userProfileService.ensureCurrentUserProfile()
    }

    func signUp(email: String, password: String, nickname: String) async throws {
        try await client.auth.signUp(
            email: email,
            password: password,
            data: [
                "nickname": .string(nickname)
            ]
        )
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func fetchCurrentUserProfile() async throws -> AppUser? {
        try await userProfileService.ensureCurrentUserProfile()
    }

    func updateCurrentUserProfile(nickname: String) async throws -> AppUser {
        try await userProfileService.updateCurrentUserProfile(nickname: nickname)
    }
}
