import SwiftUI

enum KanbanColumn: String, CaseIterable, Identifiable {
  case backlog = "Backlog"
  case inProgress = "In Progress"
  case review = "In Review"
  case done = "Done"

  var id: String { rawValue }

  var tint: Color {
    switch self {
    case .backlog: return .gray
    case .inProgress: return .blue
    case .review: return .orange
    case .done: return .green
    }
  }
}

enum TaskPriority: String, CaseIterable, Identifiable {
  case high = "High"
  case medium = "Medium"
  case low = "Low"

  var id: String { rawValue }

  var color: Color {
    switch self {
    case .high: return .red
    case .medium: return .orange
    case .low: return .teal
    }
  }
}

struct KanbanTask: Identifiable {
  let id: UUID
  var title: String
  var detail: String
  var tag: String
  var priority: TaskPriority
  var column: KanbanColumn

  init(
    id: UUID = UUID(),
    title: String,
    detail: String,
    tag: String,
    priority: TaskPriority,
    column: KanbanColumn
  ) {
    self.id = id
    self.title = title
    self.detail = detail
    self.tag = tag
    self.priority = priority
    self.column = column
  }
}

@main
struct KanbanBoardApp: App {
  var body: some Scene {
    WindowGroup("Kanban Board") {
      KanbanBoardView()
    }
    .defaultSize(width: 1120, height: 680)
  }
}

struct KanbanBoardView: View {
  @State private var tasks: [KanbanTask] = [
    KanbanTask(title: "Design dark mode tokens", detail: "Verify contrast ratios on Windows and Linux.", tag: "Design", priority: .high, column: .backlog),
    KanbanTask(title: "Add keyboard shortcuts", detail: "Support ⌘N and arrow navigation.", tag: "UX", priority: .medium, column: .backlog),
    KanbanTask(title: "Implement macOS Popover", detail: "Unified bubble path with 4-edge arrow beak.", tag: "Runtime", priority: .high, column: .inProgress),
    KanbanTask(title: "Optimize Grid column sizing", detail: "Measure ideal column widths before shrinking.", tag: "Layout", priority: .medium, column: .inProgress),
    KanbanTask(title: "Audit ScrollView hit-testing", detail: "Prevent hollow stroked borders from blocking wheel input.", tag: "Runtime", priority: .high, column: .review),
    KanbanTask(title: "Ship DesktopUIGallery", detail: "Verify Release builds on macOS, Windows, and Linux.", tag: "Examples", priority: .low, column: .done),
  ]

  @State private var showFilterPopover = false
  @State private var priorityFilter: TaskPriority? = nil
  @State private var showNewTaskSheet = false
  @State private var draftTitle = ""
  @State private var draftDetail = ""
  @State private var draftTag = "Feature"
  @State private var draftPriority: TaskPriority = .medium
  @State private var draftColumn: KanbanColumn = .backlog
  @State private var darkMode = false

  private func tasksFor(_ column: KanbanColumn) -> [KanbanTask] {
    tasks.filter { task in
      task.column == column && (priorityFilter == nil || task.priority == priorityFilter)
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 12) {
        HStack(spacing: 8) {
          Image(systemName: "rectangle.3.group")
            .foregroundStyle(Color.indigo)
            .frame(width: 20, height: 20)
          VStack(alignment: .leading, spacing: 2) {
            Text("Kanban Board")
              .font(.system(size: 18, weight: .bold))
            Text("Right-click any card to move across lanes, or use New Task & Filter.")
              .font(.system(size: 12))
              .foregroundStyle(.secondary)
          }
        }

        Spacer()

        Button(priorityFilter.map { "Filter: \($0.rawValue)" } ?? "Filter") {
          showFilterPopover.toggle()
        }
        .buttonStyle(.bordered)
        .popover(isPresented: $showFilterPopover, arrowEdge: .top) {
          VStack(alignment: .leading, spacing: 10) {
            Text("Filter by Priority")
              .font(.system(size: 13, weight: .bold))
            Button("All Priorities") {
              priorityFilter = nil
              showFilterPopover = false
            }
            .buttonStyle(.bordered)
            ForEach(TaskPriority.allCases) { p in
              Button(p.rawValue) {
                priorityFilter = p
                showFilterPopover = false
              }
              .buttonStyle(.bordered)
            }
          }
          .padding(14)
          .frame(width: 190)
        }

        Button("New Task") {
          draftTitle = ""
          draftDetail = ""
          showNewTaskSheet = true
        }
        .buttonStyle(.borderedProminent)
        .keyboardShortcut("n", modifiers: .command)

        Toggle("Dark", isOn: $darkMode)
          .toggleStyle(.switch)
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 14)

      Divider()

      ScrollView(.horizontal) {
        HStack(alignment: .top, spacing: 16) {
          ForEach(KanbanColumn.allCases) { column in
            laneView(for: column)
          }
        }
        .padding(20)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(darkMode ? Color(red: 0.10, green: 0.10, blue: 0.12) : Color.white)
    .preferredColorScheme(darkMode ? .dark : .light)
    .sheet(isPresented: $showNewTaskSheet) {
      VStack(alignment: .leading, spacing: 14) {
        Text("Create Task")
          .font(.system(size: 18, weight: .bold))
        TextField("Task title", text: $draftTitle)
          .textFieldStyle(.roundedBorder)
        TextField("Description", text: $draftDetail)
          .textFieldStyle(.roundedBorder)
        HStack(spacing: 12) {
          Picker("Priority", selection: $draftPriority) {
            ForEach(TaskPriority.allCases) { p in
              Text(p.rawValue).tag(p)
            }
          }
          .pickerStyle(.menu)

          Picker("Lane", selection: $draftColumn) {
            ForEach(KanbanColumn.allCases) { c in
              Text(c.rawValue).tag(c)
            }
          }
          .pickerStyle(.menu)
        }
        HStack {
          Spacer()
          Button("Cancel", role: .cancel) { showNewTaskSheet = false }
            .buttonStyle(.bordered)
          Button("Add Task") {
            let title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            if !title.isEmpty {
              tasks.insert(
                KanbanTask(
                  title: title,
                  detail: draftDetail.isEmpty ? "Added from desktop board." : draftDetail,
                  tag: draftTag,
                  priority: draftPriority,
                  column: draftColumn
                ),
                at: 0
              )
            }
            showNewTaskSheet = false
          }
          .buttonStyle(.borderedProminent)
        }
      }
      .padding(24)
      .frame(width: 400)
    }
  }

  private func laneView(for column: KanbanColumn) -> some View {
    let items = tasksFor(column)
    return VStack(alignment: .leading, spacing: 12) {
      HStack {
        Circle()
          .fill(column.tint)
          .frame(width: 9, height: 9)
        Text(column.rawValue)
          .font(.system(size: 14, weight: .bold))
        Spacer()
        Text("\(items.count)")
          .font(.system(size: 11, weight: .semibold))
          .foregroundStyle(.secondary)
          .padding(.horizontal, 8)
          .padding(.vertical, 2)
          .background(Color.gray.opacity(0.16), in: Capsule())
      }

      ScrollView(.vertical) {
        VStack(alignment: .leading, spacing: 10) {
          ForEach(items) { task in
            taskCard(task)
          }
        }
        .padding(.vertical, 2)
      }
    }
    .padding(14)
    .frame(width: 260)
    .frame(maxHeight: .infinity, alignment: .topLeading)
    .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    .overlay {
      RoundedRectangle(cornerRadius: 12)
        .strokeBorder(Color.gray.opacity(0.22), lineWidth: 1)
    }
  }

  private func taskCard(_ task: KanbanTask) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(task.tag)
          .font(.system(size: 10, weight: .semibold))
          .foregroundStyle(Color.indigo)
          .padding(.horizontal, 7)
          .padding(.vertical, 3)
          .background(Color.indigo.opacity(0.14), in: Capsule())
        Spacer()
        Text(task.priority.rawValue)
          .font(.system(size: 10, weight: .semibold))
          .foregroundStyle(task.priority.color)
      }
      Text(task.title)
        .font(.system(size: 13, weight: .semibold))
      Text(task.detail)
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(darkMode ? Color(red: 0.16, green: 0.16, blue: 0.19) : Color.white, in: RoundedRectangle(cornerRadius: 10))
    .overlay {
      RoundedRectangle(cornerRadius: 10)
        .strokeBorder(Color.gray.opacity(0.22), lineWidth: 1)
    }
    .contextMenu {
      ForEach(KanbanColumn.allCases) { target in
        if target != task.column {
          Button("Move to \(target.rawValue)") {
            moveTask(task.id, to: target)
          }
        }
      }
      Divider()
      Button("Delete Task", role: .destructive) {
        tasks.removeAll { $0.id == task.id }
      }
    }
  }

  private func moveTask(_ id: UUID, to column: KanbanColumn) {
    if let idx = tasks.firstIndex(where: { $0.id == id }) {
      tasks[idx].column = column
    }
  }
}
