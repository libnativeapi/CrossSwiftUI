#if canImport(AppKit)
import AppKit
#endif
#if canImport(CryptoKit)
import CryptoKit
#endif
import FluentIcons
import Foundation
import SwiftUI

struct ChecklistItem: Identifiable, Hashable {
  let id: String
  let title: String
  var isDone: Bool
}

struct ContentView: View {
  @State private var noteText = "Zero-config xcodebuild for Windows, Linux, Wasm & HarmonyOS"
  @State private var copiedDigest = false
  @State private var items: [ChecklistItem] = [
    ChecklistItem(id: "pbx", title: "Parse .xcodeproj without extra platform files", isDone: true),
    ChecklistItem(id: "assets", title: "Compile AppIcon, colorset & xcstrings", isDone: true),
    ChecklistItem(id: "ship", title: "Stage self-contained cross-platform bundles", isDone: false),
  ]

  private var remainingCount: Int {
    items.filter { !$0.isDone }.count
  }

  private var digestHex: String {
    #if canImport(CryptoKit)
    let digest = SHA256.hash(data: Data(noteText.utf8))
    return digest.map { String(format: "%02x", $0) }.joined()
    #else
    var h1: UInt64 = 0xcbf2_9ce4_8422_2325
    var h2: UInt64 = 0x8422_2325_cbf2_9ce4
    for byte in noteText.utf8 {
      h1 ^= UInt64(byte)
      h1 &*= 0x0000_0100_0000_01b3
      h2 ^= UInt64(byte) &+ 0x9e37_79b9_7f4a_7c15
      h2 &*= 0x0000_0100_0000_01b3
    }
    let hex1 = String(h1, radix: 16, uppercase: false)
    let hex2 = String(h2, radix: 16, uppercase: false)
    return String(repeating: "0", count: max(0, 16 - hex1.count)) + hex1
      + String(repeating: "0", count: max(0, 16 - hex2.count)) + hex2
    #endif
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(spacing: 12) {
        Image(.heroBadge)
          .resizable()
          .frame(width: 40, height: 40)

        Image(fluent: .home20Regular)
          .resizable()
          .renderingMode(.template)
          .foregroundColor(Color(.brandAccent))
          .frame(width: 24, height: 24)

        VStack(alignment: .leading, spacing: 4) {
          Text("demo.title")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(Color(.brandAccent))
          Text(String(localized: "demo.tasks_remaining \(remainingCount)"))
            .font(.caption)
            .foregroundColor(.secondary)
        }
        Spacer()
      }

      Divider()

      VStack(alignment: .leading, spacing: 8) {
        Text("demo.checklist_header")
          .font(.headline)

        ForEach(items) { item in
          Button {
            if let index = items.firstIndex(where: { $0.id == item.id }) {
              items[index].isDone.toggle()
            }
          } label: {
            HStack(spacing: 8) {
              Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                .foregroundColor(item.isDone ? Color(.brandAccent) : .secondary)
              Text(item.title)
              Spacer()
            }
            .padding(8)
            .background(Color(.brandAccent).opacity(item.isDone ? 0.12 : 0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8))
          }
          .buttonStyle(.plain)
        }
      }

      Divider()

      VStack(alignment: .leading, spacing: 8) {
        Text("demo.digest_header")
          .font(.headline)

        TextField("Enter release note", text: $noteText)

        HStack(spacing: 10) {
          Text(String(digestHex.prefix(32)) + "...")
            .font(.caption)
            .foregroundColor(.secondary)
          Spacer()
          Button(copiedDigest ? "Copied!" : "Copy SHA-256") {
            #if canImport(AppKit)
            NSPasteboard.general.clearContents()
            _ = NSPasteboard.general.setString(digestHex, forType: .string)
            #endif
            copiedDigest = true
          }
        }
      }

      Spacer()
    }
    .padding(20)
  }
}
