import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var nickname = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    private let authService = AuthService()

    func signIn(sessionStore: SessionStore) async {
        errorMessage = nil
        infoMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.signIn(email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                                         password: password)
            await sessionStore.refreshCurrentUser()
        } catch {
            errorMessage = mapEmailSignInError(error)
        }
    }

    func signUp() async -> Bool {
        errorMessage = nil
        infoMessage = nil

        guard !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "닉네임을 입력해주세요."
            return false
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.signUp(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            infoMessage = "회원가입 요청이 완료되었습니다. 이메일 인증이 필요한 경우 메일함을 확인한 뒤 로그인해주세요."
            return true
        } catch {
            errorMessage = mapEmailSignUpError(error)
            return false
        }
    }

    func signInWithGoogle(sessionStore: SessionStore) async {
        errorMessage = nil
        infoMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.signInWithGoogle()
            await sessionStore.refreshCurrentUser()
        } catch {
            errorMessage = mapOAuthError(error, providerName: "Google")
        }
    }

    func signInWithApple(sessionStore: SessionStore) async {
        errorMessage = nil
        infoMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.signInWithApple()
            await sessionStore.refreshCurrentUser()
        } catch {
            errorMessage = mapOAuthError(error, providerName: "Apple")
        }
    }

    private func mapEmailSignInError(_ error: Error) -> String {
        let description = normalizedDescription(for: error)

        if description.contains("email not confirmed") || description.contains("email_not_confirmed") {
            return "이메일 인증이 아직 완료되지 않았어요. 인증 메일을 확인한 뒤 다시 로그인해주세요."
        }

        if description.contains("invalid login credentials") {
            return "로그인에 실패했습니다. 이메일과 비밀번호를 다시 확인해주세요."
        }

        return "로그인에 실패했습니다. 잠시 후 다시 시도해주세요."
    }

    private func mapEmailSignUpError(_ error: Error) -> String {
        let description = normalizedDescription(for: error)

        if description.contains("user already registered") {
            return "이미 가입된 이메일입니다. 로그인하거나 비밀번호 재설정을 진행해주세요."
        }

        if description.contains("database error saving new user") || description.contains("unexpected_failure") {
            return "현재 회원가입 연동 설정 문제로 가입에 실패했어요. Supabase auth trigger 설정을 확인한 뒤 다시 시도해주세요."
        }

        if description.contains("password") && description.contains("least") {
            return "비밀번호 조건을 다시 확인해주세요."
        }

        if description.contains("signup is disabled") {
            return "현재 이메일 회원가입이 비활성화되어 있어요. 설정을 확인해주세요."
        }

        return "회원가입에 실패했습니다. 잠시 후 다시 시도해주세요."
    }

    private func mapOAuthError(_ error: Error, providerName: String) -> String {
        let description = normalizedDescription(for: error)

        if description.contains("provider is not enabled") || description.contains("unsupported provider") {
            return "\(providerName) 로그인이 아직 활성화되지 않았어요. Supabase Provider 설정을 확인해주세요."
        }

        if description.contains("cancel") {
            return "\(providerName) 로그인이 취소되었습니다."
        }

        return "\(providerName) 로그인에 실패했습니다. Provider 설정과 redirect 구성을 확인해주세요."
    }

    private func normalizedDescription(for error: Error) -> String {
        let localized = error.localizedDescription
        let reflected = String(describing: error)
        return "\(localized) \(reflected)".lowercased()
    }
}
