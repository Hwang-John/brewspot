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
            errorMessage = "로그인에 실패했습니다. 이메일과 비밀번호를 확인해주세요."
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
            infoMessage = "회원가입이 완료되었습니다. 로그인 해주세요."
            return true
        } catch {
            errorMessage = "회원가입에 실패했습니다. 다시 시도해주세요."
            return false
        }
    }
}
