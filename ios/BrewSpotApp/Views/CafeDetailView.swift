import SwiftUI

struct CafeDetailView: View {
    let cafe: Cafe

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(cafe.name)
                    .font(.largeTitle.bold())

                Text(cafe.category)
                    .font(.headline)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 10) {
                    Label(cafe.address, systemImage: "mappin.and.ellipse")
                    Label("\(String(format: "%.4f", cafe.latitude)), \(String(format: "%.4f", cafe.longitude))", systemImage: "location")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)

                Text("카페 소개")
                    .font(.headline)

                Text("\(cafe.name)은(는) \(cafe.category) 스타일의 카페로, 지역에서 인기 있는 장소입니다. 실제 방문자 리뷰와 사진을 추가해 카페 정보를 풍성하게 만들 수 있습니다.")
                    .font(.body)
                    .foregroundColor(.secondary)

                Button(action: {}) {
                    Text("리뷰 쓰기")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brewBrown)
                .padding(.top)
            }
            .padding(24)
        }
        .navigationTitle("카페 상세")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.brewCream.ignoresSafeArea())
    }
}

#Preview {
    CafeDetailView(cafe: Cafe(name: "성수커피", address: "서울 성동구 성수동", category: "스페셜티", latitude: 37.5445, longitude: 127.0561))
}
