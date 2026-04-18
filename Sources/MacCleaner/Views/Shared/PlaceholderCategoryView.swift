import SwiftUI

struct PlaceholderCategoryView: View {
    let title: String
    let description: String

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: "hourglass",
            description: Text(description)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }
}
