import SwiftUI

struct CafeDetailView: View {
    @EnvironmentObject private var bookmarkStore: BookmarkStore
    let cafe: Cafe
    @State private var reviews: [CafeReview]
    @State private var isPresentingReviewComposer = false

    init(cafe: Cafe) {
        self.cafe = cafe
        _reviews = State(initialValue: CafeReview.samples(for: cafe))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                heroSection
                statsSection
                summarySection
                featureSection
                locationSection
                reviewsSection
                reviewCallToAction
            }
            .padding(24)
        }
        .navigationTitle("카페 상세")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    bookmarkStore.toggle(cafe)
                } label: {
                    Image(systemName: bookmarkStore.isBookmarked(cafe) ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(Color.brewBrown)
                }
            }
        }
        .background(Color.brewCream.ignoresSafeArea())
        .sheet(isPresented: $isPresentingReviewComposer) {
            ReviewComposerView(cafeName: cafe.name) { review in
                reviews.insert(review, at: 0)
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(cafe.category.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brewBrown)

            Text(cafe.name)
                .font(.largeTitle.bold())

            Text(cafe.shortDescription)
                .font(.body)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Label(String(format: "%.1f", cafe.rating), systemImage: "star.fill")
                Label("\(cafe.reviewCount)개의 리뷰", systemImage: "text.bubble.fill")
                Label(cafe.priceNote, systemImage: "creditcard.fill")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(cafe.vibeTags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.footnote.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.brewLatte)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            infoCard(title: "대표 메뉴", value: cafe.signatureMenu, systemImage: "cup.and.saucer.fill")
            infoCard(title: "운영 시간", value: cafe.openHours, systemImage: "clock.fill")
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("이런 분께 잘 맞아요")
                .font(.headline)

            ForEach(cafe.features, id: \.self) { feature in
                Label(feature, systemImage: "checkmark.seal.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var featureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("카페 소개")
                .font(.headline)

            Text("\(cafe.name)은(는) \(cafe.city)에서 \(cafe.category) 무드를 즐기기 좋은 공간이에요. 대표 메뉴인 \(cafe.signatureMenu)를 중심으로, 방문 목적이 분명한 사용자에게 잘 맞는 구성이 보입니다.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("위치 정보")
                .font(.headline)

            Label(cafe.address, systemImage: "mappin.and.ellipse")
            Label("\(String(format: "%.4f", cafe.latitude)), \(String(format: "%.4f", cafe.longitude))", systemImage: "location")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var reviewCallToAction: some View {
        HStack(spacing: 12) {
            Button {
                bookmarkStore.toggle(cafe)
            } label: {
                Label(
                    bookmarkStore.isBookmarked(cafe) ? "저장됨" : "저장하기",
                    systemImage: bookmarkStore.isBookmarked(cafe) ? "bookmark.fill" : "bookmark"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(Color.brewBrown)

            Button {
                isPresentingReviewComposer = true
            } label: {
                Text("리뷰 쓰기")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.brewBrown)
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
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("방문자 리뷰")
                    .font(.headline)

                Spacer()

                Text("\(reviews.count)개")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ForEach(reviews) { review in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(review.authorName)
                            .font(.subheadline.weight(.semibold))

                        Spacer()

                        Label("\(review.rating)점", systemImage: "star.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.brewBrown)
                    }

                    Text(review.visitNote)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack {
                        Label(review.recommendedMenu, systemImage: "cup.and.saucer.fill")
                        Spacer()
                        Text(review.createdAt)
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
    }
}

#Preview {
    CafeDetailView(
        cafe: Cafe(
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
    .environmentObject(BookmarkStore())
}
