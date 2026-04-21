import SwiftUI

struct CafeHomeView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var bookmarkStore: BookmarkStore
    @EnvironmentObject private var cafeListViewModel: CafeListViewModel
    @State private var searchText = ""
    @State private var selectedCategory = "전체"

    var body: some View {
        NavigationStack {
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

                    if cafeListViewModel.isLoading {
                        ProgressView("카페 정보를 불러오는 중...")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    discoveryControls

                    CafeMapView(cafes: filteredCafes.isEmpty ? cafes : filteredCafes)

                    bookmarkedSection

                    recommendedSection

                    Button("로그아웃") {
                        Task { await sessionStore.signOut() }
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(24)
            }
            .navigationTitle("BrewSpot")
            .background(Color.brewCream.ignoresSafeArea())
            .task {
                await cafeListViewModel.loadIfNeeded()
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

    private var heroBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("오늘의 카페 탐색")
                .font(.headline)

            Text("지도에서 가까운 카페를 확인하고, 아래 추천 리스트에서 취향에 맞는 공간을 바로 골라보세요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("현재 데이터: \(cafeListViewModel.sourceDescription)")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.brewBrown)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.brewLatte, Color.brewCream],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var discoveryControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("카페명, 지역, 메뉴로 검색", text: $searchText)
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
            .background(Color(.secondarySystemBackground))
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
    }

    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("추천 카페")
                    .font(.headline)

                Spacer()

                Text("\(filteredCafes.count)곳")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if filteredCafes.isEmpty {
                emptyStateCard(
                    title: "조건에 맞는 카페가 없어요",
                    message: "검색어를 짧게 바꾸거나 다른 카테고리를 선택하면 더 많은 결과를 볼 수 있어요.",
                    systemImage: "magnifyingglass"
                )
            } else {
                ForEach(filteredCafes) { cafe in
                    NavigationLink {
                        CafeDetailView(cafe: cafe)
                    } label: {
                        cafeRow(cafe)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var bookmarkedSection: some View {
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
                    title: "아직 저장한 카페가 없어요",
                    message: "추천 카드나 카페 상세에서 저장 버튼을 누르면 관심 카페가 여기에 모여요.",
                    systemImage: "bookmark"
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(bookmarkedCafes) { cafe in
                            NavigationLink {
                                CafeDetailView(cafe: cafe)
                            } label: {
                                bookmarkedCafeCard(cafe)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func cafeRow(_ cafe: Cafe) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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

            HStack {
                Label(cafe.signatureMenu, systemImage: "cup.and.saucer.fill")
                Spacer()
                Text(cafe.priceNote)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func bookmarkedCafeCard(_ cafe: Cafe) -> some View {
        VStack(alignment: .leading, spacing: 10) {
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
        }
        .frame(width: 180, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func bookmarkButton(for cafe: Cafe) -> some View {
        Button {
            bookmarkStore.toggle(cafe)
        } label: {
            Image(systemName: bookmarkStore.isBookmarked(cafe) ? "bookmark.fill" : "bookmark")
                .foregroundStyle(bookmarkStore.isBookmarked(cafe) ? Color.brewBrown : .secondary)
        }
        .buttonStyle(.plain)
    }

    private func emptyStateCard(title: String, message: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(Color.brewBrown)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    CafeHomeView()
        .environmentObject(SessionStore())
        .environmentObject(BookmarkStore())
        .environmentObject(ReviewStore())
        .environmentObject(CafeListViewModel())
}
