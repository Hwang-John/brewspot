import SwiftUI

struct CommunityBoardView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var communityStore: CommunityStore
    @EnvironmentObject private var toastCenter: AppToastCenter

    @State private var selectedCategory = "전체"
    @State private var searchText = ""
    @State private var selectedPost: CommunityPost?
    @State private var isPresentingComposer = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroCard
                    controlCard

                    if let errorMessage = communityStore.errorMessage {
                        ErrorStateCard(
                            title: "커뮤니티 글을 불러오지 못했어요",
                            message: errorMessage,
                            buttonTitle: "다시 불러오기"
                        ) {
                            Task { await communityStore.refresh() }
                        }
                    }

                    if communityStore.isLoading {
                        ProgressView("게시판을 준비하고 있어요...")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    postListSection
                }
                .padding(24)
                .padding(.bottom, 100)
            }
            .background(Color.brewCream.ignoresSafeArea())
            .navigationTitle("커뮤니티")
            .safeAreaInset(edge: .bottom) {
                composerBar
            }
            .task {
                await communityStore.loadIfNeeded()
            }
            .sheet(item: $selectedPost) { post in
                CommunityPostDetailView(post: post)
            }
            .sheet(isPresented: $isPresentingComposer) {
                CommunityPostComposerView(
                    suggestedCity: suggestedCity,
                    authorNickname: sessionStore.currentUser?.nickname ?? "브루스팟 사용자"
                ) { submission in
                    let result = await communityStore.createPost(
                        title: submission.title,
                        content: submission.content,
                        category: submission.category,
                        city: submission.city,
                        authorNickname: sessionStore.currentUser?.nickname ?? "브루스팟 사용자"
                    )

                    switch result {
                    case .synced(let post):
                        toastCenter.showSuccess(
                            title: "게시글을 올렸어요",
                            message: "\(post.title)을 커뮤니티에 공유했어요.",
                            systemImage: "bubble.left.and.text.bubble.right.fill"
                        )
                    case .localFallback(let post):
                        toastCenter.showSuccess(
                            title: "임시 게시글로 저장했어요",
                            message: "\(post.title)을 이 기기에 먼저 담아뒀어요.",
                            systemImage: "tray.and.arrow.down.fill"
                        )
                    }
                }
                .presentationDetents([.large])
            }
        }
    }

    private var posts: [CommunityPost] {
        communityStore.posts
    }

    private var categories: [String] {
        ["전체"] + Array(Set(posts.map(\.category))).sorted()
    }

    private var filteredPosts: [CommunityPost] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        return posts.filter { post in
            let matchesCategory = selectedCategory == "전체" || post.category == selectedCategory
            let matchesSearch =
                trimmedSearch.isEmpty ||
                post.title.localizedCaseInsensitiveContains(trimmedSearch) ||
                post.content.localizedCaseInsensitiveContains(trimmedSearch) ||
                post.authorName.localizedCaseInsensitiveContains(trimmedSearch) ||
                post.city.localizedCaseInsensitiveContains(trimmedSearch)

            return matchesCategory && matchesSearch
        }
    }

    private var suggestedCity: String {
        let cityCounts = Dictionary(grouping: posts, by: \.city)
        return cityCounts.max { $0.value.count < $1.value.count }?.key ?? "성수"
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("BREW TALK")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.82))

                    Text("카페 취향을 나누는 게시판")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }

                Spacer()

                Text(communityStore.sourceDescription)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.brewMocha)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.92))
                    .clipShape(Capsule())
            }

            Text("추천, 질문, 동네 이야기를 가볍게 남기며 BrewSpot 안의 커피 대화를 시작해보세요.")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.84))

            HStack(spacing: 12) {
                metricCard(title: "전체 글", value: "\(posts.count)개", caption: "지금 보이는 흐름")
                metricCard(title: "필터 결과", value: "\(filteredPosts.count)개", caption: selectedCategory == "전체" ? "모든 카테고리" : selectedCategory)
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

    private var controlCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("게시판 탐색")
                .font(.headline)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.brewBrown)

                TextField("제목, 내용, 작성자, 동네 검색", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(14)
            .background(Color.white.opacity(0.84))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { category in
                        Button(category) {
                            selectedCategory = category
                        }
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(selectedCategory == category ? Color.brewBrown : Color.brewLatte)
                        .foregroundStyle(selectedCategory == category ? .white : .primary)
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

    private var postListSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("게시글")
                    .font(.headline)

                Spacer()

                Text("\(filteredPosts.count)개")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if filteredPosts.isEmpty {
                emptyStateCard
            } else {
                ForEach(filteredPosts) { post in
                    Button {
                        selectedPost = post
                    } label: {
                        postCard(post)
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
                Label("새 글 쓰기", systemImage: "square.and.pencil")
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

    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("아직 맞는 게시글이 없어요")
                .font(.headline)

            Text("카테고리를 바꾸거나 검색어를 지우면 다른 커뮤니티 글 흐름을 볼 수 있어요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("첫 글을 남기면 이 게시판 톤을 직접 만들 수 있어요.")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.brewBrown)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.72))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.brewLatte.opacity(0.85), Color.white.opacity(0.94)],
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

    private func postCard(_ post: CommunityPost) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                tag(post.category, tint: Color.brewBrown, background: Color.brewLatte)
                tag(post.city, tint: .primary, background: Color.white.opacity(0.82))
                tag(sourceLabel(for: post), tint: post.source == .remote ? .secondary : Color.brewBrown, background: Color.white.opacity(0.82))
                Spacer()
                Text(post.relativeDateText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(post.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(post.previewText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)

            HStack {
                Label(post.authorName, systemImage: "person.fill")
                Spacer()
                Label("\(post.likeCount)", systemImage: "heart")
                Label("\(post.commentCount)", systemImage: "text.bubble")
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

    private func sourceLabel(for post: CommunityPost) -> String {
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

private struct CommunityPostDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let post: CommunityPost

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            pill(post.category)
                            pill(post.city)
                            Spacer()
                            Text(post.relativeDateText)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        Text(post.title)
                            .font(.title2.bold())

                        HStack {
                            Label(post.authorName, systemImage: "person.fill")
                            Spacer()
                            Label("\(post.likeCount)", systemImage: "heart")
                            Label("\(post.commentCount)", systemImage: "text.bubble")
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                        Divider()

                        Text(post.content)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
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

                            Text(post.source == .sample ? "이 글은 커뮤니티 MVP 화면을 보여주기 위한 샘플 데이터예요." : "이 글은 커뮤니티 서버가 준비되기 전에 이 기기에 임시 저장된 게시글이에요.")
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
            .navigationTitle("게시글")
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

private struct CommunityPostComposerView: View {
    struct Submission {
        let category: String
        let title: String
        let content: String
        let city: String
    }

    @Environment(\.dismiss) private var dismiss

    let suggestedCity: String
    let authorNickname: String
    let onSave: (Submission) async -> Void

    @State private var selectedCategory = "자유"
    @State private var title = ""
    @State private var content = ""
    @State private var city: String
    @State private var isSaving = false

    private let categories = ["자유", "추천", "질문"]

    init(
        suggestedCity: String,
        authorNickname: String,
        onSave: @escaping (Submission) async -> Void
    ) {
        self.suggestedCity = suggestedCity
        self.authorNickname = authorNickname
        self.onSave = onSave
        _city = State(initialValue: suggestedCity)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    introCard
                    categoryCard
                    titleCard
                    cityCard
                    contentCard
                }
                .padding(24)
                .padding(.bottom, 110)
            }
            .background(Color.brewCream.ignoresSafeArea())
            .navigationTitle("새 글 쓰기")
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
            Text("오늘의 브루 대화")
                .font(.title3.bold())

            Text("\(authorNickname) 님의 카페 경험이나 질문을 짧고 또렷하게 남겨보세요.")
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

    private var categoryCard: some View {
        editorCard(title: "카테고리", subtitle: "자유롭게 나누고 싶은 대화 톤을 골라주세요.") {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    Button(category) {
                        selectedCategory = category
                    }
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(selectedCategory == category ? Color.brewBrown : Color.brewLatte)
                    .foregroundStyle(selectedCategory == category ? .white : .primary)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var titleCard: some View {
        editorCard(title: "제목", subtitle: "한 줄만 봐도 대화 주제가 보이면 좋아요.") {
            TextField("예: 성수에서 조용한 카페 추천 부탁드려요", text: $title)
                .padding(14)
                .background(Color.white.opacity(0.84))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var cityCard: some View {
        editorCard(title: "동네", subtitle: "게시글과 잘 맞는 지역을 적어두면 찾기 쉬워져요.") {
            TextField("예: 성수", text: $city)
                .padding(14)
                .background(Color.white.opacity(0.84))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var contentCard: some View {
        editorCard(title: "내용", subtitle: "구체적인 분위기, 메뉴, 시간대가 들어가면 반응이 좋아져요.") {
            VStack(alignment: .leading, spacing: 10) {
                TextEditor(text: $content)
                    .frame(minHeight: 180)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color.white.opacity(0.84))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                HStack {
                    Text("추천 글은 경험과 이유를, 질문 글은 원하는 조건을 같이 적으면 좋아요.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(content.count)자")
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

                    Text(isSaving ? "올리는 중..." : "게시글 올리기")
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
        content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
                category: selectedCategory,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                city: city.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        )

        dismiss()
    }
}

#Preview {
    CommunityBoardView()
        .environmentObject(SessionStore())
        .environmentObject(CommunityStore())
        .environmentObject(AppToastCenter())
}
