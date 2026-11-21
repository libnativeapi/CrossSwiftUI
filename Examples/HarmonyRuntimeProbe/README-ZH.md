# HarmonyOS PC Swift 运行时验证工程

[English](./README.md) | 简体中文

本 Stage 模型 HAP 从 `EntryAbility.onCreate` 加载 ARM64 Node-API 原生库。启动自检覆盖 Swift 标准库集合与动态类型转换、Foundation 的 JSON / URL / Date、包含任务组（Task Group）的分离式并发任务（Detached Task），以及 `SwiftUIRuntime` 的 `@State` 状态更新；并发任务通过 Node-API 线程安全函数（Thread-Safe Function）将结果切回 ArkTS 线程。

ArkUI 的 `ContentSlot` 根据 `SwiftUIRuntime` 布局树计算出的几何框承载原生文本节点与按钮：点击原生按钮会将对应的 `NodeID` 传回 Swift 渲染器，触发 `@State` 更新并刷新标签文本。

同一个 HAP 还内置了画廊（Gallery）模式，直接编译真实的 DazzUI SwiftUI `AppView`、组件示例与主题面板：由 Swift 渲染器解析状态与布局，通过 JSON 桥接将元素树发布给 ArkUI，渲染原生文本、按钮、输入框、滚动容器、SVG 图标与矢量路径。宿主在 ArkTS 线程初始化 `NativeAPI` 并绑定所属 `UIAbilityContext`；DazzUI 的 Code 示例通过 `NativeAPI.Clipboard.shared.writeText` 直接写入系统剪贴板。

## 构建与运行

请使用安装有 DevEco Studio（API 26 SDK）、Swift.org Swift 6.4.2 正式版工具链，并已启动 ARM64 HarmonyOS PC（2in1）模拟器的 Mac 环境：

```sh
./run-emulator.sh
python3 verify-controls.py
python3 verify-gallery.py
```

脚本默认连接 `127.0.0.1:5555`。可通过 `HARMONY_DEVICE` 指定其他 HDC 设备目标，或通过 `DEVECO_STUDIO_HOME` 指定 DevEco Studio 的 `Contents` 目录。生成的未签名调试 HAP 面向模拟器运行。

`prepare-runtime.sh` 会自动下载并校验匹配的 Swift.org Static Linux SDK。可设置 `SWIFT_STATIC_SDK_ARCHIVE` 复用本地归档包，或设置 `SWIFT_TOOLCHAIN_BIN` 指向正式版工具链的 `usr/bin`。若在分离的宿主机上构建，可先运行准备脚本，将生成的 `.build/runtime/` 目录复制到目标机器相同工程位置，再在 DevEco 宿主机上执行 `SWIFT_RUNTIME_PREPARED=1 ./run-emulator.sh`。

自检通过结果会同时显示在应用界面与当前进程的 HiLog 日志中。第二条命令通过模拟器输入工具点击原生按钮，验证 Swift 文本标签从 `Count: 1` 变为 `Count: 2`；第三条命令启动画廊模式并执行端到端交互验证。等价的手动启动命令为：

```sh
hdc shell aa force-stop dev.crossswiftui.runtimeprobe
hdc shell aa start -b dev.crossswiftui.runtimeprobe -a EntryAbility --ps gallery true
```

运行 `verify-gallery.py` 时若将 `HARMONY_GALLERY_SCREENSHOTS` 设为某个目录路径，脚本会自动保存深浅色下的 Button、Calendar、Overview 以及展开态 Collapsible 的模拟器截图。

准备脚本还需要包含 SwiftUI HarmonyOS 资源路径及接入了 `NativeAPI` 剪贴板 Code 示例的 DazzUI 检出目录（默认查找与 `libnativeapi` 同级的 `dazzlabs/dazzui`，也可通过 `DAZZUI_SWIFT_PATH` 覆盖 `packages/swift/DazzUI` 的路径）。在分离宿主机打包 HAP 前，请一并复制 `entry/src/main/resources/rawfile/fluent/` 目录。

此外，工程依赖已初始化 `core` 子模块且支持 HarmonyOS 构建的 `NativeAPI` 工作区（若不在默认同级目录，可通过 `NATIVEAPI_SWIFT_PATH` 指向 `nativeapi/bindings/swift`）。Swift 构建阶段会调用绑定的 `scripts/build-ohos.sh` 产出 `NativeAPI.o`，DevEco 宿主机同样需要该绑定下的 `ohos/` CMake 目录与 `core/` 源码树以链接 OHOS 后端。

```text
SWIFT_RUNTIME_PROBE PASS values=217,225
SWIFT_FOUNDATION_PROBE PASS value=42
SWIFT_RENDERER_PROBE PASS value=1
SWIFT_CONCURRENCY_PROBE PASS value=42
SWIFT_ARKUI_PROBE PASS Count: 1 -> Count: 2
```

## 链接细节

Static Linux SDK 提供了 Swift 标准库静态归档以及在动态库加载时注册 Swift 元数据的 `swiftrt.o` 启动目标文件；DevEco NDK 将它们针对 HarmonyOS `libc` 链接进 `libswiftprobe.so`，同时在 HAP 中打包 NDK 的 `libc++_shared.so`。准备脚本会从私有静态库副本中移除 Linux `libc++abi` 的异常存储成员，以便统一使用 NDK 的异常 TLS 实现。两个仅限 Linux 的 Foundation 符号在探针内部就地解析（程序名变量返回测试 Bundle 名称，子进程工作目录动作返回 `ENOTSUP`）。画廊模式还将 Swift 主调度队列接入 ArkTS 环境的 `libuv` 事件循环，以驱动派发至 `MainActor` 的任务。

已在 `NativeAPI_Desktop`（ARM64，HarmonyOS 7.0.0.107，API 26）上完成验证。画廊后端目前仍为原型实现：每次更新发布完整树，当父节点未变时 ArkUI 按 Swift `NodeID` 复用原生控件；布局使用 HarmonyOS Native Drawing 测量字体，布局框采用 ArkUI `vp` 视口单位，路径与裁剪指令则换算为物理像素。模拟器自动化验证覆盖了 Button 排版、Button → Calendar → Overview 页面切换、Bright 与 Studio 主题切换、浅色 → 深色 → 浅色切换、Collapsible 展开与收起、侧边栏滚动、原生搜索框过滤，以及通过 `NativeAPI` 复制 Code 示例并粘贴回 ArkUI 输入框。上下文菜单、全量组件视觉对齐与真机验证仍有待后续完善。
