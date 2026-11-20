import SwiftUI

// MARK: - 15. Text

struct TextGalleryView: View {
  var body: some View {
    List {
      Section("Multilingual & Emoji") {
        VStack(alignment: .leading, spacing: 6) {
          Text("Hello 世界 · 日本語 · 한국어 🌍✨")
            .font(.system(size: 17, weight: .medium))
          Text("SwiftUI renders Unicode and emoji natively.")
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
        }
      }

      Section("Typography Scale") {
        Text("Large Title").font(.system(size: 28, weight: .bold))
        Text("Title 2").font(.system(size: 22, weight: .semibold))
        Text("Headline").font(.system(size: 17, weight: .semibold))
        Text("Body — Regular 15pt text").font(.system(size: 15))
        Text("Caption — Secondary metadata").font(.system(size: 12)).foregroundStyle(.secondary)
      }

      Section("Word Wrapping") {
        Text("SwiftUI views evaluate cleanly across platforms, supporting multiline wrapping with natural line spacing.")
          .font(.system(size: 15))
          .lineSpacing(4)
      }

      Section("Tail Truncation") {
        Text("This is a long single-line label that demonstrates tail ellipsis truncation when horizontal space is constrained.")
          .font(.system(size: 15))
          .lineLimit(1)
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Text")
  }
}

// MARK: - 16. Image View

struct ImageViewGalleryView: View {
  var body: some View {
    List {
      Section("Symbols & Tinting") {
        HStack(spacing: 12) {
          symbolTile("star.fill", color: .orange, label: "Star")
          symbolTile("heart.fill", color: .pink, label: "Heart")
          symbolTile("bell.fill", color: .indigo, label: "Alert")
          symbolTile("sparkles", color: .teal, label: "Magic")
        }
      }

      Section("Aspect Modes") {
        HStack(spacing: 12) {
          aspectCard(title: "Aspect Fit", color: .blue, symbol: "photo")
          aspectCard(title: "Aspect Fill", color: .purple, symbol: "paintbrush.fill")
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Image View")
  }

  private func symbolTile(_ name: String, color: Color, label: String) -> some View {
    VStack(spacing: 8) {
      Image(systemName: name)
        .foregroundStyle(color)
        .frame(width: 26, height: 26)
      Text(label)
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 14)
    .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
  }

  private func aspectCard(title: String, color: Color, symbol: String) -> some View {
    VStack(spacing: 8) {
      ZStack {
        RoundedRectangle(cornerRadius: 12)
          .fill(color.opacity(0.15))
          .frame(height: 84)
        Image(systemName: symbol)
          .foregroundStyle(color)
          .frame(width: 34, height: 34)
      }
      Text(title)
        .font(.system(size: 13, weight: .medium))
    }
    .frame(maxWidth: .infinity)
  }
}

// MARK: - 17. Progress View

struct ProgressViewGalleryView: View {
  @State private var progress: Double = 0.65

  var body: some View {
    List {
      Section("Animated Progress") {
        VStack(alignment: .leading, spacing: 12) {
          HStack {
            Text("Transferring Assets…")
              .font(.system(size: 15, weight: .semibold))
            Spacer()
            Text("\(Int((progress * 100).rounded()))%")
              .font(.system(size: 14, weight: .semibold))
              .foregroundStyle(.secondary)
          }

          ProgressView(value: progress)

          HStack(spacing: 10) {
            Button("Advance (+25%)") {
              progress = min(1.0, progress + 0.25)
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity, minHeight: 38)

            Button("Reset") {
              progress = 0.0
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity, minHeight: 38)
          }
        }
      }

      Section("Default & Custom Tint") {
        VStack(alignment: .leading, spacing: 6) {
          Text("Default Style (45%)").font(.system(size: 13)).foregroundStyle(.secondary)
          ProgressView(value: 0.45)
        }
        VStack(alignment: .leading, spacing: 6) {
          Text("Custom Green Tint (82%)").font(.system(size: 13)).foregroundStyle(.secondary)
          ProgressView(value: 0.82)
            .tint(Color.green)
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Progress View")
  }
}

// MARK: - 18. Activity Indicator

struct ActivityIndicatorGalleryView: View {
  @State private var isAnimating = true

  var body: some View {
    List {
      Section("Material HUD") {
        HStack(spacing: 14) {
          ProgressView()
          Text("Preparing Workspace…")
            .font(.system(size: 15, weight: .medium))
          Spacer()
        }
      }

      Section("Custom Colors") {
        HStack(spacing: 28) {
          Spacer()
          VStack(spacing: 6) {
            ProgressView().tint(.blue)
            Text("Blue").font(.system(size: 12)).foregroundStyle(.secondary)
          }
          VStack(spacing: 6) {
            ProgressView().tint(.orange)
            Text("Orange").font(.system(size: 12)).foregroundStyle(.secondary)
          }
          VStack(spacing: 6) {
            ProgressView().tint(.green)
            Text("Green").font(.system(size: 12)).foregroundStyle(.secondary)
          }
          Spacer()
        }
      }

      Section("Playback & Visibility") {
        Toggle("Animating", isOn: $isAnimating)
        HStack {
          Text("Indicator")
            .font(.system(size: 15))
          Spacer()
          if isAnimating {
            ProgressView()
          } else {
            Text("Stopped")
              .font(.system(size: 13))
              .foregroundStyle(.secondary)
          }
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Activity Indicator")
  }
}

// MARK: - 19. View

struct ViewGalleryView: View {
  var body: some View {
    List {
      Section("Corner Radius") {
        HStack(spacing: 14) {
          radiusBox(radius: 4, label: "4 pt")
          radiusBox(radius: 14, label: "14 pt")
          radiusBox(radius: 26, label: "26 pt")
        }
      }

      Section("Clipping (clipsToBounds)") {
        HStack(spacing: 16) {
          VStack(spacing: 8) {
            ZStack {
              RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.16))
                .frame(width: 110, height: 74)
              Circle()
                .fill(Color.orange)
                .frame(width: 64, height: 64)
                .offset(x: 34, y: 18)
            }
            .frame(width: 110, height: 74)
            .clipped()
            Text("Clipped")
              .font(.system(size: 13, weight: .medium))
          }
          .frame(maxWidth: .infinity)

          VStack(spacing: 8) {
            ZStack {
              RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.16))
                .frame(width: 110, height: 74)
              Circle()
                .fill(Color.teal)
                .frame(width: 44, height: 44)
            }
            Text("Contained")
              .font(.system(size: 13, weight: .medium))
          }
          .frame(maxWidth: .infinity)
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("View")
  }

  private func radiusBox(radius: CGFloat, label: String) -> some View {
    VStack(spacing: 6) {
      RoundedRectangle(cornerRadius: radius)
        .fill(Color(red: 0, green: 0.478, blue: 1))
        .frame(height: 60)
      Text(label)
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
  }
}

// MARK: - 20. Scroll View

struct ScrollViewGalleryView: View {
  var body: some View {
    List {
      Section("Horizontal Carousel") {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 12) {
            carouselCard("Page 1 · iOS Waves", c1: .blue, c2: .cyan)
            carouselCard("Page 2 · Sunset", c1: .orange, c2: .pink)
            carouselCard("Page 3 · Emerald", c1: .green, c2: .teal)
            carouselCard("Page 4 · Twilight", c1: .purple, c2: .indigo)
          }
        }
        .frame(height: 126)
      }

      Section("Vertical List (Items 1–14)") {
        ForEach(1...14, id: \.self) { idx in
          HStack {
            Text("Item \(idx)")
              .font(.system(size: 15))
            Spacer()
            Text("Row #\(idx)")
              .font(.system(size: 13))
              .foregroundStyle(.secondary)
          }
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Scroll View")
  }

  private func carouselCard(_ title: String, c1: Color, c2: Color) -> some View {
    VStack(alignment: .leading) {
      Spacer()
      Text(title)
        .font(.system(size: 15, weight: .bold))
        .foregroundStyle(Color.white)
    }
    .padding(14)
    .frame(width: 220, height: 120, alignment: .leading)
    .background(
      LinearGradient(colors: [c1, c2], startPoint: .topLeading, endPoint: .bottomTrailing),
      in: RoundedRectangle(cornerRadius: 16)
    )
  }
}

// MARK: - 21. Collection View

struct CollectionViewGalleryView: View {
  var body: some View {
    List {
      Section("Featured (Horizontal)") {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 12) {
            featuredCard("Featured 1 · Waves", color: .blue)
            featuredCard("Featured 2 · Coral", color: .pink)
            featuredCard("Featured 3 · Mint", color: .teal)
          }
        }
        .frame(height: 114)
      }

      Section("Grid (4 Columns · Tiles 1–20)") {
        VStack(spacing: 10) {
          ForEach(0..<5, id: \.self) { row in
            HStack(spacing: 10) {
              ForEach(1...4, id: \.self) { col in
                let num = row * 4 + col
                ZStack {
                  RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0, green: 0.478, blue: 1).opacity(0.12 + Double(num % 4) * 0.08))
                    .frame(height: 58)
                  Text("\(num)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(red: 0, green: 0.478, blue: 1))
                }
                .frame(maxWidth: .infinity)
              }
            }
          }
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Collection View")
  }

  private func featuredCard(_ title: String, color: Color) -> some View {
    VStack(alignment: .leading) {
      Spacer()
      Text(title)
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(Color.white)
    }
    .padding(14)
    .frame(width: 190, height: 108, alignment: .leading)
    .background(color, in: RoundedRectangle(cornerRadius: 16))
  }
}
