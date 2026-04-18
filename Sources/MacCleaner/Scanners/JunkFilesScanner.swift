import Foundation

struct JunkFilesScanner: Scanner {
    typealias Item = CleanableItem

    let scanRoots: [URL]
    private let directorySizer: DirectorySizing
    private let permissionCoordinator: PermissionCoordinating

    init(
        scanRoots: [URL] = JunkFilesScanner.defaultRoots(),
        directorySizer: DirectorySizing? = nil,
        permissionCoordinator: PermissionCoordinating? = nil
    ) {
        self.scanRoots = scanRoots
        self.directorySizer = directorySizer ?? DirectorySizer()
        self.permissionCoordinator = permissionCoordinator ?? PermissionCoordinator()
    }

    func scan() -> AsyncStream<ScanEvent<CleanableItem>> {
        AsyncStream { continuation in
            Task(priority: .userInitiated) {
                continuation.yield(.started)

                var itemsFound = 0
                var skippedLocations = 0
                var totalBytes: Int64 = 0
                var scannedLocations = 0
                var seenPaths = Set<String>()

                for root in scanRoots {
                    switch permissionCoordinator.validateReadAccess(to: root) {
                    case .denied(let reason):
                        skippedLocations += 1
                        continuation.yield(.skipped(SkippedLocation(path: root.path, reason: reason)))
                        continuation.yield(.progress(ScanProgress(
                            phase: "Skipping inaccessible location",
                            scannedLocations: scannedLocations,
                            itemsFound: itemsFound,
                            skippedLocations: skippedLocations
                        )))
                        continue
                    case .allowed:
                        break
                    }

                    let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey]
                    guard let enumerator = FileManager.default.enumerator(
                        at: root,
                        includingPropertiesForKeys: resourceKeys,
                        options: [.skipsPackageDescendants],
                        errorHandler: { _, _ in
                            true
                        }
                    ) else {
                        skippedLocations += 1
                        continuation.yield(.skipped(SkippedLocation(path: root.path, reason: "Unable to enumerate location.")))
                        continue
                    }

                    while let fileURL = enumerator.nextObject() as? URL {
                        do {
                            let values = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                            guard values.isRegularFile == true else {
                                continue
                            }

                            let normalizedURL = fileURL.standardizedFileURL
                            let normalizedPath = normalizedURL.path

                            guard seenPaths.insert(normalizedPath).inserted else {
                                continue
                            }

                            let size = try directorySizer.sizeOfItem(at: normalizedURL)
                            itemsFound += 1
                            totalBytes += size
                            continuation.yield(.itemFound(CleanableItem(
                                name: normalizedURL.lastPathComponent,
                                path: normalizedPath,
                                sizeInBytes: size,
                                category: .junkFiles,
                                sourceRoot: root.standardizedFileURL.path
                            )))

                            if itemsFound.isMultiple(of: 200) {
                                continuation.yield(.progress(ScanProgress(
                                    phase: "Scanning \(root.lastPathComponent)",
                                    scannedLocations: scannedLocations,
                                    itemsFound: itemsFound,
                                    skippedLocations: skippedLocations
                                )))
                            }
                        } catch {
                            continue
                        }
                    }

                    scannedLocations += 1
                    continuation.yield(.progress(ScanProgress(
                        phase: "Finished \(root.lastPathComponent)",
                        scannedLocations: scannedLocations,
                        itemsFound: itemsFound,
                        skippedLocations: skippedLocations
                    )))
                }

                continuation.yield(.finished(ScanSummary(
                    itemsFound: itemsFound,
                    skippedLocations: skippedLocations,
                    totalBytes: totalBytes
                )))
                continuation.finish()
            }
        }
    }

    static func defaultRoots(
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> [URL] {
        [
            homeDirectory.appending(path: "Library/Caches"),
            URL(fileURLWithPath: "/Library/Caches"),
            homeDirectory.appending(path: "Library/Logs"),
            homeDirectory.appending(path: "Library/Logs/DiagnosticReports"),
            homeDirectory.appending(path: "Library/Application Support/CrashReporter"),
            URL(fileURLWithPath: "/Library/Logs/DiagnosticReports")
        ]
    }
}
