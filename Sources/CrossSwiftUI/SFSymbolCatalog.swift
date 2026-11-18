import Foundation

nonisolated(unsafe) private var didRegisterBuiltinSymbols = false

internal func ensureBuiltinSFSymbolsRegistered() {
  guard !didRegisterBuiltinSymbols else { return }
  didRegisterBuiltinSymbols = true

  let circle = "M12 2a10 10 0 1 0 0 20 10 10 0 1 0 0-20Z"
  let docBase = "M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8Zm0 0v6h6"
  let winBase = "M3 5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Zm0 4h18"
  let cloudBase = "M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"

  let outlineSymbols: [String: [String]] = [
    "circle": [circle],
    "accessibility": [circle, "M12 7v1m-4 2h8m-4 0v4m-2 4 2-4 2 4"],
    "antenna.radiowaves.left.and.right": [
      "M12 12v8", "M12 12a1 1 0 1 0 0-2 1 1 0 0 0 0 2Z",
      "M8.5 8.5a5 5 0 0 0 0 7", "M15.5 8.5a5 5 0 0 1 0 7",
      "M5.5 5.5a9 9 0 0 0 0 13", "M18.5 5.5a9 9 0 0 1 0 13",
    ],
    "antenna.radiowaves.left.and.right.slash": [
      "M12 12v8", "M8.5 8.5a5 5 0 0 0 0 7", "M15.5 8.5a5 5 0 0 1 0 7", "M3 3l18 18",
    ],
    "apple.intelligence": [
      "M12 3l2.2 5.8L20 11l-5.8 2.2L12 19l-2.2-5.8L4 11l5.8-2.2Z",
      "M19 3v4m-2-2h4",
    ],
    "arrow.clockwise": ["M21 12a9 9 0 1 1-2.64-6.36L21 8", "M21 3v5h-5"],
    "arrow.counterclockwise": ["M3 12a9 9 0 1 0 2.64-6.36L3 8", "M3 3v5h5"],
    "arrow.down": ["M12 5v14", "M19 12l-7 7-7-7"],
    "arrow.down.circle": [circle, "M12 8v8", "M8 12l4 4 4-4"],
    "arrow.down.circle.fill": [circle, "M12 8v8", "M8 12l4 4 4-4"],
    "arrow.down.doc": [docBase, "M12 11v6", "M9.5 14.5 12 17l2.5-2.5"],
    "arrow.right": ["M5 12h14", "M12 5l7 7-7 7"],
    "arrow.turn.down.right": ["M6 4v9a3 3 0 0 0 3 3h10", "M15 12l4 4-4 4"],
    "arrow.up": ["M12 19V5", "M5 12l7-7 7 7"],
    "arrow.up.forward.app": [
      "M21 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h6",
      "M21 3l-9 9", "M15 3h6v6",
    ],
    "arrow.up.right": ["M7 17L17 7", "M7 7h10v10"],
    "arrow.uturn.backward": ["M9 14 4 9l5-5", "M4 9h10.5a5.5 5.5 0 0 1 0 11H11"],
    "bold": ["M6 4h8a4 4 0 0 1 4 4 4 4 0 0 1-4 4H6Z", "M6 12h9a4 4 0 0 1 4 4 4 4 0 0 1-4 4H6Z"],
    "book": ["M4 19.5A2.5 2.5 0 0 1 6.5 17H20", "M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2Z"],
    "brain": [
      "M12 5a3 3 0 1 0-5.997.125 4 4 0 0 0-2.526 5.77 4 4 0 0 0 .556 6.588A4 4 0 1 0 12 18Z",
      "M12 5a3 3 0 1 1 5.997.125 4 4 0 0 1 2.526 5.77 4 4 0 0 1-.556 6.588A4 4 0 1 1 12 18Z",
    ],
    "bubble.left.and.bubble.right": [
      "M14 9a2 2 0 0 1-2 2H6l-4 4V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2Z",
      "M18 9h2a2 2 0 0 1 2 2v11l-4-4h-6a2 2 0 0 1-2-2v-1",
    ],
    "bubble.left.fill": ["M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2Z"],
    "calendar": ["M3 6a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z", "M16 2v4M8 2v4M3 10h18"],
    "calendar.badge.exclamationmark": [
      "M21 10V6a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h8",
      "M16 2v4M8 2v4M3 10h18", "M19 15v3m0 3h.01",
    ],
    "calendar.day.timeline.left": [
      "M3 6a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z",
      "M8 2v4m8-4v4M3 10h18M8 14h8M8 18h5",
    ],
    "character.cursor.ibeam": ["M16 4h4m-2 0v16m-2 0h4", "M5 18l3.5-10L12 18m-5.5-3h4"],
    "chart.line.uptrend.xyaxis": ["M3 3v18h18", "M19 9l-5 5-4-4-3 3", "M15 9h4v4"],
    "checklist": ["M3.5 5.5 5 7l2.5-2.5", "M3.5 11.5 5 13l2.5-2.5", "M3.5 17.5 5 19l2.5-2.5", "M11 6h9M11 12h9M11 18h9"],
    "checkmark": ["M20 6 9 17l-5-5"],
    "checkmark.circle": [circle, "M9 12l2 2 4-4"],
    "checkmark.circle.fill": [circle, "M9 12l2 2 4-4"],
    "checkmark.icloud.fill": [cloudBase, "M9.5 14l2 2 3.5-3.5"],
    "chevron.backward": ["M15 18l-6-6 6-6"],
    "chevron.down": ["M6 9l6 6 6-6"],
    "chevron.forward": ["M9 18l6-6-6-6"],
    "chevron.left": ["M15 18l-6-6 6-6"],
    "chevron.left.forwardslash.chevron.right": ["M16 18l6-6-6-6", "M8 6l-6 6 6 6", "M14.5 4l-5 16"],
    "chevron.right": ["M9 18l6-6-6-6"],
    "chevron.up": ["M18 15l-6-6-6 6"],
    "clock": [circle, "M12 6v6l4 2"],
    "clock.arrow.circlepath": ["M3 12a9 9 0 1 0 3-6.7L3 8", "M3 3v5h5", "M12 7v5l3 2"],
    "clock.arrow.trianglehead.2.counterclockwise.rotate.90": [
      "M3 12a9 9 0 1 0 3-6.7L3 8", "M3 3v5h5", "M12 7v5l3 2",
    ],
    "command": [
      "M18 3a3 3 0 0 0-3 3v12a3 3 0 0 0 3 3 3 3 0 0 0 3-3 3 3 0 0 0-3-3H6a3 3 0 0 0-3 3 3 3 0 0 0 3 3 3 3 0 0 0 3-3V6a3 3 0 0 0-3-3 3 3 0 0 0-3 3 3 3 0 0 0 3 3h12a3 3 0 0 0 3-3 3 3 0 0 0-3-3Z"
    ],
    "curlybraces": ["M8 3H7a2 2 0 0 0-2 2v5a2 2 0 0 1-2 2 2 2 0 0 1 2 2v5c0 1.1.9 2 2 2h1", "M16 21h1a2 2 0 0 0 2-2v-5c0-1.1.9-2 2-2a2 2 0 0 1-2-2V5a2 2 0 0 0-2-2h-1"],
    "doc": [docBase],
    "doc.badge.exclamationmark": [docBase, "M12 11v4m0 3h.01"],
    "doc.badge.gearshape": [docBase, "M12 15a2 2 0 1 0 0-4 2 2 0 0 0 0 4Z"],
    "doc.on.clipboard": [
      "M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2",
      "M9 2h6a1 1 0 0 1 1 1v2a1 1 0 0 1-1 1H9a1 1 0 0 1-1-1V3a1 1 0 0 1 1-1Z",
    ],
    "doc.on.doc": [
      "M8 8V4a2 2 0 0 1 2-2h8l4 4v10a2 2 0 0 1-2 2h-4",
      "M4 10a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2Z",
    ],
    "doc.on.doc.fill": [
      "M8 8V4a2 2 0 0 1 2-2h8l4 4v10a2 2 0 0 1-2 2h-4",
      "M4 10a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2Z",
    ],
    "doc.text": [docBase, "M8 13h8M8 17h8M8 9h2"],
    "doc.text.viewfinder": [
      "M3 7V5a2 2 0 0 1 2-2h2M17 3h2a2 2 0 0 1 2 2v2M21 17v2a2 2 0 0 1-2 2h-2M7 21H5a2 2 0 0 1-2-2v-2",
      "M8 9h8M8 13h8M8 17h5",
    ],
    "door.left.hand.open": ["M13 4h3a2 2 0 0 1 2 2v14", "M2 20h3", "M13 20h9", "M10 12v.01", "M13 4.562v16.157a1 1 0 0 1-1.242.97L5 20V5.562a2 2 0 0 1 1.515-1.94l4-1A2 2 0 0 1 13 4.561Z"],
    "exclamationmark": ["M12 5v9", "M12 19h.01"],
    "exclamationmark.icloud": [cloudBase, "M12 11v4m0 3h.01"],
    "exclamationmark.icloud.fill": [cloudBase, "M12 11v4m0 3h.01"],
    "exclamationmark.triangle": ["M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0Z", "M12 9v4m0 4h.01"],
    "exclamationmark.triangle.fill": ["M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0Z", "M12 9v4m0 4h.01"],
    "externaldrive": ["M22 12H2", "M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11Z", "M6 16h.01M10 16h.01"],
    "eye": ["M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z", "M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z"],
    "eye.slash": ["M9.88 9.88a3 3 0 1 0 4.24 4.24", "M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68", "M6.61 6.61A13.526 13.526 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61", "M2 2l20 20"],
    "face.smiling": [circle, "M8 14s1.5 2 4 2 4-2 4-2", "M9 9h.01M15 9h.01"],
    "folder": ["M4 20h16a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.93a2 2 0 0 1-1.66-.9l-.82-1.2A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13c0 1.1.9 2 2 2Z"],
    "gearshape": [
      "M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z",
      "M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1Z",
    ],
    "globe": [circle, "M2 12h20", "M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10Z"],
    "hammer": ["M15 12l-8.5 8.5c-.83.83-2.17.83-3 0 0 0 0 0 0 0a2.12 2.12 0 0 1 0-3L12 9", "M17.64 15 22 10.64", "M20.91 11.7l-1.25-1.25c-.6-.6-.93-1.4-.93-2.25v-.86L16.01 4.6a5.56 5.56 0 0 0-3.94-1.64H9l.92.82A6.18 6.18 0 0 1 12 8.4v1.56l2 2h2.47l2.26 1.91"],
    "heart": ["M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"],
    "icloud.slash": [cloudBase, "M2 2l20 20"],
    "info.circle": [circle, "M12 16v-4m0-4h.01"],
    "internaldrive": ["M4 4h16a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2Z", "M2 14h20", "M6 17h.01"],
    "internaldrive.fill": ["M4 4h16a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2Z", "M2 14h20", "M6 17h.01"],
    "italic": ["M19 4h-9M14 20H5M15 4 9 20"],
    "key": ["M21 2l-2 2m-7.61 7.61a5.5 5.5 0 1 1-7.778 7.778 5.5 5.5 0 0 1 7.777-7.777Zm0 0L15.5 7.5m0 0 3 3L22 7l-3-3m-3.5 3.5L19 4"],
    "keyboard": ["M2 6a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2Z", "M6 8h.01M10 8h.01M14 8h.01M18 8h.01M6 12h.01M10 12h.01M14 12h.01M18 12h.01M8 16h8"],
    "link": ["M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71", "M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"],
    "list.bullet": ["M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01"],
    "list.bullet.rectangle": ["M3 5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z", "M7 8h.01M11 8h6M7 12h.01M11 12h6M7 16h.01M11 16h6"],
    "list.number": ["M10 6h11M10 12h11M10 18h11M4 6h1v4M4 10h2M6 18H4c0-1 2-2 2-3s-1-1.5-2-1"],
    "lock.fill": ["M5 11h14a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2Z", "M7 11V7a5 5 0 0 1 10 0v4"],
    "lock.shield": ["M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10Z", "M12 11v3"],
    "macwindow": [winBase],
    "macwindow.and.cursorarrow": [winBase, "M13 13l6 2-2.5 1.5L15 19Z"],
    "macwindow.badge.plus": [winBase, "M12 12v6m-3-3h6"],
    "macwindow.on.rectangle": [
      "M7 7V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2h-2",
      "M3 9a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z",
    ],
    "magnifyingglass": ["M11 19a8 8 0 1 0 0-16 8 8 0 0 0 0 16Z", "M21 21l-4.35-4.35"],
    "mappin.and.ellipse": ["M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z", "M12 13a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z"],
    "menubar.rectangle": ["M3 5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z", "M3 8h18", "M7 5.5h.01M10 5.5h.01"],
    "mic.fill": ["M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z", "M19 10v2a7 7 0 0 1-14 0v-2", "M12 19v3"],
    "minus": ["M5 12h14"],
    "minus.circle": [circle, "M8 12h8"],
    "minus.circle.fill": [circle, "M8 12h8"],
    "minus.magnifyingglass": ["M11 19a8 8 0 1 0 0-16 8 8 0 0 0 0 16Z", "M21 21l-4.35-4.35", "M8 11h6"],
    "minus.rectangle": ["M3 5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z", "M8 12h8"],
    "network": [circle, "M2 12h20", "M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10Z"],
    "note.text": ["M4 4a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v12l-4 4H6a2 2 0 0 1-2-2Z", "M8 8h8M8 12h8M8 16h5"],
    "paperclip": ["M21.44 11.05l-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48"],
    "pause.circle": [circle, "M10 15V9M14 15V9"],
    "pencil": ["M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"],
    "person.crop.circle": [circle, "M12 13a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z", "M6.5 18.5a6 6 0 0 1 11 0"],
    "photo": ["M3 5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z", "M8.5 10a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3Z", "M21 15l-5-5L5 21"],
    "pin": ["M12 17v5", "M9 10.76a2 2 0 0 1-1.11 1.79l-1.78.9A2 2 0 0 0 5 15.24V16a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-.76a2 2 0 0 0-1.11-1.79l-1.78-.9A2 2 0 0 1 15 10.76V7a1 1 0 0 1 1-1 2 2 0 0 0 0-4H8a2 2 0 0 0 0 4 1 1 0 0 1 1 1Z"],
    "pin.fill": ["M12 17v5", "M9 10.76a2 2 0 0 1-1.11 1.79l-1.78.9A2 2 0 0 0 5 15.24V16a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-.76a2 2 0 0 0-1.11-1.79l-1.78-.9A2 2 0 0 1 15 10.76V7a1 1 0 0 1 1-1 2 2 0 0 0 0-4H8a2 2 0 0 0 0 4 1 1 0 0 1 1 1Z"],
    "pin.slash": ["M12 17v5", "M9 10.76V7H8a2 2 0 0 1 0-4h8a2 2 0 0 1 0 4h-1v3.76", "M2 2l20 20"],
    "play": ["M5 3l14 9-14 9V3Z"],
    "plus": ["M5 12h14M12 5v14"],
    "plus.bubble": ["M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2Z", "M9 10h6M12 7v6"],
    "plus.circle": [circle, "M8 12h8M12 8v8"],
    "plus.magnifyingglass": ["M11 19a8 8 0 1 0 0-16 8 8 0 0 0 0 16Z", "M21 21l-4.35-4.35", "M11 8v6M8 11h6"],
    "plus.square.on.square": [
      "M8 8V5a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-3",
      "M3 10a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z",
      "M9.5 11.5v6m-3-3h6",
    ],
    "power": ["M12 2v10", "M18.4 6.6a9 9 0 1 1-12.77.04"],
    "progress.indicator": ["M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83"],
    "puzzlepiece.extension": ["M19.439 7.85c-.049.322.059.648.289.878l1.568 1.568c.47.47.706 1.087.706 1.704s-.235 1.233-.706 1.704l-1.611 1.611a.98.98 0 0 1-.837.276c-.47-.07-.802-.48-.968-.925a2.501 2.501 0 1 0-3.214 3.214c.446.166.855.497.925.968a.979.979 0 0 1-.276.837l-1.61 1.61a2.404 2.404 0 0 1-1.705.707 2.402 2.402 0 0 1-1.704-.706l-1.568-1.568a1.026 1.026 0 0 0-.877-.29c-.493.074-.84.504-1.02.968a2.5 2.5 0 1 1-3.237-3.237c.464-.18.894-.527.967-1.02a1.026 1.026 0 0 0-.289-.877l-1.568-1.568A2.402 2.402 0 0 1 1.998 12c0-.617.236-1.234.706-1.704L4.23 8.77c.24-.24.581-.353.917-.303.515.077.877.528 1.073 1.01a2.5 2.5 0 1 0 3.259-3.259c-.482-.196-.933-.558-1.01-1.073-.05-.336.062-.676.303-.917l1.525-1.525A2.402 2.402 0 0 1 12 1.998c.617 0 1.234.236 1.704.706l1.568 1.568c.23.23.556.338.877.29.493-.074.84-.504 1.02-.968a2.5 2.5 0 1 1 3.237 3.237c-.464.18-.894.527-.967 1.02Z"],
    "rectangle.3.group": [
      "M3 4h7v7H3ZM14 4h7v7h-7ZM3 14h18v6H3Z"
    ],
    "rectangle.dashed.badge.record": [
      "M5 3h3M10 3h4M16 3h3M3 6v3M3 11v4M21 6v3M5 21h3M10 21h4",
      "M17 17a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z",
    ],
    "rectangle.portrait.and.arrow.right": [
      "M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4", "M16 17l5-5-5-5", "M21 12H9",
    ],
    "sidebar.left": ["M3 5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z", "M9 3v18"],
    "slider.horizontal.3": ["M4 6h16M4 12h16M4 18h16", "M8 4v4M16 10v4M10 16v4"],
    "sparkles": [
      "M12 3l1.9 5.1L19 10l-5.1 1.9L12 17l-1.9-5.1L5 10l5.1-1.9Z",
      "M19 16l.9 2.1L22 19l-2.1.9L19 22l-.9-2.1L16 19l2.1-.9Z",
    ],
    "speaker.wave.2": [
      "M11 5 6 9H2v6h4l5 4V5Z", "M15.54 8.46a5 5 0 0 1 0 7.07", "M19.07 4.93a10 10 0 0 1 0 14.14",
    ],
    "square.2.layers.3d": ["M12 2 2 7l10 5 10-5-10-5Z", "M2 17l10 5 10-5", "M2 12l10 5 10-5"],
    "square.and.arrow.up": ["M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8", "M16 6l-4-4-4 4", "M12 2v13"],
    "square.and.pencil": ["M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7", "M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5Z"],
    "square.grid.2x2": ["M3 3h7v7H3ZM14 3h7v7h-7ZM14 14h7v7h-7ZM3 14h7v7H3Z"],
    "square.on.square": [
      "M8 8V5a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-3",
      "M3 10a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z",
    ],
    "star": ["M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2Z"],
    "strikethrough": ["M16 4H9a3 3 0 0 0-2.83 4M14 12a4 4 0 0 1 0 8H6M4 12h16"],
    "terminal": ["M4 17l6-6-6-6", "M12 19h8"],
    "text.bubble": ["M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2Z", "M7 8h10M7 12h7"],
    "text.cursor": ["M17 22h-1a4 4 0 0 1-4-4V6a4 4 0 0 1 4-4h1", "M7 22h1a4 4 0 0 0 4-4v-1M7 2h1a4 4 0 0 1 4 4v1", "M9 12h6"],
    "text.page": [docBase, "M8 13h8M8 17h8M8 9h2"],
    "text.quote": ["M17 6H3M21 12H8M21 18H8M3 12v6"],
    "trash": ["M3 6h18", "M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6", "M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2", "M10 11v6M14 11v6"],
    "trash.slash": ["M3 6h18", "M19 6v10M5 6v14a2 2 0 0 0 2 2h10", "M2 2l20 20"],
    "video.fill": ["M22 8l-6 4 6 4V8Z", "M4 6h10a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2Z"],
    "video.slash": ["M22 8l-6 4 6 4V8Z", "M4 6h10a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V8", "M2 2l20 20"],
    "wand.and.sparkles": ["M15 4V2m0 14v-2M8 9h2m10 0h2m-4.2-3.8L19 4m-8.2 9.8L9 15m0-11 1.8 1.8m8.2 8.2L20 15", "M3 21l9-9"],
    "wand.and.stars": ["M15 4V2m0 14v-2M8 9h2m10 0h2m-4.2-3.8L19 4m-8.2 9.8L9 15m0-11 1.8 1.8m8.2 8.2L20 15", "M3 21l9-9"],
    "waveform": ["M2 10v4M6 6v12M10 3v18M14 8v8M18 5v14M22 10v4"],
    "wrench.and.screwdriver": ["M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76Z"],
    "xmark": ["M18 6 6 18M6 6l12 12"],
    "xmark.circle": [circle, "M15 9l-6 6M9 9l6 6"],
    "xmark.circle.fill": [circle, "M15 9l-6 6M9 9l6 6"],
  ]

  for (name, paths) in outlineSymbols {
    VectorImage.registerSymbol(name, strokeWidth: 2.0, paths: paths)
  }

  // Solid filled symbols where stroke isn't appropriate
  VectorImage.registerSymbol(
    "stop.fill",
    strokeWidth: 0,
    paths: ["M6 6h12a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2Z"]
  )
}
