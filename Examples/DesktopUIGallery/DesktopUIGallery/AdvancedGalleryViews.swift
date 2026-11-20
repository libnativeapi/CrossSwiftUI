import SwiftUI

// MARK: - 20. Custom Layout (FlowLayout)

private struct FlowLayout: Layout {
  var horizontalSpacing: CGFloat = 8
  var verticalSpacing: CGFloat = 8

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let maxWidth = proposal.width ?? .infinity
    var x: CGFloat = 0
    var y: CGFloat = 0
    var rowHeight: CGFloat = 0
    var usedWidth: CGFloat = 0

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)
      if x > 0 && x + size.width > maxWidth {
        x = 0
        y += rowHeight + verticalSpacing
        rowHeight = 0
      }
      usedWidth = max(usedWidth, x + size.width)
      x += size.width + horizontalSpacing
      rowHeight = max(rowHeight, size.height)
    }
    return CGSize(width: usedWidth, height: y + rowHeight)
  }

  func placeSubviews(
    in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
  ) {
    var x = bounds.minX
    var y = bounds.minY
    var rowHeight: CGFloat = 0

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)
      if x > bounds.minX && x + size.width > bounds.maxX {
        x = bounds.minX
        y += rowHeight + verticalSpacing
        rowHeight = 0
      }
      subview.place(
        at: CGPoint(x: x, y: y),
        anchor: .topLeading,
        proposal: ProposedViewSize(size)
      )
      x += size.width + horizontalSpacing
      rowHeight = max(rowHeight, size.height)
    }
  }
}

struct CustomLayoutGalleryView: View {
  @State private var containerWidth: Double = 360
  @State private var spacing: Double = 8
  @State private var tags = [
    "SwiftUI", "Cross-Platform", "macOS", "Windows", "Linux",
    "Layout Protocol", "Zero Config", "NativeAPI", "Direct2D", "Cairo", "Pango",
  ]
  @State private var nextTagIndex = 1

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      GallerySection("FlowLayout (Custom Layout Protocol)", subtitle: "Implements sizeThatFits & placeSubviews to wrap tags dynamically.") {
        VStack(alignment: .leading, spacing: 12) {
          HStack(spacing: 16) {
            HStack(spacing: 8) {
              Text("Width: \(Int(containerWidth)) pt")
                .font(.system(size: 12, weight: .medium))
                .frame(width: 92, alignment: .leading)
              Slider(value: $containerWidth, in: 180...520, step: 10)
                .frame(width: 160)
            }
            HStack(spacing: 8) {
              Text("Spacing: \(Int(spacing)) pt")
                .font(.system(size: 12, weight: .medium))
                .frame(width: 84, alignment: .leading)
              Slider(value: $spacing, in: 4...20, step: 2)
                .frame(width: 120)
            }
          }

          HStack(spacing: 10) {
            Button("Add Tag") {
              tags.append("Tag #\(nextTagIndex)")
              nextTagIndex += 1
            }
            .buttonStyle(.borderedProminent)

            Button("Remove Last") {
              if tags.count > 1 { tags.removeLast() }
            }
            .buttonStyle(.bordered)
            .disabled(tags.count <= 1)
          }

          FlowLayout(horizontalSpacing: spacing, verticalSpacing: spacing) {
            ForEach(Array(tags.enumerated()), id: \.offset) { idx, tag in
              let colors: [Color] = [.blue, .indigo, .purple, .teal, .orange, .pink]
              Text(tag)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(colors[idx % colors.count], in: Capsule())
            }
          }
          .padding(14)
          .frame(width: containerWidth, alignment: .leading)
          .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
          .overlay {
            RoundedRectangle(cornerRadius: 10)
              .strokeBorder(Color.blue.opacity(0.28), lineWidth: 1)
          }
        }
      }
    }
  }
}

// MARK: - 21. Toolbar & Search

struct ToolbarAndSearchGalleryView: View {
  private struct ComponentItem: Identifiable {
    let id: String
    let name: String
    let category: String
    let icon: String
  }

  private let catalog: [ComponentItem] = [
    ComponentItem(id: "btn", name: "Button", category: "Controls", icon: "capsule"),
    ComponentItem(id: "tgl", name: "Toggle", category: "Controls", icon: "switch.2"),
    ComponentItem(id: "pkr", name: "Picker", category: "Controls", icon: "rectangle.split.3x1"),
    ComponentItem(id: "sld", name: "Slider", category: "Controls", icon: "slider.horizontal.3"),
    ComponentItem(id: "txt", name: "TextField", category: "Input", icon: "text.cursor"),
    ComponentItem(id: "grd", name: "Grid", category: "Layout", icon: "square.grid.2x2"),
    ComponentItem(id: "scr", name: "ScrollView", category: "Layout", icon: "list.bullet.below.rectangle"),
    ComponentItem(id: "pop", name: "Popover", category: "Overlay", icon: "macwindow"),
    ComponentItem(id: "cnv", name: "Canvas", category: "Graphics", icon: "paintbrush.fill"),
  ]

  @State private var query = ""
  @State private var sortAscending = true

  private var filtered: [ComponentItem] {
    let base = query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      ? catalog
      : catalog.filter {
          $0.name.localizedCaseInsensitiveContains(query)
            || $0.category.localizedCaseInsensitiveContains(query)
        }
    return base.sorted { sortAscending ? $0.name < $1.name : $0.name > $1.name }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      GallerySection("Search Bar, Toolbar & Empty State", subtitle: "Live query filtering paired with toolbar actions and ContentUnavailableView.") {
        VStack(alignment: .leading, spacing: 12) {
          HStack(spacing: 10) {
            HStack(spacing: 6) {
              Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .frame(width: 14, height: 14)
              TextField("Filter components by name or category…", text: $query)
                .textFieldStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            Button(sortAscending ? "Sort A→Z" : "Sort Z→A") {
              sortAscending.toggle()
            }
            .buttonStyle(.bordered)

            if !query.isEmpty {
              Button("Clear") { query = "" }
                .buttonStyle(.bordered)
            }
          }

          if filtered.isEmpty {
            ContentUnavailableView {
              Label("No Matches for \"\(query)\"", systemImage: "magnifyingglass")
            } description: {
              Text("Try searching for Button, Grid, or Layout.")
            } actions: {
              Button("Reset Search") { query = "" }
                .buttonStyle(.borderedProminent)
            }
            .padding(.vertical, 16)
          } else {
            VStack(alignment: .leading, spacing: 6) {
              ForEach(filtered) { item in
                HStack(spacing: 10) {
                  Image(systemName: item.icon)
                    .foregroundStyle(Color.blue)
                    .frame(width: 16, height: 16)
                  Text(item.name)
                    .font(.system(size: 13, weight: .semibold))
                  Spacer()
                  Text(item.category)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.gray.opacity(0.14), in: Capsule())
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
              }
            }
          }
        }
        .toolbar {
          ToolbarItemGroup(placement: .automatic) {
            Button(sortAscending ? "A→Z" : "Z→A") {
              sortAscending.toggle()
            }
          }
        }
      }
    }
  }
}

// MARK: - 22. Keyboard & Focus

struct KeyboardAndFocusGalleryView: View {
  private let commands = ["Build Project", "Run Tests", "Open Inspector", "Toggle Sidebar", "Export Bundle"]
  @State private var selectedIndex = 0
  @State private var lastKeyEvent = "Click the panel below, then press ↑ / ↓ / Return / Escape."
  @FocusState private var panelFocused: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      GallerySection("onKeyPress & Keyboard Navigation", subtitle: "Focus the list and drive selection with Up/Down arrows, Return, and Escape.") {
        VStack(alignment: .leading, spacing: 12) {
          HStack(spacing: 10) {
            Button("Focus Command List") {
              panelFocused = true
              lastKeyEvent = "Command list focused — use ↑ / ↓ / Return / Esc"
            }
            .buttonStyle(.borderedProminent)

            Button("Run Selected (⌘R)") {
              lastKeyEvent = "Executed: \(commands[selectedIndex])"
            }
            .buttonStyle(.bordered)
            .keyboardShortcut("r", modifiers: .command)
          }

          VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(commands.enumerated()), id: \.offset) { idx, title in
              HStack {
                Image(systemName: idx == selectedIndex ? "chevron.right" : "circle")
                  .foregroundStyle(idx == selectedIndex ? Color.white : Color.secondary)
                  .frame(width: 12, height: 12)
                Text(title)
                  .font(.system(size: 13, weight: idx == selectedIndex ? .semibold : .regular))
                  .foregroundStyle(idx == selectedIndex ? Color.white : Color.primary)
                Spacer()
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 8)
              .background(
                idx == selectedIndex ? Color.blue : Color.gray.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 7)
              )
              .onTapGesture {
                selectedIndex = idx
                panelFocused = true
                lastKeyEvent = "Selected: \(title)"
              }
            }
          }
          .padding(8)
          .background(
            panelFocused ? Color.blue.opacity(0.06) : Color.clear,
            in: RoundedRectangle(cornerRadius: 10)
          )
          .overlay {
            RoundedRectangle(cornerRadius: 10)
              .strokeBorder(panelFocused ? Color.blue : Color.gray.opacity(0.25), lineWidth: 1)
          }
          .focusable()
          .focused($panelFocused)
          .onKeyPress(.upArrow) {
            selectedIndex = max(0, selectedIndex - 1)
            lastKeyEvent = "KeyPress ↑ → \(commands[selectedIndex])"
            return .handled
          }
          .onKeyPress(.downArrow) {
            selectedIndex = min(commands.count - 1, selectedIndex + 1)
            lastKeyEvent = "KeyPress ↓ → \(commands[selectedIndex])"
            return .handled
          }
          .onKeyPress(.return) {
            lastKeyEvent = "KeyPress Return → Executed \(commands[selectedIndex])"
            return .handled
          }
          .onKeyPress(.escape) {
            panelFocused = false
            lastKeyEvent = "KeyPress Escape → Cleared focus"
            return .handled
          }

          Text(lastKeyEvent)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
      }
    }
  }
}

// MARK: - 23. State & Storage

private final class SharedCounterModel: ObservableObject {
  @Published var count: Int = 0
  @Published var label: String = "Shared Workspace"
}

private struct EnvironmentCounterBadge: View {
  @EnvironmentObject private var model: SharedCounterModel

  var body: some View {
    HStack(spacing: 12) {
      Text("\(model.label): \(model.count)")
        .font(.system(size: 14, weight: .semibold))
      Spacer()
      Button("-1") { model.count -= 1 }
        .buttonStyle(.bordered)
      Button("+1") { model.count += 1 }
        .buttonStyle(.borderedProminent)
    }
    .padding(12)
    .background(Color.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
  }
}

struct StateAndStorageGalleryView: View {
  @StateObject private var shared = SharedCounterModel()
  @State private var savedNote: String =
    UserDefaults.standard.string(forKey: "DesktopUIGallery.savedNote") ?? "Persisted across launches"
  @State private var saveStatus = "Stored in UserDefaults.standard"

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      GallerySection("@StateObject & @EnvironmentObject", subtitle: "ObservableObject state shared across child views with automatic re-rendering.") {
        VStack(alignment: .leading, spacing: 12) {
          TextField("Workspace Label", text: $shared.label)
            .textFieldStyle(.roundedBorder)
            .frame(maxWidth: 320)

          EnvironmentCounterBadge()
            .environmentObject(shared)
        }
      }

      GallerySection("Persistent Preferences (UserDefaults)", subtitle: "Reads and writes persistent desktop settings cleanly on macOS, Windows, and Linux.") {
        VStack(alignment: .leading, spacing: 10) {
          HStack(spacing: 10) {
            TextField("Saved Note", text: $savedNote)
              .textFieldStyle(.roundedBorder)
              .frame(maxWidth: 320)

            Button("Save") {
              UserDefaults.standard.set(savedNote, forKey: "DesktopUIGallery.savedNote")
              saveStatus = "Saved \"\(savedNote)\""
            }
            .buttonStyle(.borderedProminent)

            Button("Reload") {
              savedNote = UserDefaults.standard.string(forKey: "DesktopUIGallery.savedNote") ?? ""
              saveStatus = "Reloaded from UserDefaults"
            }
            .buttonStyle(.bordered)
          }

          Text(saveStatus)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
      }
    }
  }
}

// MARK: - 24. Lifecycle & Async Tasks

struct LifecycleAndTaskGalleryView: View {
  @State private var topic = "Releases"
  @State private var isLoading = false
  @State private var payload = "Waiting for task…"
  @State private var showChild = true
  @State private var events: [String] = []

  private func record(_ entry: String) {
    events.insert(entry, at: 0)
    if events.count > 6 { events.removeLast() }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      GallerySection(".task(id:) & Cancellation", subtitle: "Switching topics cancels any in-flight async task and starts a fresh one.") {
        VStack(alignment: .leading, spacing: 12) {
          Picker("Topic", selection: $topic) {
            Text("Releases").tag("Releases")
            Text("Commits").tag("Commits")
            Text("Issues").tag("Issues")
          }
          .pickerStyle(.segmented)
          .frame(maxWidth: 340)

          HStack(spacing: 10) {
            if isLoading {
              ProgressView()
            }
            Text(payload)
              .font(.system(size: 13, weight: .medium))
          }
          .frame(minHeight: 24)
        }
        .task(id: topic) {
          isLoading = true
          payload = "Loading \(topic)…"
          record("task(\(topic)) started")
          try? await Task.sleep(nanoseconds: 450_000_000)
          if Task.isCancelled { return }
          isLoading = false
          payload = "Loaded \(topic) successfully (3 items)"
          record("task(\(topic)) finished")
        }
      }

      GallerySection("onAppear, onDisappear & onChange", subtitle: "Mount/unmount a child view to observe lifecycle callbacks.") {
        VStack(alignment: .leading, spacing: 10) {
          Toggle("Mount Child View", isOn: $showChild)
            .toggleStyle(.checkbox)

          if showChild {
            HStack(spacing: 8) {
              Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.green)
                .frame(width: 16, height: 16)
              Text("Child view is currently mounted")
                .font(.system(size: 13))
            }
            .padding(10)
            .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            .onAppear { record("Child onAppear") }
            .onDisappear { record("Child onDisappear") }
          }

          VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(events.enumerated()), id: \.offset) { _, line in
              Text("• \(line)")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }
          }
        }
      }
    }
  }
}

// MARK: - 25. Rich Text & OpenURL

struct RichTextAndLinksGalleryView: View {
  @State private var lastOpenedURL = "Click an inline link below to test OpenURLAction."

  private var attributedParagraph: AttributedString {
    var prefix = AttributedString("Explore ")
    var swiftLink = AttributedString("Swift.org")
    swiftLink.link = URL(string: "https://www.swift.org")
    var middle = AttributedString(" and the ")
    var repoLink = AttributedString("CrossSwiftUI GitHub")
    repoLink.link = URL(string: "https://github.com/libnativeapi/crossswift")
    var suffix = AttributedString(" documentation.")
    prefix.append(swiftLink)
    prefix.append(middle)
    prefix.append(repoLink)
    prefix.append(suffix)
    return prefix
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      GallerySection("Text(AttributedString) & OpenURLAction", subtitle: "Intercepts inline URL taps via the scoped openURL environment action.") {
        VStack(alignment: .leading, spacing: 12) {
          Text(attributedParagraph)
            .font(.system(size: 14))
            .environment(\.openURL, OpenURLAction { url in
              lastOpenedURL = "Intercepted URL: \(url.absoluteString)"
              return .handled
            })

          Text(lastOpenedURL)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
      }
    }
  }
}
