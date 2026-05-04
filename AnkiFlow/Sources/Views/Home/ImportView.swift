import SwiftUI
import UniformTypeIdentifiers

struct ImportPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ImportViewModel()
    @State private var showingPicker = false

    var onImportComplete: (() -> Void)?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if viewModel.isImporting {
                    ProgressView("Importing...")
                    Text(viewModel.statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let result = viewModel.importResult {
                    ImportResultView(result: result) {
                        if result.errors.isEmpty {
                            onImportComplete?()
                        }
                        dismiss()
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)

                        Text("Import Anki Deck")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Select a .apkg file to import")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button {
                        showingPicker = true
                    } label: {
                        Label("Select File", systemImage: "folder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showingPicker,
                allowedContentTypes: [UTType(filenameExtension: "apkg") ?? .item],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        viewModel.importFile(url: url)
                    }
                case .failure(let error):
                    viewModel.importResult = ImportResult(
                        deckName: "Import Failed",
                        totalCards: 0,
                        addedCards: 0,
                        updatedCards: 0,
                        skippedDuplicates: 0,
                        errors: [error.localizedDescription]
                    )
                }
            }
        }
    }
}

struct ImportResultView: View {
    let result: ImportResult
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: result.errors.isEmpty ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(result.errors.isEmpty ? .green : .orange)

            Text("Import Complete")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 8) {
                ResultRow(label: "Deck", value: result.deckName)
                ResultRow(label: "Added", value: "\(result.addedCards)")
                ResultRow(label: "Updated", value: "\(result.updatedCards)")
                ResultRow(label: "Skipped", value: "\(result.skippedDuplicates)")
                if !result.errors.isEmpty {
                    ResultRow(label: "Errors", value: "\(result.errors.count)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            Spacer()

            Button("Done", action: onDismiss)
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        }
    }
}

struct ResultRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

@MainActor
final class ImportViewModel: ObservableObject {
    @Published var isImporting = false
    @Published var statusMessage = ""
    @Published var importResult: ImportResult?

    private let importer = ApkgImporter()

    func importFile(url: URL) {
        isImporting = true
        statusMessage = "Analyzing package..."

        guard url.startAccessingSecurityScopedResource() else {
            importResult = ImportResult(
                deckName: url.lastPathComponent,
                totalCards: 0,
                addedCards: 0,
                updatedCards: 0,
                skippedDuplicates: 0,
                errors: ["Cannot access file"])
            isImporting = false
            return
        }

        defer {
            url.stopAccessingSecurityScopedResource()
        }

        Task {
            do {
                let result = try await importer.importFile(at: url, options: ImportOptions())
                importResult = result
            } catch {
                importResult = ImportResult(
                    deckName: url.lastPathComponent,
                    totalCards: 0,
                    addedCards: 0,
                    updatedCards: 0,
                    skippedDuplicates: 0,
                    errors: [error.localizedDescription]
                )
            }
            isImporting = false
        }
    }
}
