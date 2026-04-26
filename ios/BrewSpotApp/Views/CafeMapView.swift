import SwiftUI
import MapKit
import UIKit

struct CafeMapView: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var locationStore: LocationStore
    let cafes: [Cafe]
    @Binding var selectedCafe: Cafe?

    @State private var cameraPosition: MapCameraPosition = .region(Self.defaultRegion)
    @State private var focusedCafe: Cafe?
    @State private var presentedCafe: Cafe?

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition) {
                if locationStore.isAuthorized, locationStore.currentLocation != nil {
                    UserAnnotation()
                }

                ForEach(cafes) { cafe in
                    Annotation(cafe.name, coordinate: cafe.coordinate, anchor: .bottom) {
                        Button {
                            selectedCafe = cafe
                            focus(on: cafe, animated: true)
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(isSelected(cafe) ? Color.brewBrown : .red)
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
            }
            .cornerRadius(20)
            .shadow(radius: 4)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Label("\(cafes.count)곳 표시 중", systemImage: "map")
                            .font(.footnote.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())

                        Button(locationButtonTitle) {
                            handleLocationButtonTap()
                        }
                        .font(.footnote.weight(.semibold))
                        .buttonStyle(.bordered)
                        .tint(Color.brewBrown)

                        if cafes.count > 1 {
                            Button("전체 보기") {
                                selectedCafe = nil
                                focusedCafe = nil
                                fitMapToVisibleCafes(animated: true)
                            }
                            .font(.footnote.weight(.semibold))
                            .buttonStyle(.bordered)
                            .tint(Color.brewBrown)
                        }
                    }

                    if let nearestCafe, let distanceText = locationStore.distanceText(to: nearestCafe.coordinate) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("가장 가까운 카페")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            HStack(spacing: 6) {
                                Text(nearestCafe.name)
                                    .font(.footnote.weight(.semibold))

                                Text(distanceText)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.brewBrown)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(16)
            }

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
        .onAppear {
            locationStore.refreshLocationIfAuthorized()
            syncMapRegion(animated: false)
        }
        .onChange(of: cafeIDs) { _, _ in
            syncMapRegion(animated: true)
        }
        .onChange(of: selectedCafe?.id) { _, _ in
            syncMapRegion(animated: true)
        }
        .onChange(of: locationStore.currentLocation?.timestamp) { _, _ in
            guard selectedCafe == nil else { return }
            syncMapRegion(animated: true)
        }
        .sheet(item: $presentedCafe) { cafe in
            CafeDetailView(cafe: cafe)
        }
    }

    private var cafeIDs: [UUID] {
        cafes.map(\.id)
    }

    private var nearestCafe: Cafe? {
        locationStore.nearestCafe(in: cafes)
    }

    private var locationButtonTitle: String {
        switch locationStore.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return "내 위치"
        case .denied, .restricted:
            return "설정 열기"
        case .notDetermined:
            return "위치 사용"
        @unknown default:
            return "위치"
        }
    }

    private func isSelected(_ cafe: Cafe) -> Bool {
        selectedCafe?.id == cafe.id
    }

    private func syncMapRegion(animated: Bool) {
        guard !cafes.isEmpty else {
            focusedCafe = nil
            updateRegion(Self.defaultRegion, animated: animated)
            return
        }

        if let selectedCafe, let visibleSelection = cafes.first(where: { $0.id == selectedCafe.id }) {
            focus(on: visibleSelection, animated: animated)
            return
        }

        if let focusedCafe, cafes.contains(where: { $0.id == focusedCafe.id }) {
            focus(on: focusedCafe, animated: animated)
            return
        }

        focusedCafe = cafes.count == 1 ? cafes.first : nil
        fitMapToVisibleCafes(animated: animated)
    }

    private func focus(on cafe: Cafe, animated: Bool) {
        focusedCafe = cafe
        let focusedRegion = MKCoordinateRegion(
            center: cafe.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
        )
        updateRegion(focusedRegion, animated: animated)
    }

    private func fitMapToVisibleCafes(animated: Bool) {
        if cafes.isEmpty, let userRegion = regionForCurrentLocation() {
            updateRegion(userRegion, animated: animated)
            return
        }

        guard let firstCafe = cafes.first else {
            updateRegion(regionForCurrentLocation() ?? Self.defaultRegion, animated: animated)
            return
        }

        guard cafes.count > 1 else {
            let singleCafeRegion = MKCoordinateRegion(
                center: firstCafe.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
            )
            updateRegion(singleCafeRegion, animated: animated)
            return
        }

        let latitudes = cafes.map(\.latitude)
        let longitudes = cafes.map(\.longitude)
        let minLatitude = latitudes.min() ?? firstCafe.latitude
        let maxLatitude = latitudes.max() ?? firstCafe.latitude
        let minLongitude = longitudes.min() ?? firstCafe.longitude
        let maxLongitude = longitudes.max() ?? firstCafe.longitude

        let center = CLLocationCoordinate2D(
            latitude: (minLatitude + maxLatitude) / 2,
            longitude: (minLongitude + maxLongitude) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLatitude - minLatitude) * 1.7, 0.018),
            longitudeDelta: max((maxLongitude - minLongitude) * 1.7, 0.018)
        )

        updateRegion(MKCoordinateRegion(center: center, span: span), animated: animated)
    }

    private func handleLocationButtonTap() {
        switch locationStore.authorizationStatus {
        case .notDetermined:
            locationStore.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationStore.refreshLocationIfAuthorized()
            if let userRegion = regionForCurrentLocation() {
                focusedCafe = nil
                selectedCafe = nil
                updateRegion(userRegion, animated: true)
            }
        case .denied, .restricted:
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
            openURL(settingsURL)
        @unknown default:
            break
        }
    }

    private func regionForCurrentLocation() -> MKCoordinateRegion? {
        guard let currentLocation = locationStore.currentLocation else { return nil }

        return MKCoordinateRegion(
            center: currentLocation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
        )
    }

    private func updateRegion(_ newRegion: MKCoordinateRegion, animated: Bool) {
        if animated {
            withAnimation(.easeInOut(duration: 0.25)) {
                cameraPosition = .region(newRegion)
            }
        } else {
            cameraPosition = .region(newRegion)
        }
    }

    private static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.5575, longitude: 126.9241),
        span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
    )
}

#Preview {
    CafeMapView(cafes: Cafe.sampleCafes, selectedCafe: .constant(nil))
        .environmentObject(LocationStore())
}
