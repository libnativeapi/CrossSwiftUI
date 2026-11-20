import SwiftUI

// MARK: - 1. Shopping Cart & Checkout Flow

private struct CartItem: Identifiable {
  let id: Int
  let name: String
  let subtitle: String
  let unitPrice: Int
  var quantity: Int
}

struct ShoppingCartGalleryView: View {
  @State private var items: [CartItem] = [
    CartItem(id: 1, name: "Studio Headphones", subtitle: "Midnight · Wireless", unitPrice: 249, quantity: 1),
    CartItem(id: 2, name: "USB-C Braided Cable", subtitle: "2m · Fast Charge", unitPrice: 29, quantity: 2),
    CartItem(id: 3, name: "Magnetic Desk Stand", subtitle: "Anodized Aluminum", unitPrice: 69, quantity: 1),
  ]
  @State private var promoCode = ""
  @State private var expressShipping = false
  @State private var showOrderAlert = false
  @State private var lastOrderSummary = ""

  private var itemCount: Int {
    items.reduce(0) { $0 + $1.quantity }
  }

  private var subtotal: Int {
    items.reduce(0) { $0 + $1.unitPrice * $1.quantity }
  }

  private var promoApplied: Bool {
    promoCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "SAVE10"
  }

  private var discount: Int {
    promoApplied ? (subtotal * 10) / 100 : 0
  }

  private var shippingFee: Int {
    if itemCount == 0 { return 0 }
    return expressShipping ? 15 : 0
  }

  private var total: Int {
    max(0, subtotal - discount + shippingFee)
  }

  var body: some View {
    List {
      Section("Cart Items (\(itemCount))") {
        ForEach(items.indices, id: \.self) { index in
          VStack(alignment: .leading, spacing: 6) {
            HStack {
              VStack(alignment: .leading, spacing: 2) {
                Text(items[index].name)
                  .font(.headline)
                Text("\(items[index].subtitle) · $\(items[index].unitPrice)")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              Spacer()
              Text("$\(items[index].unitPrice * items[index].quantity)")
                .font(.subheadline.weight(.semibold))
            }
            Stepper("Qty: \(items[index].quantity)", value: $items[index].quantity, in: 0...10)
          }
          .padding(.vertical, 2)
        }
      }

      Section("Options & Promo") {
        TextField("Promo code (try SAVE10)", text: $promoCode)
        if promoApplied {
          Text("SAVE10 applied: 10% off subtotal")
            .font(.caption)
            .foregroundStyle(.green)
        }
        Toggle("Express Shipping (+$15)", isOn: $expressShipping)
      }

      Section("Order Summary") {
        HStack {
          Text("Subtotal")
          Spacer()
          Text("$\(subtotal)")
            .foregroundStyle(.secondary)
        }
        if discount > 0 {
          HStack {
            Text("Discount (10%)")
            Spacer()
            Text("-$\(discount)")
              .foregroundStyle(.green)
          }
        }
        HStack {
          Text("Shipping")
          Spacer()
          Text(shippingFee == 0 ? "Free" : "$\(shippingFee)")
            .foregroundStyle(.secondary)
        }
        HStack {
          Text("Total")
            .font(.headline)
          Spacer()
          Text("$\(total)")
            .font(.headline)
            .foregroundStyle(.blue)
        }
      }

      Section {
        HStack(spacing: 12) {
          Button("Place Order ($\(total))") {
            lastOrderSummary = "\(itemCount) item(s) · Total $\(total)\(expressShipping ? " (Express)" : " (Standard)")"
            showOrderAlert = true
          }
          .buttonStyle(.borderedProminent)
          .disabled(itemCount == 0)

          Spacer()

          Button("Reset") {
            items[0].quantity = 1
            items[1].quantity = 2
            items[2].quantity = 1
            promoCode = ""
            expressShipping = false
          }
          .buttonStyle(.bordered)
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Shopping Cart")
    .alert("Order Placed", isPresented: $showOrderAlert) {
      Button("Clear Cart") {
        for idx in items.indices { items[idx].quantity = 0 }
      }
      Button("Keep Items", role: .cancel) {}
    } message: {
      Text(lastOrderSummary)
    }
  }
}

// MARK: - 2. Task Manager Flow

private struct TaskEntry: Identifiable {
  let id: Int
  let title: String
  let tag: String
  var isDone: Bool
}

struct TaskManagerGalleryView: View {
  @State private var newTaskTitle = ""
  @State private var filter = 0
  @State private var nextTaskID = 5
  @State private var showClearAlert = false
  @State private var tasks: [TaskEntry] = [
    TaskEntry(id: 1, title: "Review iOS 27 Liquid Glass tokens", tag: "Design", isDone: true),
    TaskEntry(id: 2, title: "Verify Android NavHost back sync", tag: "Android", isDone: true),
    TaskEntry(id: 3, title: "Test HarmonyOS ArkUI Navigation", tag: "Harmony", isDone: false),
    TaskEntry(id: 4, title: "Publish interactive gallery build", tag: "Release", isDone: false),
  ]

  private var completedCount: Int {
    tasks.filter(\.isDone).count
  }

  private var completionRatio: Double {
    guard !tasks.isEmpty else { return 0 }
    return Double(completedCount) / Double(tasks.count)
  }

  private var visibleIndices: [Int] {
    tasks.indices.filter { idx in
      switch filter {
      case 1: return !tasks[idx].isDone
      case 2: return tasks[idx].isDone
      default: return true
      }
    }
  }

  var body: some View {
    List {
      Section("Progress") {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("\(completedCount) of \(tasks.count) Completed")
              .font(.subheadline.weight(.semibold))
            Spacer()
            Text("\(Int((completionRatio * 100).rounded()))%")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          ProgressView(value: completionRatio)
            .tint(.green)
        }
      }

      Section("New Task") {
        TextField("What needs to be done?", text: $newTaskTitle)
        HStack {
          Button("Add Task") {
            let trimmed = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            tasks.insert(TaskEntry(id: nextTaskID, title: trimmed, tag: "Custom", isDone: false), at: 0)
            nextTaskID += 1
            newTaskTitle = ""
          }
          .buttonStyle(.borderedProminent)
          .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

          Spacer()

          Button("Clear Done", role: .destructive) {
            showClearAlert = true
          }
          .buttonStyle(.bordered)
          .disabled(completedCount == 0)
        }
      }

      Section("Tasks (\(visibleIndices.count))") {
        Picker("", selection: $filter) {
          Text("All").tag(0)
          Text("Active").tag(1)
          Text("Done").tag(2)
        }
        .pickerStyle(.segmented)
        .labelsHidden()

        if visibleIndices.isEmpty {
          Text("No tasks in this filter.")
            .foregroundStyle(.secondary)
        } else {
          ForEach(visibleIndices, id: \.self) { index in
            HStack(spacing: 12) {
              Button {
                tasks[index].isDone.toggle()
              } label: {
                Image(systemName: tasks[index].isDone ? "checkmark.circle" : "circle")
                  .foregroundStyle(tasks[index].isDone ? .green : .secondary)
                  .frame(width: 22, height: 22)
              }
              .buttonStyle(.plain)

              VStack(alignment: .leading, spacing: 2) {
                Text(tasks[index].title)
                  .foregroundStyle(tasks[index].isDone ? .secondary : .primary)
                Text(tasks[index].tag)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }

              Spacer()

              Button {
                tasks.remove(at: index)
              } label: {
                Image(systemName: "trash")
                  .foregroundStyle(.red)
                  .frame(width: 18, height: 18)
              }
              .buttonStyle(.plain)
            }
            .padding(.vertical, 2)
          }
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Task Manager")
    .alert("Clear Completed Tasks", isPresented: $showClearAlert) {
      Button("Clear \(completedCount)", role: .destructive) {
        tasks.removeAll(where: \.isDone)
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Remove all completed tasks from the list?")
    }
  }
}

// MARK: - 3. Sign Up Form Validation Flow

struct SignUpFormGalleryView: View {
  @State private var fullName = ""
  @State private var email = ""
  @State private var password = ""
  @State private var roleIndex = 0
  @State private var acceptTerms = false
  @State private var marketingEmails = true
  @State private var showSubmittedAlert = false

  private let roles = ["Developer", "Designer", "Product Manager", "Founder"]

  private var isNameValid: Bool {
    !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private var isEmailValid: Bool {
    let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.contains("@") && trimmed.contains(".")
  }

  private var isPasswordValid: Bool {
    password.count >= 6
  }

  private var passwordStrength: Double {
    min(1.0, Double(password.count) / 10.0)
  }

  private var canSubmit: Bool {
    isNameValid && isEmailValid && isPasswordValid && acceptTerms
  }

  var body: some View {
    List {
      Section("Account Details") {
        TextField("Full Name", text: $fullName)
        TextField("Email Address", text: $email)
        SecureField("Password (6+ characters)", text: $password)

        VStack(alignment: .leading, spacing: 6) {
          HStack {
            Text("Password Strength")
              .font(.caption)
              .foregroundStyle(.secondary)
            Spacer()
            Text(password.count >= 10 ? "Strong" : (password.count >= 6 ? "Good" : "Too Short"))
              .font(.caption.weight(.semibold))
              .foregroundStyle(password.count >= 10 ? .green : (password.count >= 6 ? .orange : .secondary))
          }
          ProgressView(value: passwordStrength)
            .tint(password.count >= 10 ? .green : (password.count >= 6 ? .orange : .red))
        }
      }

      Section("Profile") {
        Picker("Role", selection: $roleIndex) {
          ForEach(roles.indices, id: \.self) { idx in
            Text(roles[idx]).tag(idx)
          }
        }
        .pickerStyle(.menu)

        Toggle("Accept Terms of Service", isOn: $acceptTerms)
        Toggle("Product Updates Newsletter", isOn: $marketingEmails)
      }

      Section("Validation Checklist") {
        validationRow("Full name provided", passed: isNameValid)
        validationRow("Valid email address", passed: isEmailValid)
        validationRow("Password at least 6 characters", passed: isPasswordValid)
        validationRow("Terms of Service accepted", passed: acceptTerms)
      }

      Section {
        Button("Create Account") {
          showSubmittedAlert = true
        }
        .buttonStyle(.borderedProminent)
        .disabled(!canSubmit)
        .frame(maxWidth: .infinity)
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Sign Up Form")
    .alert("Account Created", isPresented: $showSubmittedAlert) {
      Button("Reset Form") {
        fullName = ""
        email = ""
        password = ""
        roleIndex = 0
        acceptTerms = false
      }
      Button("Done", role: .cancel) {}
    } message: {
      Text("Welcome, \(fullName) (\(roles[roleIndex])) · \(email)")
    }
  }

  private func validationRow(_ label: String, passed: Bool) -> some View {
    HStack(spacing: 10) {
      Image(systemName: passed ? "checkmark.circle" : "circle")
        .foregroundStyle(passed ? .green : .secondary)
        .frame(width: 18, height: 18)
      Text(label)
        .font(.subheadline)
        .foregroundStyle(passed ? .primary : .secondary)
    }
  }
}
