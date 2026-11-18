# Android Counter

This Android Activity displays the shared [CounterView](../Counter/CounterView.swift)
from the desktop and web examples. The view imports `SwiftUI` and keeps the count
in Swift `@State`. The Activity displays the label and buttons using Jetpack
Compose Material 3. Tap **Increment** twice and **Reset** to see `0 → 1 → 2 → 0`.

## Build and run

Use a macOS or Linux build host with JDK 17, Android SDK Platform 36, Build
Tools 36.0.0, and Android NDK r30. Select the Swift.org Swift 6.4.2 toolchain
and install its matching [Swift SDK for Android][swift-android].

```sh
swift sdk install https://download.swift.org/swift-6.4.2-release/android-sdk/swift-6.4.2-RELEASE/swift-6.4.2-RELEASE_android.artifactbundle.tar.gz \
  --checksum 4d6ad63ea74becd58e123ff58b1b48c3be5ec0db0dff0ea5abe37ac007dd3233
export ANDROID_HOME=/path/to/android/sdk
export ANDROID_NDK_HOME=/path/to/android-ndk-r30
cd Examples/AndroidCounter
./gradlew :app:installDebug
"$ANDROID_HOME/platform-tools/adb" shell am start -n dev.crossswiftui.android.counter/.CounterActivity
```

Gradle cross-compiles Swift and bundles `arm64-v8a` and `x86_64` by default.
Pass `-PandroidAbis=arm64-v8a` or `-PandroidAbis=x86_64` for a single ABI.
Use `:app:assembleDebug` to build `app/build/outputs/apk/debug/app-debug.apk`
without a connected device. If Swift is outside `PATH`, set
`SWIFT_TOOLCHAIN_BIN` to the Swift.org toolchain's `usr/bin` directory. Set
`SWIFTUI_ANDROID_SDKS_PATH` if the Swift SDK is in a custom SwiftPM SDK directory.

With the debug APK installed and the emulator or device unlocked, run:

```sh
python3 verify-counter.py
```

The smoke test finds the Compose controls in Android's accessibility tree, taps
them by their bounds, and checks the resulting label. Set `ANDROID_SERIAL`
when multiple devices are connected.

## Host integration

The Activity loads the Swift library, passes a retained `AndroidHost` handle to
`SwiftUIComposeHost`, and closes the host from `onDestroy`. The
[Swift entry point](../Counter/AndroidCounterHost.swift) supplies `CounterView`.
On each size change and button activation, the Swift renderer updates the
layout and sends a snapshot over JNI. The host keys composables by the
renderer’s node IDs and uses a custom Compose layout to apply the Swift frames.
`@State` lives for the mounted host, so Activity recreation starts a
new count. See the [Android compatibility plan](../../docs/ANDROID.md) for the
supported subset and next milestones.

[swift-android]: https://www.swift.org/documentation/articles/swift-sdk-for-android-getting-started.html
