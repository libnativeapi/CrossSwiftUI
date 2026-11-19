import AppKit
import CryptoKit
import Foundation
import SwiftUI

struct ChecklistItem: Identifiable, Hashable {
  let id: String
  let title: String
  var isDone: Bool
}

struct ContentView: View {
  @State private var noteText = "Zero-config xcodebuild for Windows & Linux"
  @State private var copiedDigest = false
  @State private var items: [ChecklistItem] = [
    ChecklistItem(id: "pbx", title: "Parse .xcodeproj without extra platform files", isDone: true),
    ChecklistItem(id: "assets", title: "Compile AppIcon, colorset & xcstrings", isDone: true),
    ChecklistItem(id: "ship", title: "Stage self-contained Windows & Linux app bundles", isDone: false),
  ]

  private var remainingCount: Int {
    items.filter { !$0.isDone }.count
  }

  private var digestHex: String {
    let digest = SHA256.hash(data: Data(noteText.utf8))
    return digest.map { String(format: "%02x", $0) }.joined()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(spacing: 12) {
        Image(.heroBadge)
          .resizable()
          .frame(width: 40, height: 40)

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
            NSPasteboard.general.clearContents()
            _ = NSPasteboard.general.setString(digestHex, forType: .string)
            copiedDigest = true
          }
        }
      }

      Spacer()
    }
    .padding(20)
  }
}
