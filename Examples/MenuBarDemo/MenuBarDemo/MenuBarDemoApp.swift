import SwiftUI

final class FocusTimerModel: ObservableObject {
  @Published var remainingSeconds: Int = 25 * 60
  @Published var totalSeconds: Int = 25 * 60
  @Published var isRunning: Bool = false
  @Published var completedSessions: Int = 2
  @Published var doNotDisturb: Bool = true
  @Published var playSoundOnFinish: Bool = true
  @Published var quickMemo: String = "Finish cross-platform SwiftUI examples"

  var progress: Double {
    guard totalSeconds > 0 else { return 0 }
    return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
  }

  var formattedTime: String {
    let mins = remainingSeconds / 60
    let secs = remainingSeconds % 60
    return String(format: "%02d:%02d", mins, secs)
  }

  func selectPreset(minutes: Int) {
    isRunning = false
    totalSeconds = minutes * 60
    remainingSeconds = minutes * 60
  }

  func tick() {
    guard isRunning else { return }
    if remainingSeconds > 0 {
      remainingSeconds -= 1
    } else {
      isRunning = false
      completedSessions += 1
      remainingSeconds = totalSeconds
    }
  }
}

@main
struct MenuBarDemoApp: App {
  @StateObject private var timer = FocusTimerModel()

  var body: some Scene {
    WindowGroup("Focus Timer") {
      FocusPanelView(timer: timer)
        .frame(minWidth: 380, minHeight: 440)
    }
    .defaultSize(width: 400, height: 480)

    MenuBarExtra("Focus Timer", systemImage: "clock") {
      FocusPanelView(timer: timer)
        .frame(width: 320)
    }
  }
}

struct FocusPanelView: View {
  @ObservedObject var timer: FocusTimerModel
  @State private var darkMode = false

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      HStack {
        HStack(spacing: 8) {
          Image(systemName: "clock")
            .foregroundStyle(Color.indigo)
            .frame(width: 18, height: 18)
          Text("Focus Timer")
            .font(.system(size: 16, weight: .bold))
        }
        Spacer()
        Toggle("Dark", isOn: $darkMode)
          .toggleStyle(.switch)
      }

      ZStack {
        Circle()
          .stroke(Color.gray.opacity(0.22), lineWidth: 10)
        Circle()
          .trim(from: 0, to: max(0.02, timer.progress))
          .stroke(
            timer.isRunning ? Color.indigo : Color.blue,
            style: StrokeStyle(lineWidth: 10, lineCap: .round)
          )
          .rotationEffect(.degrees(-90))
        VStack(spacing: 4) {
          Text(timer.formattedTime)
            .font(.system(size: 32, weight: .bold))
          Text(timer.isRunning ? "Focusing…" : "Paused")
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
      }
      .frame(width: 156, height: 156)
      .frame(maxWidth: .infinity)
      .task(id: timer.isRunning) {
        while timer.isRunning && !Task.isCancelled {
          try? await Task.sleep(nanoseconds: 1_000_000_000)
          if !Task.isCancelled {
            timer.tick()
          }
        }
      }

      HStack(spacing: 10) {
        Button(timer.isRunning ? "Pause" : "Start Focus") {
          timer.isRunning.toggle()
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)

        Button("Reset") {
          timer.isRunning = false
          timer.remainingSeconds = timer.totalSeconds
        }
        .buttonStyle(.bordered)
      }

      HStack(spacing: 8) {
        Button("15m") { timer.selectPreset(minutes: 15) }
          .buttonStyle(.bordered)
        Button("25m") { timer.selectPreset(minutes: 25) }
          .buttonStyle(.bordered)
        Button("45m") { timer.selectPreset(minutes: 45) }
          .buttonStyle(.bordered)
        Spacer()
        Text("Sessions: \(timer.completedSessions)")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(.secondary)
      }

      Divider()

      VStack(alignment: .leading, spacing: 8) {
        Text("Current Task")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(.secondary)
        TextField("What are you working on?", text: $timer.quickMemo)
          .textFieldStyle(.roundedBorder)
        Toggle("Enable Do Not Disturb", isOn: $timer.doNotDisturb)
          .toggleStyle(.checkbox)
        Toggle("Play chime when finished", isOn: $timer.playSoundOnFinish)
          .toggleStyle(.checkbox)
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(darkMode ? Color(red: 0.11, green: 0.11, blue: 0.13) : Color.white)
    .preferredColorScheme(darkMode ? .dark : .light)
  }
}
