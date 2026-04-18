import Foundation
import XCTest
@testable import MacCleaner

@MainActor
final class JunkFilesViewModelTests: XCTestCase {
    func test_total_selected_size_updates_when_item_is_toggled() async {
        let item = CleanableItem(
            name: "cache.data",
            path: "/tmp/cache.data",
            sizeInBytes: 512,
            category: .junkFiles
        )
        let scanner = MockJunkScanner(events: [
            .started,
            .itemFound(item),
            .finished(.init(itemsFound: 1, skippedLocations: 0, totalBytes: 512))
        ])
        let viewModel = JunkFilesViewModel(scanner: scanner, trashService: RecordingTrashService())

        await viewModel.scan()
        viewModel.toggleSelection(for: item.id)

        XCTAssertEqual(viewModel.totalSelectedBytes, 512)
    }

    func test_confirmed_cleanup_calls_trash_service_for_selected_items() async throws {
        let item = CleanableItem(
            name: "cache.data",
            path: "/tmp/cache.data",
            sizeInBytes: 512,
            category: .junkFiles
        )
        let trashService = RecordingTrashService()
        let viewModel = JunkFilesViewModel(scanner: MockJunkScanner(events: []), trashService: trashService)

        viewModel.loadPreviewItems([item])
        viewModel.toggleSelection(for: item.id)
        try await viewModel.cleanSelected()

        XCTAssertEqual(trashService.trashedPaths, ["/tmp/cache.data"])
        XCTAssertEqual(viewModel.items.count, 0)
    }
}

private struct MockJunkScanner: MacCleaner.Scanner {
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

private final class RecordingTrashService: TrashServicing, @unchecked Sendable {
    private(set) var trashedPaths: [String] = []

    func trashItem(at url: URL) async throws {
        trashedPaths.append(url.path)
    }
}
