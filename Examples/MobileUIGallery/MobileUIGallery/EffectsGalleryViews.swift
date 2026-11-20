import SwiftUI

// MARK: - 9. Visual Effect

struct VisualEffectGalleryView: View {
  @State private var backdrop = 0
  @State private var cornerRadius: Double = 20

  private var backdropGradient: LinearGradient {
    switch backdrop {
    case 0:
      return LinearGradient(
        colors: [Color(red: 0.12, green: 0.48, blue: 0.98), Color(red: 0.54, green: 0.28, blue: 0.94)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    case 1:
      return LinearGradient(
        colors: [Color(red: 0.06, green: 0.66, blue: 0.78), Color(red: 0.14, green: 0.36, blue: 0.88)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    case 2:
      return LinearGradient(
        colors: [Color(red: 0.96, green: 0.32, blue: 0.56), Color(red: 0.98, green: 0.62, blue: 0.28)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    default:
      return LinearGradient(
        colors: [Color(red: 0.14, green: 0.72, blue: 0.48), Color(red: 0.20, green: 0.46, blue: 0.88)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    }
  }

  var body: some View {
    List {
      Section("Backdrop Wallpaper") {
        VStack(alignment: .leading, spacing: 12) {
          Picker("Backdrop", selection: $backdrop) {
            Text("Circles").tag(0)
            Text("Waves").tag(1)
            Text("Pink").tag(2)
            Text("Mini").tag(3)
          }
          .pickerStyle(.segmented)
          .labelsHidden()

          HStack {
            Text("Block Corner Radius")
              .font(.system(size: 14))
            Spacer()
            Text("\(Int(cornerRadius.rounded())) pt")
              .font(.system(size: 14))
              .foregroundStyle(.secondary)
          }
          Slider(value: $cornerRadius, in: 6...32, step: 1)
        }
      }

      Section("Liquid Glass") {
        VStack(spacing: 12) {
          HStack(spacing: 12) {
            glassTile(title: "Regular", subtitle: "GlassEffectStyle", opacity: 0.32)
            glassTile(title: "Clear", subtitle: "Translucent", opacity: 0.16)
          }
          HStack(spacing: 10) {
            glassPill("Regular A", opacity: 0.34)
            glassPill("Regular B", opacity: 0.34)
            glassPill("Clear", opacity: 0.18)
          }
        }
        .padding(14)
        .background(backdropGradient, in: RoundedRectangle(cornerRadius: 18))
      }

      Section("Adaptive System Materials") {
        VStack(spacing: 8) {
          materialRow("Ultra Thin", detail: "systemUltraThinMaterial", alpha: 0.18)
          materialRow("Thin", detail: "systemThinMaterial", alpha: 0.30)
          materialRow("Regular", detail: "systemMaterial", alpha: 0.46)
          materialRow("Thick", detail: "systemThickMaterial", alpha: 0.64)
          materialRow("Chrome", detail: "systemChromeMaterial", alpha: 0.78)
        }
        .padding(12)
        .background(backdropGradient, in: RoundedRectangle(cornerRadius: 18))
      }

      Section("Vibrancy Hierarchy") {
        Text("Primary Label (.label)").font(.system(size: 15, weight: .semibold))
        Text("Secondary Label (.secondaryLabel)").font(.system(size: 14)).foregroundStyle(.secondary)
        Text("Tertiary Label (.tertiaryLabel)").font(.system(size: 13)).foregroundStyle(Color.gray.opacity(0.65))
        Text("Quaternary Label (.quaternaryLabel)").font(.system(size: 12)).foregroundStyle(Color.gray.opacity(0.45))
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Visual Effect")
  }

  private func glassTile(title: String, subtitle: String, opacity: Double) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(Color.white)
      Text(subtitle)
        .font(.system(size: 12))
        .foregroundStyle(Color.white.opacity(0.82))
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.white.opacity(opacity), in: RoundedRectangle(cornerRadius: cornerRadius))
    .overlay {
      RoundedRectangle(cornerRadius: cornerRadius)
        .strokeBorder(Color.white.opacity(0.45), lineWidth: 1)
    }
  }

  private func glassPill(_ title: String, opacity: Double) -> some View {
    Text(title)
      .font(.system(size: 12, weight: .semibold))
      .foregroundStyle(Color.white)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(Color.white.opacity(opacity), in: RoundedRectangle(cornerRadius: 18))
      .overlay {
        RoundedRectangle(cornerRadius: 18)
          .strokeBorder(Color.white.opacity(0.45), lineWidth: 1)
      }
  }

  private func materialRow(_ name: String, detail: String, alpha: Double) -> some View {
    HStack {
      Text(name)
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(Color.black.opacity(0.86))
      Spacer()
      Text(detail)
        .font(.system(size: 12))
        .foregroundStyle(Color.black.opacity(0.60))
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .background(Color.white.opacity(alpha), in: RoundedRectangle(cornerRadius: 10))
  }
}

// MARK: - 10. Liquid Lens

struct LiquidLensGalleryView: View {
  @State private var lensA = true
  @State private var lensB = false
  @State private var lensC = true
  @State private var lensD = false

  var body: some View {
    List {
      Section {
        ZStack {
          RoundedRectangle(cornerRadius: 18)
            .fill(
              LinearGradient(
                colors: [Color(red: 0.98, green: 0.42, blue: 0.48), Color(red: 0.34, green: 0.46, blue: 0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .frame(height: 220)

          VStack(spacing: 16) {
            Text("Liquid Glass")
              .font(.system(size: 17, weight: .semibold))
              .foregroundStyle(Color.white)
              .padding(.horizontal, 22)
              .padding(.vertical, 10)
              .background(Color.white.opacity(0.26), in: RoundedRectangle(cornerRadius: 22))
              .overlay {
                RoundedRectangle(cornerRadius: 22)
                  .strokeBorder(Color.white.opacity(0.55), lineWidth: 1.2)
              }

            HStack(spacing: 24) {
              Toggle("", isOn: $lensA).labelsHidden()
              Toggle("", isOn: $lensB).labelsHidden()
            }
            HStack(spacing: 24) {
              Toggle("", isOn: $lensC).labelsHidden()
              Toggle("", isOn: $lensD).labelsHidden()
            }
          }
          .padding(14)
        }
      } header: {
        Text("Refraction Backdrop")
      } footer: {
        Text("Liquid Glass capsule and switches over colorful backdrop.")
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Liquid Lens")
  }
}

// MARK: - 11. Siri

struct SiriGalleryView: View {
  @State private var siriActive = true
  @State private var replayCount = 1

  var body: some View {
    List {
      Section("Edge Glow Overlay") {
        VStack(spacing: 16) {
          ZStack {
            RoundedRectangle(cornerRadius: 22)
              .fill(
                LinearGradient(
                  colors: siriActive
                    ? [
                        Color(red: 0.98, green: 0.30, blue: 0.62),
                        Color(red: 0.48, green: 0.34, blue: 0.98),
                        Color(red: 0.14, green: 0.72, blue: 0.98),
                      ]
                    : [Color.gray.opacity(0.25), Color.gray.opacity(0.18)],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
              .frame(height: 180)

            VStack(spacing: 8) {
              Image(systemName: "waveform")
                .foregroundStyle(Color.white)
                .frame(width: 34, height: 34)
              Text(siriActive ? "Siri Edge Glow Active" : "Siri Dismissed")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.white)
              Text("Trigger #\(replayCount)")
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.85))
            }
            .padding(20)
            .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 18))
          }

          HStack(spacing: 10) {
            Button("Activate Siri") {
              siriActive = true
              replayCount += 1
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.purple)
            .frame(maxWidth: .infinity, minHeight: 40)

            Button("Dismiss") {
              siriActive = false
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity, minHeight: 40)
          }
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Siri")
  }
}
