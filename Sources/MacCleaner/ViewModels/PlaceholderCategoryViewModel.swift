import Foundation

@MainActor
final class PlaceholderCategoryViewModel: ObservableObject {
    let category: CleanerCategory

    init(category: CleanerCategory) {
        self.category = category
    }
}
