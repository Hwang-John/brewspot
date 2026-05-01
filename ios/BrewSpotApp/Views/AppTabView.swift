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

                CommunityBoardView()
                    .tabItem {
                        Label("커뮤니티", systemImage: "text.bubble")
                    }

                CafeRankingView()
                    .tabItem {
                        Label("랭킹", systemImage: "chart.bar")
                    }

                HomeBaristaView()
                    .tabItem {
                        Label("홈바리스타", systemImage: "cup.and.heat.waves")
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
        .environmentObject(CommunityStore())
        .environmentObject(HomeBaristaStore())
        .environmentObject(AppToastCenter())
        .environmentObject(UserPreferenceStore())
        .environmentObject(LocationStore())
}
