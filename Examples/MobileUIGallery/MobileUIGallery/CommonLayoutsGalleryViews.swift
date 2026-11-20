import SwiftUI

// MARK: - 1. Settings Form Layout

struct SettingsLayoutGalleryView: View {
  @State private var airplaneMode = false
  @State private var wifiEnabled = true
  @State private var notificationsEnabled = true
  @State private var backgroundRefresh = true
  @State private var syncFrequency = 1
  @State private var showSignOutAlert = false
  @State private var signedOut = false

  var body: some View {
    List {
      Section {
        HStack(spacing: 14) {
          ZStack {
            Circle()
              .fill(LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
              .frame(width: 52, height: 52)
            Image(systemName: "person")
              .foregroundStyle(.white)
              .frame(width: 24, height: 24)
          }
          VStack(alignment: .leading, spacing: 3) {
            Text(signedOut ? "Guest Account" : "Alex Morgan")
              .font(.headline)
            Text(signedOut ? "Tap Sign In below to restore sync" : "Apple Account, iCloud+, Media & Purchases")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .padding(.vertical, 4)
      }

      Section("Connectivity") {
        Toggle("Airplane Mode", isOn: $airplaneMode)
          .toggleStyle(SwitchToggleStyle(tint: .orange))
        Toggle("Wi-Fi", isOn: $wifiEnabled)
          .disabled(airplaneMode)
        HStack {
          Text("Status")
          Spacer()
          Text(airplaneMode ? "Offline" : (wifiEnabled ? "Connected · 5 GHz" : "Cellular"))
            .foregroundStyle(.secondary)
        }
      }

      Section("Preferences") {
        Toggle("Push Notifications", isOn: $notificationsEnabled)
        Toggle("Background App Refresh", isOn: $backgroundRefresh)
        Picker("Sync Interval", selection: $syncFrequency) {
          Text("15 min").tag(0)
          Text("Hourly").tag(1)
          Text("Manual").tag(2)
        }
        .pickerStyle(.menu)
      }

      Section("Storage") {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("Device Storage")
              .font(.subheadline)
            Spacer()
            Text("86.4 GB of 128 GB")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          ProgressView(value: 0.675)
            .tint(.blue)
          HStack(spacing: 16) {
            Text("Apps 48 GB")
              .font(.caption)
              .foregroundStyle(.blue)
            Text("Photos 26 GB")
              .font(.caption)
              .foregroundStyle(.orange)
            Text("System 12 GB")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }

      Section {
        if signedOut {
          Button("Sign In Again") {
            signedOut = false
          }
          .buttonStyle(.borderedProminent)
          .frame(maxWidth: .infinity)
        } else {
          Button("Sign Out", role: .destructive) {
            showSignOutAlert = true
          }
          .buttonStyle(.borderedProminent)
          .frame(maxWidth: .infinity)
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Settings Form")
    .alert("Sign Out", isPresented: $showSignOutAlert) {
      Button("Sign Out", role: .destructive) {
        signedOut = true
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Local preferences remain on this device until you sign in again.")
    }
  }
}

// MARK: - 2. Card Feed Layout

private struct FeedArticle: Identifiable {
  let id: Int
  let category: Int
  let categoryName: String
  let title: String
  let summary: String
  let author: String
  let readTime: String
  let colors: [Color]
  var likes: Int
  var liked: Bool
  var starred: Bool
}

struct CardFeedLayoutGalleryView: View {
  @State private var selectedCategory = 0
  @State private var articles: [FeedArticle] = [
    FeedArticle(
      id: 1, category: 1, categoryName: "Design",
      title: "Fluid Materials & Depth Hierarchy",
      summary: "Balancing translucency, contrast, and crisp typography across modern mobile surfaces.",
      author: "Maya Lin", readTime: "4 min",
      colors: [.blue, .indigo], likes: 128, liked: false, starred: true
    ),
    FeedArticle(
      id: 2, category: 2, categoryName: "Engineering",
      title: "Cross-Platform Native Navigation",
      summary: "Keeping one SwiftUI source of truth while delegating stack transitions to each OS.",
      author: "Liam Chen", readTime: "6 min",
      colors: [.teal, .blue], likes: 94, liked: true, starred: false
    ),
    FeedArticle(
      id: 3, category: 1, categoryName: "Design",
      title: "Adaptive Controls for Every Screen",
      summary: "Why semantic controls outperform pixel-cloned widgets on Android and HarmonyOS.",
      author: "Nora Patel", readTime: "5 min",
      colors: [.purple, .pink], likes: 76, liked: false, starred: false
    ),
    FeedArticle(
      id: 4, category: 2, categoryName: "Engineering",
      title: "Zero-Copy Layout & Diffing",
      summary: "Incremental tree reconciliation keeps 60fps scrolling smooth on mobile devices.",
      author: "Kenji Sato", readTime: "7 min",
      colors: [.orange, .pink], likes: 152, liked: false, starred: true
    ),
  ]

  private var filteredIndices: [Int] {
    articles.indices.filter { selectedCategory == 0 || articles[$0].category == selectedCategory }
  }

  var body: some View {
    List {
      Section {
        Picker("", selection: $selectedCategory) {
          Text("All").tag(0)
          Text("Design").tag(1)
          Text("Engineering").tag(2)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
      }

      Section("Featured Stories (\(filteredIndices.count))") {
        ForEach(filteredIndices, id: \.self) { index in
          VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .bottomLeading) {
              LinearGradient(
                colors: articles[index].colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
              .frame(height: 112)
              .clipShape(RoundedRectangle(cornerRadius: 14))

              VStack(alignment: .leading, spacing: 4) {
                Text(articles[index].categoryName)
                  .font(.caption.weight(.semibold))
                  .foregroundStyle(.white)
                  .padding(.horizontal, 8)
                  .padding(.vertical, 3)
                  .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 6))
                Text(articles[index].title)
                  .font(.headline)
                  .foregroundStyle(.white)
              }
              .padding(12)
            }

            Text(articles[index].summary)
              .font(.subheadline)
              .foregroundStyle(.secondary)

            HStack(spacing: 12) {
              Text("\(articles[index].author) · \(articles[index].readTime)")
                .font(.caption)
                .foregroundStyle(.secondary)
              Spacer()
              Button {
                articles[index].liked.toggle()
                articles[index].likes += articles[index].liked ? 1 : -1
              } label: {
                HStack(spacing: 4) {
                  Image(systemName: "heart")
                    .foregroundStyle(articles[index].liked ? .pink : .secondary)
                    .frame(width: 15, height: 15)
                  Text("\(articles[index].likes)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(articles[index].liked ? .pink : .secondary)
                }
              }
              .buttonStyle(.plain)

              Button {
                articles[index].starred.toggle()
              } label: {
                Image(systemName: "star")
                  .foregroundStyle(articles[index].starred ? .orange : .secondary)
                  .frame(width: 16, height: 16)
              }
              .buttonStyle(.plain)
            }
          }
          .padding(.vertical, 4)
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Card Feed")
  }
}

// MARK: - 3. Dashboard Grid Layout

struct DashboardLayoutGalleryView: View {
  @State private var rangeIndex = 0
  @State private var dailyGoalProgress = 0.78

  private var activeUsers: String { ["12.4K", "84.2K", "342K"][rangeIndex] }
  private var revenue: String { ["$4,820", "$31.9K", "$142K"][rangeIndex] }
  private var conversion: String { ["4.6%", "5.1%", "4.9%"][rangeIndex] }
  private var avgLatency: String { ["42 ms", "46 ms", "44 ms"][rangeIndex] }
  private var retention: Double { [0.84, 0.79, 0.74][rangeIndex] }
  private var crashFree: Double { [0.996, 0.994, 0.992][rangeIndex] }

  var body: some View {
    List {
      Section("Time Range") {
        Picker("", selection: $rangeIndex) {
          Text("Today").tag(0)
          Text("7 Days").tag(1)
          Text("30 Days").tag(2)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
      }

      Section("Key Metrics") {
        VStack(spacing: 10) {
          HStack(spacing: 10) {
            metricTile(title: "Active Users", value: activeUsers, delta: "+14%", icon: "person", tint: .blue)
            metricTile(title: "Revenue", value: revenue, delta: "+9.2%", icon: "bolt", tint: .green)
          }
          HStack(spacing: 10) {
            metricTile(title: "Conversion", value: conversion, delta: "+0.4%", icon: "chart.bar.fill", tint: .indigo)
            metricTile(title: "P95 Latency", value: avgLatency, delta: "-8 ms", icon: "clock", tint: .orange)
          }
        }
        .padding(.vertical, 4)
      }

      Section("Health & Goals") {
        VStack(alignment: .leading, spacing: 6) {
          HStack {
            Text("Sprint Goal")
            Spacer()
            Text("\(Int((dailyGoalProgress * 100).rounded()))%")
              .foregroundStyle(.secondary)
          }
          ProgressView(value: dailyGoalProgress)
            .tint(.blue)
        }
        VStack(alignment: .leading, spacing: 6) {
          HStack {
            Text("User Retention")
            Spacer()
            Text("\(Int((retention * 100).rounded()))%")
              .foregroundStyle(.secondary)
          }
          ProgressView(value: retention)
            .tint(.green)
        }
        VStack(alignment: .leading, spacing: 6) {
          HStack {
            Text("Crash-Free Sessions")
            Spacer()
            Text("\(String(format: "%.1f", crashFree * 100))%")
              .foregroundStyle(.secondary)
          }
          ProgressView(value: crashFree)
            .tint(.indigo)
        }
        HStack(spacing: 12) {
          Button("+10% Progress") {
            dailyGoalProgress = min(1.0, dailyGoalProgress + 0.1)
          }
          .buttonStyle(.borderedProminent)
          Spacer()
          Button("Reset") {
            dailyGoalProgress = 0.25
          }
          .buttonStyle(.bordered)
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Dashboard Grid")
  }

  private func metricTile(
    title: String,
    value: String,
    delta: String,
    icon: String,
    tint: Color
  ) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Image(systemName: icon)
          .foregroundStyle(tint)
          .frame(width: 16, height: 16)
        Spacer()
        Text(delta)
          .font(.caption.weight(.semibold))
          .foregroundStyle(tint)
      }
      Text(value)
        .font(.title3.weight(.bold))
      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
  }
}

// MARK: - 4. Profile Layout

struct ProfileLayoutGalleryView: View {
  @State private var isFollowing = false
  @State private var followerCount = 1248
  @State private var selectedTab = 0

  var body: some View {
    List {
      Section {
        VStack(spacing: 12) {
          LinearGradient(
            colors: [.indigo, .blue, .teal],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
          .frame(height: 88)
          .clipShape(RoundedRectangle(cornerRadius: 14))

          VStack(spacing: 4) {
            Text("Elena Rostova")
              .font(.title3.weight(.bold))
            Text("@elena.design · San Francisco")
              .font(.caption)
              .foregroundStyle(.secondary)
            Text("Building cross-platform design systems and native mobile interfaces.")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }

          HStack(spacing: 24) {
            statColumn(value: "48", label: "Projects")
            statColumn(value: "\(followerCount)", label: "Followers")
            statColumn(value: "312", label: "Following")
          }
          .padding(.vertical, 4)

          HStack(spacing: 12) {
            if isFollowing {
              Button("Following") {
                isFollowing = false
                followerCount -= 1
              }
              .buttonStyle(.bordered)
            } else {
              Button("Follow") {
                isFollowing = true
                followerCount += 1
              }
              .buttonStyle(.borderedProminent)
            }
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
      }

      Section {
        Picker("", selection: $selectedTab) {
          Text("Overview").tag(0)
          Text("Activity").tag(1)
          Text("Saved").tag(2)
        }
        .pickerStyle(.segmented)
        .labelsHidden()

        if selectedTab == 0 {
          HStack {
            Text("Primary Stack")
            Spacer()
            Text("SwiftUI · Compose · ArkUI")
              .foregroundStyle(.secondary)
          }
          HStack {
            Text("Availability")
            Spacer()
            Text("Open for Reviews")
              .foregroundStyle(.green)
          }
        } else if selectedTab == 1 {
          Text("Published NavigationStack native transition guide · 2h ago")
            .font(.subheadline)
          Text("Updated Material 3 ListItem slot mapping · Yesterday")
            .font(.subheadline)
        } else {
          Text("Saved: Fluid Materials & Depth Hierarchy")
            .font(.subheadline)
          Text("Saved: Zero-Copy Layout & Diffing")
            .font(.subheadline)
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Profile")
  }

  private func statColumn(value: String, label: String) -> some View {
    VStack(spacing: 2) {
      Text(value)
        .font(.headline)
      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}
