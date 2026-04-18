import SwiftUI

struct JunkFilesView: View {
    @ObservedObject var viewModel: JunkFilesViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .background(
            LinearGradient(
                colors: [Color(nsColor: .windowBackgroundColor), Color.accentColor.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .toolbar {
            ToolbarItemGroup {
                Button(viewModel.isScanning ? "Stop" : "Scan") {
                    if viewModel.isScanning {
                        viewModel.cancelScan()
                    } else {
                        viewModel.startScan()
                    }
                }
                .keyboardShortcut("r", modifiers: [.command])

                Button("Clean Selected") {
                    viewModel.isShowingConfirmation = true
                }
                .disabled(viewModel.selectedItems.isEmpty)
            }
        }
        .sheet(isPresented: $viewModel.isShowingConfirmation) {
            confirmationSheet
                .frame(minWidth: 560, minHeight: 420)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Junk Files")
                .font(.system(size: 28, weight: .semibold, design: .rounded))

            Text("Review cache files, logs, and crash reports before moving anything to Trash.")
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                summaryChip(title: "Items", value: "\(viewModel.items.count)")
                summaryChip(title: "Selected", value: SizeFormatter.string(for: viewModel.totalSelectedBytes))
                summaryChip(title: "Skipped", value: "\(viewModel.skippedLocations.count)")
            }

            if let progress = viewModel.progress, viewModel.isScanning {
                ProgressView(progress.phase)
                    .controlSize(.large)
            }

            if let statusMessage = viewModel.statusMessage, !viewModel.isScanning {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
    }

    private var content: some View {
        Group {
            if viewModel.items.isEmpty && !viewModel.isScanning {
                ContentUnavailableView(
                    "No Junk Files Yet",
                    systemImage: "sparkles",
                    description: Text("Run a scan to list cache files, logs, and crash reports that are safe to review.")
                )
            } else {
                List(viewModel.items) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Toggle(
                            "",
                            isOn: Binding(
                                get: { viewModel.selectedItemIDs.contains(item.id) },
                                set: { _ in viewModel.toggleSelection(for: item.id) }
                            )
                        )
                        .toggleStyle(.checkbox)
                        .labelsHidden()

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .font(.headline)
                            Text(item.path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }

                        Spacer(minLength: 12)

                        Text(SizeFormatter.string(for: item.sizeInBytes))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
    }

    private func summaryChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var confirmationSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Move Selected Items To Trash")
                .font(.title2.weight(.semibold))

            Text("Nothing will be permanently deleted. Review the full paths and sizes below before continuing.")
                .foregroundStyle(.secondary)

            List(viewModel.selectedItems) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.path)
                        .textSelection(.enabled)
                    Text(SizeFormatter.string(for: item.sizeInBytes))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(SizeFormatter.string(for: viewModel.totalSelectedBytes))
                        .font(.headline)
                }

                Spacer()

                Button("Cancel", role: .cancel) {
                    viewModel.isShowingConfirmation = false
                }

                Button("Move to Trash") {
                    Task {
                        try? await viewModel.cleanSelected()
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
    }
}
