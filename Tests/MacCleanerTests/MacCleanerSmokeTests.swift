import XCTest
@testable import MacCleaner

final class MacCleanerSmokeTests: XCTestCase {
    func test_category_count_matches_v1_sidebar() {
        XCTAssertEqual(CleanerCategory.allCases.count, 4)
    }

    func test_default_selected_category_is_junk_files() {
        XCTAssertEqual(AppSelection.defaultCategory, .junkFiles)
    }
}
