import SwiftUI

struct MyPageView: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var bookmarkStore: BookmarkStore
    @EnvironmentObject private var reviewStore: ReviewStore
    @EnvironmentObject private var cafeListViewModel: CafeListViewModel
    @EnvironmentObject private var toastCenter: AppToastCenter
    @EnvironmentObject private var userPreferenceStore: UserPreferenceStore
    @State private var isPresentingProfileEditor = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileCard
                    errorSection
                    activitySummary
                    recentActivitySection
                    myReviewSection
                    savedCafeSection
                    preferenceSection
                    supportSection
                    legalSection
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
            .sheet(isPresented: $isPresentingProfileEditor) {
                ProfilePreferencesView(
                    initialNickname: sessionStore.currentUser?.nickname ?? "",
                    initialPreferences: userPreferenceStore.preferences,
                    availableCities: availableCities,
                    availableTags: availableVibeTags
                ) { submission in
                    try await sessionStore.updateNickname(submission.nickname)
                    userPreferenceStore.save(
                        preferredCity: submission.preferredCity,
                        favoriteVibeTags: submission.favoriteVibeTags,
                        profileNote: submission.profileNote
                    )
                    toastCenter.showSuccess(
                        title: "프로필을 업데이트했어요",
                        message: "취향과 기본 정보를 저장했어요.",
                        systemImage: "person.crop.circle.badge.checkmark"
                    )
                }
                .presentationDetents([.large])
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

    private var errorSection: some View {
        VStack(spacing: 12) {
            if let errorMessage = cafeListViewModel.errorMessage {
                ErrorStateCard(
                    title: "카페 정보를 불러오지 못했어요",
                    message: errorMessage,
                    buttonTitle: "다시 불러오기"
                ) {
                    Task {
                        await cafeListViewModel.refresh()
                        await reviewStore.refreshMyReviews(using: cafeListViewModel.cafes)
                    }
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

            if let errorMessage = reviewStore.errorMessage {
                ErrorStateCard(
                    title: "리뷰 기록을 불러오지 못했어요",
                    message: errorMessage,
                    buttonTitle: "다시 불러오기"
                ) {
                    Task { await reviewStore.refreshMyReviews(using: cafeListViewModel.cafes) }
                }
            }
        }
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("BREW PASSPORT")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.white.opacity(0.74))

                    Text(sessionStore.currentUser?.nickname ?? "게스트")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    Text(sessionStore.currentUser?.email ?? "이메일 정보 없음")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.82))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 10) {
                    Button("프로필 편집") {
                        isPresentingProfileEditor = true
                    }
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.16))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())

                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 64, height: 64)

                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                    }
                }
            }

            Text(profileNote ?? "좋아하는 공간을 저장하고 리뷰를 남기며, 나만의 카페 취향을 차분하게 쌓아가는 브루 기록이에요.")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.84))

            HStack(spacing: 12) {
                profileMetricCard(title: "저장한 카페", value: "\(bookmarkedCafes.count)", caption: "컬렉션")
                profileMetricCard(title: "작성한 리뷰", value: "\(myReviewItems.count)", caption: "기록")
            }

            HStack(spacing: 8) {
                infoPill(title: favoriteTags.isEmpty ? "취향 태그 준비 중" : "\(favoriteTags.count)개 취향 태그", systemImage: "tag.fill")
                infoPill(title: preferredCity ?? (exploredCategories.isEmpty ? "첫 셀렉션 전" : exploredCategories.prefix(2).joined(separator: " • ")), systemImage: preferredCity == nil ? "sparkles" : "mappin.circle.fill")
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
            RoundedRectangle(cornerRadius: 26)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 26))
    }

    private var activitySummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("브루 요약")
                .font(.headline)

            HStack(spacing: 12) {
                summaryCard(title: "저장한 카페", value: "\(bookmarkedCafes.count)", caption: "컬렉션", systemImage: "bookmark.fill")
                summaryCard(title: "작성한 리뷰", value: "\(myReviewItems.count)", caption: "리뷰 노트", systemImage: "square.and.pencil")
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("최근 기록")
                    .font(.headline)

                Spacer()

                Text("\(recentActivityItems.count)건")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if recentActivityItems.isEmpty {
                emptyStateCard(
                    title: "활동 기록이 아직 없어요",
                    message: "카페를 저장하거나 리뷰를 남기면 최근 기록이 여기에 차분히 쌓여요.",
                    systemImage: "clock.arrow.circlepath",
                    hint: "첫 저장이나 첫 리뷰가 생기면 이 공간도 바로 채워져요."
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
                Text("내가 남긴 노트")
                    .font(.headline)

                Spacer()

                Text("\(myReviewItems.count)개")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if myReviewItems.isEmpty {
                emptyStateCard(
                    title: "아직 남긴 노트가 없어요",
                    message: "카페 상세에서 리뷰를 남기면 내 기록으로 여기에 차곡차곡 쌓여요.",
                    systemImage: "square.and.pencil",
                    hint: "마음에 남은 공간부터 한 줄씩 남겨보세요."
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
                Text("저장 컬렉션")
                    .font(.headline)

                Spacer()

                Text("\(bookmarkedCafes.count)곳")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if bookmarkedCafes.isEmpty {
                emptyStateCard(
                    title: "저장한 카페가 아직 없어요",
                    message: "탐색 화면에서 마음에 드는 카페를 저장하면 이 컬렉션에 모아볼 수 있어요.",
                    systemImage: "bookmark",
                    hint: "지금 마음에 드는 공간을 저장해 두면 다시 찾기 쉬워져요."
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
            HStack {
                Text("취향 태그")
                    .font(.headline)

                Spacer()

                Button("편집") {
                    isPresentingProfileEditor = true
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.brewBrown)
            }

            if favoriteTags.isEmpty, preferredCity == nil, profileNote == nil {
                emptyStateCard(
                    title: "취향 태그가 아직 없어요",
                    message: "카페를 저장하거나 프로필 편집에서 직접 취향을 고르면 여기에서 정리돼요.",
                    systemImage: "tag",
                    hint: "선호 동네와 분위기 태그를 먼저 골라둘 수도 있어요."
                )
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    if let preferredCity {
                        preferenceSpotlightCard(
                            title: "선호 동네",
                            value: preferredCity,
                            subtitle: "탐색 기준으로 먼저 떠올리고 싶은 지역이에요.",
                            systemImage: "mappin.circle.fill"
                        )
                    }

                    if let profileNote {
                        preferenceSpotlightCard(
                            title: "요즘 찾는 분위기",
                            value: profileNote,
                            subtitle: "프로필 편집에서 언제든 다시 바꿀 수 있어요.",
                            systemImage: "text.quote"
                        )
                    }

                    if !favoriteTags.isEmpty {
                        FlowTagView(tags: favoriteTags)
                    }
                }
            }
        }
    }

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("도움말")
                .font(.headline)

            actionRow(
                title: "문의 메일",
                subtitle: AppConfig.supportEmail,
                systemImage: "envelope"
            ) {
                open(AppConfig.supportMailURL())
            }

            actionRow(
                title: "지원 페이지",
                subtitle: "도움말과 문의 경로를 웹에서 확인해요.",
                systemImage: "questionmark.bubble"
            ) {
                open(AppConfig.supportPageURL)
            }
        }
    }

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("정책 안내")
                .font(.headline)

            actionRow(
                title: "개인정보처리방침",
                subtitle: "수집 항목과 이용 목적을 확인해요.",
                systemImage: "hand.raised"
            ) {
                open(AppConfig.privacyPolicyURL)
            }

            actionRow(
                title: "이용약관",
                subtitle: "서비스 이용 기준과 책임 범위를 확인해요.",
                systemImage: "doc.text"
            ) {
                open(AppConfig.termsURL)
            }
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("계정 관리")
                .font(.headline)

            infoRow(
                title: "계정 삭제 요청",
                subtitle: "삭제가 필요하면 문의 메일로 요청해 주세요.",
                detail: "메일 열기",
                systemImage: "person.crop.circle.badge.exclamationmark"
            ) {
                open(
                    AppConfig.supportMailURL(
                        subject: "BrewSpot 계정 삭제 요청",
                        body: "삭제를 원하는 계정 이메일:\n요청 사유:\n"
                    )
                )
            }

            staticInfoRow(
                title: "앱 버전",
                subtitle: appVersionText,
                systemImage: "info.circle"
            )

            Button("로그아웃하기") {
                Task { await sessionStore.signOut() }
            }
            .buttonStyle(.bordered)
            .tint(Color.brewBrown)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var favoriteTags: [String] {
        if !userPreferenceStore.preferences.favoriteVibeTags.isEmpty {
            return userPreferenceStore.preferences.favoriteVibeTags
        }

        return Array(Set(bookmarkedCafes.flatMap(\.vibeTags))).sorted()
    }

    private var exploredCategories: [String] {
        Array(Set(bookmarkedCafes.map(\.category))).sorted()
    }

    private var preferredCity: String? {
        let explicitCity = userPreferenceStore.preferences.preferredCity.trimmingCharacters(in: .whitespacesAndNewlines)
        return explicitCity.isEmpty ? nil : explicitCity
    }

    private var profileNote: String? {
        let note = userPreferenceStore.preferences.profileNote.trimmingCharacters(in: .whitespacesAndNewlines)
        return note.isEmpty ? nil : note
    }

    private var availableCities: [String] {
        Array(Set(cafes.map(\.city))).sorted()
    }

    private var availableVibeTags: [String] {
        Array(Set(cafes.flatMap(\.vibeTags))).sorted()
    }

    private func cafe(id: UUID) -> Cafe? {
        cafes.first { $0.id == id }
    }

    private var appVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
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
        .background(Color.white.opacity(0.82))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.brewBrown.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func preferenceSpotlightCard(title: String, value: String, subtitle: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.brewBrown)
                .frame(width: 36, height: 36)
                .background(Color.brewLatte)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white.opacity(0.82))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.brewBrown.opacity(0.08), lineWidth: 1)
        )
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
        .background(Color.white.opacity(0.82))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.brewBrown.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func actionRow(
        title: String,
        subtitle: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.brewBrown)
                    .frame(width: 34, height: 34)
                    .background(Color.brewLatte)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color.white.opacity(0.82))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.brewBrown.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private func infoRow(
        title: String,
        subtitle: String,
        detail: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.brewBrown)
                    .frame(width: 34, height: 34)
                    .background(Color.brewLatte)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Text(detail)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.brewBrown)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color.white.opacity(0.82))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.brewBrown.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private func staticInfoRow(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.brewBrown)
                .frame(width: 34, height: 34)
                .background(Color.brewLatte)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white.opacity(0.82))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.brewBrown.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func open(_ url: URL?) {
        guard let url else { return }
        openURL(url)
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
        .background(Color.white.opacity(0.82))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.brewBrown.opacity(0.08), lineWidth: 1)
        )
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
        .background(Color.white.opacity(0.82))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.brewBrown.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func profileMetricCard(title: String, value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.7))

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

    private func infoPill(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.14))
            .clipShape(Capsule())
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
        .environmentObject(AppToastCenter())
        .environmentObject(UserPreferenceStore())
}
