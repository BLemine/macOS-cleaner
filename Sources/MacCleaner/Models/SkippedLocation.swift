import Foundation

struct SkippedLocation: Equatable, Sendable, Identifiable {
    let id: UUID
    let path: String
    let reason: String

    init(id: UUID = UUID(), path: String, reason: String) {
        self.id = id
        self.path = path
        self.reason = reason
    }
}
