# 与 Apple SwiftUI 的已知差异

**非官方实现；与 Apple 无关。** API 支持状态详见 [COMPAT-ZH.md](COMPAT-ZH.md)。

[English](./DIVERGENCES.md) | 简体中文

## 平台与原生控件

在 Windows 上，`CrossSwiftUI`（`WindowsDrawingBackend` + `CSwiftUIWindows`）在 `NativeAPI` 内容 `HWND` 上维护保留式 GDI+ 显示列表。带自定义样式的按钮保留原生 `BUTTON` 的点击激活、鼠标捕获、键盘焦点、无障碍名称与禁用状态，并通过 Owner Draw 绘制视觉内容。`TextField`、`SecureField` 与 `TextEditor` 采用原生 Win32 `EDIT` 控件以提供选区、剪贴板快捷键与输入法（IME）支持，并通过双通道遮罩提取将文本透明合成在画布背景之上，使自定义背景、占位符、滚动视图与禁用态都能自然透出。原生控件按滚动视口进行裁剪。无边框窗口与浮动 AppKit 面板（`CrossAppKit.NSPanel`）在 Windows 上支持逐像素 Alpha 透明与基于 Alpha 轮廓的窗口阴影。

纯自绘装饰内容尚未接入完整的 UI Automation 或 AT-SPI 无障碍树提供程序：无障碍修饰符会保留元数据，原生控件的无障碍名称与模态遮罩焦点排除已实现，但完整的自绘节点无障碍层级与焦点作用域（Focus Scope）尚未实现。

在 Linux 上，`CrossSwiftUI`（`LinuxDrawingBackend`）在 GTK 3 绘图区内使用 Cairo 与 Pango 绘制界面：由 GTK 单行输入框与多行文本视图提供原生文本编辑、多行占位符叠加层及键盘焦点，由 GTK 按钮提供原生激活与 AT-SPI 无障碍名称。Windows 与 Linux 窗口标题栏边框均会跟随深色/浅色外观同步切换。

在 macOS 上，应用程序直接针对 Apple 原生 `SwiftUI` 与 `AppKit` SDK 编译；`SwiftUIRuntime`、`CrossAppKit` 与 `CrossXcodeBuild` 在 macOS 上编译用于运行单元测试及执行跨平台 `.xcodeproj` 构建。

## 浏览器与移动端宿主

`SwiftUIWeb` 将单个 `WindowGroup` 挂载到页面中的 `#swiftui-root` 元素，窗口标题映射至 `document.title`，根元素尺寸驱动布局计算。按钮、输入框与滚动条采用原生 HTML 控件，文本度量与滚动条外观遵循浏览器默认行为。使用 `CrossXcodeBuild` 打包 Web 产物时，`.xcassets` 图像、`.xcstrings` 多语言目录与内置 SF Symbols 会通过 `web-manifest.json`（`window.__crossSwiftUIResources`）自动注入。`CrossAppKit` 与 `MenuBarExtra` 属于桌面端模块，在 WebAssembly 与 Android 上不可用。

`SwiftUIAndroid` 与 HarmonyOS ArkUI 宿主（`HarmonyBuilder`）在 Swift 侧运行 `SwiftUIRuntime` 求值状态与布局，同时将语义控件（`Toggle`、`Slider`、`Stepper`、`Picker`、`Menu`、`ProgressView`、`List`、`NavigationStack`、`TabView`、`.sheet`、`.alert`）映射为原生 Jetpack Compose / ArkUI 控件或 iOS Liquid Glass 风格组件。详见 [ANDROID-ZH.md](ANDROID-ZH.md)。

## 图形、资源与文本排版

Windows 下由 GDI+ 按逻辑点测量和绘制字体，系统无衬线、衬线与等宽字体分别映射为 Segoe UI、Georgia 与 Consolas；字重采用常规/粗体两档分桶，不具备可变字体或与 Apple 完全一致的字体回退链。支持自动换行、显式换行符、行间距与首/尾省略号。Linux 使用系统字体族及 Pango 字重选择、字距追踪与下划线。拼接的 `Text` 片段会保留各自字体与颜色元数据，但尚未构成完整的双向混排富文本段落引擎。

`Image` 支持内置 `SFSymbolCatalog`（`Image(systemName:)`）、`.xcassets` 图像集与 PDF 矢量资源、位图文件以及内置 SVG 路径（支持椭圆弧、逐路径填充/描边样式保留，以及 `template` / `original` 渲染模式）。不解析任意 SVG `<text>`、`<filter>` 与内嵌位图标签。`LinearGradient`、`RadialGradient` 与 `AngularGradient` 支持显式色标，`Canvas` 支持路径填充/描边、裁剪以及缩放与平移。圆形路径支持 `trim`，任意多段路径的 `trim` 尚未完整实现。

`.circular` 与 `.continuous` 圆角目前均采用标准圆弧几何。桌面端阴影通过对圆角矩形或圆形轮廓遮罩执行三次盒式滤波来近似高斯模糊，`.mask` 在桌面端支持视图 Alpha 遮罩合成。Windows 按绘制图元应用 `.opacity`，Linux 通过 Cairo 组合成透明度。任意裁剪路径可约束矢量绘制，而原生控件仅执行矩形视口裁剪。

## 布局、状态与事件

布局系统支持尺寸提案、嵌套 Frame/内边距/背景叠加层、堆栈主轴弹性、`Grid`、滚动内容边界与自定义 `Layout` 协议（含主交叉轴弹性探测）。在 `ScrollView` 内，当 `ForEach` 数据量超过 72 项时，`LazyVStack` 会借助高度估算缓存执行视口窗口虚拟化；更小规模的 `LazyVStack` 以及 `LazyHStack`、`LazyVGrid`、`LazyHGrid` 均即时求值全部子视图。布局优先级（`layoutPriority`）、跨混合控件的精确文本基线对齐与 `Spacer.minLength` 约束尚未完整实现。

`.hidden()` 会折叠布局空间；内层 `.disabled(false)` 可重新启用被祖先禁用的子树。拖拽与悬停在宿主层执行命中测试，原生控件的键盘与焦点回调向祖先节点冒泡。多手势同时/高优先级竞争仲裁、带时长计时的 `LongPressGesture` 识别器，以及完整的物理键盘布局字符映射尚未实现。

`StateRegistry` 为进程级单例，但 `@State` 存储及 `.onAppear` / `.onDisappear` / `.task` 生命周期均按每个 `Renderer` 根节点独立隔离（从而支持多窗口、`MenuBarExtra` 菜单与多个 `NSHostingView` 并存）。`@Observable`（`@Bindable`）与 `ObservableObject` 模型变更会通知所有观察该模型的渲染器刷新。运行时通过反射注入直接存储的属性包装器，而非完整复刻 Apple SwiftUI 嵌套的 `DynamicProperty` 图。测量与排布缓存会复用未变化子树；`WindowsDrawingBackend` 在验证显示指令安全可平移时直接复用整数像素滚动内部帧缓冲，不满足条件时自动回退至常规脏区重绘。评估交互帧率时请使用 `Release` 构建。

各类弹出展示层（`.popover`、`.sheet`、`.confirmationDialog`、`.alert`、`.contextMenu` 与 `Menu` 下拉菜单）在桌面与 Web 端均会提升至滚动裁剪层之上，`.popover` 在靠近窗口边缘时自动翻转箭头方向，并支持点击遮罩或按 Escape 关闭。在桌面端这些浮层绘制于宿主窗口内部，而非创建独立操作系统窗口（`MenuBarExtra` 托盘菜单及显式创建的 `CrossAppKit` `NSWindow` / `NSPanel` 除外）。

## 生命周期、场景与兼容垫片

出现、值变更与消失回调在挂载提交后执行；`.task` 在视图卸载或 `id` 改变时自动取消。`NativeAPI` 的 Swift 绑定会在 Win32、GTK 与 HarmonyOS UI 事件循环旁协同泵送 Swift 主队列（`DispatchQueue.main`）。

桌面后端支持跨 `withAnimation` 与 `.animation(_:value:)` 事务对旋转、缩放、透明度、位移以及布局尺寸（Frame、内边距与堆栈间距）执行三次贝塞尔曲线插值；颜色插值与插入/移除 `.transition` 过渡动画尚未完整实现。

`CrossSwiftUI` 的场景运行器支持单个主 `WindowGroup` 搭配任意数量的 `MenuBarExtra` 状态栏项（以及基于 `CrossAppKit.NSApplication` 运行的无主窗口菜单栏常驻应用）。声明式 `Window`、`Settings`、`DocumentGroup` 场景及窗口状态恢复尚未实现。Windows 可执行文件与 WASI 调试构建默认预留 16 MiB 线程栈，以容纳深度嵌套的声明式视图树。

`ViewThatFits` 会即时求值所有候选分支并裁剪未选中的分支。`TimelineView` 基于可取消异步任务驱动而非显示器垂直同步信号，当前支持 `.animation` 调度（间隔限制在 1/240 秒至 1 天之间）。`ScrollViewReader` 直接跳转至显式 ID 位置，不含平滑滚动动画。`.blur` 提供编译兼容的透明度近似而非高斯模糊滤镜，`.saturation` 与 `.grayscale` 仅变换显式颜色属性而非对合成后像素做后处理。
