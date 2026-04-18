import Foundation

struct ScanProgress: Equatable, Sendable {
    let phase: String
    let scannedLocations: Int
    let itemsFound: Int
    let skippedLocations: Int
}
