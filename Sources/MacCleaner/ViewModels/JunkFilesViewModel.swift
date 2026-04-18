import Foundation

@MainActor
final class JunkFilesViewModel: ObservableObject {
    @Published private(set) var items: [CleanableItem] = []
    @Published private(set) var selectedItemIDs: Set<UUID> = []
    @Published private(set) var skippedLocations: [SkippedLocation] = []
    @Published private(set) var progress: ScanProgress?
    @Published private(set) var summary: ScanSummary?
    @Published private(set) var isScanning = false
    @Published var isShowingConfirmation = false
    @Published private(set) var lastCleanupError: String?

    private let scanner: any Scanner<CleanableItem>
    private let trashService: any TrashServicing

    init(
        scanner: any Scanner<CleanableItem> = JunkFilesScanner(),
        trashService: any TrashServicing = TrashService()
    ) {
        self.scanner = scanner
        self.trashService = trashService
    }

    var totalSelectedBytes: Int64 {
        items
            .filter { selectedItemIDs.contains($0.id) }
            .reduce(0) { $0 + $1.sizeInBytes }
    }

    var selectedItems: [CleanableItem] {
        items.filter { selectedItemIDs.contains($0.id) }
    }

    func scan() async {
        items = []
        selectedItemIDs = []
        skippedLocations = []
        progress = nil
        summary = nil
        lastCleanupError = nil
        isScanning = true
        var pendingItems: [CleanableItem] = []

        for await event in scanner.scan() {
            switch event {
            case .started:
                progress = ScanProgress(phase: "Preparing scan", scannedLocations: 0, itemsFound: 0, skippedLocations: 0)
            case .progress(let value):
                if !pendingItems.isEmpty {
                    items.append(contentsOf: pendingItems)
                    pendingItems.removeAll(keepingCapacity: true)
                }
                progress = value
            case .itemFound(let item):
                pendingItems.append(item)

                if pendingItems.count >= 200 {
                    items.append(contentsOf: pendingItems)
                    pendingItems.removeAll(keepingCapacity: true)
                }
            case .skipped(let location):
                skippedLocations.append(location)
            case .finished(let value):
                if !pendingItems.isEmpty {
                    items.append(contentsOf: pendingItems)
                    pendingItems.removeAll(keepingCapacity: true)
                }
                items.sort { $0.sizeInBytes > $1.sizeInBytes }
                summary = value
                isScanning = false
            case .failed(let message):
                if !pendingItems.isEmpty {
                    items.append(contentsOf: pendingItems)
                    pendingItems.removeAll(keepingCapacity: true)
                }
                items.sort { $0.sizeInBytes > $1.sizeInBytes }
                lastCleanupError = message
                isScanning = false
            }
        }

        isScanning = false
    }

    func toggleSelection(for id: UUID) {
        if selectedItemIDs.contains(id) {
            selectedItemIDs.remove(id)
        } else {
            selectedItemIDs.insert(id)
        }
    }

    func loadPreviewItems(_ items: [CleanableItem]) {
        self.items = items
    }

    func cleanSelected() async throws {
        lastCleanupError = nil

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
    }
}
