import SwiftUI

struct GalleryHomeView: View {
  var body: some View {
    NavigationStack {
      List {
        Section("Controls") {
          navRow("Slider", icon: "slider.horizontal.3", color: .blue) {
            SliderGalleryView()
          }
          navRow("Switch", icon: "switch.2", color: .green) {
            SwitchGalleryView()
          }
          navRow("Segmented Control", icon: "rectangle.split.3x1", color: .indigo) {
            SegmentedControlGalleryView()
          }
          navRow("Button", icon: "capsule", color: .blue) {
            ButtonGalleryView()
          }
          navRow("Stepper", icon: "plusminus", color: .orange) {
            StepperGalleryView()
          }
          navRow("Page Control", icon: "ellipsis", color: .teal) {
            PageControlGalleryView()
          }
          navRow("Text Field", icon: "text.cursor", color: .cyan) {
            TextFieldGalleryView()
          }
          navRow("Control & Flex", icon: "hand.tap", color: .purple) {
            ControlFlexGalleryView()
          }
        }

        Section("Materials & Effects") {
          navRow("Visual Effect", icon: "sparkles", color: .indigo) {
            VisualEffectGalleryView()
          }
          navRow("Liquid Lens", icon: "drop.fill", color: .cyan) {
            LiquidLensGalleryView()
          }
          navRow("Siri", icon: "waveform", color: .pink) {
            SiriGalleryView()
          }
        }

        Section("Bars & Presentation") {
          navRow("Navigation", icon: "sidebar.left", color: .blue) {
            NavigationGalleryView()
          }
          navRow("Tab Bar", icon: "menubar.dock.rectangle", color: .teal) {
            TabBarGalleryView()
          }
          navRow("Alert", icon: "exclamationmark.triangle", color: .orange) {
            AlertGalleryView()
          }
        }

        Section("Content & Indicators") {
          navRow("Text", icon: "textformat", color: .blue) {
            TextGalleryView()
          }
          navRow("Image View", icon: "photo", color: .green) {
            ImageViewGalleryView()
          }
          navRow("Progress View", icon: "chart.bar.fill", color: .indigo) {
            ProgressViewGalleryView()
          }
          navRow("Activity Indicator", icon: "rays", color: .gray) {
            ActivityIndicatorGalleryView()
          }
        }

        Section("Layout & Containers") {
          navRow("View", icon: "square.on.square", color: .blue) {
            ViewGalleryView()
          }
          navRow("Scroll View", icon: "list.bullet.below.rectangle", color: .purple) {
            ScrollViewGalleryView()
          }
          navRow("Collection View", icon: "square.grid.2x2", color: .teal) {
            CollectionViewGalleryView()
          }
        }

        Section("Common Layouts") {
          navRow("Settings Form", icon: "gearshape", color: .gray) {
            SettingsLayoutGalleryView()
          }
          navRow("Card Feed", icon: "folder", color: .indigo) {
            CardFeedLayoutGalleryView()
          }
          navRow("Dashboard Grid", icon: "chart.bar.fill", color: .blue) {
            DashboardLayoutGalleryView()
          }
          navRow("Profile", icon: "person.crop.circle", color: .teal) {
            ProfileLayoutGalleryView()
          }
        }

        Section("Interactive Flows") {
          navRow("Shopping Cart", icon: "bolt", color: .orange) {
            ShoppingCartGalleryView()
          }
          navRow("Task Manager", icon: "checklist", color: .green) {
            TaskManagerGalleryView()
          }
          navRow("Sign Up Form", icon: "person", color: .purple) {
            SignUpFormGalleryView()
          }
        }
      }
      .listStyle(.insetGrouped)
      .navigationTitle("Mobile UI Gallery")
    }
  }

  private func navRow<Destination: View>(
    _ title: String,
    icon: String,
    color: Color,
    @ViewBuilder destination: () -> Destination
  ) -> some View {
    NavigationLink(destination: destination) {
      Label {
        Text(title)
      } icon: {
        ZStack {
          RoundedRectangle(cornerRadius: 8)
            .fill(color.opacity(0.15))
            .frame(width: 30, height: 30)
          Image(systemName: icon)
            .foregroundStyle(color)
            .frame(width: 17, height: 17)
        }
      }
    }
  }
}
