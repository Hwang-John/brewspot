import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("BrewSpot")
                    .font(.largeTitle.bold())
                Text("커피 취향에 맞는 카페를 찾고 기록하세요")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 14) {
                TextField("이메일", text: $viewModel.email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                SecureField("비밀번호", text: $viewModel.password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task { await viewModel.signIn(sessionStore: sessionStore) }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("로그인")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brewBrown)
                .disabled(viewModel.email.isEmpty || viewModel.password.isEmpty || viewModel.isLoading)

                NavigationLink("회원가입", destination: SignUpView())
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            Spacer()
        }
        .padding(24)
        .background(Color.brewCream.ignoresSafeArea())
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(SessionStore())
    }
}
