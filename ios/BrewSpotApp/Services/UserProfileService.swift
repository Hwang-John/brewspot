import Foundation
import Supabase

struct UserProfileService {
    private let client = SupabaseClientProvider.client

    func ensureCurrentUserProfile() async throws -> AppUser? {
        let session = try await client.auth.session
        let authUser = session.user
        let existingProfiles: [AppUser] = try await client
            .from("users")
            .select()
            .eq("id", value: authUser.id)
            .execute()
            .value

        if let existingProfile = existingProfiles.first {
            return existingProfile
        }

        let nicknameBase =
            authUser.email?
            .split(separator: "@")
            .first
            .map(String.init) ??
            "brewspot_user"
        let fallbackNickname = String(nicknameBase.prefix(23)) + "_" + String(authUser.id.uuidString.replacingOccurrences(of: "-", with: "").prefix(6))

        let profile: AppUser = try await client
            .from("users")
            .insert(
                UserProfileInsert(
                    id: authUser.id,
                    nickname: fallbackNickname,
                    email: authUser.email
                )
            )
            .select()
            .single()
            .execute()
            .value

        return profile
    }

    func updateCurrentUserProfile(nickname: String) async throws -> AppUser {
        let session = try await client.auth.session

        let updatedProfile: AppUser = try await client
            .from("users")
            .update(
                UserProfileUpdate(
                    nickname: String(nickname.prefix(30))
                )
            )
            .eq("id", value: session.user.id)
            .select()
            .single()
            .execute()
            .value

        return updatedProfile
    }
}

private struct UserProfileInsert: Encodable {
    let id: UUID
    let nickname: String
    let email: String?
}

private struct UserProfileUpdate: Encodable {
    let nickname: String
}
