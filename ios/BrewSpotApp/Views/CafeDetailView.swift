import SwiftUI

struct CafeDetailView: View {
    @EnvironmentObject private var bookmarkStore: BookmarkStore
    @EnvironmentObject private var reviewStore: ReviewStore
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var toastCenter: AppToastCenter
    let cafe: Cafe
    @State private var isPresentingReviewComposer = false
    @State private var isTogglingBookmark = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                heroSection
                statsSection
                summarySection
                featureSection
                locationSection
                reviewsSection
                Color.clear
                    .frame(height: 8)
            }
            .padding(24)
        }
        .navigationTitle("카페 상세")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: cafe.id) {
            await reviewStore.loadReviews(for: cafe)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await toggleBookmarkWithFeedback()
                    }
                } label: {
                    if isTogglingBookmark {
                        ProgressView()
                            .tint(Color.brewBrown)
                    } else {
                        Image(systemName: bookmarkStore.isBookmarked(cafe) ? "bookmark.fill" : "bookmark")
                            .foregroundStyle(Color.brewBrown)
                    }
                }
            }
        }
        .background(Color.brewCream.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            actionBar
        }
        .sheet(isPresented: $isPresentingReviewComposer) {
            ReviewComposerView(cafeName: cafe.name, initialNickname: sessionStore.currentUser?.nickname ?? "") { submission in
                try await reviewStore.addReview(
                    cafe: cafe,
                    authorNickname: submission.authorName,
                    rating: submission.rating,
                    visitNote: submission.visitNote,
                    recommendedMenu: submission.recommendedMenu
                )
                toastCenter.showSuccess(
                    title: "리뷰를 남겼어요",
                    message: "\(cafe.name)에 오늘의 노트를 저장했어요.",
                    systemImage: "checkmark.bubble.fill"
                )
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var reviews: [CafeReview] {
        reviewStore.reviews(for: cafe)
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                HStack(spacing: 8) {
                    detailBadge(cafe.city, tint: Color.brewMocha, fill: Color.white.opacity(0.88))
                    detailBadge(cafe.category.uppercased(), tint: .white, fill: Color.white.opacity(0.14))
                }

                Spacer()

                detailBadge(cafe.priceNote, tint: .white, fill: Color.white.opacity(0.14))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(cafe.name)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text(cafe.shortDescription)
                    .font(.body)
                    .foregroundStyle(Color.white.opacity(0.84))
            }

            CafeArtworkView(cafe: cafe, variant: .hero)

            HStack(spacing: 12) {
                heroInfoCard(title: "평점", value: String(format: "%.1f", cafe.rating), systemImage: "star.fill")
                heroInfoCard(title: "리뷰", value: "\(cafe.reviewCount)개", systemImage: "text.bubble.fill")
                heroInfoCard(title: "대표 메뉴", value: cafe.signatureMenu, systemImage: "cup.and.saucer.fill")
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("BREW NOTES")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.white.opacity(0.76))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(cafe.vibeTags, id: \.self) { tag in
                            detailBadge("#\(tag)", tint: .white, fill: Color.white.opacity(0.12))
                        }
                    }
                }
            }
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [Color.brewMocha, Color.brewBrown],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            infoCard(title: "시그니처 메뉴", value: cafe.signatureMenu, systemImage: "cup.and.saucer.fill")
            infoCard(title: "운영 시간", value: cafe.openHours, systemImage: "clock.fill")
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("이런 순간에 잘 어울려요")
                .font(.headline)

            ForEach(cafe.features, id: \.self) { feature in
                Label(feature, systemImage: "checkmark.seal.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
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

    private var featureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("공간 노트")
                .font(.headline)

            Text("\(cafe.name)은(는) \(cafe.city)에서 \(cafe.category) 무드를 즐기기 좋은 공간이에요. \(cafe.signatureMenu)를 중심으로, 짧게 머물러도 분위기가 또렷하게 남는 카페예요.")
                .font(.body)
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

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("찾아가기")
                .font(.headline)

            Label(cafe.address, systemImage: "mappin.and.ellipse")
            Label("\(String(format: "%.4f", cafe.latitude)), \(String(format: "%.4f", cafe.longitude))", systemImage: "location")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .padding(18)
        .background(Color.white.opacity(0.82))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.brewBrown.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                Task {
                    await toggleBookmarkWithFeedback()
                }
            } label: {
                Label(
                    bookmarkStore.isBookmarked(cafe) ? "저장됨" : "컬렉션 저장",
                    systemImage: bookmarkStore.isBookmarked(cafe) ? "bookmark.fill" : "bookmark"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(Color.brewBrown)

            Button {
                isPresentingReviewComposer = true
            } label: {
                Text("리뷰 남기기")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.brewBrown)
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 18)
        .background(.ultraThinMaterial)
    }

    private func toggleBookmarkWithFeedback() async {
        isTogglingBookmark = true
        defer { isTogglingBookmark = false }

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

    private func infoCard(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.82))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.brewBrown.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("방문 노트")
                    .font(.headline)

                Spacer()

                Text("\(reviews.count)개")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            reviewInsightCard

            if reviewStore.isLoadingReviews(for: cafe) && reviews.isEmpty {
                ProgressView("리뷰를 불러오는 중...")
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if reviews.isEmpty {
                emptyReviewState
            } else {
                ForEach(reviews) { review in
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(review.authorName)
                                    .font(.headline)

                                Text(review.relativeCreatedAt)
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            reviewScoreBadge(review.rating)
                        }

                        Text(review.visitNote)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { index in
                                Image(systemName: index <= review.rating ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundStyle(index <= review.rating ? Color.brewBrown : Color.brewLatte)
                            }
                        }

                        HStack {
                            Label(review.recommendedMenu, systemImage: "cup.and.saucer.fill")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Color.brewBrown)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.brewLatte.opacity(0.55))
                                .clipShape(Capsule())
                            Spacer()

                            Text("방문 노트")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(Color.white.opacity(0.84))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.brewBrown.opacity(0.08), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                }
            }
        }
    }

    private var reviewInsightCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("REVIEW TONE")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(reviews.isEmpty ? "첫 방문 노트를 기다리고 있어요." : "남겨진 한 줄을 보고 이 공간의 톤을 가늠해보세요.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(String(format: "%.1f", cafe.rating))
                    .font(.title3.bold())
                    .foregroundStyle(Color.brewBrown)

                Text("평균 평점")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.82))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.brewBrown.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var emptyReviewState: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.brewLatte.opacity(0.55))
                        .frame(width: 46, height: 46)

                    Image(systemName: "text.bubble")
                        .foregroundStyle(Color.brewBrown)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("아직 남겨진 노트가 없어요")
                        .font(.headline)

                    Text("첫 방문 노트를 남기고 이 카페의 분위기를 가장 먼저 기록해보세요.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Text("첫 노트가 다음 방문자의 선택을 도와줘요.")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.brewBrown)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.72))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.brewLatte.opacity(0.88), Color.white.opacity(0.92)],
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

    private func reviewScoreBadge(_ rating: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
            Text("\(rating)점")
        }
        .font(.footnote.weight(.bold))
        .foregroundStyle(Color.brewBrown)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.brewLatte.opacity(0.55))
        .clipShape(Capsule())
    }

    private func detailBadge(_ text: String, tint: Color, fill: Color) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(fill)
            .clipShape(Capsule())
    }

    private func heroInfoCard(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.76))

            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    CafeDetailView(
        cafe: Cafe(
            id: UUID(uuidString: "c31f7050-5677-49d1-a3e0-df0c3b0fb001")!,
            name: "성수커피",
            address: "서울 성동구 성수동",
            category: "스페셜티",
            city: "성수",
            latitude: 37.5445,
            longitude: 127.0561,
            rating: 4.8,
            reviewCount: 128,
            priceNote: "1인 7천원대",
            signatureMenu: "플랫화이트",
            shortDescription: "밸런스 좋은 에스프레소와 차분한 좌석 구성이 돋보이는 스페셜티 카페",
            vibeTags: ["조용한", "작업하기 좋은", "원두 선택 폭 넓음"],
            features: ["산미와 고소함 균형이 좋아 첫 방문 만족도가 높아요.", "노트북 좌석이 비교적 넉넉해서 짧은 작업에 적합해요.", "혼자 방문해도 부담 없는 차분한 분위기예요."],
            openHours: "매일 10:00 - 21:00"
        )
    )
    .environmentObject(SessionStore())
    .environmentObject(BookmarkStore())
    .environmentObject(ReviewStore())
}
