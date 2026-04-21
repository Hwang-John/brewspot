import SwiftUI

struct AppTabView: View {
    var body: some View {
        TabView {
            CafeHomeView()
                .tabItem {
                    Label("탐색", systemImage: "map")
                }

            MyPageView()
                .tabItem {
                    Label("마이", systemImage: "person.crop.circle")
                }
        }
        .tint(Color.brewBrown)
    }
}

#Preview {
    AppTabView()
        .environmentObject(SessionStore())
        .environmentObject(BookmarkStore())
        .environmentObject(ReviewStore())
        .environmentObject(CafeListViewModel())
}
