import SwiftUI

struct AppTabView: View {
    var body: some View {
        ZStack {
            Color.brewCream.ignoresSafeArea()

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
        }
        .tint(Color.brewBrown)
        .toolbarBackground(Color.brewFoam, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.light, for: .tabBar)
    }
}

#Preview {
    AppTabView()
        .environmentObject(SessionStore())
        .environmentObject(BookmarkStore())
        .environmentObject(ReviewStore())
        .environmentObject(CafeListViewModel())
}
