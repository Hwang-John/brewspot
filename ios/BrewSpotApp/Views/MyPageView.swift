import SwiftUI

struct MyPageView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var bookmarkStore: BookmarkStore
    @EnvironmentObject private var reviewStore: ReviewStore
    @EnvironmentObject private var cafeListViewModel: CafeListViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileCard
                    activitySummary
                    recentActivitySection
                    myReviewSection
                    savedCafeSection
                    preferenceSection
                    accountSection
                }
                .padding(24)
            }
            .navigationTitle("마이페이지")
            .background(Color.brewCream.ignoresSafeArea())
            .task(id: sessionStore.currentUser?.id) {
                await cafeListViewModel.loadIfNeeded()
                await bookmarkStore.refresh()
                await reviewStore.refreshMyReviews(using: cafeListViewModel.cafes)
            }
        }
    }

    private var cafes: [Cafe] {
        cafeListViewModel.cafes
    }

    private var bookmarkedCafes: [Cafe] {
        cafes.filter { bookmarkStore.isBookmarked($0) }
    }

    private var myReviewItems: [ReviewStore.SavedReviewItem] {
        reviewStore.myReviews
    }

    private var recentActivityItems: [RecentActivityItem] {
        let bookmarkActivities: [RecentActivityItem] = bookmarkedCafes.compactMap { cafe in
            guard let date = bookmarkStore.bookmarkedAt(cafe) else { return nil }
            return RecentActivityItem(
                title: cafe.name,
                subtitle: "카페를 저장했어요",
                detail: "\(cafe.city) • \(cafe.category)",
                systemImage: "bookmark.fill",
                timestamp: date
            )
        }

        let reviewActivities = myReviewItems.map { item in
            RecentActivityItem(
                title: item.cafeName,
                subtitle: "리뷰를 남겼어요",
                detail: item.review.recommendedMenu,
                systemImage: "square.and.pencil",
                timestamp: item.review.createdAt
            )
        }

        let mergedActivities = (bookmarkActivities + reviewActivities)
            .sorted { $0.timestamp > $1.timestamp }

        return Array(mergedActivities.prefix(5))
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.brewLatte)
                        .frame(width: 58, height: 58)

                    Image(systemName: "person.fill")
                        .foregroundStyle(Color.brewBrown)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(sessionStore.currentUser?.nickname ?? "게스트")
                        .font(.title3.bold())

                    Text(sessionStore.currentUser?.email ?? "이메일 정보 없음")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Text("좋아하는 공간을 저장하고, 취향에 맞는 카페를 계속 쌓아가는 BrewSpot 프로필")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.brewLatte, Color.brewCream],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var activitySummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("활동 요약")
                .font(.headline)

            HStack(spacing: 12) {
                summaryCard(title: "저장한 카페", value: "\(bookmarkedCafes.count)", caption: "관심 공간", systemImage: "bookmark.fill")
                summaryCard(title: "작성한 리뷰", value: "\(myReviewItems.count)", caption: "남긴 기록", systemImage: "square.and.pencil")
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("최근 활동")
                    .font(.headline)

                Spacer()

                Text("\(recentActivityItems.count)건")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if recentActivityItems.isEmpty {
                emptyStateCard(
                    title: "활동 기록이 아직 없어요",
                    message: "카페를 저장하거나 리뷰를 남기면 최근 활동이 시간순으로 여기에 쌓여요.",
                    systemImage: "clock.arrow.circlepath"
                )
            } else {
                ForEach(recentActivityItems) { item in
                    recentActivityRow(item)
                }
            }
        }
    }

    private var myReviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("내가 쓴 리뷰")
                    .font(.headline)

                Spacer()

                Text("\(myReviewItems.count)개")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if myReviewItems.isEmpty {
                emptyStateCard(
                    title: "아직 작성한 리뷰가 없어요",
                    message: "카페 상세에서 리뷰를 남기면 내 기록으로 여기에 쌓여요.",
                    systemImage: "square.and.pencil"
                )
            } else {
                ForEach(myReviewItems) { item in
                    if let cafe = cafe(id: item.cafeID) {
                        NavigationLink {
                            CafeDetailView(cafe: cafe)
                        } label: {
                            myReviewRow(item)
                        }
                        .buttonStyle(.plain)
                    } else {
                        myReviewRow(item)
                    }
                }
            }
        }
    }

    private var savedCafeSection: some View {
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
                    message: "탐색 화면에서 마음에 드는 카페를 저장하면 여기에 모아볼 수 있어요.",
                    systemImage: "bookmark"
                )
            } else {
                ForEach(bookmarkedCafes) { cafe in
                    NavigationLink {
                        CafeDetailView(cafe: cafe)
                    } label: {
                        savedCafeRow(cafe)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var preferenceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("취향 태그")
                .font(.headline)

            if favoriteTags.isEmpty {
                emptyStateCard(
                    title: "취향 태그가 아직 없어요",
                    message: "카페를 저장하면 분위기 태그를 바탕으로 취향 키워드가 여기에 정리돼요.",
                    systemImage: "tag"
                )
            } else {
                FlowTagView(tags: favoriteTags)
            }
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("계정")
                .font(.headline)

            Button("로그아웃") {
                Task { await sessionStore.signOut() }
            }
            .buttonStyle(.bordered)
            .tint(Color.brewBrown)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var favoriteTags: [String] {
        Array(Set(bookmarkedCafes.flatMap(\.vibeTags))).sorted()
    }

    private var exploredCategories: [String] {
        Array(Set(bookmarkedCafes.map(\.category))).sorted()
    }

    private func cafe(id: UUID) -> Cafe? {
        cafes.first { $0.id == id }
    }

    private func summaryCard(title: String, value: String, caption: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title.bold())

            Text(caption)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func savedCafeRow(_ cafe: Cafe) -> some View {
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

                Label(String(format: "%.1f", cafe.rating), systemImage: "star.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.brewBrown)
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

    private func myReviewRow(_ item: ReviewStore.SavedReviewItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.cafeName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(item.review.authorName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Label("\(item.review.rating)점", systemImage: "star.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.brewBrown)
            }

            Text(item.review.visitNote)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)

            HStack {
                Label(item.review.recommendedMenu, systemImage: "cup.and.saucer.fill")
                Spacer()
                Text(item.review.relativeCreatedAt)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func recentActivityRow(_ item: RecentActivityItem) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: item.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.brewBrown)
                .frame(width: 30, height: 30)
                .background(Color.brewLatte)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)

                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(item.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(item.relativeTime)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
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

private struct RecentActivityItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let detail: String
    let systemImage: String
    let timestamp: Date

    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

private struct FlowTagView: View {
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(rowGroups, id: \.self) { row in
                HStack {
                    ForEach(row, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.footnote.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.brewLatte)
                            .clipShape(Capsule())
                    }

                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var rowGroups: [[String]] {
        stride(from: 0, to: tags.count, by: 3).map { start in
            Array(tags[start..<min(start + 3, tags.count)])
        }
    }
}

#Preview {
    MyPageView()
        .environmentObject(SessionStore())
        .environmentObject(BookmarkStore())
        .environmentObject(ReviewStore())
        .environmentObject(CafeListViewModel())
}
