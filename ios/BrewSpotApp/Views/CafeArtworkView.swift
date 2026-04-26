import SwiftUI

struct CafeArtworkView: View {
    enum Variant {
        case compact
        case wide
        case hero

        var height: CGFloat {
            switch self {
            case .compact: 96
            case .wide: 112
            case .hero: 148
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .compact: 18
            case .wide: 20
            case .hero: 24
            }
        }

        var cityFont: Font {
            switch self {
            case .compact: .caption2.weight(.bold)
            case .wide: .caption.weight(.bold)
            case .hero: .caption.weight(.bold)
            }
        }

        var labelFont: Font {
            switch self {
            case .compact: .footnote.weight(.semibold)
            case .wide: .subheadline.weight(.semibold)
            case .hero: .headline.weight(.semibold)
            }
        }
    }

    let cafe: Cafe
    let variant: Variant

    var body: some View {
        let style = artworkStyle

        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: variant.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [style.topColor, style.bottomColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(style.glow.opacity(0.36))
                .frame(width: variant == .hero ? 144 : 104, height: variant == .hero ? 144 : 104)
                .offset(x: variant == .hero ? 98 : 72, y: -14)

            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                .frame(width: variant == .hero ? 124 : 86, height: variant == .hero ? 124 : 86)
                .offset(x: variant == .hero ? 132 : 98, y: 26)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(cafe.city.uppercased())
                        .font(variant.cityFont)
                        .foregroundStyle(style.labelColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.16))
                        .clipShape(Capsule())

                    Spacer()

                    Image(systemName: style.systemImage)
                        .font(variant == .hero ? .title2 : .headline)
                        .foregroundStyle(style.iconColor)
                        .frame(width: variant == .hero ? 40 : 34, height: variant == .hero ? 40 : 34)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Circle())
                }

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 5) {
                    Text(style.caption)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(style.labelColor.opacity(0.8))

                    Text(cafe.category)
                        .font(variant.labelFont)
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text(cafe.signatureMenu)
                        .font(.footnote)
                        .foregroundStyle(Color.white.opacity(0.84))
                        .lineLimit(1)
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: variant.height)
        .overlay(
            RoundedRectangle(cornerRadius: variant.cornerRadius)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: variant.cornerRadius))
    }

    private var artworkStyle: ArtworkStyle {
        let lowered = cafe.category.lowercased()

        if lowered.contains("로스터") {
            return ArtworkStyle(
                systemImage: "flame.fill",
                caption: "ROAST PROFILE",
                topColor: Color.brewMocha,
                bottomColor: Color.brewBrown,
                glow: Color.brewLatte,
                iconColor: .white,
                labelColor: Color.white
            )
        }

        if lowered.contains("디저트") || lowered.contains("베이커리") {
            return ArtworkStyle(
                systemImage: "birthday.cake.fill",
                caption: "SWEET TABLE",
                topColor: Color(red: 0.64, green: 0.43, blue: 0.31),
                bottomColor: Color(red: 0.45, green: 0.29, blue: 0.2),
                glow: Color.brewLatte,
                iconColor: .white,
                labelColor: Color.white
            )
        }

        if lowered.contains("브런치") {
            return ArtworkStyle(
                systemImage: "sun.max.fill",
                caption: "BRUNCH SPOT",
                topColor: Color(red: 0.63, green: 0.44, blue: 0.29),
                bottomColor: Color(red: 0.39, green: 0.25, blue: 0.18),
                glow: Color.brewFoam,
                iconColor: .white,
                labelColor: Color.white
            )
        }

        if lowered.contains("작업") || cafe.vibeTags.joined(separator: " ").contains("작업") {
            return ArtworkStyle(
                systemImage: "laptopcomputer",
                caption: "WORK TABLE",
                topColor: Color(red: 0.33, green: 0.22, blue: 0.18),
                bottomColor: Color(red: 0.19, green: 0.13, blue: 0.1),
                glow: Color.brewLatte,
                iconColor: .white,
                labelColor: Color.white
            )
        }

        return ArtworkStyle(
            systemImage: "cup.and.saucer.fill",
            caption: "HOUSE BREW",
            topColor: Color.brewBrown,
            bottomColor: Color.brewMocha,
            glow: Color.brewLatte,
            iconColor: .white,
            labelColor: Color.white
        )
    }
}

private struct ArtworkStyle {
    let systemImage: String
    let caption: String
    let topColor: Color
    let bottomColor: Color
    let glow: Color
    let iconColor: Color
    let labelColor: Color
}

#Preview {
    CafeArtworkView(cafe: Cafe.sampleCafes[0], variant: .hero)
        .padding()
        .background(Color.brewCream)
}
