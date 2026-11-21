---
name: xcodebuild
description: >-
  Use CrossSwift's cross-platform `xcodebuild` CLI (`CrossXcodeBuild` /
  `CrossXcodeBuildCLI`) to inspect and compile unmodified macOS/iOS `.xcodeproj`
  or `.xcworkspace` apps into self-contained Windows, Linux, WebAssembly,
  HarmonyOS, or Android artifacts. Activate when building an Xcode project for
  non-Apple targets, querying targets/schemes/build settings (`-list`,
  `-showBuildSettings`), or troubleshooting CrossXcodeBuild SDKs, paths,
  dependencies, and staged output.
---

# CrossSwift `xcodebuild`

CrossSwift (`crossswift`, SwiftPM package `CrossSwiftUI`) ships an
`xcodebuild`-compatible CLI (`CrossXcodeBuild` / `CrossXcodeBuildCLI`) that
parses `project.pbxproj`, `.xcworkspace`, `.xcconfig`, `Package.resolved`, and
`Info.plist` in pure Swift and compiles unmodified `.xcodeproj` / `.xcworkspace`
projects (classic groups or Xcode 16 synchronized folders) for non-Apple
platforms.

## Invocation

On **macOS**, `/usr/bin/xcodebuild` is Apple's Xcode tool. Invoke CrossSwift's
CLI explicitly via SwiftPM or an explicit binary path so you do not accidentally
run Apple's `xcodebuild`:

```bash
swift run --package-path <crossswift-dir> xcodebuild [options] [KEY=VALUE ...] [clean] [build]
```

On **Windows** or **Linux** (where CrossSwift's `xcodebuild` may be installed on
`PATH`), you can call `xcodebuild` directly or use `swift run --package-path`.
Verify which binary you are running:

```bash
swift run --package-path <crossswift-dir> xcodebuild -version
# Xcode 16.0 (CrossSwiftUI)
# Build version CrossSwiftUI-1.0
```

## Workflow

### 1. Inspect the project first

Before building, discover schemes, targets, configurations, and effective
output paths (omit `-project` to auto-discover in the current directory):

```bash
xcodebuild -list -json -project path/to/App.xcodeproj
xcodebuild -showBuildSettings -json \
  -project path/to/App.xcodeproj \
  -scheme App \
  -configuration Release \
  -destination generic/platform=Wasm \
  -derivedDataPath build
```

### 2. Choose the target platform and host

| Target | `-destination` (or `-sdk`) | Allowed build hosts | Required checkout / toolchain |
| --- | --- | --- | --- |
| **Windows** | default on Windows (`-destination generic/platform=Windows` / `-sdk windows`) | Windows only | Swift 6.4.2+ (MSVC), `crossswift` checkout, `nativeapi/bindings/swift` |
| **Linux** | default on Linux (`-destination generic/platform=Linux` / `-sdk linux`) | Linux only | Swift 6.0+, GTK 3 / SQLite3 / X11 dev libs, `crossswift` checkout, `nativeapi/bindings/swift` |
| **WebAssembly** | `-destination generic/platform=Wasm` (`-sdk wasm` \| `web` \| `wasi`) | macOS, Linux | Swift Wasm SDK (e.g. `swift-6.4.2-RELEASE_wasm`), `npm`, `crossswift` checkout |
| **HarmonyOS** | `-destination generic/platform=HarmonyOS` (`-sdk harmonyos` \| `ohos`) | macOS, Linux | Swift 6.4.2 + Static Linux ARM64 musl SDK, `crossswift` checkout, `nativeapi/bindings/swift`; optional DevEco Studio for `.hap` |
| **Android** | `-destination generic/platform=Android` (`-sdk android`) | macOS, Linux | Swift Android SDK, Android NDK (`llvm-strip`), Android SDK + JDK 17 for `.apk`, `crossswift` checkout |

> Windows and Linux targets **cannot** be cross-compiled from macOS; run on the
> matching host (e.g. over SSH) or choose Wasm / HarmonyOS / Android on macOS or
> Linux.

### 3. Build and clean

Default configuration when `-configuration` is omitted is `Release` (`Debug`
and `Release` are supported). Pass `CODE_SIGNING_ALLOWED=NO` when sharing
commands with Apple `xcodebuild` scripts.

```bash
# Current desktop host (Windows or Linux)
xcodebuild -project App.xcodeproj -scheme App -configuration Release \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO clean build

# WebAssembly (from macOS or Linux)
xcodebuild -project App.xcodeproj -scheme App -configuration Release \
  -destination generic/platform=Wasm -derivedDataPath build clean build

# HarmonyOS arm64-v8a (from macOS or Linux)
xcodebuild -project App.xcodeproj -scheme App -configuration Release \
  -destination generic/platform=HarmonyOS -derivedDataPath build clean build

# Android APK (from macOS or Linux; override ABIs if needed)
xcodebuild -project App.xcodeproj -scheme App -configuration Release \
  -destination generic/platform=Android -derivedDataPath build \
  ANDROID_ABIS=arm64-v8a,x86_64 clean build
```

### 4. Verify staged output

A successful run prints `Staged product at <path>` followed by
`** BUILD SUCCEEDED **`. By default, output is staged at:

```text
<derivedDataPath>/Build/Products/<Configuration>/<ProductName>/
```

(Overridable via `SYMROOT=...` or `CONFIGURATION_BUILD_DIR=...`; default
`-derivedDataPath` is `<projectRoot>/build`.)

- **Windows**: `<ProductName>.exe`, `Resources/`, SwiftPM `.resources`/`.bundle`, runtime `.dll`s.
- **Linux**: `<ProductName>`, `Resources/`, `lib/*.so` (`$ORIGIN/lib` RPATH), `.desktop`, `icons/hicolor/`.
- **Wasm**: `index.html`, `app/<Executable>.wasm`, `app/index.js`, `app/node_modules/@bjorn3/browser_wasi_shim`, `Resources/`. Serve the staged directory over HTTP (e.g. `python3 -m http.server 8000 --directory <staged>`).
- **HarmonyOS**: `runtime/*.o` + static Swift musl archives, Stage-model project (`AppScope/`, `entry/`), and `<ProductName>.hap` when DevEco Studio is available.
- **Android**: Gradle project (`app/`, `gradlew`, `jniLibs/<abi>/lib<Executable>.so`, `assets/Resources/`), and `<ProductName>.apk` when Android SDK / Gradle succeeds.

## Common options

| Option | Purpose |
| --- | --- |
| `-project <path>` / `-workspace <path>` | Select `.xcodeproj` or `.xcworkspace` |
| `-scheme <name>` / `-target <name>` / `-alltargets` | Select scheme or target(s) |
| `-configuration <Debug\|Release>` | Build configuration (default: `Release`) |
| `-derivedDataPath <dir>` | Derived data and default output root (default: `./build`) |
| `-destination <spec>` / `-sdk <sdk>` | Target platform hint |
| `-xcconfig <file>` / `KEY=VALUE` | Load or override build settings |
| `-list` / `-showBuildSettings` / `-json` | Inspect project metadata or effective settings |
| `-quiet` | Suppress non-error output |
| `--crossswift-path <dir>` | Override `crossswift` checkout path (or set `CROSS_SWIFTUI_PATH`) |
| `--nativeapi-path <dir>` | Override `nativeapi/bindings/swift` path (or set `NATIVEAPI_SWIFT_PATH`) |
| `--scratch-path <dir>` | Override intermediate SwiftPM build directory |
| `--console` | Keep Windows console subsystem instead of `/SUBSYSTEM:WINDOWS` |

## Troubleshooting

- **Exit code 65**: CLI/build error; inspect stderr (`xcodebuild: error: ...`).
- **Build logs**: Check `<buildRoot>/swift-build.log`, `swift-wasm-build.log`, or `swift-android-<abi>.log`. On Windows, `<buildRoot>` defaults to `%TEMP%\csb\<slug>-<hash>` to stay under `MAX_PATH` unless `--scratch-path` is set.
- **`Could not locate CrossSwiftUI checkout` / `NativeAPI Swift binding`**: Pass `--crossswift-path` / `--nativeapi-path` or set `CROSS_SWIFTUI_PATH` / `NATIVEAPI_SWIFT_PATH`. By default `nativeapi/bindings/swift` is expected as a sibling of the `crossswift` checkout (`../nativeapi/bindings/swift`).
- **Windows `nativeapi` core symlink**: Ensure `nativeapi`'s `core` submodule is initialized; `CrossXcodeBuild` automatically converts a plain-file Git symlink into a directory junction when building on Windows.
- **Unsupported actions**: Only `build` and `clean` actions are executed (`test` / `archive` / XCTest targets are not supported yet).

For all environment variables, platform-specific build settings, Apple framework
mappings, and SDK installation details, read
[references/platforms.md](references/platforms.md).
