# Mac Cleaner Design

**Goal**

Build a macOS 14+ SwiftUI cleaner app with MVVM architecture, async category scanning, explicit destructive-action confirmation, Trash-only cleanup, and an initial end-to-end Junk Files category.

**Product Scope**

- v1 includes a sidebar-based macOS app shell with four categories:
  - Junk Files
  - Large Apps
  - Unused Apps
  - Large Caches
- Only Junk Files is fully implemented in v1.
- The other categories are present as view model and UI placeholders so the architecture is ready for follow-on work.

**Architecture**

- App framework: SwiftUI for macOS 14+.
- Pattern: MVVM with one view model per category.
- Scanning: every scanner conforms to a shared `Scanner` protocol and emits results through `AsyncStream`.
- Safety: scanning is dry-run only; cleanup requires explicit user confirmation and always uses `FileManager.trashItem`.

**Core Design**

1. `Scanner` protocol
   - Generic over the result item type.
   - Exposes `scan() -> AsyncStream<ScanEvent<Item>>`.
   - Supports incremental progress, discovered items, skipped paths, completion, and failure.

2. Shared models
   - `CleanableItem`: display name, full path, size, category metadata, and optional auxiliary fields.
   - `ScanProgress`: current phase plus counts for scanned roots, found items, and skipped paths.
   - `SkippedLocation`: path plus human-readable reason.
   - `ScanEvent<Item>`: started, progress, itemFound, skipped, finished, failed.

3. Services
   - `PermissionCoordinator`: central place for access checks and future elevated-permission workflow.
   - `TrashService`: moves selected URLs to Trash asynchronously.
   - `DirectorySizer`: computes recursive directory sizes without mutating the file system.

4. View models
   - One view model per category.
   - `JunkFilesViewModel` owns scan state, selected item ids, progress summary, skipped paths, and cleanup confirmation state.
   - Placeholder view models provide category title and stub state for unimplemented categories.

5. UI
   - `NavigationSplitView` with category sidebar.
   - Content panel contains toolbar actions, progress indicator, summary metrics, and item list.
   - Confirmation sheet shows every selected item’s full path and size before trashing.
   - Use semantic colors and native materials so light and dark mode both look correct.

**Junk Files Category**

- Scan targets:
  - `~/Library/Caches`
  - `/Library/Caches`
  - `~/Library/Logs`
  - user crash-report locations under `~/Library`
  - system crash-report locations when readable
- Files are enumerated recursively.
- Each readable file is emitted as an item with exact path and size.
- Protected roots are attempted; if access is denied and deeper access is unavailable, those roots are reported as skipped.

**Permissions**

- v1 is best-effort.
- The app scans what current permissions allow.
- When protected locations are not readable, the app records those paths as skipped.
- `PermissionCoordinator` is intentionally isolated so a privileged helper can be added later without redesigning scanner/view-model boundaries.

**Safety Rules**

- Never delete without explicit user confirmation.
- Never use `removeItem`.
- Always show full path and size before cleanup.
- Always move to Trash via `FileManager.trashItem`.
- Scanning never writes to disk.

**Testing Strategy**

- Start with unit tests for `JunkFilesScanner`.
- Cover:
  - found file streaming
  - directory size calculation
  - skipped-path reporting for unreadable or missing roots
- Add unit tests for `JunkFilesViewModel` selection, totals, and scan result handling.

**Implementation Boundary**

- v1 does not include a privileged helper.
- v1 does not implement end-to-end cleaning for Large Apps, Unused Apps, or Large Caches.
- v1 does provide the shared architecture those categories will use.
