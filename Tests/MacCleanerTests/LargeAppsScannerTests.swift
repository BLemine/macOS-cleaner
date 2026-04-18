import Foundation
import XCTest
@testable import MacCleaner

final class LargeAppsScannerTests: XCTestCase {
    func test_scanner_streams_app_bundles_from_readable_roots() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let firstApp = root.appendingPathComponent("Small.app")
        let secondApp = root.appendingPathComponent("Large.app")

        try FileManager.default.createDirectory(at: firstApp, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: secondApp, withIntermediateDirectories: true)
        try Data(repeating: 1, count: 128).write(to: firstApp.appendingPathComponent("binary"))
        try Data(repeating: 1, count: 2048).write(to: secondApp.appendingPathComponent("binary"))
        defer { try? FileManager.default.removeItem(at: root) }

        let scanner = LargeAppsScanner(
            scanRoots: [root],
            permissionCoordinator: AlwaysReadableLargeAppsPermissionCoordinator()
        )

        var found: [CleanableItem] = []
        for await event in scanner.scan() {
            if case .itemFound(let item) = event {
                found.append(item)
            }
        }

        XCTAssertEqual(found.count, 2)
        XCTAssertEqual(found.map(\.name).sorted(), ["Large", "Small"])
        XCTAssertTrue(found.contains(where: { $0.sizeInBytes == 2048 }))
    }
}

private struct AlwaysReadableLargeAppsPermissionCoordinator: PermissionCoordinating {
    func validateReadAccess(to url: URL) -> ReadAccessValidation {
        .allowed
    }
}
