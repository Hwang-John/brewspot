import SwiftUI

struct CafeRankingView: View {
    private enum RankingMode: String, CaseIterable, Identifiable {
        case overall = "종합"
        case rating = "평점"
        case reviews = "리뷰"
        case nearby = "내 주변"

        var id: String { rawValue }
    }

    private struct RankingEntry: Identifiable {
        let rank: Int
        let cafe: Cafe
        let highlight: String
        let detail: String

        var id: UUID { cafe.id }
    }

    @EnvironmentObject private var cafeListViewModel: CafeListViewModel
    @EnvironmentObject private var locationStore: LocationStore

    @State private var selectedMode: RankingMode = .overall
    @State private var selectedCity = "전체"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroCard
                    controlCard

                    if let errorMessage = cafeListViewModel.errorMessage {
                        ErrorStateCard(
                            title: "랭킹 데이터를 불러오지 못했어요",
                            message: errorMessage,
                            buttonTitle: "다시 불러오기"
                        ) {
                            Task { await cafeListViewModel.refresh() }
                        }
                    }

                    if cafeListViewModel.isLoading {
                        ProgressView("랭킹을 계산하고 있어요...")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    rankingListSection
                }
                .padding(24)
            }
            .background(Color.brewCream.ignoresSafeArea())
            .navigationTitle("랭킹")
            .task {
                await cafeListViewModel.loadIfNeeded()
            }
        }
    }

    private var cities: [String] {
        ["전체"] + Array(Set(cafeListViewModel.cafes.map(\.city))).sorted()
    }

    private var filteredCafes: [Cafe] {
        cafeListViewModel.cafes.filter { cafe in
            selectedCity == "전체" || cafe.city == selectedCity
        }
    }

    private var rankingEntries: [RankingEntry] {
        let sorted: [Cafe]

        switch selectedMode {
        case .overall:
            sorted = filteredCafes.sorted { lhs, rhs in
                overallScore(for: lhs) > overallScore(for: rhs)
            }
        case .rating:
            sorted = filteredCafes.sorted {
                ($0.rating, $0.reviewCount) > ($1.rating, $1.reviewCount)
            }
        case .reviews:
            sorted = filteredCafes.sorted {
                ($0.reviewCount, $0.rating) > ($1.reviewCount, $1.rating)
            }
        case .nearby:
            sorted = filteredCafes.sorted {
                (locationStore.distance(to: $0.coordinate) ?? .greatestFiniteMagnitude)
                < (locationStore.distance(to: $1.coordinate) ?? .greatestFiniteMagnitude)
            }
        }

        return Array(sorted.prefix(10)).enumerated().map { index, cafe in
            RankingEntry(
                rank: index + 1,
                cafe: cafe,
                highlight: highlightText(for: cafe),
                detail: detailText(for: cafe)
            )
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("BREW RANK")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.82))

                    Text("지금 주목할 카페 랭킹")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }

                Spacer()

                Text(cafeListViewModel.sourceDescription)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.brewMocha)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.92))
                    .clipShape(Capsule())
            }

            Text("평점, 리뷰 수, 현재 위치를 기준으로 BrewSpot 안의 카페 흐름을 한눈에 볼 수 있어요.")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.84))

            HStack(spacing: 12) {
                metricCard(title: "랭킹 모드", value: selectedMode.rawValue, caption: selectedCity == "전체" ? "전체 동네" : selectedCity)
                metricCard(title: "표시 수", value: "\(rankingEntries.count)곳", caption: "Top 10 기준")
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

    private var controlCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("랭킹 필터")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(RankingMode.allCases) { mode in
                    Button(mode.rawValue) {
                        selectedMode = mode
                    }
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(selectedMode == mode ? Color.brewBrown : Color.brewLatte)
                    .foregroundStyle(selectedMode == mode ? .white : .primary)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(cities, id: \.self) { city in
                        Button(city) {
                            selectedCity = city
                        }
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(selectedCity == city ? Color.brewBrown : Color.white.opacity(0.84))
                        .foregroundStyle(selectedCity == city ? .white : .primary)
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white.opacity(0.8))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.brewBrown.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var rankingListSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Top Cafes")
                    .font(.headline)

                Spacer()

                Text(rankingNote)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if rankingEntries.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("랭킹에 표시할 카페가 아직 없어요")
                        .font(.headline)

                    Text(selectedCity == "전체" ? "시드 데이터가 준비되면 랭킹 카드가 채워져요." : "\(selectedCity) 기준 카페가 더 들어오면 랭킹이 표시돼요.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color.white.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: 22))
            } else {
                ForEach(rankingEntries) { entry in
                    NavigationLink {
                        CafeDetailView(cafe: entry.cafe)
                    } label: {
                        rankingCard(entry)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var rankingNote: String {
        switch selectedMode {
        case .overall:
            return "평점 + 리뷰 균형"
        case .rating:
            return "평점 우선"
        case .reviews:
            return "리뷰 수 우선"
        case .nearby:
            return locationStore.currentLocation == nil ? "위치 미확인" : "거리 우선"
        }
    }

    private func rankingCard(_ entry: RankingEntry) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 6) {
                Text("\(entry.rank)")
                    .font(.title2.bold())
                    .foregroundStyle(entry.rank <= 3 ? Color.brewBrown : .primary)

                Text(entry.rank == 1 ? "TOP" : "#")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 42)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(entry.cafe.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(entry.highlight)
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Color.brewBrown)
                }

                Text("\(entry.cafe.city) • \(entry.cafe.category)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(entry.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 10) {
                    pill("평점 \(String(format: "%.1f", entry.cafe.rating))")
                    pill("리뷰 \(entry.cafe.reviewCount)개")
                    if let distanceText = locationStore.distanceText(to: entry.cafe.coordinate) {
                        pill(distanceText)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.95), Color.brewLatte.opacity(0.52)],
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

    private func metricCard(title: String, value: String, caption: String) -> some View {
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

    private func pill(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.brewBrown)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.82))
            .clipShape(Capsule())
    }

    private func overallScore(for cafe: Cafe) -> Double {
        cafe.rating * 20 + Double(min(cafe.reviewCount, 30)) * 1.8
    }

    private func highlightText(for cafe: Cafe) -> String {
        switch selectedMode {
        case .overall:
            return "\(Int(overallScore(for: cafe).rounded()))점"
        case .rating:
            return String(format: "%.1f★", cafe.rating)
        case .reviews:
            return "리뷰 \(cafe.reviewCount)"
        case .nearby:
            return locationStore.distanceText(to: cafe.coordinate) ?? "거리 미확인"
        }
    }

    private func detailText(for cafe: Cafe) -> String {
        switch selectedMode {
        case .overall:
            return "평점과 리뷰 수를 함께 반영한 지금 기준 추천 순위예요."
        case .rating:
            return "리뷰가 어느 정도 쌓인 카페 중 평점이 높은 순서예요."
        case .reviews:
            return "사용자 기록이 많이 쌓인 카페부터 먼저 보여줘요."
        case .nearby:
            return locationStore.currentLocation == nil
                ? "현재 위치를 허용하면 내 주변 랭킹으로 더 정확하게 정렬돼요."
                : "현재 위치에서 가까운 카페부터 빠르게 비교할 수 있어요."
        }
    }
}

#Preview {
    CafeRankingView()
        .environmentObject(CafeListViewModel())
        .environmentObject(LocationStore())
}
