import SwiftUI

// MARK: - 10. Stacks & Divider

struct StacksAndDividerGalleryView: View {
  @State private var swapZOrder = false

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      GallerySection("VStack & HStack with Spacer", subtitle: "Directional stacks, alignment, spacing, and flexible Spacer distribution.") {
        HStack(spacing: 12) {
          stackChip("Leading", color: .blue)
          Spacer()
          stackChip("Center", color: .indigo)
          Spacer()
          stackChip("Trailing", color: .purple)
        }
        .padding(12)
        .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))

        Divider()

        HStack(alignment: .top, spacing: 24) {
          VStack(alignment: .leading, spacing: 6) {
            Text("VStack (.leading)").font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
            stackChip("Short", color: .teal)
            stackChip("Medium Label", color: .teal)
            stackChip("Longer Row Item", color: .teal)
          }

          VStack(alignment: .center, spacing: 6) {
            Text("VStack (.center)").font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
            stackChip("Short", color: .orange)
            stackChip("Medium Label", color: .orange)
            stackChip("Longer Row Item", color: .orange)
          }

          VStack(alignment: .trailing, spacing: 6) {
            Text("VStack (.trailing)").font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
            stackChip("Short", color: .pink)
            stackChip("Medium Label", color: .pink)
            stackChip("Longer Row Item", color: .pink)
          }
        }
      }

      GallerySection("ZStack & zIndex", subtitle: "Overlapping layers with alignment and dynamic z-ordering.") {
        HStack(spacing: 24) {
          ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 14)
              .fill(Color.blue.opacity(0.85))
              .frame(width: 110, height: 76)
              .offset(x: -18, y: -12)
              .zIndex(swapZOrder ? 2 : 0)

            RoundedRectangle(cornerRadius: 14)
              .fill(Color.orange.opacity(0.90))
              .frame(width: 110, height: 76)
              .offset(x: 18, y: 12)
              .zIndex(swapZOrder ? 0 : 2)
          }
          .frame(width: 180, height: 120)

          VStack(alignment: .leading, spacing: 8) {
            Text("Front layer: \(swapZOrder ? "Blue" : "Orange")")
              .font(.system(size: 13, weight: .semibold))
            Button("Swap Z-Order") {
              swapZOrder.toggle()
            }
            .buttonStyle(.borderedProminent)
          }
        }
      }
    }
  }

  private func stackChip(_ text: String, color: Color) -> some View {
    Text(text)
      .font(.system(size: 12, weight: .semibold))
      .foregroundStyle(Color.white)
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background(color, in: RoundedRectangle(cornerRadius: 6))
  }
}

// MARK: - 11. Grid, LazyVGrid & LazyHGrid

struct GridsGalleryView: View {
  private let palette: [(String, Color)] = [
    ("Blue", .blue), ("Indigo", .indigo), ("Purple", .purple), ("Pink", .pink),
    ("Orange", .orange), ("Yellow", .yellow), ("Green", .green), ("Teal", .teal),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      GallerySection("Grid & GridRow", subtitle: "Aligned multi-column matrix with shared column widths.") {
        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
          GridRow {
            Text("Platform").font(.system(size: 12, weight: .bold)).foregroundStyle(.secondary)
            Text("Renderer").font(.system(size: 12, weight: .bold)).foregroundStyle(.secondary)
            Text("Status").font(.system(size: 12, weight: .bold)).foregroundStyle(.secondary)
          }
          Divider()
          GridRow {
            Text("macOS")
            Text("Apple SwiftUI")
            Text("Native").foregroundStyle(Color.green)
          }
          GridRow {
            Text("Windows")
            Text("GDI+ & Win32 via nativeapi")
            Text("Native").foregroundStyle(Color.green)
          }
          GridRow {
            Text("Linux")
            Text("Cairo, Pango & GTK3")
            Text("Native").foregroundStyle(Color.green)
          }
        }
        .font(.system(size: 13))
      }

      GallerySection("LazyVGrid", subtitle: "Responsive adaptive vertical grid.") {
        LazyVGrid(
          columns: [GridItem(.adaptive(minimum: 120), spacing: 10)],
          spacing: 10
        ) {
          ForEach(0..<palette.count, id: \.self) { idx in
            let item = palette[idx]
            VStack(spacing: 4) {
              Text(item.0)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.white)
              Text("Tile \(idx + 1)")
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(item.1, in: RoundedRectangle(cornerRadius: 10))
          }
        }
      }

      GallerySection(
        "LazyHGrid",
        subtitle: "Horizontal scrolling grid with two fixed rows.",
        contentPadding: 0
      ) {
        ScrollView(.horizontal) {
          LazyHGrid(
            rows: [GridItem(.fixed(44)), GridItem(.fixed(44))],
            spacing: 10
          ) {
            ForEach(0..<12, id: \.self) { idx in
              let item = palette[idx % palette.count]
              Text("\(item.0) #\(idx + 1)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 14)
                .frame(height: 40)
                .background(item.1, in: RoundedRectangle(cornerRadius: 8))
            }
          }
          .padding(16)
        }
      }
    }
  }
}

// MARK: - 12. ScrollView, ScrollViewReader & Lazy Stacks

struct ScrollAndLazyGalleryView: View {
  @State private var lastTarget = "None"

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      GallerySection(
        "ScrollViewReader & LazyVStack",
        subtitle: "Programmatic scrollTo jumps inside a vertical ScrollView.",
        contentPadding: 0
      ) {
        ScrollViewReader { proxy in
          VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
              Button("Jump to #1") {
                proxy.scrollTo(1, anchor: .top)
                lastTarget = "Row #1"
              }
              .buttonStyle(.bordered)

              Button("Jump to #15") {
                proxy.scrollTo(15, anchor: .center)
                lastTarget = "Row #15"
              }
              .buttonStyle(.bordered)

              Button("Jump to #30") {
                proxy.scrollTo(30, anchor: .bottom)
                lastTarget = "Row #30"
              }
              .buttonStyle(.bordered)

              Spacer()
              Text("Last jump: \(lastTarget)")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            ScrollView(.vertical) {
              LazyVStack(alignment: .leading, spacing: 6) {
                ForEach(1...30, id: \.self) { row in
                  HStack {
                    Text("Lazy Row #\(row)")
                      .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Text("ID \(row)")
                      .font(.system(size: 11))
                      .foregroundStyle(.secondary)
                  }
                  .padding(.horizontal, 12)
                  .padding(.vertical, 8)
                  .background(
                    row % 5 == 0 ? Color.blue.opacity(0.14) : Color.gray.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 8)
                  )
                  .id(row)
                }
              }
              .padding(16)
            }
            .frame(height: 220)
          }
        }
      }

      GallerySection(
        "Horizontal ScrollView & LazyHStack",
        subtitle: "Horizontal card strip with LazyHStack.",
        contentPadding: 0
      ) {
        ScrollView(.horizontal) {
          LazyHStack(spacing: 12) {
            ForEach(1...10, id: \.self) { index in
              VStack(alignment: .leading, spacing: 6) {
                Text("Card \(index)")
                  .font(.system(size: 14, weight: .bold))
                  .foregroundStyle(Color.white)
                Text("Horizontal item")
                  .font(.system(size: 11))
                  .foregroundStyle(Color.white.opacity(0.85))
              }
              .padding(14)
              .frame(width: 130, alignment: .leading)
              .background(
                LinearGradient(
                  colors: [Color.blue, Color.indigo],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 10)
              )
            }
          }
          .padding(16)
        }
      }
    }
  }
}

// MARK: - 13. List & Form

struct ListAndFormGalleryView: View {
  @State private var selectedFile: String? = "README.md"
  @State private var appName = "DesktopUIGallery"
  @State private var enableTelemetry = false
  @State private var autoCheckUpdates = true
  @State private var updateChannel = "Stable"

  private let files = ["Package.swift", "README.md", "GalleryRootView.swift", "ControlsGalleryViews.swift"]

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      GallerySection("Selectable List", subtitle: "List with Section header/footer and live selection binding.") {
        VStack(alignment: .leading, spacing: 8) {
          List(selection: $selectedFile) {
            Section {
              ForEach(files, id: \.self) { file in
                HStack(spacing: 8) {
                  Image(systemName: "doc.text")
                    .foregroundStyle(Color.blue)
                    .frame(width: 14, height: 14)
                  Text(file)
                    .font(.system(size: 13))
                }
                .tag(file)
              }
            } header: {
              Text("Workspace Files")
            } footer: {
              Text("Selected: \(selectedFile ?? "None")")
            }
          }
          .listStyle(.bordered)
          .frame(height: 190)
        }
      }

      GallerySection("Desktop Form", subtitle: "Grouped settings form combining TextField, Toggle, Picker, and LabeledContent.") {
        Form {
          Section("General") {
            TextField("Application Name", text: $appName)
            Toggle("Automatically check for updates", isOn: $autoCheckUpdates)
            Toggle("Send anonymous diagnostics", isOn: $enableTelemetry)
          }

          Section("Release Channel") {
            Picker("Channel", selection: $updateChannel) {
              Text("Stable").tag("Stable")
              Text("Beta").tag("Beta")
              Text("Nightly").tag("Nightly")
            }
            LabeledContent("Active Channel", value: updateChannel)
          }
        }
        .formStyle(.grouped)
        .frame(height: 300)
      }
    }
  }
}

// MARK: - 14. GeometryReader, ViewThatFits & TimelineView

struct AdaptiveAndGeometryGalleryView: View {
  @State private var containerWidth: Double = 360
  @State private var timelinePaused = false

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      GallerySection("GeometryReader", subtitle: "Reads proposed container size dynamically and builds proportional layouts.") {
        GeometryReader { proxy in
          VStack(alignment: .leading, spacing: 10) {
            Text("Measured Size: \(Int(proxy.size.width)) × \(Int(proxy.size.height)) pt")
              .font(.system(size: 13, weight: .semibold))
            HStack(spacing: 4) {
              RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue)
                .frame(width: max(20, proxy.size.width * 0.55), height: 22)
              RoundedRectangle(cornerRadius: 6)
                .fill(Color.teal)
                .frame(width: max(20, proxy.size.width * 0.25), height: 22)
              RoundedRectangle(cornerRadius: 6)
                .fill(Color.orange)
                .frame(maxWidth: .infinity)
                .frame(height: 22)
            }
          }
        }
        .frame(height: 62)
      }

      GallerySection("ViewThatFits", subtitle: "Drag the width slider to watch ViewThatFits pick the first variant that fits.") {
        VStack(alignment: .leading, spacing: 12) {
          HStack {
            Text("Available Width: \(Int(containerWidth)) pt")
              .font(.system(size: 13, weight: .medium))
            Spacer()
            Slider(value: $containerWidth, in: 110...440, step: 10)
              .frame(width: 220)
          }

          ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
              Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.green)
                .frame(width: 16, height: 16)
              Text("Full Horizontal Banner — All checks passed")
                .font(.system(size: 13, weight: .semibold))
            }

            HStack(spacing: 6) {
              Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.blue)
                .frame(width: 16, height: 16)
              Text("Compact Status")
                .font(.system(size: 13, weight: .semibold))
            }

            Image(systemName: "checkmark.circle.fill")
              .foregroundStyle(Color.orange)
              .frame(width: 18, height: 18)
          }
          .padding(12)
          .frame(width: containerWidth, alignment: .leading)
          .background(Color.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
        }
      }

      GallerySection("TimelineView", subtitle: "Periodic date-driven updates with pause/resume control.") {
        VStack(alignment: .leading, spacing: 10) {
          TimelineView(.animation(minimumInterval: 0.25, paused: timelinePaused)) { context in
            let secs = Int(context.date.timeIntervalSince1970) % 60
            HStack(spacing: 12) {
              Circle()
                .fill(secs % 2 == 0 ? Color.green : Color.teal)
                .frame(width: 12, height: 12)
              Text("Tick second: \(secs < 10 ? "0\(secs)" : "\(secs)")s")
                .font(.system(size: 14, weight: .semibold))
              Text(timelinePaused ? "(Paused)" : "(Live)")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }
          }

          Button(timelinePaused ? "Resume Timeline" : "Pause Timeline") {
            timelinePaused.toggle()
          }
          .buttonStyle(.bordered)
        }
      }
    }
  }
}
