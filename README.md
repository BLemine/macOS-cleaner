# MacCleaner

MacCleaner is a macOS cleaner app built in Swift with SwiftUI.

The current version focuses on a modern desktop UI, an MVVM-based architecture, and async scanning infrastructure for cleanup categories such as junk files, large apps, unused apps, and large caches.

## Current Status

This repository is an early v1.

Implemented today:
- SwiftUI macOS app target for `macOS 14+`
- MVVM architecture
- Shared async `Scanner` protocol using `AsyncStream`
- Junk Files category UI and scanning flow
- Safe cleanup flow that moves items to Trash using `FileManager.trashItem()`
- Confirmation sheet before cleanup
- Sidebar navigation for all planned categories

Not fully implemented yet:
- Large Apps scanning
- Unused Apps scanning
- Large Caches scanning
- Privileged helper for protected system locations
- Polished permission UX for Full Disk Access / elevated access

## Safety Rules

The app is designed around conservative cleanup behavior:

- It never deletes immediately.
- Cleanup actions require explicit user confirmation.
- Cleanup uses Trash only, never direct removal.
- Scanning is dry-run only and does not modify files.
- The confirmation flow shows full paths and sizes before cleanup.

## Implemented Category

### Junk Files

The Junk Files category scans common junk locations such as:

- `~/Library/Caches`
- `/Library/Caches`
- `~/Library/Logs`
- user crash-report locations under `~/Library`
- system crash-report locations when accessible

The scanner is asynchronous and streams results incrementally to keep the UI responsive.

## Planned Categories

### Large Apps

Will scan `/Applications` and sort apps by bundle size descending.

### Unused Apps

Will identify apps not opened in the last 90+ days using Spotlight metadata.

### Large Caches

Will break down `~/Library/Caches` by app/cache owner and sort by size.

## Architecture

The project uses:

- `SwiftUI` for the app UI
- `MVVM` for presentation and state management
- One view model per category
- A shared `Scanner` protocol for category scanners
- `async/await` and `AsyncStream` for non-blocking scans

Current source layout:

```text
Sources/MacCleaner/
  App/
  Models/
  Protocols/
  Scanners/
  Services/
  ViewModels/
  Views/
```

## Running The App

### In Xcode

1. Open `mac-cleaner.xcodeproj`
2. Select the `MacCleaner` scheme
3. Choose `My Mac`
4. Press `Run`

### From The Command Line

The repository also keeps a `Package.swift` for local SwiftPM builds and tests, but the recommended way to run the app is through the Xcode project because it launches a proper macOS `.app` bundle.

## Testing

This repo includes unit tests for:

- scan event models
- junk file scanner behavior
- junk file view model behavior
- basic app shell expectations

## Known Limitations

- Only Junk Files is implemented end to end right now.
- Large cache trees can still take time to enumerate on real machines.
- Protected folders may be skipped depending on macOS permissions.
- The other sidebar categories are placeholders until their scanners and view models are implemented.

## Roadmap

Short-term next steps:

1. Finish stabilizing the Junk Files scan and cancel flow.
2. Implement Large Apps end to end.
3. Implement Large Caches as grouped cache ownership rather than every file row.
4. Add proper permission guidance for protected locations.
5. Improve scan summaries and cleanup reporting.

## License

No license has been added yet.
