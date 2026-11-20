import SwiftUI

enum NoteFolder: String, CaseIterable, Identifiable, Hashable {
  case all = "All Notes"
  case work = "Work"
  case personal = "Personal"
  case ideas = "Ideas"

  var id: String { rawValue }

  var icon: String {
    switch self {
    case .all: return "folder"
    case .work: return "doc.text"
    case .personal: return "heart"
    case .ideas: return "sparkles"
    }
  }
}

struct NoteItem: Identifiable, Hashable {
  let id: UUID
  var title: String
  var body: String
  var folder: NoteFolder
  var isPinned: Bool
  var updatedAt: String

  init(
    id: UUID = UUID(),
    title: String,
    body: String,
    folder: NoteFolder,
    isPinned: Bool = false,
    updatedAt: String = "Just now"
  ) {
    self.id = id
    self.title = title
    self.body = body
    self.folder = folder
    self.isPinned = isPinned
    self.updatedAt = updatedAt
  }
}

@main
struct NotesApp: App {
  var body: some Scene {
    WindowGroup("Notes") {
      NotesRootView()
    }
    .defaultSize(width: 1020, height: 680)
  }
}

struct NotesRootView: View {
  @State private var notes: [NoteItem] = [
    NoteItem(
      title: "CrossSwiftUI Architecture",
      body: "# CrossSwiftUI\n\nSingle SwiftUI codebase compiled natively for macOS, Windows, and Linux.\n\n- Value views & declarative layout\n- Native Win32/GDI+ & GTK/Cairo drawing\n- Unmodified .xcodeproj builds",
      folder: .work,
      isPinned: true,
      updatedAt: "Today, 14:20"
    ),
    NoteItem(
      title: "Release Checklist",
      body: "# v1.0 Release Checklist\n\n1. Verify DesktopUIGallery on macOS, Windows, Linux\n2. Check dark mode contrast\n3. Run SwiftUIRuntimeTests\n4. Tag and publish binaries",
      folder: .work,
      updatedAt: "Today, 11:05"
    ),
    NoteItem(
      title: "Weekend Reading List",
      body: "# Books & Papers\n\n- Designing Data-Intensive Applications\n- Swift Concurrency Manifesto\n- Crafting Interpreters",
      folder: .personal,
      updatedAt: "Yesterday"
    ),
    NoteItem(
      title: "Plugin Ideas",
      body: "# Future Ideas\n\n- Markdown split preview\n- Quick command palette (⌘K)\n- Cloud sync via WebDAV",
      folder: .ideas,
      updatedAt: "Nov 18"
    ),
  ]

  @State private var selectedFolder: NoteFolder? = .all
  @State private var selectedNoteID: UUID?
  @State private var searchQuery = ""
  @State private var showPreview = false
  @State private var pendingDeleteID: UUID?
  @State private var showDeleteAlert = false

  private var visibleNotes: [NoteItem] {
    let folder = selectedFolder ?? .all
    return notes
      .filter { note in
        let folderMatch = (folder == .all) || (note.folder == folder)
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let searchMatch =
          query.isEmpty
          || note.title.localizedCaseInsensitiveContains(query)
          || note.body.localizedCaseInsensitiveContains(query)
        return folderMatch && searchMatch
      }
      .sorted { lhs, rhs in
        if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
        return lhs.title < rhs.title
      }
  }

  private var activeNoteIndex: Int? {
    guard let id = selectedNoteID ?? visibleNotes.first?.id else { return nil }
    return notes.firstIndex(where: { $0.id == id })
  }

  var body: some View {
    NavigationSplitView {
      List(selection: $selectedFolder) {
        Section("Folders") {
          ForEach(NoteFolder.allCases) { folder in
            HStack(spacing: 8) {
              Image(systemName: folder.icon)
                .foregroundStyle(Color.orange)
                .frame(width: 15, height: 15)
              Text(folder.rawValue)
                .font(.system(size: 13, weight: .medium))
              Spacer()
              Text("\(countFor(folder))")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            }
            .tag(folder)
          }
        }
      }
      .listStyle(.sidebar)
    } content: {
      VStack(spacing: 0) {
        HStack(spacing: 8) {
          TextField("Search notes…", text: $searchQuery)
            .textFieldStyle(.roundedBorder)
          Button {
            createNote()
          } label: {
            Image(systemName: "square.and.pencil")
              .frame(width: 15, height: 15)
          }
          .buttonStyle(.borderedProminent)
          .help("New Note (⌘N)")
          .keyboardShortcut("n", modifiers: .command)
        }
        .padding(12)

        Divider()

        if visibleNotes.isEmpty {
          ContentUnavailableView {
            Label("No Notes", systemImage: "note.text")
          } description: {
            Text("Create a new note or clear the search query.")
          } actions: {
            Button("New Note") { createNote() }
              .buttonStyle(.borderedProminent)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          List(selection: $selectedNoteID) {
            ForEach(visibleNotes) { note in
              VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                  if note.isPinned {
                    Image(systemName: "pin.fill")
                      .foregroundStyle(Color.orange)
                      .frame(width: 11, height: 11)
                  }
                  Text(note.title.isEmpty ? "Untitled Note" : note.title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                }
                Text(note.body.replacingOccurrences(of: "\n", with: " "))
                  .font(.system(size: 11))
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
                Text("\(note.folder.rawValue) · \(note.updatedAt)")
                  .font(.system(size: 10))
                  .foregroundStyle(.secondary)
              }
              .padding(.vertical, 4)
              .tag(note.id)
              .contextMenu {
                Button(note.isPinned ? "Unpin" : "Pin to Top") {
                  togglePin(note.id)
                }
                Button("Duplicate") {
                  duplicateNote(note)
                }
                Divider()
                Button("Delete", role: .destructive) {
                  pendingDeleteID = note.id
                  showDeleteAlert = true
                }
              }
            }
          }
        }
      }
      .frame(width: 260)
    } detail: {
      if let index = activeNoteIndex {
        VStack(alignment: .leading, spacing: 0) {
          HStack(spacing: 12) {
            TextField("Title", text: $notes[index].title)
              .font(.system(size: 18, weight: .bold))
              .textFieldStyle(.plain)

            Spacer()

            Picker("Folder", selection: $notes[index].folder) {
              Text("Work").tag(NoteFolder.work)
              Text("Personal").tag(NoteFolder.personal)
              Text("Ideas").tag(NoteFolder.ideas)
            }
            .pickerStyle(.menu)
            .labelsHidden()

            Toggle("Preview", isOn: $showPreview)
              .toggleStyle(.button)

            Button("Delete", role: .destructive) {
              pendingDeleteID = notes[index].id
              showDeleteAlert = true
            }
            .buttonStyle(.bordered)
          }
          .padding(.horizontal, 20)
          .padding(.vertical, 12)

          Divider()

          if showPreview {
            ScrollView(.vertical) {
              VStack(alignment: .leading, spacing: 10) {
                ForEach(
                  Array(notes[index].body.components(separatedBy: "\n").enumerated()),
                  id: \.offset
                ) { _, line in
                  if line.hasPrefix("# ") {
                    Text(String(line.dropFirst(2)))
                      .font(.system(size: 22, weight: .bold))
                  } else if line.hasPrefix("- ") {
                    HStack(alignment: .top, spacing: 8) {
                      Text("•").font(.system(size: 14, weight: .bold))
                      Text(String(line.dropFirst(2))).font(.system(size: 14))
                    }
                  } else {
                    Text(line.isEmpty ? " " : line)
                      .font(.system(size: 14))
                  }
                }
              }
              .padding(20)
              .frame(maxWidth: .infinity, alignment: .leading)
            }
          } else {
            TextEditor(text: $notes[index].body)
              .font(.system(size: 14))
              .padding(16)
          }

          Divider()

          HStack {
            Text("Words: \(wordCount(notes[index].body)) · Characters: \(notes[index].body.count)")
              .font(.system(size: 11))
              .foregroundStyle(.secondary)
            Spacer()
            Text(notes[index].isPinned ? "Pinned" : notes[index].updatedAt)
              .font(.system(size: 11))
              .foregroundStyle(.secondary)
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        ContentUnavailableView {
          Label("Select a Note", systemImage: "doc.text")
        } description: {
          Text("Choose a note from the list or press ⌘N to create one.")
        }
      }
    }
    .onAppear {
      if selectedNoteID == nil { selectedNoteID = notes.first?.id }
    }
    .alert("Delete Note?", isPresented: $showDeleteAlert) {
      Button("Cancel", role: .cancel) { pendingDeleteID = nil }
      Button("Delete", role: .destructive) {
        if let id = pendingDeleteID {
          notes.removeAll { $0.id == id }
          if selectedNoteID == id { selectedNoteID = visibleNotes.first?.id }
          pendingDeleteID = nil
        }
      }
    } message: {
      Text("This note will be permanently removed.")
    }
  }

  private func countFor(_ folder: NoteFolder) -> Int {
    if folder == .all { return notes.count }
    return notes.filter { $0.folder == folder }.count
  }

  private func createNote() {
    let targetFolder = (selectedFolder == nil || selectedFolder == .all) ? .work : selectedFolder!
    let item = NoteItem(title: "New Note", body: "# New Note\n\nStart writing…", folder: targetFolder)
    notes.insert(item, at: 0)
    selectedNoteID = item.id
  }

  private func togglePin(_ id: UUID) {
    if let idx = notes.firstIndex(where: { $0.id == id }) {
      notes[idx].isPinned.toggle()
    }
  }

  private func duplicateNote(_ note: NoteItem) {
    let copy = NoteItem(
      title: "\(note.title) Copy",
      body: note.body,
      folder: note.folder,
      isPinned: false,
      updatedAt: "Just now"
    )
    notes.insert(copy, at: 0)
    selectedNoteID = copy.id
  }

  private func wordCount(_ text: String) -> Int {
    text.split { $0.isWhitespace || $0.isNewline }.count
  }
}
