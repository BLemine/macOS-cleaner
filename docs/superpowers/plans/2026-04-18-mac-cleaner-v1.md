# Mac Cleaner V1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS 14+ SwiftUI cleaner app with MVVM architecture and async scanner infrastructure, then implement the Junk Files category end to end with safe Trash-only cleanup.

**Architecture:** Use a Swift Package executable app with SwiftUI and a focused source layout under `Sources/MacCleaner`. Shared models, scanner abstractions, services, and category view models stay separate so later categories can plug into the same async event pipeline.

**Tech Stack:** Swift 6, SwiftUI, Foundation, XCTest

---

### Task 1: Scaffold The App Package

**Files:**
- Create: `Package.swift`
- Create: `Sources/MacCleaner/App/MacCleanerApp.swift`
- Create: `Sources/MacCleaner/App/AppView.swift`
- Test: `Tests/MacCleanerTests/MacCleanerSmokeTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import MacCleaner

final class MacCleanerSmokeTests: XCTestCase {
    func test_category_count_matches_v1_sidebar() {
        XCTAssertEqual(CleanerCategory.allCases.count, 4)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter MacCleanerSmokeTests/test_category_count_matches_v1_sidebar`
Expected: FAIL because `CleanerCategory` is not defined yet.

- [ ] **Step 3: Write minimal implementation**

```swift
enum CleanerCategory: String, CaseIterable {
    case junkFiles
    case largeApps
    case unusedApps
    case largeCaches
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter MacCleanerSmokeTests/test_category_count_matches_v1_sidebar`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Package.swift Sources/MacCleaner/App Sources/MacCleaner/Models/CleanerCategory.swift Tests/MacCleanerTests/MacCleanerSmokeTests.swift
git commit -m "feat: scaffold mac cleaner app package"
```

### Task 2: Add Shared Scan Models And Protocol

**Files:**
- Create: `Sources/MacCleaner/Models/CleanableItem.swift`
- Create: `Sources/MacCleaner/Models/ScanEvent.swift`
- Create: `Sources/MacCleaner/Models/ScanProgress.swift`
- Create: `Sources/MacCleaner/Models/SkippedLocation.swift`
- Create: `Sources/MacCleaner/Protocols/Scanner.swift`
- Test: `Tests/MacCleanerTests/ScannerProtocolTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ScannerProtocolTests/test_finished_event_carries_summary_counts`
Expected: FAIL because the scan types are missing.

- [ ] **Step 3: Write minimal implementation**

```swift
struct ScanSummary: Equatable {
    let itemsFound: Int
    let skippedLocations: Int
    let totalBytes: Int64
}

enum ScanEvent<Item: Sendable>: Sendable {
    case started
    case progress(ScanProgress)
    case itemFound(Item)
    case skipped(SkippedLocation)
    case finished(ScanSummary)
    case failed(String)
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ScannerProtocolTests/test_finished_event_carries_summary_counts`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Sources/MacCleaner/Models Sources/MacCleaner/Protocols/Scanner.swift Tests/MacCleanerTests/ScannerProtocolTests.swift
git commit -m "feat: add scanner protocol and scan event models"
```

### Task 3: Implement Directory Sizing And Junk Scanner

**Files:**
- Create: `Sources/MacCleaner/Services/DirectorySizer.swift`
- Create: `Sources/MacCleaner/Scanners/JunkFilesScanner.swift`
- Test: `Tests/MacCleanerTests/JunkFilesScannerTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import MacCleaner

final class JunkFilesScannerTests: XCTestCase {
    func test_scanner_streams_files_from_readable_roots() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let fileURL = root.appendingPathComponent("cache.data")
        try Data(repeating: 1, count: 128).write(to: fileURL)

        let scanner = JunkFilesScanner(scanRoots: [root], fileManager: .default)
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
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter JunkFilesScannerTests/test_scanner_streams_files_from_readable_roots`
Expected: FAIL because `JunkFilesScanner` does not exist.

- [ ] **Step 3: Write minimal implementation**

```swift
struct JunkFilesScanner: Scanner {
    typealias Item = CleanableItem

    func scan() -> AsyncStream<ScanEvent<CleanableItem>> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter JunkFilesScannerTests/test_scanner_streams_files_from_readable_roots`
Expected: PASS after implementing recursive enumeration and size lookup.

- [ ] **Step 5: Commit**

```bash
git add Sources/MacCleaner/Services/DirectorySizer.swift Sources/MacCleaner/Scanners/JunkFilesScanner.swift Tests/MacCleanerTests/JunkFilesScannerTests.swift
git commit -m "feat: implement junk files scanner"
```

### Task 4: Build Junk Files View Model

**Files:**
- Create: `Sources/MacCleaner/ViewModels/JunkFilesViewModel.swift`
- Test: `Tests/MacCleanerTests/JunkFilesViewModelTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import MacCleaner

final class JunkFilesViewModelTests: XCTestCase {
    func test_total_selected_size_updates_when_item_is_toggled() async {
        let item = CleanableItem(name: "cache.data", path: "/tmp/cache.data", sizeInBytes: 512, category: .junkFiles)
        let scanner = MockJunkScanner(events: [.started, .itemFound(item), .finished(.init(itemsFound: 1, skippedLocations: 0, totalBytes: 512))])
        let viewModel = JunkFilesViewModel(scanner: scanner, trashService: TrashService())

        await viewModel.scan()
        await viewModel.toggleSelection(for: item.id)

        XCTAssertEqual(await viewModel.totalSelectedBytes, 512)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter JunkFilesViewModelTests/test_total_selected_size_updates_when_item_is_toggled`
Expected: FAIL because `JunkFilesViewModel` does not exist.

- [ ] **Step 3: Write minimal implementation**

```swift
@MainActor
final class JunkFilesViewModel: ObservableObject {
    @Published private(set) var items: [CleanableItem] = []
    @Published private(set) var selectedItemIDs: Set<UUID> = []

    var totalSelectedBytes: Int64 {
        items.filter { selectedItemIDs.contains($0.id) }.reduce(0) { $0 + $1.sizeInBytes }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter JunkFilesViewModelTests/test_total_selected_size_updates_when_item_is_toggled`
Expected: PASS after implementing scan event handling and selection state.

- [ ] **Step 5: Commit**

```bash
git add Sources/MacCleaner/ViewModels/JunkFilesViewModel.swift Tests/MacCleanerTests/JunkFilesViewModelTests.swift
git commit -m "feat: add junk files view model"
```

### Task 5: Build Sidebar UI And Junk Files Screen

**Files:**
- Create: `Sources/MacCleaner/Views/Sidebar/SidebarView.swift`
- Create: `Sources/MacCleaner/Views/JunkFiles/JunkFilesView.swift`
- Create: `Sources/MacCleaner/Views/Shared/PlaceholderCategoryView.swift`
- Modify: `Sources/MacCleaner/App/AppView.swift`
- Test: `Tests/MacCleanerTests/MacCleanerSmokeTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
func test_default_selected_category_is_junk_files() {
    XCTAssertEqual(AppSelection.defaultCategory, .junkFiles)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter MacCleanerSmokeTests/test_default_selected_category_is_junk_files`
Expected: FAIL because `AppSelection` is missing.

- [ ] **Step 3: Write minimal implementation**

```swift
enum AppSelection {
    static let defaultCategory: CleanerCategory = .junkFiles
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter MacCleanerSmokeTests/test_default_selected_category_is_junk_files`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Sources/MacCleaner/App Sources/MacCleaner/Views Tests/MacCleanerTests/MacCleanerSmokeTests.swift
git commit -m "feat: add sidebar shell and junk files screen"
```

### Task 6: Add Confirmation Sheet And Trash Workflow

**Files:**
- Create: `Sources/MacCleaner/Services/TrashService.swift`
- Modify: `Sources/MacCleaner/ViewModels/JunkFilesViewModel.swift`
- Modify: `Sources/MacCleaner/Views/JunkFiles/JunkFilesView.swift`
- Test: `Tests/MacCleanerTests/JunkFilesViewModelTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
func test_confirmed_cleanup_calls_trash_service_for_selected_items() async throws {
    let item = CleanableItem(name: "cache.data", path: "/tmp/cache.data", sizeInBytes: 512, category: .junkFiles)
    let trashService = RecordingTrashService()
    let viewModel = JunkFilesViewModel(scanner: MockJunkScanner(events: []), trashService: trashService)

    await viewModel.loadPreviewItems([item])
    await viewModel.toggleSelection(for: item.id)
    try await viewModel.cleanSelected()

    XCTAssertEqual(trashService.trashedPaths, ["/tmp/cache.data"])
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter JunkFilesViewModelTests/test_confirmed_cleanup_calls_trash_service_for_selected_items`
Expected: FAIL because `cleanSelected()` and the trash service contract are missing.

- [ ] **Step 3: Write minimal implementation**

```swift
protocol TrashServicing {
    func trashItem(at url: URL) async throws
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter JunkFilesViewModelTests/test_confirmed_cleanup_calls_trash_service_for_selected_items`
Expected: PASS after implementing Trash-only cleanup and post-clean selection reset.

- [ ] **Step 5: Commit**

```bash
git add Sources/MacCleaner/Services/TrashService.swift Sources/MacCleaner/ViewModels/JunkFilesViewModel.swift Sources/MacCleaner/Views/JunkFiles/JunkFilesView.swift Tests/MacCleanerTests/JunkFilesViewModelTests.swift
git commit -m "feat: add junk file trash workflow"
```

### Task 7: Verification

**Files:**
- Test: `Tests/MacCleanerTests/JunkFilesScannerTests.swift`
- Test: `Tests/MacCleanerTests/JunkFilesViewModelTests.swift`
- Test: `Tests/MacCleanerTests/MacCleanerSmokeTests.swift`

- [ ] **Step 1: Run focused test suite**

Run: `swift test`
Expected: PASS with the junk scanner, view model, and app shell tests green.

- [ ] **Step 2: Build the app target**

Run: `swift build`
Expected: PASS with no compile errors.

- [ ] **Step 3: Manually verify the app launches in Xcode**

Run: open the package in Xcode and launch the macOS app.
Expected: sidebar renders, Junk Files scan runs, confirmation sheet shows paths and sizes, cleanup uses Trash only.

- [ ] **Step 4: Commit**

```bash
git add .
git commit -m "feat: deliver mac cleaner junk files v1"
```
