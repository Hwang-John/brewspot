import SwiftUI

struct HomeBaristaView: View {
    @EnvironmentObject private var homeBaristaStore: HomeBaristaStore
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var toastCenter: AppToastCenter

    @State private var selectedMethod = "전체"
    @State private var selectedPost: HomeBaristaPost?
    @State private var isPresentingComposer = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroCard
                    methodFilterCard

                    if let errorMessage = homeBaristaStore.errorMessage {
                        ErrorStateCard(
                            title: "레시피를 불러오지 못했어요",
                            message: errorMessage,
                            buttonTitle: "다시 불러오기"
                        ) {
                            Task { await homeBaristaStore.refresh() }
                        }
                    }

                    if homeBaristaStore.isLoading {
                        ProgressView("홈바리스타 피드를 준비하고 있어요...")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    feedSection
                }
                .padding(24)
                .padding(.bottom, 100)
            }
            .background(Color.brewCream.ignoresSafeArea())
            .navigationTitle("홈바리스타")
            .safeAreaInset(edge: .bottom) {
                composerBar
            }
            .task {
                await homeBaristaStore.loadIfNeeded()
            }
            .sheet(item: $selectedPost) { post in
                HomeBaristaDetailView(post: post)
            }
            .sheet(isPresented: $isPresentingComposer) {
                HomeBaristaComposerView(
                    authorNickname: sessionStore.currentUser?.nickname ?? "브루스팟 사용자"
                ) { submission in
                    let result = await homeBaristaStore.createPost(
                        brewMethod: submission.brewMethod,
                        title: submission.title,
                        beanName: submission.beanName,
                        ratioNote: submission.ratioNote,
                        tastingNote: submission.tastingNote,
                        brewNote: submission.brewNote,
                        authorNickname: sessionStore.currentUser?.nickname ?? "브루스팟 사용자"
                    )

                    switch result {
                    case .synced(let post):
                        toastCenter.showSuccess(
                            title: "레시피를 공유했어요",
                            message: "\(post.title)을 홈바리스타 피드에 올렸어요.",
                            systemImage: "cup.and.heat.waves.fill"
                        )
                    case .localFallback(let post):
                        toastCenter.showSuccess(
                            title: "임시 레시피로 저장했어요",
                            message: "\(post.title)을 이 기기에 먼저 담아뒀어요.",
                            systemImage: "tray.and.arrow.down.fill"
                        )
                    }
                }
                .presentationDetents([.large])
            }
        }
    }

    private var posts: [HomeBaristaPost] {
        homeBaristaStore.posts
    }

    private var methods: [String] {
        ["전체"] + Array(Set(posts.map(\.brewMethod))).sorted()
    }

    private var filteredPosts: [HomeBaristaPost] {
        posts.filter { post in
            selectedMethod == "전체" || post.brewMethod == selectedMethod
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("HOME BREW")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.82))

                    Text("집에서도 BrewSpot 취향을 이어가기")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }

                Spacer()

                Text(homeBaristaStore.sourceDescription)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.brewMocha)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.92))
                    .clipShape(Capsule())
            }

            Text("드립 레시피, 원두 메모, 추출 팁을 짧게 공유하면서 카페 밖에서도 브루 흐름을 이어가보세요.")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.84))

            HStack(spacing: 12) {
                metricCard(title: "전체 레시피", value: "\(posts.count)개", caption: "지금 보이는 피드")
                metricCard(title: "추출 방식", value: "\(methods.count - 1)개", caption: selectedMethod == "전체" ? "모든 방식" : selectedMethod)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            LinearGradient(
                colors: [Color.brewMocha, Color.brewBrown],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var methodFilterCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("추출 방식 필터")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(methods, id: \.self) { method in
                        Button(method) {
                            selectedMethod = method
                        }
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(selectedMethod == method ? Color.brewBrown : Color.brewLatte)
                        .foregroundStyle(selectedMethod == method ? .white : .primary)
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white.opacity(0.8))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.brewBrown.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var feedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("레시피 피드")
                    .font(.headline)

                Spacer()

                Text("\(filteredPosts.count)개")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if filteredPosts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("아직 맞는 레시피가 없어요")
                        .font(.headline)

                    Text("다른 추출 방식을 고르거나 첫 레시피를 직접 올려보세요.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color.white.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: 22))
            } else {
                ForEach(filteredPosts) { post in
                    Button {
                        selectedPost = post
                    } label: {
                        feedCard(post)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var composerBar: some View {
        VStack(spacing: 10) {
            Button {
                isPresentingComposer = true
            } label: {
                Label("레시피 공유하기", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.brewBrown)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .background(.ultraThinMaterial)
    }

    private func feedCard(_ post: HomeBaristaPost) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                tag(post.brewMethod, tint: Color.brewBrown, background: Color.brewLatte)
                tag(sourceLabel(for: post), tint: post.source == .remote ? .secondary : Color.brewBrown, background: Color.white.opacity(0.82))
                Spacer()
                Text(post.relativeDateText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(post.title)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(post.beanName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brewBrown)

            Text(post.previewText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)

            HStack {
                Label(post.authorName, systemImage: "person.fill")
                Spacer()
                Label(post.ratioNote, systemImage: "drop.fill")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.95), Color.brewLatte.opacity(0.52)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.brewBrown.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func metricCard(title: String, value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.72))

            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text(caption)
                .font(.footnote)
                .foregroundStyle(Color.white.opacity(0.78))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func tag(_ text: String, tint: Color, background: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(background)
            .clipShape(Capsule())
    }

    private func sourceLabel(for post: HomeBaristaPost) -> String {
        switch post.source {
        case .remote:
            return "실시간"
        case .localFallback:
            return "임시 저장"
        case .sample:
            return "샘플"
        }
    }
}

private struct HomeBaristaDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let post: HomeBaristaPost

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            pill(post.brewMethod)
                            Spacer()
                            Text(post.relativeDateText)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        Text(post.title)
                            .font(.title2.bold())

                        Label(post.authorName, systemImage: "person.fill")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Divider()

                        detailSection(title: "원두", value: post.beanName)
                        detailSection(title: "비율", value: post.ratioNote)
                        detailSection(title: "테이스팅 노트", value: post.tastingNote)
                        detailSection(title: "추출 메모", value: post.brewNote)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color.white.opacity(0.86))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.brewBrown.opacity(0.08), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22))

                    if post.source != .remote {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("운영 메모")
                                .font(.headline)

                            Text(post.source == .sample ? "이 레시피는 홈바리스타 MVP를 보여주기 위한 샘플 데이터예요." : "이 레시피는 홈바리스타 서버가 준비되기 전에 이 기기에 임시 저장된 글이에요.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(Color.white.opacity(0.78))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.brewBrown.opacity(0.08), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
                .padding(24)
            }
            .background(Color.brewCream.ignoresSafeArea())
            .navigationTitle("레시피")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func detailSection(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.body)
                .foregroundStyle(.primary)
        }
    }

    private func pill(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.brewBrown)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.brewLatte)
            .clipShape(Capsule())
    }
}

private struct HomeBaristaComposerView: View {
    struct Submission {
        let brewMethod: String
        let title: String
        let beanName: String
        let ratioNote: String
        let tastingNote: String
        let brewNote: String
    }

    @Environment(\.dismiss) private var dismiss

    let authorNickname: String
    let onSave: (Submission) async -> Void

    @State private var selectedMethod = "V60"
    @State private var title = ""
    @State private var beanName = ""
    @State private var ratioNote = ""
    @State private var tastingNote = ""
    @State private var brewNote = ""
    @State private var isSaving = false

    private let methods = ["V60", "에어로프레스", "프렌치프레스", "에스프레소", "콜드브루"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    introCard
                    methodCard
                    titleCard
                    beanCard
                    ratioCard
                    tastingCard
                    brewNoteCard
                }
                .padding(24)
                .padding(.bottom, 110)
            }
            .background(Color.brewCream.ignoresSafeArea())
            .navigationTitle("레시피 공유")
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
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("홈 브루 메모 남기기")
                .font(.title3.bold())

            Text("\(authorNickname) 님이 집에서 찾은 추출 감각을 짧고 선명하게 공유해보세요.")
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

    private var methodCard: some View {
        editorCard(title: "추출 방식", subtitle: "가장 가까운 레시피 카테고리를 골라주세요.") {
            HStack(spacing: 8) {
                ForEach(methods, id: \.self) { method in
                    Button(method) {
                        selectedMethod = method
                    }
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(selectedMethod == method ? Color.brewBrown : Color.brewLatte)
                    .foregroundStyle(selectedMethod == method ? .white : .primary)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var titleCard: some View {
        editorCard(title: "제목", subtitle: "내가 다시 봐도 어떤 추출인지 떠오르게 적어보세요.") {
            TextField("예: 산미를 줄인 주말용 V60 레시피", text: $title)
                .padding(14)
                .background(Color.white.opacity(0.84))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var beanCard: some View {
        editorCard(title: "원두", subtitle: "원두명이나 로스터 이름이 들어가면 기록하기 쉬워져요.") {
            TextField("예: Ethiopia Guji", text: $beanName)
                .padding(14)
                .background(Color.white.opacity(0.84))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var ratioCard: some View {
        editorCard(title: "비율 / 시간", subtitle: "추출 비율과 시간을 간단히 적어주세요.") {
            TextField("예: 15g : 240ml / 2분 30초", text: $ratioNote)
                .padding(14)
                .background(Color.white.opacity(0.84))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var tastingCard: some View {
        editorCard(title: "테이스팅 노트", subtitle: "맛과 질감이 어떻게 느껴졌는지 적어보세요.") {
            TextEditor(text: $tastingNote)
                .frame(minHeight: 110)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(Color.white.opacity(0.84))
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    private var brewNoteCard: some View {
        editorCard(title: "추출 메모", subtitle: "물줄기, 온도, 침출 시간 같은 팁을 남겨보세요.") {
            TextEditor(text: $brewNote)
                .frame(minHeight: 150)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(Color.white.opacity(0.84))
                .clipShape(RoundedRectangle(cornerRadius: 18))
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

                    Text(isSaving ? "공유 중..." : "레시피 공유하기")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.brewBrown)
            .disabled(isSubmitDisabled || isSaving)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .background(.ultraThinMaterial)
    }

    private var isSubmitDisabled: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        beanName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        ratioNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        tastingNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        brewNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

    private func submit() async {
        isSaving = true
        defer { isSaving = false }

        await onSave(
            Submission(
                brewMethod: selectedMethod,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                beanName: beanName.trimmingCharacters(in: .whitespacesAndNewlines),
                ratioNote: ratioNote.trimmingCharacters(in: .whitespacesAndNewlines),
                tastingNote: tastingNote.trimmingCharacters(in: .whitespacesAndNewlines),
                brewNote: brewNote.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        )

        dismiss()
    }
}

#Preview {
    HomeBaristaView()
        .environmentObject(HomeBaristaStore())
        .environmentObject(SessionStore())
        .environmentObject(AppToastCenter())
}
