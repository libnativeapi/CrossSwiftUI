import SwiftUI

struct ServiceStatus: Identifiable {
  let id: String
  let name: String
  let region: String
  let latencyMs: Int
  let uptime: String
  let healthy: Bool
}

@main
struct MetricsDashboardApp: App {
  var body: some Scene {
    WindowGroup("Metrics Dashboard") {
      MetricsDashboardView()
    }
    .defaultSize(width: 980, height: 680)
  }
}

struct MetricsDashboardView: View {
  @State private var rangeIndex = 0
  @State private var isPaused = false
  @State private var darkMode = false

  private let services: [ServiceStatus] = [
    ServiceStatus(id: "api", name: "Edge API Gateway", region: "us-west-2", latencyMs: 18, uptime: "99.99%", healthy: true),
    ServiceStatus(id: "auth", name: "Identity & SSO", region: "eu-central-1", latencyMs: 24, uptime: "99.97%", healthy: true),
    ServiceStatus(id: "build", name: "Artifact Builder", region: "ap-northeast-1", latencyMs: 112, uptime: "99.42%", healthy: false),
    ServiceStatus(id: "cdn", name: "Static Asset CDN", region: "global", latencyMs: 9, uptime: "100.00%", healthy: true),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 14) {
        HStack(spacing: 8) {
          Image(systemName: "chart.line.uptrend.xyaxis")
            .foregroundStyle(Color.indigo)
            .frame(width: 20, height: 20)
          VStack(alignment: .leading, spacing: 2) {
            Text("Metrics Dashboard")
              .font(.system(size: 18, weight: .bold))
            Text("Real-time telemetry rendered with TimelineView, Canvas, and Grid")
              .font(.system(size: 12))
              .foregroundStyle(.secondary)
          }
        }

        Spacer()

        Picker("Range", selection: $rangeIndex) {
          Text("15m").tag(0)
          Text("1h").tag(1)
          Text("24h").tag(2)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(width: 150)

        Button(isPaused ? "Resume" : "Pause") {
          isPaused.toggle()
        }
        .buttonStyle(.bordered)
        .fixedSize()

        Toggle("Dark", isOn: $darkMode)
          .toggleStyle(.switch)
          .fixedSize()
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 14)

      Divider()

      ScrollView(.vertical) {
        TimelineView(.animation(minimumInterval: 0.8, paused: isPaused)) { context in
          let tick = Int(context.date.timeIntervalSince1970)
          let cpu = 32 + ((tick * 7 + rangeIndex * 11) % 34)
          let mem = 58 + ((tick * 3 + rangeIndex * 5) % 18)
          let rps = 1240 + ((tick * 29 + rangeIndex * 130) % 480)

          VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 14) {
              kpiCard(title: "CPU Usage", value: "\(cpu)%", progress: Double(cpu) / 100.0, color: .blue)
              kpiCard(title: "Memory", value: "\(mem)%", progress: Double(mem) / 100.0, color: .indigo)
              kpiCard(title: "Throughput", value: "\(rps) req/s", progress: min(1.0, Double(rps) / 2000.0), color: .teal)
            }

            VStack(alignment: .leading, spacing: 10) {
              HStack {
                Text("Live Request Throughput")
                  .font(.system(size: 15, weight: .semibold))
                Spacer()
                Text(isPaused ? "Paused" : "Streaming")
                  .font(.system(size: 12, weight: .medium))
                  .foregroundStyle(isPaused ? Color.orange : Color.green)
              }

              Canvas { ctx, size in
                let count = 24
                let gap: CGFloat = 6
                let barW = max(6, (size.width - gap * CGFloat(count + 1)) / CGFloat(count))
                for i in 0..<count {
                  let phase = Double(tick + i * 2 + rangeIndex * 5)
                  let normalized = 0.25 + 0.65 * (0.5 + 0.5 * sin(phase * 0.45))
                  let h = max(12, (size.height - 20) * normalized)
                  let x = gap + CGFloat(i) * (barW + gap)
                  let y = size.height - h - 8
                  let rect = CGRect(x: x, y: y, width: barW, height: h)
                  let color: Color = normalized > 0.78 ? .orange : (normalized > 0.55 ? .indigo : .blue)
                  ctx.fill(Path(roundedRect: rect, cornerRadius: 4), with: .color(color))
                }
              }
              .frame(height: 170)
              .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }
            .padding(16)
            .background(Color.gray.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
            .overlay {
              RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.gray.opacity(0.22), lineWidth: 1)
            }

            VStack(alignment: .leading, spacing: 12) {
              Text("Service Health")
                .font(.system(size: 15, weight: .semibold))

              Grid(alignment: .leading, horizontalSpacing: 28, verticalSpacing: 10) {
                GridRow {
                  Text("Service").font(.system(size: 12, weight: .bold)).foregroundStyle(.secondary)
                  Text("Region").font(.system(size: 12, weight: .bold)).foregroundStyle(.secondary)
                  Text("Latency").font(.system(size: 12, weight: .bold)).foregroundStyle(.secondary)
                  Text("Uptime").font(.system(size: 12, weight: .bold)).foregroundStyle(.secondary)
                  Text("State").font(.system(size: 12, weight: .bold)).foregroundStyle(.secondary)
                }
                Divider()
                ForEach(services) { svc in
                  GridRow {
                    Text(svc.name).font(.system(size: 13, weight: .medium))
                    Text(svc.region).font(.system(size: 13)).foregroundStyle(.secondary)
                    Text("\(svc.latencyMs + (tick % 5)) ms").font(.system(size: 13))
                    Text(svc.uptime).font(.system(size: 13))
                    Text(svc.healthy ? "Healthy" : "Degraded")
                      .font(.system(size: 12, weight: .semibold))
                      .foregroundStyle(svc.healthy ? Color.green : Color.orange)
                  }
                }
              }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
            .overlay {
              RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.gray.opacity(0.22), lineWidth: 1)
            }
          }
          .padding(24)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(darkMode ? Color(red: 0.10, green: 0.10, blue: 0.12) : Color.white)
    .preferredColorScheme(darkMode ? .dark : .light)
  }

  private func kpiCard(title: String, value: String, progress: Double, color: Color) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text(title)
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(.secondary)
        Spacer()
        Text(value)
          .font(.system(size: 18, weight: .bold))
      }
      ProgressView(value: progress)
        .tint(color)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(color.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
    .overlay {
      RoundedRectangle(cornerRadius: 12)
        .strokeBorder(color.opacity(0.24), lineWidth: 1)
    }
  }
}
