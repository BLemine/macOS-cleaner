import SwiftUI

struct SidebarView: View {
    @Binding var selectedCategory: CleanerCategory?

    var body: some View {
        List(CleanerCategory.allCases, selection: $selectedCategory) { category in
            Label(category.title, systemImage: category.systemImage)
                .tag(category)
        }
        .navigationSplitViewColumnWidth(min: 220, ideal: 240)
        .listStyle(.sidebar)
    }
}
