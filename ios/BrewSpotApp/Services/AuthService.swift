import Foundation
import Supabase

struct AuthService {
    private let client = SupabaseClientProvider.client

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
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
        let session = try await client.auth.session
        let authUserId = session.user.id

        return try await client
            .from("users")
            .select()
            .eq("id", value: authUserId)
            .single()
            .execute()
            .value
    }
}
