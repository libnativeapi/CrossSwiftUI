import SwiftUI

// MARK: - 1. Buttons & ControlGroup

private struct PillAccentButtonStyle: ButtonStyle {
  let color: Color

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 13, weight: .semibold))
      .foregroundStyle(Color.white)
      .padding(.horizontal, 16)
      .padding(.vertical, 8)
      .background(
        color.opacity(configuration.isPressed ? 0.72 : 1.0),
        in: Capsule()
      )
      .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
  }
}

struct ButtonsGalleryView: View {
  @State private var tapCount = 0
  @State private var lastAction = "Click any button to trigger an action."

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      GallerySection("Standard Button Styles", subtitle: "Built-in desktop button styles with live state feedback.") {
        HStack(spacing: 12) {
          Button("Automatic") {
            tapCount += 1
            lastAction = "Automatic tapped (\(tapCount))"
          }
          .buttonStyle(.automatic)

          Button("Bordered") {
            tapCount += 1
            lastAction = "Bordered tapped (\(tapCount))"
          }
          .buttonStyle(.bordered)

          Button("Prominent") {
            tapCount += 1
            lastAction = "BorderedProminent tapped (\(tapCount))"
          }
          .buttonStyle(.borderedProminent)

          Button("Borderless") {
            tapCount += 1
            lastAction = "Borderless tapped (\(tapCount))"
          }
          .buttonStyle(.borderless)

          Button("Link Style") {
            tapCount += 1
            lastAction = "Link tapped (\(tapCount))"
          }
          .buttonStyle(.link)
        }

        Text(lastAction)
          .font(.system(size: 12))
          .foregroundStyle(.secondary)
      }

      GallerySection("Roles, Sizes & States", subtitle: "ButtonRole, ControlSize, keyboard shortcuts, tooltips (.help), and disabled state.") {
        HStack(spacing: 12) {
          Button("Cancel", role: .cancel) {
            lastAction = "Cancel role triggered"
          }
          .buttonStyle(.bordered)

          Button("Delete Item", role: .destructive) {
            lastAction = "Destructive role triggered"
          }
          .buttonStyle(.bordered)

          Button("Save (⌘S)") {
            lastAction = "Save triggered (⌘S / Ctrl+S)"
          }
          .buttonStyle(.borderedProminent)
          .keyboardShortcut("s", modifiers: .command)
          .help("Save the current document")

          Button("Disabled") {}
            .buttonStyle(.bordered)
            .disabled(true)
        }

        HStack(spacing: 12) {
          Button("Mini") { lastAction = "Mini button" }
            .buttonStyle(.bordered)
            .controlSize(.mini)

          Button("Small") { lastAction = "Small button" }
            .buttonStyle(.bordered)
            .controlSize(.small)

          Button("Regular") { lastAction = "Regular button" }
            .buttonStyle(.bordered)
            .controlSize(.regular)

          Button("Large") { lastAction = "Large button" }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
      }

      GallerySection("Custom ButtonStyle & ControlGroup", subtitle: "Custom pressed-state rendering and grouped toolbar-like controls.") {
        HStack(spacing: 16) {
          Button {
            tapCount += 1
            lastAction = "Custom Pill tapped (\(tapCount))"
          } label: {
            HStack(spacing: 6) {
              Image(systemName: "sparkles")
                .frame(width: 14, height: 14)
              Text("Custom Style")
            }
          }
          .buttonStyle(PillAccentButtonStyle(color: .indigo))

          ControlGroup {
            Button("Bold") { lastAction = "ControlGroup: Bold" }
            Button("Italic") { lastAction = "ControlGroup: Italic" }
            Button("Underline") { lastAction = "ControlGroup: Underline" }
          }
        }
      }
    }
  }
}

// MARK: - 2. Toggle

struct TogglesGalleryView: View {
  @State private var switchOff = false
  @State private var switchOn = true
  @State private var tintedSwitch = true
  @State private var checkAutoSave = true
  @State private var checkLineNumbers = false
  @State private var checkWordWrap = true
  @State private var buttonPin = true
  @State private var buttonMute = false
  @State private var disabledOff = false
  @State private var disabledOn = true

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      GallerySection("Checkbox Style (Desktop)", subtitle: "Classic macOS / Windows / Linux checkbox toggles.") {
        VStack(alignment: .leading, spacing: 10) {
          Toggle("Auto-save documents", isOn: $checkAutoSave)
            .toggleStyle(.checkbox)
          Toggle("Show line numbers", isOn: $checkLineNumbers)
            .toggleStyle(.checkbox)
          Toggle("Wrap long lines", isOn: $checkWordWrap)
            .toggleStyle(.checkbox)
        }
      }

      GallerySection("Switch Style", subtitle: "Standard switches and custom tint colors.") {
        VStack(alignment: .leading, spacing: 10) {
          Toggle("Dark Sidebar", isOn: $switchOff)
            .toggleStyle(.switch)
          Toggle("Hardware Acceleration", isOn: $switchOn)
            .toggleStyle(.switch)
          Toggle("Custom Orange Tint", isOn: $tintedSwitch)
            .toggleStyle(SwitchToggleStyle(tint: .orange))
        }
      }

      GallerySection("Button Style & Disabled", subtitle: "Toggle buttons with SF Symbols and non-interactive states.") {
        HStack(spacing: 12) {
          Toggle("Pin Window", systemImage: "pin.fill", isOn: $buttonPin)
            .toggleStyle(.button)
          Toggle("Mute Audio", systemImage: "speaker.slash", isOn: $buttonMute)
            .toggleStyle(.button)
        }

        Divider()

        HStack(spacing: 24) {
          Toggle("Disabled Off", isOn: $disabledOff)
            .toggleStyle(.checkbox)
            .disabled(true)
          Toggle("Disabled On", isOn: $disabledOn)
            .toggleStyle(.checkbox)
            .disabled(true)
        }
      }
    }
  }
}

// MARK: - 3. Picker

struct PickersGalleryView: View {
  @State private var viewMode = 0
  @State private var themeChoice = "System"
  @State private var radioChoice = "Balanced"
  @State private var inlineChoice = "Medium"

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      GallerySection("Segmented Picker", subtitle: "Horizontal segmented control for switching modes.") {
        VStack(alignment: .leading, spacing: 8) {
          Picker("View Mode", selection: $viewMode) {
            Text("Icons").tag(0)
            Text("List").tag(1)
            Text("Columns").tag(2)
            Text("Gallery").tag(3)
          }
          .pickerStyle(.segmented)
          .frame(maxWidth: 420)

          Text("Selected index: \(viewMode)")
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
      }

      GallerySection("Menu Picker", subtitle: "Pop-up menu picker for selecting from a list of options.") {
        HStack(spacing: 16) {
          Picker("Appearance", selection: $themeChoice) {
            Text("System").tag("System")
            Text("Light").tag("Light")
            Text("Dark").tag("Dark")
            Text("High Contrast").tag("High Contrast")
          }
          .pickerStyle(.menu)
          .frame(maxWidth: 260)

          Text("Active: \(themeChoice)")
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
      }

      GallerySection("Radio Group & Inline", subtitle: "Desktop radio buttons and inline option lists.") {
        HStack(alignment: .top, spacing: 40) {
          VStack(alignment: .leading, spacing: 8) {
            Text("Performance Profile (.radioGroup)")
              .font(.system(size: 13, weight: .medium))
            Picker("Profile", selection: $radioChoice) {
              Text("Efficiency").tag("Efficiency")
              Text("Balanced").tag("Balanced")
              Text("High Performance").tag("High Performance")
            }
            .pickerStyle(.radioGroup)
            Text("Profile: \(radioChoice)")
              .font(.system(size: 12))
              .foregroundStyle(.secondary)
          }

          VStack(alignment: .leading, spacing: 8) {
            Text("Font Density (.inline)")
              .font(.system(size: 13, weight: .medium))
            Picker("Density", selection: $inlineChoice) {
              Text("Compact").tag("Compact")
              Text("Medium").tag("Medium")
              Text("Comfortable").tag("Comfortable")
            }
            .pickerStyle(.inline)
            Text("Density: \(inlineChoice)")
              .font(.system(size: 12))
              .foregroundStyle(.secondary)
          }
        }
      }
    }
  }
}

// MARK: - 4. Slider & Stepper

struct SlidersAndSteppersGalleryView: View {
  @State private var continuousValue: Double = 0.62
  @State private var steppedDraft: Double = 40
  @State private var committedStep: Double = 40
  @State private var volume: Double = 0.75
  @State private var disabledSlider: Double = 0.35
  @State private var copies: Int = 2
  @State private var customZoom: Int = 100

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      GallerySection("Continuous & Stepped Sliders", subtitle: "Live value bindings, step increments, and release callbacks.") {
        VStack(alignment: .leading, spacing: 14) {
          VStack(alignment: .leading, spacing: 6) {
            HStack {
              Text("Opacity")
                .font(.system(size: 13, weight: .medium))
              Spacer()
              Text("\(Int((continuousValue * 100).rounded()))%")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            }
            Slider(value: $continuousValue, in: 0...1)
          }

          VStack(alignment: .leading, spacing: 6) {
            HStack {
              Text("Stepped (0–100, step 10)")
                .font(.system(size: 13, weight: .medium))
              Spacer()
              Text("Live: \(Int(steppedDraft)) · Committed: \(Int(committedStep))")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }
            Slider(value: $steppedDraft, in: 0...100, step: 10) { editing in
              if !editing { committedStep = steppedDraft }
            }
          }

          HStack(spacing: 10) {
            Image(systemName: "speaker.fill")
              .foregroundStyle(Color.orange)
              .frame(width: 16, height: 16)
            Slider(value: $volume, in: 0...1)
              .tint(.orange)
            Image(systemName: "speaker.wave.3.fill")
              .foregroundStyle(Color.orange)
              .frame(width: 18, height: 18)
          }

          Slider(value: $disabledSlider, in: 0...1)
            .disabled(true)
        }
      }

      GallerySection("Stepper", subtitle: "Range-clamped numeric stepper and custom increment/decrement handlers.") {
        VStack(alignment: .leading, spacing: 12) {
          Stepper("Copies: \(copies)", value: $copies, in: 1...20)
            .frame(maxWidth: 280)

          Stepper {
            Text("Canvas Zoom: \(customZoom)%")
          } onIncrement: {
            customZoom = min(200, customZoom + 25)
          } onDecrement: {
            customZoom = max(50, customZoom - 25)
          }
          .frame(maxWidth: 280)
        }
      }
    }
  }
}

// MARK: - 5. TextField, SecureField & TextEditor

struct TextInputGalleryView: View {
  enum Field: Hashable {
    case username
    case email
  }

  @State private var username = "Ada Lovelace"
  @State private var email = ""
  @State private var plainQuery = ""
  @State private var password = "secret-passphrase"
  @State private var revealPassword = false
  @State private var notes = "Multiline TextEditor supports native editing, selection, and scrolling across macOS, Windows, and Linux."
  @State private var submitStatus = "Press Return in Username to trigger onSubmit."
  @FocusState private var focusedField: Field?

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      GallerySection("TextField & @FocusState", subtitle: "Rounded border and plain styles with focus management and submit handling.") {
        VStack(alignment: .leading, spacing: 12) {
          HStack(spacing: 12) {
            Text("Username")
              .frame(width: 84, alignment: .trailing)
            TextField("Enter username", text: $username)
              .textFieldStyle(.roundedBorder)
              .focused($focusedField, equals: .username)
              .onSubmit {
                submitStatus = "Submitted username: \(username)"
              }
              .frame(maxWidth: 320)
          }

          HStack(spacing: 12) {
            Text("Email")
              .frame(width: 84, alignment: .trailing)
            TextField("name@example.com", text: $email)
              .textFieldStyle(.roundedBorder)
              .focused($focusedField, equals: .email)
              .frame(maxWidth: 320)
          }

          HStack(spacing: 12) {
            Text("Plain Style")
              .frame(width: 84, alignment: .trailing)
            TextField("Search filter…", text: $plainQuery)
              .textFieldStyle(.plain)
              .padding(.horizontal, 10)
              .padding(.vertical, 6)
              .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
              .frame(maxWidth: 320)
          }

          HStack(spacing: 10) {
            Button("Focus Username") { focusedField = .username }
              .buttonStyle(.bordered)
            Button("Focus Email") { focusedField = .email }
              .buttonStyle(.bordered)
            Button("Clear Focus") { focusedField = nil }
              .buttonStyle(.bordered)
          }

          Text(submitStatus)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
      }

      GallerySection("SecureField", subtitle: "Masked password input with optional visibility toggle.") {
        HStack(spacing: 12) {
          if revealPassword {
            TextField("Password", text: $password)
              .textFieldStyle(.roundedBorder)
              .frame(maxWidth: 280)
          } else {
            SecureField("Password", text: $password)
              .textFieldStyle(.roundedBorder)
              .frame(maxWidth: 280)
          }
          Toggle("Reveal", isOn: $revealPassword)
            .toggleStyle(.checkbox)
          Text("\(password.count) chars")
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
      }

      GallerySection("TextEditor", subtitle: "Multiline editable text area.") {
        VStack(alignment: .leading, spacing: 8) {
          TextEditor(text: $notes)
            .font(.system(size: 13))
            .frame(height: 110)
            .overlay {
              RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.gray.opacity(0.35), lineWidth: 1)
            }
          Text("Characters: \(notes.count)")
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
      }
    }
  }
}

// MARK: - 6. Menu & Link

struct MenusAndLinksGalleryView: View {
  @State private var lastMenuAction = "Choose an action from any menu."

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      GallerySection("Menu", subtitle: "Pull-down menus with text titles, SF Symbols, dividers, and destructive actions.") {
        VStack(alignment: .leading, spacing: 12) {
          HStack(spacing: 16) {
            Menu("Actions") {
              Button("New File") { lastMenuAction = "Selected: New File" }
              Button("Duplicate") { lastMenuAction = "Selected: Duplicate" }
              Button("Rename…") { lastMenuAction = "Selected: Rename…" }
              Divider()
              Button("Move to Trash", role: .destructive) {
                lastMenuAction = "Selected: Move to Trash"
              }
            }

            Menu("Export", systemImage: "square.and.arrow.up") {
              Button("Export as PDF") { lastMenuAction = "Exported as PDF" }
              Button("Export as PNG") { lastMenuAction = "Exported as PNG" }
              Button("Export as SVG") { lastMenuAction = "Exported as SVG" }
            }
          }

          Text(lastMenuAction)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
      }

      GallerySection("Link", subtitle: "Clickable hyperlinks using URL destinations.") {
        HStack(spacing: 20) {
          Link("CrossSwiftUI Repository", destination: URL(string: "https://github.com/libnativeapi/crossswift")!)
          Link(destination: URL(string: "https://www.swift.org")!) {
            Label("Swift.org", systemImage: "globe")
          }
        }
      }
    }
  }
}
