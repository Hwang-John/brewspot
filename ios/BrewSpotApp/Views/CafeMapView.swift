import SwiftUI
import MapKit

struct CafeMapView: View {
    let cafes: [Cafe]

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.5575, longitude: 126.9241),
        span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
    )
    @State private var focusedCafe: Cafe?
    @State private var presentedCafe: Cafe?

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: $region, annotationItems: cafes) { cafe in
                MapAnnotation(coordinate: cafe.coordinate) {
                    Button {
                        focusedCafe = cafe
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

            if let cafe = focusedCafe {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(cafe.name)
                                .font(.headline)

                            Spacer()

                            Label(String(format: "%.1f", cafe.rating), systemImage: "star.fill")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Color.brewBrown)
                        }

                        Text(cafe.address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("\(cafe.category) • \(cafe.signatureMenu)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)

                    Button("상세 보기") {
                        presentedCafe = cafe
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.brewBrown)
                    .frame(maxWidth: .infinity)

                    Button("닫기") {
                        focusedCafe = nil
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
        .sheet(item: $presentedCafe) { cafe in
            CafeDetailView(cafe: cafe)
        }
    }
}

#Preview {
    CafeMapView(cafes: Cafe.sampleCafes)
}
