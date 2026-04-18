import Foundation
import XCTest
@testable import MacCleaner

final class JunkFilesScannerTests: XCTestCase {
    func test_scanner_streams_files_from_readable_roots() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let fileURL = root.appendingPathComponent("cache.data")
        try Data(repeating: 1, count: 128).write(to: fileURL)

        let scanner = JunkFilesScanner(
            scanRoots: [root],
            permissionCoordinator: AlwaysReadablePermissionCoordinator()
        )
        var found: [CleanableItem] = []

        for await event in scanner.scan() {
            if case .itemFound(let item) = event {
                found.append(item)
            }
        }

        XCTAssertEqual(found.count, 1)
        XCTAssertEqual(found.first?.path, fileURL.path)
        XCTAssertEqual(found.first?.sizeInBytes, 128)
    }

    func test_scanner_reports_skipped_locations_when_access_is_denied() async {
        let root = URL(fileURLWithPath: "/path/that/is/not/readable")
        let scanner = JunkFilesScanner(
            scanRoots: [root],
            permissionCoordinator: AlwaysDeniedPermissionCoordinator()
        )
        var skipped: [SkippedLocation] = []

        for await event in scanner.scan() {
            if case .skipped(let location) = event {
                skipped.append(location)
            }
        }

        XCTAssertEqual(skipped.map(\.path), [root.path])
        XCTAssertEqual(skipped.first?.reason, "Permission denied in test.")
    }
}

private struct AlwaysReadablePermissionCoordinator: PermissionCoordinating {
    func validateReadAccess(to url: URL) -> ReadAccessValidation {
        .allowed
    }
}

private struct AlwaysDeniedPermissionCoordinator: PermissionCoordinating {
    func validateReadAccess(to url: URL) -> ReadAccessValidation {
        .denied("Permission denied in test.")
    }
}
