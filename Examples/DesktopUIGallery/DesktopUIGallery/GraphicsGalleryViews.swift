import SwiftUI

// MARK: - 17. Shapes, Path & Canvas

private struct DiamondShape: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.midX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
    path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
    path.closeSubpath()
    return path
  }
}

struct ShapesAndCanvasGalleryView: View {
  @State private var trimProgress: Double = 0.72

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      GallerySection("Built-in Shapes", subtitle: "Rectangle, RoundedRectangle, Circle, Capsule, Ellipse, UnevenRoundedRectangle, and custom Path.") {
        HStack(spacing: 16) {
          shapeTile("Rectangle") {
            Rectangle().fill(Color.blue).frame(width: 56, height: 40)
          }
          shapeTile("Rounded") {
            RoundedRectangle(cornerRadius: 10).fill(Color.indigo).frame(width: 56, height: 40)
          }
          shapeTile("Circle") {
            Circle().fill(Color.teal).frame(width: 44, height: 44)
          }
          shapeTile("Capsule") {
            Capsule().fill(Color.orange).frame(width: 64, height: 34)
          }
          shapeTile("Ellipse") {
            Ellipse().fill(Color.pink).frame(width: 64, height: 36)
          }
          shapeTile("Uneven") {
            UnevenRoundedRectangle(
              topLeadingRadius: 16,
              bottomLeadingRadius: 4,
              bottomTrailingRadius: 16,
              topTrailingRadius: 4
            )
            .fill(Color.purple)
            .frame(width: 56, height: 40)
          }
          shapeTile("Custom Path") {
            DiamondShape().fill(Color.green).frame(width: 46, height: 46)
          }
        }
      }

      GallerySection("Trimmed Shape & Stroke", subtitle: "Circular trim progress ring driven by a Slider.") {
        HStack(spacing: 24) {
          ZStack {
            Circle()
              .stroke(Color.gray.opacity(0.25), lineWidth: 8)
            Circle()
              .trim(from: 0, to: trimProgress)
              .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
              .rotationEffect(.degrees(-90))
            Text("\(Int((trimProgress * 100).rounded()))%")
              .font(.system(size: 14, weight: .bold))
          }
          .frame(width: 84, height: 84)

          VStack(alignment: .leading, spacing: 8) {
            Text("Trim End: \(String(format: "%.2f", trimProgress))")
              .font(.system(size: 13, weight: .medium))
            Slider(value: $trimProgress, in: 0.05...1.0)
              .frame(width: 240)
          }
        }
      }

      GallerySection("Canvas", subtitle: "Immediate-mode vector drawing with GraphicsContext fills and transforms.") {
        Canvas { context, size in
          let barCount = 8
          let gap: CGFloat = 10
          let barWidth = max(12, (size.width - gap * CGFloat(barCount + 1)) / CGFloat(barCount))
          let heights: [CGFloat] = [0.35, 0.58, 0.44, 0.82, 0.68, 0.92, 0.54, 0.76]
          let colors: [Color] = [.blue, .indigo, .purple, .pink, .orange, .teal, .cyan, .green]

          for i in 0..<barCount {
            let h = max(14, (size.height - 20) * heights[i])
            let x = gap + CGFloat(i) * (barWidth + gap)
            let y = size.height - h - 8
            let rect = CGRect(x: x, y: y, width: barWidth, height: h)
            let path = Path(roundedRect: rect, cornerRadius: 6)
            context.fill(path, with: .color(colors[i % colors.count]))
          }
        }
        .frame(height: 130)
        .background(Color.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
      }
    }
  }

  private func shapeTile<S: View>(_ title: String, @ViewBuilder shape: () -> S) -> some View {
    VStack(spacing: 8) {
      ZStack {
        shape()
      }
      .frame(width: 72, height: 52)
      Text(title)
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
    }
  }
}

// MARK: - 18. Gradients, Materials & Effects

struct GradientsAndMaterialsGalleryView: View {
  @State private var elevation: Double = 8
  @State private var cardOpacity: Double = 0.90

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      GallerySection("Gradients", subtitle: "LinearGradient, RadialGradient, and AngularGradient fills.") {
        HStack(spacing: 14) {
          gradientTile("LinearGradient") {
            LinearGradient(
              colors: [.blue, .purple, .pink],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          }

          gradientTile("RadialGradient") {
            RadialGradient(
              colors: [.yellow, .orange, .red],
              center: .center,
              startRadius: 4,
              endRadius: 72
            )
          }

          gradientTile("AngularGradient") {
            AngularGradient(
              colors: [.blue, .teal, .green, .orange, .pink, .blue],
              center: .center
            )
          }
        }
      }

      GallerySection("Materials & Glass", subtitle: "Translucent layers over vibrant backdrops.") {
        HStack(spacing: 12) {
          materialCard("Ultra Thin", material: .ultraThinMaterial)
          materialCard("Regular", material: .regularMaterial)
          materialCard("Thick", material: .thickMaterial)
        }
        .padding(16)
        .background(
          LinearGradient(
            colors: [Color(red: 0.12, green: 0.44, blue: 0.96), Color(red: 0.62, green: 0.24, blue: 0.88)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          in: RoundedRectangle(cornerRadius: 14)
        )
      }

      GallerySection("Shadow, Opacity & Clipping", subtitle: "Interactive shadow radius and opacity modifiers.") {
        HStack(spacing: 24) {
          VStack(spacing: 4) {
            Text("Elevated Card")
              .font(.system(size: 14, weight: .semibold))
              .foregroundStyle(Color.white)
            Text("Shadow \(Int(elevation))pt · α \(String(format: "%.2f", cardOpacity))")
              .font(.system(size: 11))
              .foregroundStyle(Color.white.opacity(0.85))
          }
          .padding(18)
          .background(Color.indigo, in: RoundedRectangle(cornerRadius: 12))
          .opacity(cardOpacity)
          .shadow(color: Color.black.opacity(0.28), radius: elevation, x: 0, y: elevation * 0.4)

          VStack(alignment: .leading, spacing: 10) {
            HStack {
              Text("Shadow Radius").font(.system(size: 12))
              Slider(value: $elevation, in: 0...20)
                .frame(width: 180)
            }
            HStack {
              Text("Opacity").font(.system(size: 12))
              Slider(value: $cardOpacity, in: 0.2...1.0)
                .frame(width: 180)
            }
          }
        }
      }
    }
  }

  private func gradientTile<V: View>(_ title: String, @ViewBuilder fill: () -> V) -> some View {
    VStack(spacing: 6) {
      fill()
        .frame(height: 84)
        .clipShape(RoundedRectangle(cornerRadius: 12))
      Text(title)
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
  }

  private func materialCard(_ title: String, material: Material) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.system(size: 13, weight: .semibold))
      Text("Material surface")
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(material, in: RoundedRectangle(cornerRadius: 10))
    .overlay {
      RoundedRectangle(cornerRadius: 10)
        .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
    }
  }
}

// MARK: - 19. Gestures & Animation

struct GesturesAndAnimationGalleryView: View {
  @State private var tapCount = 0
  @State private var isHovering = false
  @State private var dragOffset: CGSize = .zero
  @State private var isExpanded = false

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      GallerySection("Tap & Hover Gestures", subtitle: "onTapGesture and onHover desktop pointer feedback.") {
        HStack(spacing: 16) {
          VStack(spacing: 6) {
            Text("Tap Count: \(tapCount)")
              .font(.system(size: 15, weight: .bold))
              .foregroundStyle(Color.white)
            Text("Click this card")
              .font(.system(size: 12))
              .foregroundStyle(Color.white.opacity(0.85))
          }
          .padding(18)
          .frame(maxWidth: .infinity)
          .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
          .onTapGesture {
            tapCount += 1
          }

          VStack(spacing: 6) {
            Text(isHovering ? "Pointer Hovering" : "Move Pointer Here")
              .font(.system(size: 15, weight: .bold))
              .foregroundStyle(isHovering ? Color.white : Color.primary)
            Text(isHovering ? "onHover(true)" : "onHover(false)")
              .font(.system(size: 12))
              .foregroundStyle(isHovering ? Color.white.opacity(0.85) : Color.secondary)
          }
          .padding(18)
          .frame(maxWidth: .infinity)
          .background(
            isHovering ? Color.teal : Color.gray.opacity(0.14),
            in: RoundedRectangle(cornerRadius: 12)
          )
          .onHover { hovering in
            isHovering = hovering
          }
        }
      }

      GallerySection("DragGesture", subtitle: "Drag the puck inside the arena; live translation updates in real time.") {
        VStack(alignment: .leading, spacing: 10) {
          ZStack {
            RoundedRectangle(cornerRadius: 12)
              .fill(Color.gray.opacity(0.10))
              .frame(height: 120)

            Circle()
              .fill(Color.orange)
              .frame(width: 44, height: 44)
              .overlay {
                Image(systemName: "hand.tap")
                  .foregroundStyle(Color.white)
                  .frame(width: 18, height: 18)
              }
              .offset(x: dragOffset.width, y: dragOffset.height)
              .gesture(
                DragGesture()
                  .onChanged { value in
                    dragOffset = CGSize(
                      width: max(-120, min(120, value.translation.width)),
                      height: max(-36, min(36, value.translation.height))
                    )
                  }
              )
          }

          HStack {
            Text("Offset: (\(Int(dragOffset.width)), \(Int(dragOffset.height)))")
              .font(.system(size: 12))
              .foregroundStyle(.secondary)
            Spacer()
            Button("Reset Position") {
              dragOffset = .zero
            }
            .buttonStyle(.bordered)
          }
        }
      }

      GallerySection("Animation", subtitle: "Animated scale, rotation, offset, and opacity transitions via withAnimation.") {
        HStack(spacing: 24) {
          ZStack {
            RoundedRectangle(cornerRadius: 14)
              .fill(isExpanded ? Color.purple : Color.blue)
              .frame(width: 64, height: 64)
              .scaleEffect(isExpanded ? 1.25 : 1.0)
              .rotationEffect(.degrees(isExpanded ? 45 : 0))
              .opacity(isExpanded ? 0.95 : 0.75)
              .animation(.easeInOut(duration: 0.3), value: isExpanded)
          }
          .frame(width: 110, height: 96)

          VStack(alignment: .leading, spacing: 8) {
            Text(isExpanded ? "State: Transformed (1.25×, 45°)" : "State: Resting (1.0×, 0°)")
              .font(.system(size: 13, weight: .semibold))
            Button("Toggle Animation") {
              withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded.toggle()
              }
            }
            .buttonStyle(.borderedProminent)
          }
        }
      }
    }
  }
}
