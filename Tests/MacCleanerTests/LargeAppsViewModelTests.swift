import Foundation
import XCTest
@testable import MacCleaner

@MainActor
final class LargeAppsViewModelTests: XCTestCase {
    func test_items_remain_sorted_by_size_descending() async {
        let small = CleanableItem(name: "Small", path: "/Applications/Small.app", sizeInBytes: 1024, category: .largeApps)
        let large = CleanableItem(name: "Large", path: "/Applications/Large.app", sizeInBytes: 4096, category: .largeApps)

        let scanner = MockLargeAppsScanner(events: [
            .started,
            .itemFound(small),
            .itemFound(large),
            .finished(.init(itemsFound: 2, skippedLocations: 0, totalBytes: 5120))
        ])

        let viewModel = LargeAppsViewModel(scanner: scanner, trashService: RecordingLargeAppsTrashService())
        viewModel.startScan()

        try? await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(viewModel.items.map(\.name), ["Large", "Small"])
    }
}

private struct MockLargeAppsScanner: MacCleaner.Scanner {
    typealias Item = CleanableItem

    let events: [ScanEvent<CleanableItem>]

    func scan() -> AsyncStream<ScanEvent<CleanableItem>> {
        AsyncStream { continuation in
            Task {
                for event in events {
                    continuation.yield(event)
                }
                continuation.finish()
            }
        }
    }
}

private final class RecordingLargeAppsTrashService: TrashServicing, @unchecked Sendable {
    func trashItem(at url: URL) async throws {}
}
