import SwiftUI

struct ReviewComposerView: View {
    @Environment(\.dismiss) private var dismiss

    let cafeName: String
    let onSubmit: (CafeReview) -> Void

    @State private var nickname = ""
    @State private var selectedRating = 5
    @State private var recommendedMenu = ""
    @State private var visitNote = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("\(cafeName)에 대한 방문 경험을 간단히 남겨보세요.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("작성자") {
                    TextField("닉네임", text: $nickname)
                }

                Section("평점") {
                    Picker("평점", selection: $selectedRating) {
                        ForEach(1...5, id: \.self) { rating in
                            Text("\(rating)점").tag(rating)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("추천 메뉴") {
                    TextField("예: 플랫화이트", text: $recommendedMenu)
                }

                Section("한 줄 후기") {
                    TextField("방문 경험을 적어주세요", text: $visitNote, axis: .vertical)
                        .lineLimit(4...6)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.brewCream)
            .navigationTitle("리뷰 쓰기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("등록") {
                        onSubmit(
                            CafeReview(
                                authorName: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
                                rating: selectedRating,
                                visitNote: visitNote.trimmingCharacters(in: .whitespacesAndNewlines),
                                recommendedMenu: recommendedMenu.trimmingCharacters(in: .whitespacesAndNewlines),
                                createdAt: "방금"
                            )
                        )
                        dismiss()
                    }
                    .disabled(isSubmitDisabled)
                }
            }
        }
    }

    private var isSubmitDisabled: Bool {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        recommendedMenu.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        visitNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    ReviewComposerView(cafeName: "성수커피") { _ in }
}
