import SwiftUI

struct ErrorStateCard: View {
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.brewBrown)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Text("잠시 후 다시 시도해 주세요.")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.brewBrown)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.7))
                .clipShape(Capsule())

            Button(buttonTitle, action: action)
                .buttonStyle(.bordered)
                .tint(Color.brewBrown)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white.opacity(0.84))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.brewBrown.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    ErrorStateCard(
        title: "데이터를 불러오지 못했어요",
        message: "네트워크 상태를 확인한 뒤 다시 시도해 주세요.",
        buttonTitle: "다시 시도"
    ) {}
    .padding()
    .background(Color.brewCream)
}
