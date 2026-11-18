# Android compatibility plan

SwiftUI view source compiles for Android against the port's `SwiftUI` module.
`SwiftUIRuntime` evaluates views and owns state, layout, and node identity.
`SwiftUIAndroid` connects that runtime to Jetpack Compose inside an Activity. The
[official Swift SDK for Android][swift-sdk] cross-compiles the Swift code into
an Android shared library, which Gradle packages into the APK.

```text
SwiftUI view → SwiftUIRuntime → SwiftUIAndroid → JNI → Compose
                    ↑                                    │
                    └────── actions keyed by NodeID ──────┘
```

The Android build selects its SwiftPM dependency graph with
`CROSS_SWIFTUI_ANDROID=1` because SwiftPM evaluates `Package.swift` on the
build host. That graph builds the facade and Android host without resolving
the desktop NativeAPI or WebAssembly dependencies. The Kotlin host uses
Compose Material 3. Swift owns application state and publishes snapshots
containing control properties and frames.

## 1. Counter and the Compose host

- Build `Examples/Counter/CounterView.swift` with `import SwiftUI` for both
  `arm64-v8a` and `x86_64`. An Activity mounts it via `AndroidHost`.
- Map `Text` and unstyled `Button` to Material 3 composables. A custom Compose
  `Layout` converts the runtime's stack, spacer, padding and frame geometry to
  pixels. Use Compose `TextMeasurer` with the same font styles for Swift layout
  and rendering. Map disabled state and accessibility labels to Compose semantics.
- Mount and update on the Android UI thread. Key composables by `NodeID`,
  feed Compose clicks back into the Swift renderer, and release the
  renderer when the Activity is destroyed.
- Acceptance checks exercise a real APK and the tap sequence
  `0 → 1 → 2 → 0`. The [example README](../Examples/AndroidCounter/README.md)
  contains the build commands and smoke test.

## 2. Input, environment and lifecycle

- Route Swift render invalidations through the Android Looper and schedule
  frame callbacks through `Choreographer`. Wire cancellation and cleanup to
  the host lifecycle. Verify a Swift `.task` can update a mounted view and
  cannot publish to a closed host.
- Add `TextField`, `SecureField` and Compose scroll containers. Route editing,
  focus, IME and scroll events back to the renderer. Test that text
  composition, selection and scroll offsets survive Swift re-rendering.
- Propagate Android appearance, layout direction, font scale and safe-area
  changes. Define scene state across Activity recreation, then exercise
  rotation, foreground/background, and accessibility navigation on an emulator.

## 3. Drawing and application integration

- Add Compose drawing for shapes, images, clipping and custom button visuals.
  Integrate Compose input controls with Swift hit testing,
  drawing order and accessibility. Check layering, viewport clipping and
  tap targets at multiple display densities.
- Map `App` and `WindowGroup` to Android Activity and scene semantics. Package
  the Android host for other Gradle projects, add an APK build and emulator
  smoke test to CI, and update the compatibility table as features are verified.

The Counter milestone uses an Activity entry point, synchronous interaction,
and a snapshot of controls. The broader API matrix includes
capabilities from the desktop drawing backends.

[swift-sdk]: https://www.swift.org/documentation/articles/swift-sdk-for-android-getting-started.html
