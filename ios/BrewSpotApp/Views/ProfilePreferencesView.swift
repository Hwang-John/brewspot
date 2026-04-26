import SwiftUI

struct ProfilePreferencesView: View {
    struct Submission {
        let nickname: String
        let preferredCity: String
        let favoriteVibeTags: [String]
        let profileNote: String
    }

    @Environment(\.dismiss) private var dismiss

    let initialNickname: String
    let initialPreferences: UserPreferenceData
    let availableCities: [String]
    let availableTags: [String]
    let onSave: (Submission) async throws -> Void

    @State private var nickname: String
    @State private var preferredCity: String
    @State private var selectedTags: [String]
    @State private var profileNote: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(
        initialNickname: String,
        initialPreferences: UserPreferenceData,
        availableCities: [String],
        availableTags: [String],
        onSave: @escaping (Submission) async throws -> Void
    ) {
        self.initialNickname = initialNickname
        self.initialPreferences = initialPreferences
        self.availableCities = availableCities
        self.availableTags = availableTags
        self.onSave = onSave

        _nickname = State(initialValue: initialNickname)
        _preferredCity = State(initialValue: initialPreferences.preferredCity)
        _selectedTags = State(initialValue: initialPreferences.favoriteVibeTags)
        _profileNote = State(initialValue: initialPreferences.profileNote)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    introCard
                    nicknameCard
                    preferredCityCard
                    tasteTagCard
                    noteCard
                }
                .padding(24)
                .padding(.bottom, 110)
            }
            .background(Color.brewCream.ignoresSafeArea())
            .navigationTitle("프로필 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
            }
            .safeAreaInset(edge: .bottom) {
                saveBar
            }
            .alert("프로필을 저장하지 못했어요", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "잠시 후 다시 시도해 주세요.")
            }
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("나만의 브루 프로필")
                .font(.title3.bold())

            Text("닉네임은 계정에 반영되고, 선호 지역과 취향 태그, 짧은 메모는 지금 기기에서 바로 저장돼요.")
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

    private var nicknameCard: some View {
        editorCard(title: "닉네임", subtitle: "리뷰와 마이페이지에 표시돼요.") {
            TextField("닉네임", text: $nickname)
                .textInputAutocapitalization(.never)
                .padding(14)
                .background(Color.white.opacity(0.84))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var preferredCityCard: some View {
        editorCard(title: "선호 동네", subtitle: "자주 탐색하는 지역을 정해둘 수 있어요.") {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    preferredCity = ""
                } label: {
                    HStack {
                        Text("선택 안 함")
                        Spacer()
                        if preferredCity.isEmpty {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.brewBrown)
                        }
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.84))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)

                FlowSelectionView(
                    options: availableCities,
                    selectedValues: preferredCity.isEmpty ? [] : [preferredCity]
                ) { city in
                    preferredCity = city
                }
            }
        }
    }

    private var tasteTagCard: some View {
        editorCard(title: "취향 태그", subtitle: "분위기 취향을 직접 골라둘 수 있어요.") {
            VStack(alignment: .leading, spacing: 12) {
                FlowSelectionView(
                    options: availableTags,
                    selectedValues: selectedTags
                ) { tag in
                    toggle(tag: tag)
                }

                if !selectedTags.isEmpty {
                    Button("선택 초기화") {
                        selectedTags.removeAll()
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.brewBrown)
                }
            }
        }
    }

    private var noteCard: some View {
        editorCard(title: "짧은 소개", subtitle: "요즘 찾고 있는 카페 분위기를 적어보세요.") {
            VStack(alignment: .leading, spacing: 10) {
                TextEditor(text: $profileNote)
                    .frame(minHeight: 120)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color.white.opacity(0.84))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                HStack {
                    Text("예: 조용하고 오래 머물기 좋은 카페를 자주 찾고 있어요.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(profileNote.count)자")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.brewBrown)
                }
            }
        }
    }

    private var saveBar: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    await submit()
                }
            } label: {
                HStack {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    }

                    Text(isSaving ? "저장 중..." : "프로필 저장하기")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.brewBrown)
            .disabled(isSaveDisabled || isSaving)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .background(.ultraThinMaterial)
    }

    private var isSaveDisabled: Bool {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func editorCard<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
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
        .background(Color.white.opacity(0.82))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.brewBrown.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func toggle(tag: String) {
        if let existingIndex = selectedTags.firstIndex(of: tag) {
            selectedTags.remove(at: existingIndex)
        } else {
            selectedTags.append(tag)
        }
    }

    private func submit() async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await onSave(
                Submission(
                    nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
                    preferredCity: preferredCity,
                    favoriteVibeTags: selectedTags,
                    profileNote: profileNote.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            )
            dismiss()
        } catch {
            errorMessage = "닉네임 또는 취향 정보를 저장하지 못했어요."
        }
    }
}

private struct FlowSelectionView: View {
    let options: [String]
    let selectedValues: [String]
    let onTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(rowGroups, id: \.self) { row in
                HStack {
                    ForEach(row, id: \.self) { option in
                        let isSelected = selectedValues.contains(option)

                        Button(option) {
                            onTap(option)
                        }
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(isSelected ? Color.brewBrown : Color.brewLatte)
                        .foregroundStyle(isSelected ? .white : .primary)
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var rowGroups: [[String]] {
        stride(from: 0, to: options.count, by: 3).map { start in
            Array(options[start..<min(start + 3, options.count)])
        }
    }
}

#Preview {
    ProfilePreferencesView(
        initialNickname: "brewspot_john",
        initialPreferences: UserPreferenceData(
            preferredCity: "성수",
            favoriteVibeTags: ["조용한", "작업하기 좋은"],
            profileNote: "오래 머물기 좋은 카페를 자주 찾아요."
        ),
        availableCities: ["성수", "연남", "망원"],
        availableTags: ["조용한", "작업하기 좋은", "디저트 맛집", "대화하기 좋은", "사진이 잘 나오는", "핸드드립"]
    ) { _ in }
}
