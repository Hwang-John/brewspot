import SwiftUI

struct RootView: View {
    @EnvironmentObject private var sessionStore: SessionStore

    var body: some View {
        Group {
            if sessionStore.isLoading {
                ProgressView("불러오는 중...")
            } else if sessionStore.currentUser != nil {
                AppTabView()
            } else {
                NavigationStack {
                    LoginView()
                }
            }
        }
    }
}
