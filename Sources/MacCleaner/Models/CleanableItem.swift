import Foundation

struct CleanableItem: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let path: String
    let sizeInBytes: Int64
    let category: CleanerCategory
    let sourceRoot: String?

    init(
        id: UUID = UUID(),
        name: String,
        path: String,
        sizeInBytes: Int64,
        category: CleanerCategory,
        sourceRoot: String? = nil
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.sizeInBytes = sizeInBytes
        self.category = category
        self.sourceRoot = sourceRoot
    }
}
