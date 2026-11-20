import SwiftUI

// MARK: - 12. Navigation

struct NavigationGalleryView: View {
  @State private var depth = 1

  var body: some View {
    List {
      Section("Stack State") {
        VStack(alignment: .leading, spacing: 12) {
          HStack {
            Text("Navigation stack: \(depth)")
              .font(.system(size: 16, weight: .semibold))
            Spacer()
            Text("Page \(depth)")
              .font(.system(size: 13, weight: .medium))
              .foregroundStyle(.secondary)
          }

          HStack(spacing: 10) {
            Button("Push next page") {
              depth += 1
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity, minHeight: 40)

            Button("Pop to first") {
              depth = 1
            }
            .buttonStyle(.bordered)
            .disabled(depth <= 1)
            .frame(maxWidth: .infinity, minHeight: 40)
          }
        }
      }

      Section("Nested NavigationLink") {
        NavigationLink("Push Real Subpage →") {
          List {
            Section("Pushed Destination") {
              Text("Tap the Back button in the top navigation bar to return.")
                .font(.system(size: 15))
            }
          }
          .listStyle(.insetGrouped)
          .navigationTitle("Page \(depth + 1)")
        }
      }

      Section("Scrollable Content Under Bar") {
        ForEach(0..<4, id: \.self) { idx in
          let colors: [Color] = [.blue, .indigo, .teal, .orange]
          HStack {
            Text("Recents Card \(idx + 1)")
              .font(.system(size: 15, weight: .semibold))
              .foregroundStyle(Color.white)
            Spacer()
            Text("Depth \(depth)")
              .font(.system(size: 12))
              .foregroundStyle(Color.white.opacity(0.85))
          }
          .padding(14)
          .background(colors[idx % colors.count], in: RoundedRectangle(cornerRadius: 14))
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Navigation")
  }
}

// MARK: - 13. Tab Bar

struct TabBarGalleryView: View {
  @State private var selectedTab = 0

  var body: some View {
    TabView(selection: $selectedTab) {
      tabHero(
        title: "Home",
        subtitle: "Selected: Home",
        detail: "Standard SwiftUI TabView with native platform tab bar presentation.",
        c1: Color(red: 0.12, green: 0.44, blue: 0.96),
        c2: Color(red: 0.34, green: 0.72, blue: 0.98)
      )
      .tabItem {
        Label("Home", systemImage: "house")
      }
      .tag(0)

      tabHero(
        title: "Search",
        subtitle: "Selected: Search",
        detail: "Switch between tabs to test live selection and tab bar chrome.",
        c1: Color(red: 0.08, green: 0.64, blue: 0.52),
        c2: Color(red: 0.28, green: 0.82, blue: 0.68)
      )
      .tabItem {
        Label("Search", systemImage: "magnifyingglass")
      }
      .tag(1)

      tabHero(
        title: "Profile",
        subtitle: "Selected: Profile",
        detail: "Pure SwiftUI TabView compiled natively across platforms.",
        c1: Color(red: 0.56, green: 0.24, blue: 0.88),
        c2: Color(red: 0.90, green: 0.34, blue: 0.68)
      )
      .tabItem {
        Label("Profile", systemImage: "person")
      }
      .tag(2)
    }
    .navigationTitle("Tab Bar")
  }

  private func tabHero(title: String, subtitle: String, detail: String, c1: Color, c2: Color) -> some View {
    VStack(spacing: 16) {
      Spacer()
      VStack(spacing: 10) {
        Text(title)
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(Color.white)
        Text(subtitle)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(Color.white.opacity(0.92))
        Text(detail)
          .font(.system(size: 14))
          .foregroundStyle(Color.white.opacity(0.84))
          .multilineTextAlignment(.center)
      }
      .padding(24)
      .frame(maxWidth: .infinity)
      .background(
        LinearGradient(colors: [c1, c2], startPoint: .topLeading, endPoint: .bottomTrailing),
        in: RoundedRectangle(cornerRadius: 22)
      )
      .padding(.horizontal, 20)
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - 14. Alert

struct AlertGalleryView: View {
  @State private var lastAction = "No action chosen yet."
  @State private var showOneAction = false
  @State private var showTwoActions = false
  @State private var showThreeActions = false
  @State private var showDestructive = false
  @State private var showTitleOnly = false
  @State private var showSheet = false

  var body: some View {
    List {
      Section {
        Button("One Action") { showOneAction = true }.buttonStyle(.borderless)
        Button("Two Actions") { showTwoActions = true }.buttonStyle(.borderless)
        Button("Three Actions") { showThreeActions = true }.buttonStyle(.borderless)
      } header: {
        Text("Actions")
      } footer: {
        Text("Fewer than three actions sit side by side when their titles fit.")
      }

      Section("Action Styles & Sheet") {
        Button("Destructive Action") { showDestructive = true }.buttonStyle(.borderless)
        Button("Title Only") { showTitleOnly = true }.buttonStyle(.borderless)
        Button("Present Bottom Sheet") { showSheet = true }.buttonStyle(.borderless)
      }

      Section("Last Action") {
        Text(lastAction)
          .font(.system(size: 15))
          .foregroundStyle(.secondary)
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Alert")
    .sheet(isPresented: $showSheet) {
      VStack(alignment: .leading, spacing: 14) {
        Text("Modal Sheet")
          .font(.system(size: 20, weight: .bold))
        Text("Presented with native ModalBottomSheet on Android and Liquid Glass sheet styling.")
          .font(.system(size: 15))
          .foregroundStyle(.secondary)
        Button("Done") {
          lastAction = "Dismissed Sheet"
          showSheet = false
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity, minHeight: 42)
      }
      .padding(24)
      .frame(width: 340, height: 220)
    }
    .alert("Notice", isPresented: $showOneAction) {
      Button("OK") { lastAction = "Chose: OK (One Action)" }
    } message: {
      Text("A single action acknowledges this alert.")
    }
    .alert("Title", isPresented: $showTwoActions) {
      Button("Cancel", role: .cancel) { lastAction = "Chose: Cancel" }
      Button("OK") { lastAction = "Chose: OK" }
    } message: {
      Text("A message that explains what happens.")
    }
    .alert("Save Changes?", isPresented: $showThreeActions) {
      Button("Save") { lastAction = "Chose: Save" }
      Button("Don't Save", role: .destructive) { lastAction = "Chose: Don't Save" }
      Button("Cancel", role: .cancel) { lastAction = "Chose: Cancel" }
    } message: {
      Text("You have unsaved edits in this document.")
    }
    .alert("Delete Item?", isPresented: $showDestructive) {
      Button("Cancel", role: .cancel) { lastAction = "Cancelled deletion" }
      Button("Delete", role: .destructive) { lastAction = "Chose: Delete (Destructive)" }
    } message: {
      Text("This action cannot be undone.")
    }
    .alert("Title Only Alert", isPresented: $showTitleOnly) {
      Button("Dismiss", role: .cancel) { lastAction = "Dismissed Title Only" }
    }
  }
}
