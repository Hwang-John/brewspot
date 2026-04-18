import Foundation
import Supabase

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var currentUser: AppUser?
    @Published private(set) var isLoading = true

    private let authService = AuthService()

    func bootstrap() async {
        defer { isLoading = false }
        await refreshCurrentUser()
    }

    func refreshCurrentUser() async {
        do {
            currentUser = try await authService.fetchCurrentUserProfile()
        } catch {
            currentUser = nil
        }
    }

    func signOut() async {
        do {
            try await authService.signOut()
            currentUser = nil
        } catch {
            print("Sign out error: \(error)")
        }
    }
}
