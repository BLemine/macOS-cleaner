import Foundation

@MainActor
final class LargeAppsViewModel: ObservableObject {
    @Published private(set) var items: [CleanableItem] = []
    @Published private(set) var selectedItemIDs: Set<UUID> = []
    @Published private(set) var skippedLocations: [SkippedLocation] = []
    @Published private(set) var progress: ScanProgress?
    @Published private(set) var summary: ScanSummary?
    @Published private(set) var isScanning = false
    @Published var isShowingConfirmation = false
    @Published private(set) var statusMessage: String?
    @Published private(set) var lastCleanupError: String?

    private let scanner: any Scanner<CleanableItem>
    private let trashService: any TrashServicing
    private var scanTask: Task<Void, Never>?
    private let fileManager = FileManager.default

    init(
        scanner: any Scanner<CleanableItem> = LargeAppsScanner(),
        trashService: any TrashServicing = TrashService()
    ) {
        self.scanner = scanner
        self.trashService = trashService
    }

    deinit {
        scanTask?.cancel()
    }

    var totalSelectedBytes: Int64 {
        items
            .filter { selectedItemIDs.contains($0.id) }
            .reduce(0) { $0 + $1.sizeInBytes }
    }

    var selectedItems: [CleanableItem] {
        items.filter { selectedItemIDs.contains($0.id) }
    }

    var blockedSelectedItems: [CleanableItem] {
        selectedItems.filter { !canTrashApp($0) }
    }

    var canCleanSelected: Bool {
        !selectedItems.isEmpty && blockedSelectedItems.isEmpty
    }

    var permissionExplanation: String? {
        guard !blockedSelectedItems.isEmpty else {
            return nil
        }

        if blockedSelectedItems.count == 1 {
            return "This app is in a protected location and requires admin privileges. V1 can scan it, but cannot move it to Trash."
        }

        return "Some selected apps are in protected locations and require admin privileges. V1 can scan them, but cannot move them to Trash."
    }

    func startScan() {
        scanTask?.cancel()
        scanTask = Task { [weak self] in
            await self?.scan()
        }
    }

    func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
        statusMessage = "Scan stopped."
    }

    func toggleSelection(for id: UUID) {
        if selectedItemIDs.contains(id) {
            selectedItemIDs.remove(id)
        } else {
            selectedItemIDs.insert(id)
        }
    }

    func cleanSelected() async throws {
        lastCleanupError = nil

        guard blockedSelectedItems.isEmpty else {
            lastCleanupError = permissionExplanation
            return
        }

        for item in selectedItems {
            do {
                try await trashService.trashItem(at: URL(fileURLWithPath: item.path))
            } catch {
                lastCleanupError = error.localizedDescription
                throw error
            }
        }

        let ids = Set(selectedItems.map(\.id))
        items.removeAll { ids.contains($0.id) }
        selectedItemIDs.removeAll()
        isShowingConfirmation = false
        statusMessage = "Moved selected apps to Trash."
    }

    private func scan() async {
        items = []
        selectedItemIDs = []
        skippedLocations = []
        progress = nil
        summary = nil
        lastCleanupError = nil
        statusMessage = nil
        isScanning = true

        for await event in scanner.scan() {
            switch event {
            case .started:
                progress = ScanProgress(phase: "Preparing scan", scannedLocations: 0, itemsFound: 0, skippedLocations: 0)
            case .progress(let value):
                progress = value
            case .itemFound(let item):
                items.append(item)
                items.sort { $0.sizeInBytes > $1.sizeInBytes }
            case .skipped(let location):
                skippedLocations.append(location)
            case .finished(let value):
                summary = value
                statusMessage = "Scan finished."
                scanTask = nil
                isScanning = false
            case .cancelled(let value):
                summary = value
                statusMessage = "Scan stopped."
                scanTask = nil
                isScanning = false
            case .failed(let message):
                lastCleanupError = message
                statusMessage = message
                scanTask = nil
                isScanning = false
            }
        }

        scanTask = nil
        isScanning = false
    }

    func canTrashApp(_ item: CleanableItem) -> Bool {
        let url = URL(fileURLWithPath: item.path)
        let standardizedPath = url.standardizedFileURL.path

        // Apps inside /Applications are typically admin-managed even if simple
        // deletability checks appear permissive for the current session.
        if standardizedPath.hasPrefix("/Applications/") {
            return false
        }

        return fileManager.isDeletableFile(atPath: standardizedPath)
    }
}
