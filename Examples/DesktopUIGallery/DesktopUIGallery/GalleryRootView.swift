import SwiftUI

enum GalleryItem: String, CaseIterable, Identifiable, Hashable {
  // Controls
  case buttons
  case toggles
  case pickers
  case slidersAndSteppers
  case textInput
  case menusAndLinks

  // Content & Media
  case textAndLabels
  case imagesAndSymbols
  case progressAndStatus

  // Layout & Containers
  case stacksAndDivider
  case grids
  case scrollAndLazy
  case listAndForm
  case adaptiveAndGeometry

  // Navigation & Presentation
  case navigationAndTabs
  case presentation

  // Graphics & Interaction
  case shapesAndCanvas
  case gradientsAndMaterials
  case gesturesAndAnimation

  // Advanced & System
  case customLayout
  case toolbarAndSearch
  case keyboardAndFocus
  case stateAndStorage
  case lifecycleAndTask
  case richTextAndLinks

  var id: String { rawValue }

  var title: String {
    switch self {
    case .buttons: return "Buttons & ControlGroup"
    case .toggles: return "Toggle"
    case .pickers: return "Picker"
    case .slidersAndSteppers: return "Slider & Stepper"
    case .textInput: return "TextField, SecureField & TextEditor"
    case .menusAndLinks: return "Menu & Link"
    case .textAndLabels: return "Text, Label & LabeledContent"
    case .imagesAndSymbols: return "Image & SF Symbols"
    case .progressAndStatus: return "ProgressView & Status"
    case .stacksAndDivider: return "Stacks & Divider"
    case .grids: return "Grid, LazyVGrid & LazyHGrid"
    case .scrollAndLazy: return "ScrollView & Lazy Stacks"
    case .listAndForm: return "List & Form"
    case .adaptiveAndGeometry: return "Geometry, ViewThatFits & Timeline"
    case .navigationAndTabs: return "NavigationStack & TabView"
    case .presentation: return "Popover, ContextMenu, Alert & Sheet"
    case .shapesAndCanvas: return "Shapes, Path & Canvas"
    case .gradientsAndMaterials: return "Gradients, Materials & Effects"
    case .gesturesAndAnimation: return "Gestures & Animation"
    case .customLayout: return "Custom Layout (FlowLayout)"
    case .toolbarAndSearch: return "Toolbar & Search"
    case .keyboardAndFocus: return "Keyboard & Focus"
    case .stateAndStorage: return "State & Persistent Storage"
    case .lifecycleAndTask: return "Lifecycle & Async Tasks"
    case .richTextAndLinks: return "AttributedString & OpenURL"
    }
  }

  var sidebarTitle: String {
    switch self {
    case .buttons: return "Button"
    case .toggles: return "Toggle"
    case .pickers: return "Picker"
    case .slidersAndSteppers: return "Slider & Stepper"
    case .textInput: return "Text Input"
    case .menusAndLinks: return "Menu & Link"
    case .textAndLabels: return "Text & Label"
    case .imagesAndSymbols: return "Image & Symbols"
    case .progressAndStatus: return "Progress & Status"
    case .stacksAndDivider: return "Stacks & Divider"
    case .grids: return "Grids"
    case .scrollAndLazy: return "Scroll & Lazy"
    case .listAndForm: return "List & Form"
    case .adaptiveAndGeometry: return "Adaptive & Geometry"
    case .navigationAndTabs: return "Navigation & Tabs"
    case .presentation: return "Overlays & Dialogs"
    case .shapesAndCanvas: return "Shapes & Canvas"
    case .gradientsAndMaterials: return "Gradients & Effects"
    case .gesturesAndAnimation: return "Gestures & Animation"
    case .customLayout: return "Custom Layout"
    case .toolbarAndSearch: return "Toolbar & Search"
    case .keyboardAndFocus: return "Keyboard & Focus"
    case .stateAndStorage: return "State & Storage"
    case .lifecycleAndTask: return "Lifecycle & Task"
    case .richTextAndLinks: return "Rich Text & Links"
    }
  }

  var subtitle: String {
    switch self {
    case .buttons: return "Standard button styles, roles, control sizes, custom ButtonStyle, and ControlGroup."
    case .toggles: return "Switch, checkbox, and button toggle styles with custom tint and disabled states."
    case .pickers: return "Segmented, menu, radio group, and inline pickers backed by live bindings."
    case .slidersAndSteppers: return "Continuous and stepped sliders alongside numeric and custom-action steppers."
    case .textInput: return "Single-line TextField, SecureField password entry, multiline TextEditor, and @FocusState."
    case .menusAndLinks: return "Pull-down Menu actions with dividers and destructive roles, plus external Link."
    case .textAndLabels: return "Typography scale, rich concatenated Text runs, truncation, Label styles, and LabeledContent."
    case .imagesAndSymbols: return "Vector SF Symbols with tinting, sizing, and aspect-ratio presentation."
    case .progressAndStatus: return "Determinate and indeterminate ProgressView indicators and ContentUnavailableView."
    case .stacksAndDivider: return "VStack, HStack, ZStack, Spacer, and Divider alignment and layering."
    case .grids: return "Grid with GridRow alignment, LazyVGrid columns, and horizontal LazyHGrid."
    case .scrollAndLazy: return "Vertical/horizontal ScrollView, ScrollViewReader programmatic scrolling, and lazy stacks."
    case .listAndForm: return "Selectable List with sections and desktop-styled Form with grouped controls."
    case .adaptiveAndGeometry: return "GeometryReader metrics, ViewThatFits responsive fallback, and TimelineView."
    case .navigationAndTabs: return "NavigationStack push/pop navigation and TabView tab switching."
    case .presentation: return "4-edge Popover, right-click contextMenu, alert, sheet, and confirmationDialog."
    case .shapesAndCanvas: return "Built-in shapes, trim, custom Path geometry, and Canvas vector rendering."
    case .gradientsAndMaterials: return "Linear, radial, and angular gradients, translucent materials, shadows, and clipping."
    case .gesturesAndAnimation: return "Tap, hover, and drag gestures paired with animated transforms."
    case .customLayout: return "SwiftUI Layout protocol implementing a wrapping FlowLayout tag cloud."
    case .toolbarAndSearch: return "ToolbarItemGroup actions combined with live search filtering and empty states."
    case .keyboardAndFocus: return "onKeyPress arrow/return/escape handling, @FocusState, and keyboard shortcuts."
    case .stateAndStorage: return "@StateObject, @EnvironmentObject shared state, and UserDefaults persistence."
    case .lifecycleAndTask: return "Cancellable .task(id:) async work alongside onAppear and onDisappear logs."
    case .richTextAndLinks: return "Text(AttributedString) with inline links intercepted via OpenURLAction."
    }
  }

  var icon: String {
    switch self {
    case .buttons: return "capsule"
    case .toggles: return "switch.2"
    case .pickers: return "rectangle.split.3x1"
    case .slidersAndSteppers: return "slider.horizontal.3"
    case .textInput: return "text.cursor"
    case .menusAndLinks: return "menubar.rectangle"
    case .textAndLabels: return "textformat"
    case .imagesAndSymbols: return "photo"
    case .progressAndStatus: return "chart.bar.fill"
    case .stacksAndDivider: return "square.on.square"
    case .grids: return "square.grid.2x2"
    case .scrollAndLazy: return "list.bullet.below.rectangle"
    case .listAndForm: return "list.bullet"
    case .adaptiveAndGeometry: return "rectangle.3.group"
    case .navigationAndTabs: return "sidebar.left"
    case .presentation: return "macwindow"
    case .shapesAndCanvas: return "paintbrush.fill"
    case .gradientsAndMaterials: return "sparkles"
    case .gesturesAndAnimation: return "hand.tap"
    case .customLayout: return "square.2.layers.3d"
    case .toolbarAndSearch: return "magnifyingglass"
    case .keyboardAndFocus: return "keyboard"
    case .stateAndStorage: return "internaldrive"
    case .lifecycleAndTask: return "clock.arrow.circlepath"
    case .richTextAndLinks: return "link"
    }
  }

  var accent: Color {
    switch self {
    case .buttons: return .blue
    case .toggles: return .green
    case .pickers: return .indigo
    case .slidersAndSteppers: return .orange
    case .textInput: return .cyan
    case .menusAndLinks: return .purple
    case .textAndLabels: return .blue
    case .imagesAndSymbols: return .green
    case .progressAndStatus: return .indigo
    case .stacksAndDivider: return .blue
    case .grids: return .teal
    case .scrollAndLazy: return .purple
    case .listAndForm: return .orange
    case .adaptiveAndGeometry: return .cyan
    case .navigationAndTabs: return .blue
    case .presentation: return .pink
    case .shapesAndCanvas: return .orange
    case .gradientsAndMaterials: return .indigo
    case .gesturesAndAnimation: return .purple
    case .customLayout: return .teal
    case .toolbarAndSearch: return .blue
    case .keyboardAndFocus: return .orange
    case .stateAndStorage: return .indigo
    case .lifecycleAndTask: return .green
    case .richTextAndLinks: return .cyan
    }
  }
}

struct GalleryRootView: View {
  @State private var selection: GalleryItem? = .buttons
  @State private var darkMode = false

  var body: some View {
    NavigationSplitView {
      List(selection: $selection) {
        Section("Controls") {
          sidebarRow(.buttons)
          sidebarRow(.toggles)
          sidebarRow(.pickers)
          sidebarRow(.slidersAndSteppers)
          sidebarRow(.textInput)
          sidebarRow(.menusAndLinks)
        }

        Section("Content & Media") {
          sidebarRow(.textAndLabels)
          sidebarRow(.imagesAndSymbols)
          sidebarRow(.progressAndStatus)
        }

        Section("Layout & Containers") {
          sidebarRow(.stacksAndDivider)
          sidebarRow(.grids)
          sidebarRow(.scrollAndLazy)
          sidebarRow(.listAndForm)
          sidebarRow(.adaptiveAndGeometry)
        }

        Section("Navigation & Overlays") {
          sidebarRow(.navigationAndTabs)
          sidebarRow(.presentation)
        }

        Section("Graphics & Interaction") {
          sidebarRow(.shapesAndCanvas)
          sidebarRow(.gradientsAndMaterials)
          sidebarRow(.gesturesAndAnimation)
        }

        Section("Advanced & System") {
          sidebarRow(.customLayout)
          sidebarRow(.toolbarAndSearch)
          sidebarRow(.keyboardAndFocus)
          sidebarRow(.stateAndStorage)
          sidebarRow(.lifecycleAndTask)
          sidebarRow(.richTextAndLinks)
        }
      }
      .listStyle(.sidebar)
    } detail: {
      let current = selection ?? .buttons
      VStack(alignment: .leading, spacing: 0) {
        detailHeader(for: current)
        Divider()
        ScrollView(.vertical) {
          detailContent(for: current)
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .preferredColorScheme(darkMode ? .dark : .light)
  }

  private func sidebarRow(_ item: GalleryItem) -> some View {
    HStack(spacing: 10) {
      ZStack {
        RoundedRectangle(cornerRadius: 6)
          .fill(item.accent.opacity(0.16))
          .frame(width: 24, height: 24)
        Image(systemName: item.icon)
          .foregroundStyle(item.accent)
          .frame(width: 14, height: 14)
      }
      Text(item.sidebarTitle)
        .font(.system(size: 13, weight: .medium))
    }
    .tag(item)
  }

  private func detailHeader(for item: GalleryItem) -> some View {
    HStack(spacing: 14) {
      ZStack {
        RoundedRectangle(cornerRadius: 10)
          .fill(item.accent.opacity(0.15))
          .frame(width: 40, height: 40)
        Image(systemName: item.icon)
          .foregroundStyle(item.accent)
          .frame(width: 20, height: 20)
      }
      VStack(alignment: .leading, spacing: 2) {
        Text(item.title)
          .font(.system(size: 20, weight: .bold))
        Text(item.subtitle)
          .font(.system(size: 13))
          .foregroundStyle(.secondary)
      }
      Spacer()
      Toggle("Dark", isOn: $darkMode)
        .toggleStyle(.switch)
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 16)
  }

  @ViewBuilder
  private func detailContent(for item: GalleryItem) -> some View {
    switch item {
    case .buttons: ButtonsGalleryView()
    case .toggles: TogglesGalleryView()
    case .pickers: PickersGalleryView()
    case .slidersAndSteppers: SlidersAndSteppersGalleryView()
    case .textInput: TextInputGalleryView()
    case .menusAndLinks: MenusAndLinksGalleryView()
    case .textAndLabels: TextAndLabelsGalleryView()
    case .imagesAndSymbols: ImagesAndSymbolsGalleryView()
    case .progressAndStatus: ProgressAndStatusGalleryView()
    case .stacksAndDivider: StacksAndDividerGalleryView()
    case .grids: GridsGalleryView()
    case .scrollAndLazy: ScrollAndLazyGalleryView()
    case .listAndForm: ListAndFormGalleryView()
    case .adaptiveAndGeometry: AdaptiveAndGeometryGalleryView()
    case .navigationAndTabs: NavigationAndTabsGalleryView()
    case .presentation: PresentationGalleryView()
    case .shapesAndCanvas: ShapesAndCanvasGalleryView()
    case .gradientsAndMaterials: GradientsAndMaterialsGalleryView()
    case .gesturesAndAnimation: GesturesAndAnimationGalleryView()
    case .customLayout: CustomLayoutGalleryView()
    case .toolbarAndSearch: ToolbarAndSearchGalleryView()
    case .keyboardAndFocus: KeyboardAndFocusGalleryView()
    case .stateAndStorage: StateAndStorageGalleryView()
    case .lifecycleAndTask: LifecycleAndTaskGalleryView()
    case .richTextAndLinks: RichTextAndLinksGalleryView()
    }
  }
}

struct GallerySection<Content: View>: View {
  let title: String
  let subtitle: String?
  let contentPadding: CGFloat
  let content: Content

  init(
    _ title: String,
    subtitle: String? = nil,
    contentPadding: CGFloat = 16,
    @ViewBuilder content: () -> Content
  ) {
    self.title = title
    self.subtitle = subtitle
    self.contentPadding = contentPadding
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.system(size: 15, weight: .semibold))
        if let subtitle {
          Text(subtitle)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
      }
      VStack(alignment: .leading, spacing: contentPadding > 0 ? 12 : 0) {
        content
      }
      .padding(contentPadding)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .overlay {
        RoundedRectangle(cornerRadius: 12)
          .strokeBorder(Color.gray.opacity(0.22), lineWidth: 1)
      }
    }
  }
}
