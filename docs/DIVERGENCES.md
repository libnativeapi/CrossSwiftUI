# Known divergences from Apple SwiftUI

**Unofficial; not affiliated with Apple.** See [COMPAT.md](COMPAT.md) for API status.

English | [简体中文](./DIVERGENCES-ZH.md)

## Platforms and controls

On Windows, `CrossSwiftUI` (`WindowsDrawingBackend` + `CSwiftUIWindows`) uses a
retained GDI+ display list on a `NativeAPI` content HWND. Styled buttons retain
native `BUTTON` activation, capture, focus, accessible names, and disabled state
using owner drawing. `TextField`, `SecureField`, and `TextEditor` use native
Win32 `EDIT` controls for selection, clipboard commands, and IME, composited
transparently over the drawn canvas backdrop via dual-pass matte extraction so
custom backgrounds, placeholders, scroll views, and disabled states show through
cleanly. Native controls are clipped to scroll viewports. Borderless windows and
floating AppKit panels (`CrossAppKit.NSPanel`) support per-pixel alpha and
alpha-silhouette window shadows on Windows.

Decorative content has no complete UI Automation or AT-SPI provider.
Accessibility modifiers retain metadata; native control names and modal control
exclusion are implemented, while a full accessible hierarchy for drawn shapes
and focus scopes are not.

On Linux, `CrossSwiftUI` (`LinuxDrawingBackend`) uses Cairo and Pango in a GTK 3
drawing area. GTK entries and text views provide native editing, multiline
placeholder overlays, and keyboard focus. GTK buttons expose native activation
and AT-SPI names. Window chrome follows light and dark appearances on both
Windows and Linux.

On macOS, applications compile directly against Apple's native `SwiftUI` and
`AppKit` SDKs; `SwiftUIRuntime`, `CrossAppKit`, and `CrossXcodeBuild` build on
macOS for unit testing and cross-platform `.xcodeproj` compilation.

## Browser and mobile hosts

`SwiftUIWeb` mounts one `WindowGroup` inside `#swiftui-root` in the page. Its
title sets `document.title`, and the host element's dimensions drive layout.
HTML controls provide editing, focus, and activation; text metrics and
scrollbars follow the browser. When staged by `CrossXcodeBuild`, `.xcassets`
images, `.xcstrings` catalogs, and embedded SF Symbols are loaded via
`web-manifest.json` (`window.__crossSwiftUIResources`). `CrossAppKit` and
`MenuBarExtra` are desktop-only modules and are not available on WebAssembly or
Android.

`SwiftUIAndroid` and the HarmonyOS ArkUI host (`HarmonyBuilder`) map semantic
controls (`Toggle`, `Slider`, `Stepper`, `Picker`, `Menu`, `ProgressView`,
`List`, `NavigationStack`, `TabView`, `.sheet`, `.alert`) to native Jetpack
Compose / ArkUI components or iOS Liquid Glass renderers while `SwiftUIRuntime`
evaluates state and layout in Swift. See [ANDROID.md](ANDROID.md).

## Drawing, assets and text

GDI+ measures and draws Windows fonts in logical points. System sans, serif, and
monospaced faces map to Segoe UI, Georgia, and Consolas; weights use
regular/bold buckets without variable-font or Apple font-fallback parity.
Wrapping, newlines, line spacing, and head/tail ellipsis are supported. Linux
uses system font families with Pango weight selection, tracking, and underline.
Concatenated `Text` runs retain font and color metadata without forming a full
bidirectional paragraph engine.

`Image` supports the embedded `SFSymbolCatalog` (`Image(systemName:)`),
`.xcassets` imagesets and PDF vector assets, raster files, and bundled SVG
paths (including elliptical arcs, per-path fill/stroke styles, and template vs.
original `renderingMode`). Arbitrary SVG `<text>`, `<filter>`, and embedded
bitmap elements are not parsed. `LinearGradient`, `RadialGradient`, and
`AngularGradient` support explicit stops, and `Canvas` supports path
fills/strokes, clipping, and scale/translation. Circular path `trim` is
supported; arbitrary multi-segment path `trim` is incomplete.

Rounded corners use circular arcs for both `.circular` and `.continuous` styles.
Desktop shadows blur a rounded-rectangle or circular silhouette mask with three
box filters approximating a Gaussian, and `.mask` applies view alpha masks on
desktop. Windows applies `.opacity` per primitive; Linux composites Cairo
groups. Arbitrary clip paths constrain vector drawing, whereas native controls
use rectangular viewport clipping.

## Layout, state and events

Layout uses proposals, nested frames/padding/layers, stack flexibility, `Grid`,
scroll content extents, and custom `Layout` callbacks (with axis-flexibility
probing). Inside a `ScrollView`, `LazyVStack` virtualizes `ForEach` collections
exceeding 72 items using cached height estimates; smaller `LazyVStack`s,
`LazyHStack`, `LazyVGrid`, and `LazyHGrid` evaluate children eagerly. Layout
priority, exact text-baseline alignment across mixed controls, and `Spacer.minLength`
enforcement are incomplete.

`.hidden()` collapses space and inner `.disabled(false)` can re-enable content.
Dragging and hovering are hit-tested in the host, and controls bubble key/focus
callbacks to ancestors. Multi-gesture priority/simultaneous arbitration, timed
`LongPressGesture` recognition, and full keyboard layout-to-character mapping
are not implemented.

`StateRegistry` is process-wide, while `@State` retention and `.onAppear` /
`.onDisappear` / `.task` lifecycles are isolated per `Renderer` root (allowing
independent windows, `MenuBarExtra` menus, and `NSHostingView` instances).
`@Observable` (`@Bindable`) and `ObservableObject` models invalidate all
observing renderers. Reflection installs directly stored wrappers rather than
Apple SwiftUI's complete nested `DynamicProperty` graph. Measurement and
placement caches reuse unchanged subtrees; `WindowsDrawingBackend` verifies
display commands before reusing integer-pixel scroll interiors, falling back to
normal damage repainting when unsafe. Use `Release` builds when benchmarking
interactive frame rates.

Presentations (`.popover`, `.sheet`, `.confirmationDialog`, `.alert`,
`.contextMenu`, and `Menu` dropdowns) hoist above scroll clipping on desktop and
web, flip `.popover` edges within window bounds, and dismiss on backdrop press
or Escape. On desktop they render inside the window surface rather than spawning
separate OS windows (except `MenuBarExtra` status items and explicit
`CrossAppKit` `NSWindow` / `NSPanel` instances).

## Lifecycle, scenes and compatibility shims

Appearance, change, and disappearance callbacks commit after mounting; `.task`
cancels on disappearance or `id` change. `NativeAPI`'s Swift binding pumps
Swift's main `DispatchQueue` alongside the Win32, GTK, and HarmonyOS UI loops.

Desktop backends interpolate rotation, scale, opacity, offset, and animated
layout sizing (frames, padding, and stack spacing) across `withAnimation` and
`.animation(_:value:)` using cubic-bezier timing curves. Color interpolation and
insertion/removal `.transition` animations remain incomplete.

`CrossSwiftUI`'s scene runner supports one `WindowGroup` together with
`MenuBarExtra` status items (plus accessory/menu-bar-only apps backed by
`CrossAppKit.NSApplication`). Declarative `Window`, `Settings`, and
`DocumentGroup` scenes and scene state restoration are not implemented. Windows
executables reserve 16 MiB of stack (and WASI debug builds reserve 16 MiB) for
deeply nested declarative view trees.

`ViewThatFits` evaluates candidates eagerly and clips unselected branches.
`TimelineView` uses a cancellable task rather than a display link and supports
the `.animation` schedule (bounded between 1/240s and 86,400s).
`ScrollViewReader` jumps to explicit IDs without scroll animation. `.blur`
applies a compile-compatible opacity fallback rather than a pixel blur filter,
and `.saturation` / `.grayscale` transform explicit colors rather than
post-composited pixels.
