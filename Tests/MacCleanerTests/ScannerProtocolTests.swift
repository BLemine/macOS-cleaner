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
}
