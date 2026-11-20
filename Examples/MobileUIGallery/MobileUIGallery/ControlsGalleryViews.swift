import SwiftUI

// MARK: - 1. Slider

struct SliderGalleryView: View {
  @State private var brightness: Double = 0.72
  @State private var continuousValue: Double = 0.50
  @State private var committedDraft: Double = 50
  @State private var committedValue: Double = 50
  @State private var volumeValue: Double = 0.65
  @State private var disabledValue: Double = 0.40

  var body: some View {
    List {
      Section("Control Center Platter") {
        VStack(alignment: .leading, spacing: 12) {
          HStack {
            Text("DISPLAY BRIGHTNESS")
              .font(.system(size: 11, weight: .semibold))
              .foregroundStyle(Color.white.opacity(0.8))
            Spacer()
            Text("\(Int((brightness * 100).rounded()))%")
              .font(.system(size: 13, weight: .semibold))
              .foregroundStyle(Color.white)
          }
          HStack(spacing: 10) {
            Image(systemName: "sun.min")
              .foregroundStyle(Color.white.opacity(0.85))
              .frame(width: 18, height: 18)
            Slider(value: $brightness, in: 0...1)
              .tint(Color.white)
            Image(systemName: "sun.max")
              .foregroundStyle(Color.white)
              .frame(width: 20, height: 20)
          }
        }
        .padding(14)
        .background(
          LinearGradient(
            colors: [Color(red: 0.14, green: 0.34, blue: 0.78), Color(red: 0.36, green: 0.56, blue: 0.94)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          in: RoundedRectangle(cornerRadius: 18)
        )
      }

      Section("Continuous") {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("Current Value")
              .font(.system(size: 15))
            Spacer()
            Text(String(format: "%.2f", continuousValue))
              .font(.system(size: 15, weight: .medium))
              .foregroundStyle(.secondary)
          }
          Slider(value: $continuousValue, in: 0...1)
        }
      }

      Section {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("Committed Value")
              .font(.system(size: 15))
            Spacer()
            Text("\(Int(committedValue.rounded()))")
              .font(.system(size: 15, weight: .medium))
              .foregroundStyle(.secondary)
          }
          Slider(value: $committedDraft, in: 0...100, step: 1) { editing in
            if !editing {
              committedValue = committedDraft
            }
          }
        }
      } header: {
        Text("Updates on Release")
      } footer: {
        Text("Commits value when dragging finishes.")
      }

      Section("Custom Tint & Value Images") {
        HStack(spacing: 10) {
          Image(systemName: "speaker.fill")
            .foregroundStyle(Color.orange)
            .frame(width: 18, height: 18)
          Slider(value: $volumeValue, in: 0...1)
            .tint(Color.orange)
          Image(systemName: "speaker.wave.3.fill")
            .foregroundStyle(Color.orange)
            .frame(width: 20, height: 20)
        }
      }

      Section("Disabled") {
        Slider(value: $disabledValue, in: 0...1)
          .disabled(true)
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Slider")
  }
}

// MARK: - 2. Switch

struct SwitchGalleryView: View {
  @State private var switchOff = false
  @State private var switchOn = true
  @State private var tintedOn = true
  @State private var toggleButtonA = true
  @State private var toggleButtonB = false
  @State private var disabledOff = false
  @State private var disabledOn = true

  var body: some View {
    List {
      Section("Enabled") {
        Toggle("Off", isOn: $switchOff)
        Toggle("On", isOn: $switchOn)
        Toggle("Custom Tint (Orange)", isOn: $tintedOn)
          .toggleStyle(SwitchToggleStyle(tint: .orange))
      }

      Section("Button Style") {
        HStack(spacing: 12) {
          Toggle("Notifications", isOn: $toggleButtonA)
            .toggleStyle(.button)
          Toggle("Auto-Download", isOn: $toggleButtonB)
            .toggleStyle(.button)
        }
      }

      Section("Disabled") {
        Toggle("Off", isOn: $disabledOff)
          .disabled(true)
        Toggle("On", isOn: $disabledOn)
          .disabled(true)
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Switch")
  }
}

// MARK: - 3. Segmented Control

struct SegmentedControlGalleryView: View {
  @State private var basicSelection = 0
  @State private var calendarSelection = 1
  @State private var menuChoice = "Standard"
  @State private var lastMomentary = "Tap an action below"

  var body: some View {
    List {
      Section("Titles") {
        VStack(alignment: .leading, spacing: 10) {
          Picker("Titles", selection: $basicSelection) {
            Text("First").tag(0)
            Text("Second").tag(1)
            Text("Third").tag(2)
          }
          .pickerStyle(.segmented)
          .labelsHidden()
          Text("Selected: \(["First", "Second", "Third"][basicSelection])")
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
        }
      }

      Section("Sized by Content") {
        VStack(alignment: .leading, spacing: 10) {
          Picker("Range", selection: $calendarSelection) {
            Text("Day").tag(0)
            Text("Work Week").tag(1)
            Text("Month").tag(2)
          }
          .pickerStyle(.segmented)
          .labelsHidden()
          Text("Schedule: \(["Day", "Work Week", "Month"][calendarSelection])")
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
        }
      }

      Section("Menu Picker") {
        Picker("Quality", selection: $menuChoice) {
          Text("Compact").tag("Compact")
          Text("Standard").tag("Standard")
          Text("High Resolution").tag("High Resolution")
        }
        .pickerStyle(.menu)
      }

      Section {
        HStack(spacing: 8) {
          Button("Undo") { lastMomentary = "Triggered: Undo" }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
          Button("Redo") { lastMomentary = "Triggered: Redo" }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
          Button("Clear", role: .destructive) { lastMomentary = "Triggered: Clear" }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
        }
      } header: {
        Text("Momentary")
      } footer: {
        Text(lastMomentary)
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Segmented Control")
  }
}

// MARK: - 4. Button

struct ButtonGalleryView: View {
  @State private var tapCount = 0
  @State private var isSelected = false
  @State private var lastButton = "Tap any button to test"

  var body: some View {
    List {
      Section {
        HStack {
          Button("System Action") {
            tapCount += 1
            lastButton = "System Action tapped (\(tapCount))"
          }
          .buttonStyle(.borderless)
          Spacer()
          Text("\(tapCount)")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.secondary)
        }
      } header: {
        Text("System")
      } footer: {
        Text(lastButton)
      }

      Section("Configurations") {
        VStack(spacing: 12) {
          Button("Plain Configuration") {
            lastButton = "Plain Configuration tapped"
          }
          .buttonStyle(.borderless)
          .frame(maxWidth: .infinity, minHeight: 38)

          Button("Gray Configuration") {
            lastButton = "Gray Configuration tapped"
          }
          .buttonStyle(.bordered)
          .frame(maxWidth: .infinity, minHeight: 40)

          Button("Tinted Configuration") {
            lastButton = "Tinted Configuration tapped"
          }
          .buttonStyle(.bordered)
          .tint(Color.indigo)
          .frame(maxWidth: .infinity, minHeight: 40)

          Button("Filled Configuration") {
            lastButton = "Filled Configuration tapped"
          }
          .buttonStyle(.borderedProminent)
          .frame(maxWidth: .infinity, minHeight: 42)
        }
      }

      Section("Selection & Roles") {
        VStack(spacing: 12) {
          Button(isSelected ? "Selected ✓" : "Select") {
            isSelected.toggle()
            lastButton = isSelected ? "Selection enabled" : "Selection cleared"
          }
          .buttonStyle(.borderedProminent)
          .tint(isSelected ? Color.green : Color(red: 0, green: 0.478, blue: 1))
          .frame(maxWidth: .infinity, minHeight: 40)

          Button("Destructive Action", role: .destructive) {
            lastButton = "Destructive Action tapped"
          }
          .buttonStyle(.borderedProminent)
          .frame(maxWidth: .infinity, minHeight: 40)

          Button("Disabled") {}
            .buttonStyle(.borderedProminent)
            .disabled(true)
            .frame(maxWidth: .infinity, minHeight: 40)
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Button")
  }
}

// MARK: - 5. Stepper

struct StepperGalleryView: View {
  @State private var quantity = 3
  @State private var cycle = 5
  @State private var accelerated = 100
  @State private var unavailable = 1

  var body: some View {
    List {
      Section("Standard (0 to 10)") {
        Stepper("Quantity: \(quantity)", value: $quantity, in: 0...10)
      }

      Section("Wrapping (1–5)") {
        Stepper {
          Text("Cycle (1–5): \(cycle)")
        } onIncrement: {
          cycle = cycle >= 5 ? 1 : cycle + 1
        } onDecrement: {
          cycle = cycle <= 1 ? 5 : cycle - 1
        }
      }

      Section("Step ×5") {
        Stepper("Step ×5: \(accelerated)", value: $accelerated, in: 0...200, step: 5)
      }

      Section("Disabled") {
        Stepper("Unavailable: \(unavailable)", value: $unavailable, in: 0...10)
          .disabled(true)
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Stepper")
  }
}

// MARK: - 6. Page Control

struct PageControlGalleryView: View {
  @State private var currentPage = 0
  @State private var minimalPage = 2
  @State private var windowedPage = 4

  private let wallpapers: [(String, Color, Color)] = [
    ("iOS Waves", Color(red: 0.10, green: 0.42, blue: 0.96), Color(red: 0.38, green: 0.78, blue: 0.98)),
    ("Sunset Glow", Color(red: 0.95, green: 0.36, blue: 0.28), Color(red: 0.99, green: 0.70, blue: 0.25)),
    ("Emerald Mist", Color(red: 0.08, green: 0.64, blue: 0.48), Color(red: 0.32, green: 0.85, blue: 0.68)),
    ("Twilight Plum", Color(red: 0.45, green: 0.22, blue: 0.86), Color(red: 0.86, green: 0.34, blue: 0.72)),
    ("Midnight", Color(red: 0.12, green: 0.14, blue: 0.26), Color(red: 0.28, green: 0.34, blue: 0.56)),
  ]

  var body: some View {
    List {
      Section("Wallpaper Pager") {
        let wp = wallpapers[currentPage]
        VStack(spacing: 14) {
          ZStack {
            RoundedRectangle(cornerRadius: 16)
              .fill(LinearGradient(colors: [wp.1, wp.2], startPoint: .topLeading, endPoint: .bottomTrailing))
              .frame(height: 150)
            VStack(spacing: 6) {
              Text(wp.0)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.white)
              Text("Page \(currentPage + 1) of \(wallpapers.count)")
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.85))
            }
          }

          HStack(spacing: 12) {
            Button("Previous") {
              currentPage = (currentPage - 1 + wallpapers.count) % wallpapers.count
            }
            .buttonStyle(.bordered)
            Spacer()
            HStack(spacing: 7) {
              ForEach(0..<wallpapers.count, id: \.self) { idx in
                Button {
                  currentPage = idx
                } label: {
                  Circle()
                    .fill(idx == currentPage ? Color(red: 0, green: 0.478, blue: 1) : Color.gray.opacity(0.35))
                    .frame(width: idx == currentPage ? 9 : 7, height: idx == currentPage ? 9 : 7)
                }
                .buttonStyle(.plain)
              }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.gray.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))
            Spacer()
            Button("Next") {
              currentPage = (currentPage + 1) % wallpapers.count
            }
            .buttonStyle(.bordered)
          }
        }
      }

      Section("Minimal & Custom Tint") {
        HStack(spacing: 10) {
          Spacer()
          ForEach(0..<5, id: \.self) { idx in
            Button {
              minimalPage = idx
            } label: {
              Circle()
                .fill(idx == minimalPage ? Color.blue : Color.blue.opacity(0.25))
                .frame(width: 9, height: 9)
            }
            .buttonStyle(.plain)
          }
          Spacer()
        }
      }

      Section("Windowed Dots (12 Pages)") {
        VStack(spacing: 10) {
          HStack(spacing: 6) {
            ForEach(0..<12, id: \.self) { idx in
              let dist = abs(idx - windowedPage)
              let sz: CGFloat = dist == 0 ? 9 : (dist <= 2 ? 7 : 5)
              Button {
                windowedPage = idx
              } label: {
                Circle()
                  .fill(idx == windowedPage ? Color(red: 0, green: 0.478, blue: 1) : Color.gray.opacity(dist <= 2 ? 0.45 : 0.25))
                  .frame(width: sz, height: sz)
              }
              .buttonStyle(.plain)
            }
          }
          Text("Page \(windowedPage + 1) of 12")
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Page Control")
  }
}

// MARK: - 7. Text Field

struct TextFieldGalleryView: View {
  @State private var name = "Taylor Swift"
  @State private var email = ""
  @State private var password = "••••••••"

  var body: some View {
    List {
      Section("Input Fields") {
        TextField("Full Name", text: $name)
          .frame(height: 44)
        TextField("Email Address", text: $email)
          .frame(height: 44)
        SecureField("Password", text: $password)
          .frame(height: 44)
      }

      Section("Live State") {
        Text("Name: \(name.isEmpty ? "(empty)" : name)")
          .font(.system(size: 14))
        Text("Email: \(email.isEmpty ? "(empty)" : email)")
          .font(.system(size: 14))
          .foregroundStyle(.secondary)
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Text Field")
  }
}

// MARK: - 8. Control & Flex

struct ControlFlexGalleryView: View {
  @State private var activeCard = 0
  @State private var flexScale: Double = 1.0

  var body: some View {
    List {
      Section {
        VStack(spacing: 14) {
          HStack(spacing: 12) {
            Button {
              activeCard = 0
            } label: {
              VStack(spacing: 6) {
                Image(systemName: "hand.tap")
                  .foregroundStyle(Color.white)
                  .frame(width: 22, height: 22)
                Text("Small")
                  .font(.system(size: 13, weight: .semibold))
                  .foregroundStyle(Color.white)
              }
              .frame(maxWidth: .infinity, minHeight: 72)
              .background(Color.blue.opacity(activeCard == 0 ? 1.0 : 0.72), in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            Button {
              activeCard = 1
            } label: {
              VStack(spacing: 6) {
                Image(systemName: "sparkles")
                  .foregroundStyle(Color.white)
                  .frame(width: 22, height: 22)
                Text("Wide Teal")
                  .font(.system(size: 13, weight: .semibold))
                  .foregroundStyle(Color.white)
              }
              .frame(maxWidth: .infinity, minHeight: 72)
              .background(Color.teal.opacity(activeCard == 1 ? 1.0 : 0.72), in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
          }

          Button {
            activeCard = 2
          } label: {
            HStack {
              VStack(alignment: .leading, spacing: 4) {
                Text("Large Purple Platter")
                  .font(.system(size: 16, weight: .semibold))
                  .foregroundStyle(Color.white)
                Text("Active selection: #\(activeCard + 1) · Flex \(Int(flexScale * 100))%")
                  .font(.system(size: 13))
                  .foregroundStyle(Color.white.opacity(0.85))
              }
              Spacer()
              Image(systemName: "star.fill")
                .foregroundStyle(Color.white)
                .frame(width: 22, height: 22)
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 84)
            .background(Color.purple.opacity(activeCard == 2 ? 1.0 : 0.78), in: RoundedRectangle(cornerRadius: 20))
          }
          .buttonStyle(.plain)

          Slider(value: $flexScale, in: 0.5...1.5)
            .tint(Color.purple)
        }
      } header: {
        Text("Interactive Platters")
      } footer: {
        Text("Tap a platter or adjust flex intensity.")
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Control & Flex")
  }
}
