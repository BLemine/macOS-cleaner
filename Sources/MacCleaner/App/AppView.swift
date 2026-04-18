import SwiftUI

enum AppSelection {
    static let defaultCategory: CleanerCategory = .junkFiles
}

struct AppView: View {
    @State private var selectedCategory: CleanerCategory? = AppSelection.defaultCategory
    @StateObject private var junkFilesViewModel = JunkFilesViewModel()

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedCategory: $selectedCategory)
        } detail: {
            Group {
                switch selectedCategory ?? .junkFiles {
                case .junkFiles:
                    JunkFilesView(viewModel: junkFilesViewModel)
                case .largeApps:
                    PlaceholderCategoryView(
                        title: CleanerCategory.largeApps.title,
                        description: "Large Apps will scan /Applications and rank bundles by size."
                    )
                case .unusedApps:
                    PlaceholderCategoryView(
                        title: CleanerCategory.unusedApps.title,
                        description: "Unused Apps will identify applications not opened in the last 90 days."
                    )
                case .largeCaches:
                    PlaceholderCategoryView(
                        title: CleanerCategory.largeCaches.title,
                        description: "Large Caches will break down cache usage per app."
                    )
                }
            }
            .navigationTitle(selectedCategory?.title ?? CleanerCategory.junkFiles.title)
        }
        .onChange(of: selectedCategory) { _, newValue in
            if newValue != .junkFiles {
                junkFilesViewModel.cancelScan()
            }
        }
    }
}
