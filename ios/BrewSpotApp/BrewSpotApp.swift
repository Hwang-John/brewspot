import SwiftUI

@main
struct BrewSpotApp: App {
    @StateObject private var sessionStore = SessionStore()
    @StateObject private var bookmarkStore = BookmarkStore()
    @StateObject private var reviewStore = ReviewStore()
    @StateObject private var cafeListViewModel = CafeListViewModel()
    @StateObject private var communityStore = CommunityStore()
    @StateObject private var homeBaristaStore = HomeBaristaStore()
    @StateObject private var toastCenter = AppToastCenter()
    @StateObject private var userPreferenceStore = UserPreferenceStore()
    @StateObject private var locationStore = LocationStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(sessionStore)
                .environmentObject(bookmarkStore)
                .environmentObject(reviewStore)
                .environmentObject(cafeListViewModel)
                .environmentObject(communityStore)
                .environmentObject(homeBaristaStore)
                .environmentObject(toastCenter)
                .environmentObject(userPreferenceStore)
                .environmentObject(locationStore)
                .task {
                    await sessionStore.bootstrap()
                }
        }
    }
}
