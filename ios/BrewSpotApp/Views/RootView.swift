import SwiftUI

struct RootView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var toastCenter: AppToastCenter

    var body: some View {
        ZStack(alignment: .top) {
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

            if let item = toastCenter.item {
                ToastBannerView(item: item) {
                    toastCenter.dismiss()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .animation(.spring(duration: 0.28), value: toastCenter.item)
    }
}
