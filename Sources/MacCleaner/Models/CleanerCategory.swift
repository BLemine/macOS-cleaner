import Foundation

enum CleanerCategory: String, CaseIterable, Hashable, Sendable, Identifiable {
    case junkFiles
    case largeApps
    case unusedApps
    case largeCaches

    var id: String { rawValue }

    var title: String {
        switch self {
        case .junkFiles:
            return "Junk Files"
        case .largeApps:
            return "Large Apps"
        case .unusedApps:
            return "Unused Apps"
        case .largeCaches:
            return "Large Caches"
        }
    }

    var systemImage: String {
        switch self {
        case .junkFiles:
            return "trash.slash"
        case .largeApps:
            return "shippingbox"
        case .unusedApps:
            return "clock.arrow.trianglehead.counterclockwise.rotate.90"
        case .largeCaches:
            return "externaldrive.badge.timemachine"
        }
    }
}
