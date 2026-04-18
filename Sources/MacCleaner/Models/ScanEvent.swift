import Foundation

struct ScanSummary: Equatable, Sendable {
    let itemsFound: Int
    let skippedLocations: Int
    let totalBytes: Int64
}

enum ScanEvent<Item: Sendable>: Sendable {
    case started
    case progress(ScanProgress)
    case itemFound(Item)
    case skipped(SkippedLocation)
    case finished(ScanSummary)
    case cancelled(ScanSummary)
    case failed(String)
}
