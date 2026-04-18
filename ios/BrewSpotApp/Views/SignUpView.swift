import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("회원가입")
                    .font(.title.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("닉네임", text: $viewModel.nickname)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

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

                if let infoMessage = viewModel.infoMessage {
                    Text(infoMessage)
                        .foregroundStyle(.green)
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task {
                        let success = await viewModel.signUp()
                        if success {
                            dismiss()
                        }
                    }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("회원가입")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brewBrown)
                .disabled(viewModel.email.isEmpty || viewModel.password.isEmpty || viewModel.nickname.isEmpty || viewModel.isLoading)
            }
            .padding(24)
        }
        .background(Color.brewCream.ignoresSafeArea())
    }
}

#Preview {
    NavigationStack {
        SignUpView()
    }
}
