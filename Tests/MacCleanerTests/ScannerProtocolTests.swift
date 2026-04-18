import XCTest
@testable import MacCleaner

final class ScannerProtocolTests: XCTestCase {
    func test_finished_event_carries_summary_counts() {
        let summary = ScanSummary(itemsFound: 3, skippedLocations: 1, totalBytes: 4096)
        let event = ScanEvent<CleanableItem>.finished(summary)

        guard case .finished(let value) = event else {
            return XCTFail("Expected finished event")
        }

        XCTAssertEqual(value.itemsFound, 3)
        XCTAssertEqual(value.skippedLocations, 1)
        XCTAssertEqual(value.totalBytes, 4096)
    }

    func test_cancelled_event_carries_summary_counts() {
        let summary = ScanSummary(itemsFound: 5, skippedLocations: 2, totalBytes: 8192)
        let event = ScanEvent<CleanableItem>.cancelled(summary)

        guard case .cancelled(let value) = event else {
            return XCTFail("Expected cancelled event")
        }

        XCTAssertEqual(value.itemsFound, 5)
        XCTAssertEqual(value.skippedLocations, 2)
        XCTAssertEqual(value.totalBytes, 8192)
    }
}
