import SwiftUI

// MARK: - 15. NavigationStack & TabView

struct NavigationAndTabsGalleryView: View {
  @State private var selectedTab = 0

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      GallerySection("TabView", subtitle: "Multi-tab container with Label tab items and live selection binding.") {
        TabView(selection: $selectedTab) {
          tabCard(
            title: "Overview",
            detail: "Tab 0 is active. Switch tabs to test live state and selection binding.",
            color: .blue
          )
          .tabItem {
            Label("Overview", systemImage: "house")
          }
          .tag(0)

          tabCard(
            title: "Search",
            detail: "Tab 1 is active. Each tab preserves its own SwiftUI subtree.",
            color: .teal
          )
          .tabItem {
            Label("Search", systemImage: "magnifyingglass")
          }
          .tag(1)

          tabCard(
            title: "Settings",
            detail: "Tab 2 is active. Works on macOS, Windows, and Linux.",
            color: .indigo
          )
          .tabItem {
            Label("Settings", systemImage: "gearshape")
          }
          .tag(2)
        }
        .frame(height: 190)
      }

      GallerySection("NavigationStack & NavigationLink", subtitle: "Embedded navigation stack with push and back transitions.") {
        NavigationStack {
          VStack(alignment: .leading, spacing: 12) {
            Text("Root View inside NavigationStack")
              .font(.system(size: 14, weight: .semibold))
            NavigationLink("Open Inspector Detail →") {
              VStack(alignment: .leading, spacing: 10) {
                Text("Pushed Detail Destination")
                  .font(.system(size: 15, weight: .bold))
                Text("Use the Back button to pop back to the root view.")
                  .font(.system(size: 13))
                  .foregroundStyle(.secondary)
              }
              .padding(16)
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
              .navigationTitle("Inspector Detail")
            }
            .buttonStyle(.borderedProminent)
          }
          .padding(16)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
          .navigationTitle("Root")
        }
        .frame(height: 170)
        .overlay {
          RoundedRectangle(cornerRadius: 8)
            .strokeBorder(Color.gray.opacity(0.25), lineWidth: 1)
        }
      }
    }
  }

  private func tabCard(title: String, detail: String, color: Color) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.system(size: 18, weight: .bold))
        .foregroundStyle(Color.white)
      Text(detail)
        .font(.system(size: 13))
        .foregroundStyle(Color.white.opacity(0.9))
    }
    .padding(18)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .background(color, in: RoundedRectangle(cornerRadius: 10))
    .padding(8)
  }
}

// MARK: - 16. Popover, ContextMenu, Alert, Sheet & ConfirmationDialog

struct PresentationGalleryView: View {
  @State private var showTopPopover = false
  @State private var showBottomPopover = false
  @State private var showLeadingPopover = false
  @State private var showTrailingPopover = false
  @State private var showAlert = false
  @State private var showDestructiveAlert = false
  @State private var showSheet = false
  @State private var showDialog = false
  @State private var lastEvent = "Trigger any overlay or right-click the card below."

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      GallerySection("Popover (4 Arrow Edges)", subtitle: "macOS-style anchored popover bubbles with automatic edge flipping.") {
        HStack(spacing: 12) {
          popoverButton("Arrow Top", edge: .top, isPresented: $showTopPopover)
          popoverButton("Arrow Bottom", edge: .bottom, isPresented: $showBottomPopover)
          popoverButton("Arrow Leading", edge: .leading, isPresented: $showLeadingPopover)
          popoverButton("Arrow Trailing", edge: .trailing, isPresented: $showTrailingPopover)
        }
      }

      GallerySection("Alert, Sheet & ConfirmationDialog", subtitle: "Desktop modal presentation primitives.") {
        VStack(alignment: .leading, spacing: 12) {
          HStack(spacing: 12) {
            Button("Info Alert") {
              showAlert = true
            }
            .buttonStyle(.borderedProminent)

            Button("Destructive Alert", role: .destructive) {
              showDestructiveAlert = true
            }
            .buttonStyle(.bordered)

            Button("Present Sheet") {
              showSheet = true
            }
            .buttonStyle(.bordered)

            Button("Confirmation Dialog") {
              showDialog = true
            }
            .buttonStyle(.bordered)
          }

          Text("Last Event: \(lastEvent)")
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
        .alert("Build Succeeded", isPresented: $showAlert) {
          Button("OK", role: .cancel) {
            lastEvent = "Info alert acknowledged"
          }
        } message: {
          Text("DesktopUIGallery compiled cleanly for the active platform.")
        }
        .alert("Delete Cached Artifacts?", isPresented: $showDestructiveAlert) {
          Button("Cancel", role: .cancel) {
            lastEvent = "Destructive alert cancelled"
          }
          Button("Delete", role: .destructive) {
            lastEvent = "Confirmed destructive delete"
          }
        } message: {
          Text("This action removes temporary build caches and cannot be undone.")
        }
        .sheet(isPresented: $showSheet) {
          VStack(alignment: .leading, spacing: 14) {
            Text("Modal Sheet")
              .font(.system(size: 18, weight: .bold))
            Text("Sheets present focused secondary workflows over the active window.")
              .font(.system(size: 13))
              .foregroundStyle(.secondary)
            HStack {
              Spacer()
              Button("Close Sheet") {
                showSheet = false
                lastEvent = "Sheet closed"
              }
              .buttonStyle(.borderedProminent)
            }
          }
          .padding(24)
          .frame(width: 360)
        }
        .confirmationDialog("Export Format", isPresented: $showDialog) {
          Button("Portable Archive (.zip)") { lastEvent = "Dialog: .zip" }
          Button("Installer Package") { lastEvent = "Dialog: Installer" }
          Button("Cancel", role: .cancel) { lastEvent = "Dialog cancelled" }
        } message: {
          Text("Choose a format for the exported bundle.")
        }
      }

      GallerySection("Context Menu", subtitle: "Right-click anywhere inside the target surface to open a contextMenu.") {
        HStack(spacing: 12) {
          Image(systemName: "macwindow.and.cursorarrow")
            .foregroundStyle(Color.indigo)
            .frame(width: 24, height: 24)
          VStack(alignment: .leading, spacing: 2) {
            Text("Right-Click Target Surface")
              .font(.system(size: 14, weight: .semibold))
            Text("Secondary-click here to inspect context menu items.")
              .font(.system(size: 12))
              .foregroundStyle(.secondary)
          }
          Spacer()
        }
        .padding(18)
        .background(Color.indigo.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
        .overlay {
          RoundedRectangle(cornerRadius: 10)
            .strokeBorder(Color.indigo.opacity(0.35), lineWidth: 1)
        }
        .contextMenu {
          Button("Copy Path") { lastEvent = "ContextMenu: Copy Path" }
          Button("Duplicate") { lastEvent = "ContextMenu: Duplicate" }
          Divider()
          Button("Remove", role: .destructive) { lastEvent = "ContextMenu: Remove" }
        }
      }
    }
  }

  private func popoverButton(_ title: String, edge: Edge, isPresented: Binding<Bool>) -> some View {
    Button(title) {
      isPresented.wrappedValue.toggle()
    }
    .buttonStyle(.bordered)
    .popover(isPresented: isPresented, arrowEdge: edge) {
      VStack(alignment: .leading, spacing: 10) {
        Text(title)
          .font(.system(size: 14, weight: .bold))
        Text("Anchored popover bubble with pointer beak. Click outside or press Escape to dismiss.")
          .font(.system(size: 12))
          .foregroundStyle(.secondary)
        Button("Done") {
          isPresented.wrappedValue = false
          lastEvent = "\(title) dismissed"
        }
        .buttonStyle(.borderedProminent)
      }
      .padding(16)
      .frame(width: 240)
    }
  }
}
