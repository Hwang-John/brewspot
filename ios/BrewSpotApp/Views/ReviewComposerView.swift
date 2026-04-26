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
    @FocusState private var focusedField: Field?

    private enum Field {
        case nickname
        case menu
        case note
    }

    init(cafeName: String, initialNickname: String = "", onSubmit: @escaping (Submission) async throws -> Void) {
        self.cafeName = cafeName
        self.initialNickname = initialNickname
        self.onSubmit = onSubmit
        _nickname = State(initialValue: initialNickname)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brewCream.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        headerCard
                        authorCard
                        ratingCard
                        menuCard
                        noteCard

                        if isSubmitDisabled {
                            helperNotice
                        }
                    }
                    .padding(24)
                    .padding(.bottom, 110)
                }
            }
            .navigationTitle("리뷰 남기기")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                submitBar
            }
            .alert("리뷰를 저장하지 못했어요", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "잠시 후 다시 시도해 주세요.")
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
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
            errorMessage = "리뷰를 저장하지 못했어요."
        }
    }

    private var isSubmitDisabled: Bool {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        recommendedMenu.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        visitNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var ratingDescription: String {
        switch selectedRating {
        case 5: return "다시 찾고 싶은 카페였어요."
        case 4: return "추천하고 싶은 방문이었어요."
        case 3: return "편안하게 머물렀어요."
        case 2: return "조금 아쉬움이 남았어요."
        default: return "다음엔 다른 선택을 할 것 같아요."
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(cafeName)
                .font(.title2.bold())

            Text("오늘의 한 잔과 공간 인상을 짧게 남겨보세요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.brewLatte, Color.brewCream],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var authorCard: some View {
        inputCard(title: "이름", subtitle: "리뷰에 표시될 이름이에요.") {
            TextField("닉네임", text: $nickname)
                .focused($focusedField, equals: .nickname)
                .textInputAutocapitalization(.never)
                .padding(14)
                .background(Color.white.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var ratingCard: some View {
        inputCard(title: "평점", subtitle: ratingDescription) {
            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { rating in
                    Button {
                        selectedRating = rating
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: selectedRating >= rating ? "star.fill" : "star")
                                .font(.title3)
                            Text("\(rating)")
                                .font(.caption.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(selectedRating >= rating ? Color.brewBrown : .secondary)
                        .background(selectedRating == rating ? Color.brewLatte : Color.white.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var menuCard: some View {
        inputCard(title: "추천 메뉴", subtitle: "가장 기억에 남은 메뉴를 적어주세요.") {
            VStack(alignment: .leading, spacing: 10) {
                TextField("예: 플랫화이트", text: $recommendedMenu)
                    .focused($focusedField, equals: .menu)
                    .padding(14)
                    .background(Color.white.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(["플랫화이트", "아메리카노", "바닐라라떼", "핸드드립"], id: \.self) { menu in
                            Button(menu) {
                                recommendedMenu = menu
                            }
                            .font(.footnote.weight(.semibold))
                            .buttonStyle(.bordered)
                            .tint(Color.brewBrown)
                        }
                    }
                }
            }
        }
    }

    private var noteCard: some View {
        inputCard(title: "방문 노트", subtitle: "분위기와 맛, 다시 찾고 싶은 이유를 짧게 남겨보세요.") {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $visitNote)
                        .focused($focusedField, equals: .note)
                        .frame(minHeight: 140)
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .background(Color.white.opacity(0.82))
                        .clipShape(RoundedRectangle(cornerRadius: 18))

                    if visitNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("예: 조용해서 오래 머물기 좋았고 라떼 밸런스가 좋았어요.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }

                HStack {
                    Text("짧고 선명할수록 읽기 쉬워요.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(visitNote.count)자")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.brewBrown)
                }
            }
        }
    }

    private var helperNotice: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundStyle(Color.brewBrown)

            Text("이름, 메뉴, 방문 노트를 채우면 바로 남길 수 있어요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var submitBar: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    await submit()
                }
            } label: {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    }

                    Text(isSubmitting ? "저장 중..." : "리뷰 남기기")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.brewBrown)
            .disabled(isSubmitDisabled || isSubmitting)

            Text(isSubmitDisabled ? "세 항목을 채우면 바로 남길 수 있어요." : "이대로 바로 남길 수 있어요.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 18)
        .background(.ultraThinMaterial)
    }

    private func inputCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.brewLatte.opacity(0.45))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.brewBrown.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

#Preview {
    ReviewComposerView(cafeName: "성수커피", initialNickname: "브루러버") { _ in }
}
