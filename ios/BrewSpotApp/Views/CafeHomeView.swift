import SwiftUI

struct CafeHomeView: View {
    @EnvironmentObject private var sessionStore: SessionStore

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let user = sessionStore.currentUser {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("안녕하세요, \(user.nickname)")
                            .font(.title2.bold())
                        Text(user.email ?? "")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text("다음 단계에서 카페 목록/상세 화면을 연결합니다.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                Button("로그아웃") {
                    Task { await sessionStore.signOut() }
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
            .padding(24)
            .navigationTitle("BrewSpot")
            .background(Color.brewCream.ignoresSafeArea())
        }
    }
}

#Preview {
    CafeHomeView()
        .environmentObject(SessionStore())
}
