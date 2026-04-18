import Foundation

struct LargeAppsScanner: Scanner {
    typealias Item = CleanableItem

    let scanRoots: [URL]
    private let directorySizer: DirectorySizing
    private let permissionCoordinator: PermissionCoordinating

    init(
        scanRoots: [URL] = [URL(fileURLWithPath: "/Applications")],
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

                for root in scanRoots {
                    guard !Task.isCancelled else {
                        continuation.yield(.cancelled(ScanSummary(
                            itemsFound: itemsFound,
                            skippedLocations: skippedLocations,
                            totalBytes: totalBytes
                        )))
                        continuation.finish()
                        return
                    }

                    switch permissionCoordinator.validateReadAccess(to: root) {
                    case .denied(let reason):
                        skippedLocations += 1
                        continuation.yield(.skipped(SkippedLocation(path: root.path, reason: reason)))
                        continue
                    case .allowed:
                        break
                    }

                    let resourceKeys: Set<URLResourceKey> = [
                        .isDirectoryKey,
                        .isApplicationKey,
                        .isSymbolicLinkKey,
                        .nameKey
                    ]

                    guard let enumerator = FileManager.default.enumerator(
                        at: root,
                        includingPropertiesForKeys: Array(resourceKeys),
                        options: [.skipsHiddenFiles, .skipsPackageDescendants],
                        errorHandler: { _, _ in true }
                    ) else {
                        skippedLocations += 1
                        continuation.yield(.skipped(SkippedLocation(path: root.path, reason: "Unable to enumerate location.")))
                        continue
                    }

                    while let url = enumerator.nextObject() as? URL {
                        guard !Task.isCancelled else {
                            continuation.yield(.cancelled(ScanSummary(
                                itemsFound: itemsFound,
                                skippedLocations: skippedLocations,
                                totalBytes: totalBytes
                            )))
                            continuation.finish()
                            return
                        }

                        do {
                            let values = try url.resourceValues(forKeys: resourceKeys)
                            if values.isSymbolicLink == true {
                                continue
                            }

                            guard values.isDirectory == true else {
                                continue
                            }

                            guard values.isApplication == true || url.pathExtension == "app" else {
                                continue
                            }

                            let standardizedURL = url.standardizedFileURL
                            let size = try directorySizer.sizeOfItem(at: standardizedURL)

                            itemsFound += 1
                            totalBytes += size

                            continuation.yield(.itemFound(CleanableItem(
                                name: standardizedURL.deletingPathExtension().lastPathComponent,
                                path: standardizedURL.path,
                                sizeInBytes: size,
                                category: .largeApps,
                                sourceRoot: root.path
                            )))

                            continuation.yield(.progress(ScanProgress(
                                phase: "Scanning Applications (\(itemsFound) found)",
                                scannedLocations: scannedLocations,
                                itemsFound: itemsFound,
                                skippedLocations: skippedLocations
                            )))

                            enumerator.skipDescendants()
                        } catch {
                            continue
                        }
                    }

                    scannedLocations += 1
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
}
