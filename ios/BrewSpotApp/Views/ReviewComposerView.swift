import SwiftUI

struct ReviewComposerView: View {
    struct Submission {
        let authorName: String
        let rating: Int
        let recommendedMenu: String
        let visitNote: String
    }

    @Environment(\.dismiss) private var dismiss

    let cafeName: String
    let initialNickname: String
    let onSubmit: (Submission) async throws -> Void

    @State private var nickname: String
    @State private var selectedRating = 5
    @State private var recommendedMenu = ""
    @State private var visitNote = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    init(cafeName: String, initialNickname: String = "", onSubmit: @escaping (Submission) async throws -> Void) {
        self.cafeName = cafeName
        self.initialNickname = initialNickname
        self.onSubmit = onSubmit
        _nickname = State(initialValue: initialNickname)
    }

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
            .alert("리뷰 등록에 실패했어요", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "잠시 후 다시 시도해주세요.")
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("등록") {
                        Task {
                            await submit()
                        }
                    }
                    .disabled(isSubmitDisabled || isSubmitting)
                }
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await onSubmit(
                Submission(
                    authorName: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
                    rating: selectedRating,
                    recommendedMenu: recommendedMenu.trimmingCharacters(in: .whitespacesAndNewlines),
                    visitNote: visitNote.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            )
            dismiss()
        } catch {
            errorMessage = "서버에 리뷰를 저장하지 못했어요."
        }
    }

    private var isSubmitDisabled: Bool {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        recommendedMenu.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        visitNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    ReviewComposerView(cafeName: "성수커피", initialNickname: "브루러버") { _ in }
}
