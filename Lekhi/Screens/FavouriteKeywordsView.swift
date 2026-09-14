//
//  FavouriteKeywordsView.swift
//  Lekhi
//
//  Manage the favourite keywords shown in the keyboard's idle suggestion
//  bar: add, edit, reorder and delete them, and move them in and out of the
//  app as JSON.
//

import SwiftUI
import UniformTypeIdentifiers

struct FavouriteKeywordsView: View {

    @State private var keywords: [String] = PinnedKeywordsStore.current()
    @State private var newKeyword = ""
    @State private var addError: String?

    @State private var editingIndex: Int?
    @State private var editText = ""

    @State private var showingFileImporter = false
    @State private var showingPasteSheet = false
    @State private var pendingImport: [String?]?
    @State private var showingClearConfirmation = false
    @State private var alert: AlertContent?

    @FocusState private var addFieldFocused: Bool

    private struct AlertContent: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    TextField("Add a keyword", text: $newKeyword)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .focused($addFieldFocused)
                        .onSubmit(addKeyword)
                        .onChange(of: newKeyword) { _, _ in addError = nil }

                    Button("Add", action: addKeyword)
                        .disabled(PinnedKeywordsStore.normalized(newKeyword) == nil)
                }
                if let addError {
                    Text(addError)
                        .font(.system(size: 13))
                        .foregroundStyle(.orange)
                }
            } footer: {
                Text("Tip: long-press any suggestion on the Lekhi keyboard to save it here.")
            }

            Section {
                if keywords.isEmpty {
                    Text("No favourites yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(keywords.enumerated()), id: \.element) { index, keyword in
                        Button {
                            editText = keyword
                            editingIndex = index
                        } label: {
                            HStack {
                                Text(keyword)
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                if index < 3 {
                                    Text("In bar")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Color.secondary)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.secondary.opacity(0.15)))
                                }
                            }
                        }
                    }
                    .onDelete { offsets in
                        var next = keywords
                        next.remove(atOffsets: offsets)
                        save(next)
                    }
                    .onMove { source, destination in
                        var next = keywords
                        next.move(fromOffsets: source, toOffset: destination)
                        save(next)
                    }
                }
            } header: {
                Text("Favourites (\(keywords.count))")
            } footer: {
                Text("The first three appear in the suggestion bar before you start typing; swipe the bar to reach the rest. Tap a keyword to edit it, or use Edit to reorder.")
            }

            Section {
                Button {
                    showingFileImporter = true
                } label: {
                    Label("Import from File…", systemImage: "doc.badge.plus")
                }

                Button {
                    showingPasteSheet = true
                } label: {
                    Label("Paste JSON…", systemImage: "doc.on.clipboard")
                }

                ShareLink(
                    item: FavouriteKeywordsExport(keywords: keywords),
                    preview: SharePreview("Lekhi favourite keywords")
                ) {
                    Label("Export as JSON", systemImage: "square.and.arrow.up")
                }
                .disabled(keywords.isEmpty)
            } header: {
                Text("Import & Export")
            } footer: {
                Text("Import a JSON list of words, like [\"আমি\", \"আপনি\"], or a file exported from Lekhi.")
            }

            Section {
                Button("Reset to Defaults") {
                    PinnedKeywordsStore.resetToDefaults()
                    reload()
                }
                Button("Remove All Favourites", role: .destructive) {
                    showingClearConfirmation = true
                }
                .disabled(keywords.isEmpty)
            }
        }
        .navigationTitle("Favourite Keywords")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !keywords.isEmpty {
                EditButton()
            }
        }
        .onAppear(perform: reload)
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.json, .plainText]
        ) { result in
            switch result {
            case .success(let url):
                readImportFile(at: url)
            case .failure(let error):
                alert = AlertContent(title: "Couldn't Open File", message: error.localizedDescription)
            }
        }
        .sheet(isPresented: $showingPasteSheet) {
            PasteKeywordsSheet { data in
                showingPasteSheet = false
                // Let the sheet finish dismissing before the next prompt.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    beginImport(data)
                }
            }
        }
        .confirmationDialog(
            importDialogTitle,
            isPresented: Binding(
                get: { pendingImport != nil },
                set: { if !$0 { pendingImport = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Add to Favourites") { finishImport(replace: false) }
            Button("Replace Favourites", role: .destructive) { finishImport(replace: true) }
            Button("Cancel", role: .cancel) { pendingImport = nil }
        } message: {
            Text("Add keeps your current favourites and appends new words. Replace swaps your list for the file's.")
        }
        .confirmationDialog(
            "Remove all \(keywords.count) favourites?",
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove All", role: .destructive) { save([]) }
        } message: {
            Text("Export them first if you might want them back.")
        }
        .alert(
            "Edit Keyword",
            isPresented: Binding(
                get: { editingIndex != nil },
                set: { if !$0 { editingIndex = nil } }
            )
        ) {
            TextField("Keyword", text: $editText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Save", action: commitEdit)
            Button("Cancel", role: .cancel) { editingIndex = nil }
        }
        .alert(item: $alert) { content in
            Alert(title: Text(content.title), message: Text(content.message))
        }
    }

    private var importDialogTitle: String {
        let count = pendingImport?.count ?? 0
        return "Import \(count) \(count == 1 ? "entry" : "entries")"
    }

    // MARK: - Editing

    private func reload() {
        keywords = PinnedKeywordsStore.current()
    }

    private func save(_ next: [String]) {
        PinnedKeywordsStore.set(next)
        reload()
    }

    private func addKeyword() {
        switch PinnedKeywordsStore.add(newKeyword) {
        case .added:
            newKeyword = ""
            addError = nil
            reload()
        case .alreadySaved:
            addError = "That keyword is already a favourite."
        case .full:
            addError = "You've reached the limit of \(PinnedKeywordsStore.maxCount) favourites."
        case .invalid:
            addError = "Keywords can't be empty or longer than \(PinnedKeywordsStore.maxKeywordLength) characters."
        }
        addFieldFocused = true
    }

    private func commitEdit() {
        guard let index = editingIndex, index < keywords.count else { return }
        editingIndex = nil

        guard let edited = PinnedKeywordsStore.normalized(editText) else {
            alert = AlertContent(
                title: "Keyword Not Saved",
                message: "Keywords can't be empty or longer than \(PinnedKeywordsStore.maxKeywordLength) characters."
            )
            return
        }
        guard edited != keywords[index] else { return }
        guard !keywords.contains(edited) else {
            alert = AlertContent(title: "Keyword Not Saved", message: "“\(edited)” is already a favourite.")
            return
        }

        var next = keywords
        next[index] = edited
        save(next)
    }

    // MARK: - Import

    private func readImportFile(at url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            beginImport(try Data(contentsOf: url))
        } catch {
            alert = AlertContent(title: "Couldn't Read File", message: error.localizedDescription)
        }
    }

    private func beginImport(_ data: Data) {
        do {
            pendingImport = try PinnedKeywordsStore.decodeImport(data)
            // Nothing to merge with or overwrite, so there is nothing to ask.
            if keywords.isEmpty {
                finishImport(replace: false)
            }
        } catch {
            alert = AlertContent(title: "Import Failed", message: error.localizedDescription)
        }
    }

    private func finishImport(replace: Bool) {
        guard let entries = pendingImport else { return }
        pendingImport = nil

        do {
            let summary = try PinnedKeywordsStore.importing(entries, into: keywords, replace: replace)
            save(summary.keywords)
            alert = AlertContent(title: "Import Complete", message: Self.describe(summary))
        } catch {
            alert = AlertContent(title: "Import Failed", message: error.localizedDescription)
        }
    }

    private static func describe(_ summary: PinnedKeywordsStore.ImportSummary) -> String {
        var lines = [summary.added == 0
            ? "No new keywords were added."
            : "Added \(summary.added) \(summary.added == 1 ? "keyword" : "keywords")."]
        if summary.duplicates > 0 {
            lines.append("Skipped \(summary.duplicates) already in your list.")
        }
        if summary.invalid > 0 {
            lines.append("Skipped \(summary.invalid) empty, too long, or not text.")
        }
        if summary.overLimit > 0 {
            lines.append("\(summary.overLimit) didn't fit — the limit is \(PinnedKeywordsStore.maxCount).")
        }
        return lines.joined(separator: "\n")
    }
}

/// Lets the user paste JSON copied from somewhere else, for when the list
/// isn't saved as a file.
private struct PasteKeywordsSheet: View {

    let onImport: (Data) -> Void

    @State private var text = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $text)
                        .font(.system(.body, design: .monospaced))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .frame(minHeight: 180)

                    PasteButton(payloadType: String.self) { strings in
                        if let first = strings.first {
                            text = first
                        }
                    }
                } footer: {
                    Text("For example: [\"আমি\", \"আপনি\", \"ধন্যবাদ\"]")
                }
            }
            .navigationTitle("Paste JSON")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") { onImport(Data(text.utf8)) }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

/// Exported as a named `.json` file so share targets like Files and AirDrop
/// keep a sensible filename.
struct FavouriteKeywordsExport: Transferable {
    let keywords: [String]

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { export in
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("lekhi-favourite-keywords.json")
            try PinnedKeywordsStore.exportData(export.keywords).write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }
}
