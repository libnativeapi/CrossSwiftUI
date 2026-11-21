# Android Counter

[English](./README.md) | 简体中文

本示例通过 Android `Activity` 展示与桌面端和 Web 端共享的 [CounterView](../Counter/CounterView.swift)。该视图直接 `import SwiftUI` 并在 Swift `@State` 中维护计数值；`Activity` 使用 Jetpack Compose Material 3 渲染文本标签与按钮。依次点击两次 **Increment** 再点击 **Reset**，即可看到计数按 `0 → 1 → 2 → 0` 变化。

## 构建与运行

请使用安装了 JDK 17、Android SDK Platform 36、Build Tools 36.0.0 与 Android NDK r30 的 macOS 或 Linux 构建宿主机，选择 Swift.org 的 Swift 6.4.2 工具链并安装配套的 [Swift SDK for Android][swift-android]：

```sh
swift sdk install https://download.swift.org/swift-6.4.2-release/android-sdk/swift-6.4.2-RELEASE/swift-6.4.2-RELEASE_android.artifactbundle.tar.gz \
  --checksum 4d6ad63ea74becd58e123ff58b1b48c3be5ec0db0dff0ea5abe37ac007dd3233
export ANDROID_HOME=/path/to/android/sdk
export ANDROID_NDK_HOME=/path/to/android-ndk-r30
cd Examples/AndroidCounter
./gradlew :app:installDebug
"$ANDROID_HOME/platform-tools/adb" shell am start -n dev.crossswiftui.android.counter/.CounterActivity
```

Gradle 默认会交叉编译 Swift 代码并同时打包 `arm64-v8a` 与 `x86_64` 架构；如需仅构建单一 ABI，可传入 `-PandroidAbis=arm64-v8a` 或 `-PandroidAbis=x86_64`。无连接设备时可执行 `:app:assembleDebug` 生成 `app/build/outputs/apk/debug/app-debug.apk`。若 Swift 不在 `PATH` 中，请将 `SWIFT_TOOLCHAIN_BIN` 设为 Swift.org 工具链的 `usr/bin` 目录；若 Swift SDK 安装在自定义目录，请设置 `SWIFTUI_ANDROID_SDKS_PATH`。

安装好调试版 APK 并解锁模拟器或真机后，可运行冒烟验证脚本：

```sh
python3 verify-counter.py
```

该脚本会在 Android 无障碍节点树中定位 Compose 控件，按其屏幕矩形触发点击并校验更新后的文本内容。连接多台设备时可通过 `ANDROID_SERIAL` 指定目标设备。

## 宿主集成说明

`Activity` 加载 Swift 动态库后，将保留的 `AndroidHost` 句柄传给 `SwiftUIComposeHost`，并在 `onDestroy` 中关闭宿主。[Swift 入口文件](../Counter/AndroidCounterHost.swift) 负责提供根视图 `CounterView`。每次尺寸变化或按钮激活时，Swift 渲染器都会更新布局并通过 JNI 发送快照；Compose 宿主以渲染器 `NodeID` 作为键值管理组合项，并通过自定义 Compose 布局应用 Swift 侧计算出的坐标框。`@State` 的生命周期绑定于当前挂载的宿主实例，因此 `Activity` 重建时会重新从初始计数开始。关于 Material 3 / iOS Liquid Glass 双风格切换、直接构建 `.xcodeproj` APK 及更多宿主集成细节，请参见 [Android 后端文档](../../docs/ANDROID-ZH.md)。

[swift-android]: https://www.swift.org/documentation/articles/swift-sdk-for-android-getting-started.html
