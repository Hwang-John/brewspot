import SwiftUI

@MainActor
final class AppToastCenter: ObservableObject {
    struct ToastItem: Identifiable, Equatable {
        let id = UUID()
        let title: String
        let message: String
        let systemImage: String
    }

    @Published private(set) var item: ToastItem?

    private var dismissTask: Task<Void, Never>?

    func showSuccess(title: String, message: String, systemImage: String = "checkmark.circle.fill") {
        show(title: title, message: message, systemImage: systemImage)
    }

    func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil

        withAnimation(.spring(duration: 0.28)) {
            item = nil
        }
    }

    private func show(title: String, message: String, systemImage: String) {
        dismissTask?.cancel()

        let toast = ToastItem(title: title, message: message, systemImage: systemImage)

        withAnimation(.spring(duration: 0.28)) {
            item = toast
        }

        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.2))
            guard !Task.isCancelled else { return }
            await self?.dismiss()
        }
    }
}
