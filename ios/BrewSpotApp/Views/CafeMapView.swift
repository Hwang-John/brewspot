import SwiftUI
import MapKit

struct CafeMapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.5575, longitude: 126.9241),
        span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
    )
    @State private var selectedCafe: Cafe?

    private let cafes: [Cafe] = [
        Cafe(name: "성수커피", address: "서울 성동구 성수동", category: "스페셜티", latitude: 37.5445, longitude: 127.0561),
        Cafe(name: "연남카페", address: "서울 마포구 연남동", category: "로스팅", latitude: 37.5651, longitude: 126.9234),
        Cafe(name: "망원카페", address: "서울 마포구 망원동", category: "브런치", latitude: 37.5565, longitude: 126.9018)
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: $region, annotationItems: cafes) { cafe in
                MapAnnotation(coordinate: cafe.coordinate) {
                    Button {
                        selectedCafe = cafe
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.red)
                            Text(cafe.name)
                                .font(.caption2)
                                .bold()
                                .foregroundColor(.primary)
                                .padding(4)
                                .background(.regularMaterial)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .cornerRadius(20)
            .shadow(radius: 4)

            if let cafe = selectedCafe {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(cafe.name)
                            .font(.headline)
                        Text(cafe.address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("카테고리: \(cafe.category)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)

                    Button("닫기") {
                        selectedCafe = nil
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color(.systemBackground).opacity(0.95))
                .cornerRadius(20)
                .padding(.horizontal)
            }
        }
        .frame(height: 420)
        .padding(.horizontal)
        .sheet(item: $selectedCafe) { cafe in
            CafeDetailView(cafe: cafe)
        }
    }
}

#Preview {
    CafeMapView()
}
