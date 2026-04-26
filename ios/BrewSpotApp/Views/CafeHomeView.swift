import SwiftUI
import UIKit

struct CafeHomeView: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var bookmarkStore: BookmarkStore
    @EnvironmentObject private var cafeListViewModel: CafeListViewModel
    @EnvironmentObject private var toastCenter: AppToastCenter
    @EnvironmentObject private var locationStore: LocationStore
    @State private var searchText = ""
    @State private var selectedCategory = "전체"
    @State private var selectedMapCafe: Cafe?
    private let mapSectionID = "cafe-map-section"

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
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

                        heroBanner
                        locationPermissionCard

                        if let errorMessage = cafeListViewModel.errorMessage {
                            ErrorStateCard(
                                title: "카페 리스트를 불러오지 못했어요",
                                message: errorMessage,
                                buttonTitle: "다시 불러오기"
                            ) {
                                Task { await cafeListViewModel.refresh() }
                            }
                        }

                        if let errorMessage = bookmarkStore.errorMessage {
                            ErrorStateCard(
                                title: "저장 컬렉션을 불러오지 못했어요",
                                message: errorMessage,
                                buttonTitle: "다시 불러오기"
                            ) {
                                Task { await bookmarkStore.refresh() }
                            }
                        }

                        if cafeListViewModel.isLoading {
                            ProgressView("카페를 준비하고 있어요...")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        discoveryControls

                        CafeMapView(cafes: mapDisplayCafes, selectedCafe: $selectedMapCafe)
                            .id(mapSectionID)

                        bookmarkedSection { cafe in
                            focusMap(on: cafe, using: proxy)
                        }

                        recommendedSection { cafe in
                            focusMap(on: cafe, using: proxy)
                        }

                        Button("로그아웃") {
                            Task { await sessionStore.signOut() }
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("BrewSpot")
            .background(Color.brewCream.ignoresSafeArea())
            .task {
                await cafeListViewModel.loadIfNeeded()
            }
            .task(id: sessionStore.currentUser?.id) {
                await bookmarkStore.refresh()
            }
            .task {
                locationStore.refreshLocationIfAuthorized()
            }
        }
    }

    private var cafes: [Cafe] {
        cafeListViewModel.cafes
    }

    private var categories: [String] {
        ["전체"] + Array(Set(cafes.map(\.category))).sorted()
    }

    private var filteredCafes: [Cafe] {
        cafes.filter { cafe in
            let matchesCategory = selectedCategory == "전체" || cafe.category == selectedCategory
            let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch =
                trimmedSearch.isEmpty ||
                cafe.name.localizedCaseInsensitiveContains(trimmedSearch) ||
                cafe.city.localizedCaseInsensitiveContains(trimmedSearch) ||
                cafe.category.localizedCaseInsensitiveContains(trimmedSearch) ||
                cafe.signatureMenu.localizedCaseInsensitiveContains(trimmedSearch) ||
                cafe.vibeTags.joined(separator: " ").localizedCaseInsensitiveContains(trimmedSearch)

            return matchesCategory && matchesSearch
        }
    }

    private var bookmarkedCafes: [Cafe] {
        cafes.filter { bookmarkStore.isBookmarked($0) }
    }

    private var mapDisplayCafes: [Cafe] {
        filteredCafes.isEmpty ? cafes : filteredCafes
    }

    private var discoverySummary: String {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedSearch.isEmpty {
            return "`\(trimmedSearch)`에 맞는 카페를 골라봤어요."
        }

        if selectedCategory != "전체" {
            return "\(selectedCategory) 무드의 카페를 모았어요."
        }

        return "지금 둘러보기 좋은 카페를 모았어요."
    }

    private var heroBanner: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("BrewSpot")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.86))

                    Text("오늘의 브루 가이드")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }

                Spacer()

                Text("DAILY PICK")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.brewMocha)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Capsule())
            }

            Text("지도와 리스트를 오가며 오늘 머물고 싶은 카페를 차분하게 골라보세요.")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.86))

            HStack(spacing: 12) {
                heroMetricCard(title: "추천 카페", value: "\(filteredCafes.count)곳", caption: selectedCategory == "전체" ? "오늘의 셀렉션" : selectedCategory)
                heroMetricCard(title: "저장한 카페", value: "\(bookmarkedCafes.count)곳", caption: "내 컬렉션")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("현재 셀렉션")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.72))

                Text(cafeListViewModel.sourceDescription)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 18))

            if let nearestCafe = locationStore.nearestCafe(in: mapDisplayCafes),
               let distanceText = locationStore.distanceText(to: nearestCafe.coordinate) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("내 주변 브루 스팟")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.72))

                    HStack {
                        Text(nearestCafe.name)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white)

                        Spacer()

                        Text(distanceText)
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(Color.brewMocha)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Capsule())
                    }

                    if let placeSummary = locationStore.placeSummary {
                        Text(placeSummary)
                            .font(.caption)
                            .foregroundStyle(Color.white.opacity(0.72))
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            LinearGradient(
                colors: [Color.brewMocha, Color.brewBrown],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var discoveryControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("탐색 필터")
                        .font(.headline)

                    Text("지역, 무드, 메뉴 기준으로 빠르게 좁혀보세요.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.brewBrown)

                TextField("카페명, 지역, 메뉴 검색", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(14)
            .background(Color.brewFoam)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(categories, id: \.self) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            Text(category)
                                .font(.footnote.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(selectedCategory == category ? Color.brewBrown : Color(.secondarySystemBackground))
                                .foregroundStyle(selectedCategory == category ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.76))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.brewBrown.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var locationPermissionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("현재 위치")
                        .font(.headline)

                    Text(locationStore.authorizationDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("요청 \(locationStore.requestCount)회")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.brewBrown)
            }

            if let placeSummary = locationStore.placeSummary {
                Text("현재 기준 위치: \(placeSummary)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let refreshStatusText = locationStore.refreshStatusText {
                Label(refreshStatusText, systemImage: locationStore.isRefreshing ? "location.fill" : "info.circle")
                    .font(.footnote)
                    .foregroundColor(locationStore.lastErrorMessage == nil ? .secondary : .orange)
            }

            HStack(spacing: 10) {
                Button(primaryLocationButtonTitle) {
                    handlePrimaryLocationAction()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brewBrown)

                if locationStore.isAuthorized {
                    Button("현재 위치 새로고침") {
                        locationStore.refreshLocationIfAuthorized()
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.brewBrown)
                    .disabled(locationStore.isRefreshing)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white.opacity(0.82))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.brewBrown.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var primaryLocationButtonTitle: String {
        switch locationStore.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return "내 위치 사용 중"
        case .denied, .restricted:
            return "설정 열기"
        case .notDetermined:
            return "위치 권한 요청"
        @unknown default:
            return "위치 확인"
        }
    }

    private func handlePrimaryLocationAction() {
        switch locationStore.authorizationStatus {
        case .notDetermined:
            locationStore.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationStore.refreshLocationIfAuthorized()
        case .denied, .restricted:
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
            openURL(settingsURL)
        @unknown default:
            break
        }
    }

    private func recommendedSection(focusOnMap: @escaping (Cafe) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("추천 카페")
                    .font(.headline)

                Spacer()

                Text("\(filteredCafes.count)곳")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(discoverySummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if filteredCafes.isEmpty {
                emptyStateCard(
                    title: "아직 맞는 카페가 없어요",
                    message: "검색어나 카테고리를 바꾸면 다른 셀렉션을 볼 수 있어요.",
                    systemImage: "magnifyingglass",
                    hint: "검색어를 가볍게 바꾸면 새로운 추천이 보여요."
                )
            } else {
                ForEach(filteredCafes) { cafe in
                    cafeRow(cafe, focusOnMap: focusOnMap)
                }
            }
        }
    }

    private func bookmarkedSection(focusOnMap: @escaping (Cafe) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("저장한 카페")
                    .font(.headline)

                Spacer()

                Text("\(bookmarkedCafes.count)곳")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if bookmarkedCafes.isEmpty {
                emptyStateCard(
                    title: "저장한 카페가 아직 없어요",
                    message: "마음에 드는 카페를 저장하면 이 컬렉션에 차곡차곡 쌓여요.",
                    systemImage: "bookmark",
                    hint: "탐색 중 저장한 공간은 언제든 다시 꺼내볼 수 있어요."
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(bookmarkedCafes) { cafe in
                            bookmarkedCafeCard(cafe, focusOnMap: focusOnMap)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func cafeRow(_ cafe: Cafe, focusOnMap: @escaping (Cafe) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            CafeArtworkView(cafe: cafe, variant: .wide)

            HStack(spacing: 8) {
                tagPill(cafe.city, tint: Color.brewBrown, background: Color.brewLatte)
                tagPill(cafe.category, tint: .primary, background: Color.white.opacity(0.72))
                if let distanceText = locationStore.distanceText(to: cafe.coordinate) {
                    tagPill(distanceText, tint: Color.brewBrown, background: Color.white.opacity(0.72))
                }
                Spacer()
                Text("리뷰 \(cafe.reviewCount)개")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(cafe.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("\(cafe.city) • \(cafe.category)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 10) {
                    Label(String(format: "%.1f", cafe.rating), systemImage: "star.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.brewBrown)

                    bookmarkButton(for: cafe)
                }
            }

            Text(cafe.shortDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(cafe.vibeTags.prefix(3)), id: \.self) { tag in
                        tagPill("#\(tag)", tint: Color.brewBrown, background: Color.white.opacity(0.75))
                    }
                }
            }

            HStack {
                Label(cafe.signatureMenu, systemImage: "cup.and.saucer.fill")
                Spacer()
                Text(cafe.priceNote)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button {
                    focusOnMap(cafe)
                } label: {
                    Label("지도에서 보기", systemImage: "map")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(Color.brewBrown)

                NavigationLink {
                    CafeDetailView(cafe: cafe)
                } label: {
                    Text("상세 보기")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brewBrown)
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.95), Color.brewLatte.opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.brewBrown.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func bookmarkedCafeCard(_ cafe: Cafe, focusOnMap: @escaping (Cafe) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            CafeArtworkView(cafe: cafe, variant: .compact)

            HStack {
                Text(cafe.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "bookmark.fill")
                    .foregroundStyle(Color.brewBrown)
            }

            Text("\(cafe.city) • \(cafe.category)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(cafe.signatureMenu)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.brewBrown)

            if let distanceText = locationStore.distanceText(to: cafe.coordinate) {
                Text("현재 위치에서 \(distanceText)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(cafe.vibeTags.prefix(2)), id: \.self) { tag in
                        tagPill("#\(tag)", tint: Color.brewBrown, background: Color.white.opacity(0.72))
                    }
                }
            }

            VStack(spacing: 8) {
                Button {
                    focusOnMap(cafe)
                } label: {
                    Label("지도에서 보기", systemImage: "map")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(Color.brewBrown)

                NavigationLink {
                    CafeDetailView(cafe: cafe)
                } label: {
                    Text("상세 보기")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brewBrown)
            }
        }
        .frame(width: 180, alignment: .leading)
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.94), Color.brewLatte.opacity(0.52)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.brewBrown.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func bookmarkButton(for cafe: Cafe) -> some View {
        Button {
            Task {
                guard let result = await bookmarkStore.toggle(cafe) else { return }

                switch result {
                case .added:
                    toastCenter.showSuccess(
                        title: "컬렉션에 담았어요",
                        message: "\(cafe.name)을 저장해뒀어요.",
                        systemImage: "bookmark.fill"
                    )
                case .removed:
                    toastCenter.showSuccess(
                        title: "컬렉션에서 뺐어요",
                        message: "\(cafe.name)을 저장 목록에서 뺐어요.",
                        systemImage: "bookmark.slash.fill"
                    )
                }
            }
        } label: {
            Image(systemName: bookmarkStore.isBookmarked(cafe) ? "bookmark.fill" : "bookmark")
                .foregroundStyle(bookmarkStore.isBookmarked(cafe) ? Color.brewBrown : .secondary)
        }
        .buttonStyle(.plain)
    }

    private func emptyStateCard(title: String, message: String, systemImage: String, hint: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.72))
                        .frame(width: 46, height: 46)

                    Image(systemName: systemImage)
                        .font(.title3)
                        .foregroundStyle(Color.brewBrown)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Text(hint)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.brewBrown)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.7))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.brewLatte.opacity(0.85), Color.white.opacity(0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.brewBrown.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func focusMap(on cafe: Cafe, using proxy: ScrollViewProxy) {
        selectedMapCafe = cafe
        withAnimation(.easeInOut(duration: 0.25)) {
            proxy.scrollTo(mapSectionID, anchor: .top)
        }
    }

    private func tagPill(_ text: String, tint: Color, background: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(background)
            .clipShape(Capsule())
    }

    private func heroMetricCard(title: String, value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.72))

            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text(caption)
                .font(.footnote)
                .foregroundStyle(Color.white.opacity(0.78))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    CafeHomeView()
        .environmentObject(SessionStore())
        .environmentObject(BookmarkStore())
        .environmentObject(ReviewStore())
        .environmentObject(CafeListViewModel())
        .environmentObject(AppToastCenter())
        .environmentObject(LocationStore())
}
