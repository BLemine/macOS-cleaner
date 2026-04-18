import Foundation

protocol TrashServicing: Sendable {
    func trashItem(at url: URL) async throws
}

struct TrashService: TrashServicing {
    func trashItem(at url: URL) async throws {
        try await Task(priority: .userInitiated) {
            var resultingItemURL: NSURL?
            try FileManager.default.trashItem(at: url, resultingItemURL: &resultingItemURL)
        }.value
    }
}
