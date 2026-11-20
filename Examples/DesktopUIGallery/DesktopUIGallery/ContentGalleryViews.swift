import SwiftUI

// MARK: - 7. Text, Label & LabeledContent

struct TextAndLabelsGalleryView: View {
  private var richTextRun: Text {
    let part1 = Text("Concatenated ") + Text("Bold").bold()
    let part2 = Text(" + ") + Text("Italic").italic()
    let part3 = Text(" + ") + Text("Colored").foregroundColor(.blue)
    return (part1 + part2) + part3
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      GallerySection("Typography & Multilingual", subtitle: "System font sizes, weights, Unicode, and emoji rendering.") {
        VStack(alignment: .leading, spacing: 8) {
          Text("Large Title · 28pt Bold")
            .font(.system(size: 28, weight: .bold))
          Text("Title 2 · 20pt Semibold")
            .font(.system(size: 20, weight: .semibold))
          Text("Headline · 15pt Semibold")
            .font(.system(size: 15, weight: .semibold))
          Text("Body · 14pt Regular — Hello 世界 · 日本語 · 한국어 🌍✨")
            .font(.system(size: 14))
          Text("Caption · 12pt Secondary Metadata")
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
      }

      GallerySection("Rich Runs, Kerning & Truncation", subtitle: "Concatenated styled Text, underline, kerning, line spacing, and truncation.") {
        VStack(alignment: .leading, spacing: 10) {
          richTextRun
            .font(.system(size: 14))

          Text("Underlined Text Modifier")
            .font(.system(size: 14))
            .underline()

          Text("TRACKED UPPERCASE HEADING")
            .font(.system(size: 12, weight: .semibold))
            .kerning(2.0)
            .foregroundStyle(.secondary)

          Text("Multiline text wraps cleanly across lines with configurable line spacing so desktop documentation and descriptions stay easy to scan.")
            .font(.system(size: 13))
            .lineSpacing(5)
            .frame(maxWidth: 460, alignment: .leading)

          Text("This long single-line label demonstrates tail truncation when the available horizontal width is constrained.")
            .font(.system(size: 13))
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: 320, alignment: .leading)
        }
      }

      GallerySection("Label & LabeledContent", subtitle: "Label style variants and desktop key-value inspector rows.") {
        HStack(spacing: 24) {
          Label("Title & Icon", systemImage: "star.fill")
            .labelStyle(.titleAndIcon)
          Label("Icon Only", systemImage: "bell.fill")
            .labelStyle(.iconOnly)
          Label("Title Only", systemImage: "gearshape")
            .labelStyle(.titleOnly)
        }

        Divider()

        VStack(spacing: 8) {
          LabeledContent("Framework", value: "CrossSwiftUI")
          LabeledContent("Targets", value: "macOS · Windows · Linux")
          LabeledContent("Status") {
            Text("Ready")
              .font(.system(size: 12, weight: .semibold))
              .foregroundStyle(Color.green)
          }
        }
        .frame(maxWidth: 380)
      }
    }
  }
}

// MARK: - 8. Image & SF Symbols

struct ImagesAndSymbolsGalleryView: View {
  private let symbols: [(name: String, label: String, color: Color)] = [
    ("house.fill", "House", .blue),
    ("folder", "Folder", .orange),
    ("doc.text", "Document", .indigo),
    ("gearshape", "Settings", .gray),
    ("bell.fill", "Alerts", .pink),
    ("heart.fill", "Favorite", .red),
    ("star.fill", "Starred", .yellow),
    ("sparkles", "Effects", .purple),
    ("terminal", "Terminal", .teal),
    ("globe", "Network", .cyan),
    ("lock.shield", "Security", .green),
    ("keyboard", "Shortcuts", .blue),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      GallerySection("SF Symbols & Tinting", subtitle: "Template-rendered vector icons scaled and tinted with foregroundStyle.") {
        LazyVGrid(
          columns: [
            GridItem(.adaptive(minimum: 110), spacing: 12)
          ],
          spacing: 12
        ) {
          ForEach(symbols, id: \.name) { item in
            VStack(spacing: 8) {
              Image(systemName: item.name)
                .foregroundStyle(item.color)
                .frame(width: 26, height: 26)
              Text(item.label)
                .font(.system(size: 12, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(item.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
          }
        }
      }

      GallerySection("Sizing & Aspect Ratio", subtitle: "Uniform symbol scaling inside fixed frames.") {
        HStack(spacing: 20) {
          sizeBadge(size: 16, label: "16pt")
          sizeBadge(size: 24, label: "24pt")
          sizeBadge(size: 36, label: "36pt")
          sizeBadge(size: 48, label: "48pt")
        }
      }
    }
  }

  private func sizeBadge(size: CGFloat, label: String) -> some View {
    VStack(spacing: 8) {
      ZStack {
        RoundedRectangle(cornerRadius: 10)
          .fill(Color.blue.opacity(0.10))
          .frame(width: 68, height: 68)
        Image(systemName: "macwindow")
          .aspectRatio(contentMode: .fit)
          .foregroundStyle(Color.blue)
          .frame(width: size, height: size)
      }
      Text(label)
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
    }
  }
}

// MARK: - 9. ProgressView & ContentUnavailableView

struct ProgressAndStatusGalleryView: View {
  @State private var progress: Double = 0.65
  @State private var filterText = "nonexistent-item"

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      GallerySection("Determinate ProgressView", subtitle: "Linear progress bars with live updates and custom tints.") {
        VStack(alignment: .leading, spacing: 12) {
          HStack {
            Text("Building Release Artifact…")
              .font(.system(size: 13, weight: .semibold))
            Spacer()
            Text("\(Int((progress * 100).rounded()))%")
              .font(.system(size: 13, weight: .medium))
              .foregroundStyle(.secondary)
          }

          ProgressView(value: progress)

          HStack(spacing: 10) {
            Button("Advance +15%") {
              progress = min(1.0, progress + 0.15)
            }
            .buttonStyle(.borderedProminent)

            Button("Reset") {
              progress = 0.0
            }
            .buttonStyle(.bordered)
          }

          Divider()

          VStack(alignment: .leading, spacing: 6) {
            Text("Success Tint (85%)")
              .font(.system(size: 12))
              .foregroundStyle(.secondary)
            ProgressView(value: 0.85)
              .tint(.green)
          }

          VStack(alignment: .leading, spacing: 6) {
            Text("Warning Tint (35%)")
              .font(.system(size: 12))
              .foregroundStyle(.secondary)
            ProgressView(value: 0.35)
              .tint(.orange)
          }
        }
      }

      GallerySection("Indeterminate ProgressView", subtitle: "Spinner indicators for unknown-duration tasks.") {
        HStack(spacing: 28) {
          ProgressView()
          ProgressView("Syncing workspace…")
        }
      }

      GallerySection("ContentUnavailableView", subtitle: "Standard empty-state placeholder with action button.") {
        ContentUnavailableView {
          Label("No Results for \"\(filterText)\"", systemImage: "magnifyingglass")
        } description: {
          Text("Try adjusting your search query or clearing active filters.")
        } actions: {
          Button("Clear Filter") {
            filterText = "all-views"
          }
          .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
      }
    }
  }
}
