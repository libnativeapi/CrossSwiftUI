# API 兼容性矩阵

**非官方实现；与 Apple 无关。**

[English](./COMPAT.md) | 简体中文

`supported` 表示该符号在 CrossSwift 已实现子集内具备对应的 API 形态；`partial` 表示存在行为简化或平台差异限制。两者均不代表与 Apple SwiftUI 完全一致。英文原表 [`COMPAT.md`](./COMPAT.md) 中的每一条 `supported` / `partial` 记录均由 `COMPATTests` 自动对照 `Sources/` 源码校验。渲染、布局与状态语义细节请参见 [DIVERGENCES-ZH.md](DIVERGENCES-ZH.md)。

Windows 与 Linux 使用 `SwiftUIRuntime` 配合 `CrossSwiftUI`（GDI+ / GTK 绘制与原生控件）、`CrossAppKit`（`import AppKit`）及 `CrossFoundation` 垫片；WebAssembly 使用 `SwiftUIWeb`；Android 使用 `SwiftUIAndroid`（见 [ANDROID-ZH.md](ANDROID-ZH.md)）；HarmonyOS 使用 `CrossXcodeBuild` 的 ArkUI 宿主。macOS 应用直接针对 Apple 原生 SDK 编译，同时 `SwiftUIRuntime`、`CrossAppKit` 与 `CrossXcodeBuild` 在 macOS 上可直接运行各自测试套件。

## 核心 SwiftUI 视图、状态与修饰符

| 符号 | 状态 | 行为说明 |
|---|---|---|
| `View` | supported | 含 `Body` 关联类型的值类型视图 |
| `View.body` | supported | 递归求值直至原语节点 |
| `@ViewBuilder` | supported | 0–10 个表达式、条件分支、`switch` 与循环 |
| `EmptyView` | supported | 空内容视图 |
| `AnyView` | supported | 类型擦除视图 |
| `Group` | supported | 透明分组容器 |
| `ViewModifier` | partial | 支持作用域环境与局部存储状态；比 Apple 完整 `DynamicProperty` 机制精简 |
| `VStack(alignment:spacing:)` | supported | 纵向堆栈布局 |
| `HStack(alignment:spacing:)` | supported | 横向堆栈布局 |
| `Spacer` | partial | 占据主轴剩余空间；未强制执行 `minLength` |
| `Text` | partial | 原生文本测量、自动换行、省略号截断、`.xcstrings` 本地化及拼接富文本片段 |
| `Button(_:action:)` | supported | 原生按钮句柄与激活回调 |
| `Button(action:label:)` | partial | 通过 `ButtonStyle`（`plain`、`bordered`、`borderedProminent`、`borderless`、`link`）支持自定义标签；无样式标签展平为原生文本标题 |
| `ButtonStyle` | partial | 自定义视觉外观、原生激活与 `isPressed` 按压态 |
| `Color` | partial | RGB/透明度、深浅色动态闭包、`.xcassets` 颜色集、`Color(nsColor:)` 及语义色 |
| `Font` | partial | 原生字体族、文本样式与字号；Windows 使用常规/粗体两档字重桶 |
| `Rectangle` | partial | 填充与内描边（`strokeBorder`） |
| `RoundedRectangle` | partial | 圆弧圆角；`continuous` 当前与 `circular` 共用圆弧几何 |
| `Shape` | partial | 自定义 `Path`、`Circle`、`Ellipse`、`Capsule`、`UnevenRoundedRectangle`、`AnyShape`；圆形路径支持 `trim` |
| `ShapeStyle` | partial | `Color`、`HierarchicalShapeStyle`（`.primary`/`.secondary`/…）、`Material`、`Glass`、渐变与 `AnyShapeStyle` |
| `Edge` | supported | 单边枚举与用于内边距的 `Edge.Set` |
| `Alignment` | partial | Frame 与图层对齐 |
| `@State` | partial | 按结构路径、具体视图类型与属性序号寻址；按每个 `Renderer` 根节点独立隔离 |
| `@Binding` | supported | 读写闭包对与常量绑定 |
| `@Bindable`, `@Observable` | supported | 支持 Swift `Observation` 读取追踪与跨渲染器双向属性绑定 |
| `@Environment` | partial | 作用域环境值与 `@Observable` 对象注入，回调闭包可保留快照 |
| `EnvironmentKey` | supported | 带默认值的自定义环境键 |
| `@Entry` | supported | 自动生成 `EnvironmentKey` 与 `EnvironmentValues` 访问器的宏 |
| `EnvironmentValues` | partial | 自定义环境值、`font`、`colorScheme`、`locale`、`openURL`、`dismiss` 与 `accessibilityReduceMotion` |
| `@FocusState` | partial | `Bool` 与可选值焦点绑定；驱动原生按钮/输入框焦点 |
| `.padding(_:)` | supported | 统一间距、`EdgeInsets` 与 `Edge.Set` 重载 |
| `.frame(width:height:alignment:)` | partial | 有序尺寸包装器；支持对齐、`min`/`max` 与 `.infinity` |
| `.background(_:)` | partial | 纯色、`ShapeStyle`、材质与视图构建器背景层 |
| `.overlay` | partial | 不影响主视图测量尺寸的叠加视图与形状层 |
| `.foregroundColor(_:)` | partial | 可继承的 `Text` 与模板矢量图前景色 |
| `.foregroundStyle` | partial | 支持 `Color`、层级样式与各类 `ShapeStyle` |
| `.font` | partial | 作用于 `Text`、表单控件及自定义样式按钮标签 |
| `.lineLimit` | partial | 行数限制与首/尾省略号；富文本多行折行有限 |
| `.lineSpacing` | partial | 行间距设置 |
| `.opacity` | partial | Windows 按图元应用透明度；Linux 使用 Cairo 合成组 |
| `.clipShape` | partial | 矢量绘制路径裁剪与原生控件矩形视口裁剪 |
| `.mask` | partial | 桌面端支持视图 Alpha 遮罩合成 |
| `.contentShape` | partial | Windows 原生按钮圆角点击热区及宿主形状命中测试 |
| `.shadow` | partial | 桌面端基于三次盒式滤波高斯近似的圆角矩形/圆形轮廓阴影 |
| `.animation` | partial | 支持透明度、旋转、缩放、位移与布局尺寸的三次贝塞尔插值动画 |
| `.hidden()` | partial | 折叠布局空间而非保留空白占位 |
| `.disabled(_:)` | partial | 向下继承禁用态；内层显式传入 `false` 可重新启用 |
| `.onTapGesture(perform:)` | partial | 按钮动作及宿主区域命中测试点击 |
| `.onHover` | partial | 控件与宿主悬停检测及向祖先节点冒泡 |
| `.focused` | partial | `Bool` 与可选值焦点绑定；暂不支持焦点作用域（Focus Scope） |
| `.help` | partial | 原生按钮悬停工具提示（Tooltip） |
| `.id(_:)` | partial | 显式指定 diff 身份与局部状态作用域 |
| `App` | supported | 应用入口协议，由 `CrossSwiftUI`（桌面端）与 `SwiftUIWeb`（Wasm）提供运行器 |
| `Scene` | partial | 基于 `@SceneBuilder` 组合 `WindowGroup`、`MenuBarExtra` 与 `Commands` |
| `WindowGroup` | partial | 主窗口、`defaultSize` 默认尺寸与窗口缩放事件 |
| `MenuBarExtra` | partial | 桌面端基于 `CrossAppKit.NSStatusItem`（`NativeAPI.TrayIcon`）的托盘/菜单栏常驻项 |
| `@main` | supported | `App.main()` 启动入口 |
| `Preview` (`#Preview`) | supported | 在非 Apple 平台构建中可直接通过编译的独立预览宏 |
| `SwiftUI` module | supported | 面向 Windows、Linux、WebAssembly、HarmonyOS 与 Android 的统一门面模块 |

## 控件、容器、导航与图形

| 符号 | 状态 | 行为说明 |
|---|---|---|
| `ZStack` | supported | 支持对齐方式与 `zIndex` 排序的层叠容器 |
| `Divider` | supported | 自适应主轴方向的分割线及菜单分隔符 |
| `Label` | partial | 标题 + 图标组合，支持 `LabelStyle`（`titleAndIcon`、`iconOnly`、`titleOnly`） |
| `LabeledContent` | supported | 标签与值对齐行 |
| `Toggle` | partial | 支持 `switch`、`checkbox` 与 `button` 样式；在 Android 与 HarmonyOS 上映射原生/双风格开关 |
| `Slider` | partial | 连续或分段步进滑块；移动端映射原生滑块 |
| `Stepper` | partial | 增减按钮回调或数值绑定步进器 |
| `Picker` | partial | 支持 `segmented`、`menu`、`inline` 与 `radioGroup` 样式 |
| `Menu` | partial | 桌面端为锚定弹出下拉层（`_menuPopover`）；移动端映射原生或双风格菜单 |
| `ProgressView` | partial | 确定性线性进度条与不确定性加载指示器 |
| `ControlGroup` | partial | 水平组合控件容器 |
| `Form`, `Section` | partial | 带页眉与页脚的分组/双列设置表单容器 |
| `List` | partial | 可滚动、支持行选择的列表（`plain`、`inset`、`insetGrouped`、`sidebar`） |
| `NavigationStack`, `NavigationLink` | partial | 基于值或目标视图的压栈导航；Android 下映射 Jetpack Navigation Compose `NavHost`，HarmonyOS 下映射 ArkUI `Navigation` |
| `NavigationSplitView` | partial | 支持侧边栏显隐切换的两栏与三栏分栏导航 |
| `TabView` | partial | 支持选中项绑定及标签图标/文字的标签页容器 |
| `.navigationTitle`, `.toolbar` | partial | 导航栏标题及 `ToolbarItem` / `ToolbarItemGroup` 工具栏项 |
| `.searchable` | partial | 绑定式搜索栏过滤修饰符 |
| `ContentUnavailableView` | supported | 居中的空状态图标、标题、描述与操作按钮占位视图 |
| `Link` | partial | 调用当前作用域的 `OpenURLAction` |
| `ForEach` | partial | 稳定的数据 ID 状态作用域；在 `LazyVStack` 内当元素数 `> 72` 时启用视口虚拟化 |
| `ScrollView` | partial | 纵向/横向滚轮与触控滚动、视口裁剪及滚动几何读取 |
| `LazyVStack` | partial | 大列表（`> 72` 项）视口窗口虚拟化纵向容器 |
| `LazyHStack` | partial | 横向堆栈布局；即时求值所有子项 |
| `Grid` | partial | 跨 `GridRow` 共享列宽的二维网格 |
| `LazyVGrid`, `LazyHGrid` | partial | 支持弹性/固定/自适应轨道的网格布局；即时求值 |
| `GeometryReader` | partial | 基于提案尺寸求值子视图，支持读取局部、全局与命名坐标空间矩形 |
| `Layout` | partial | 支持 `sizeThatFits`/`placeSubviews`、轴向弹性探测与 `AnyLayout` |
| `Path` | partial | 移动、直线、二次/三次贝塞尔曲线、圆弧、圆角矩形与闭合子路径 |
| `Canvas` | partial | 矢量填充/描边、裁剪、平移与缩放绘制画布 |
| `LinearGradient`, `RadialGradient`, `AngularGradient` | partial | 支持显式色标（Stop）的线性、径向与角度渐变 |
| `Image` | partial | 内置 `SFSymbolCatalog`（`systemName:`）、`.xcassets` 图像集与 PDF 矢量图、SVG 路径（保留逐路径填充/描边样式与 `renderingMode`）以及位图文件 |
| `TextField` | partial | 原生单行/多行文本编辑器，支持绑定、选区、IME 输入法及 Windows 透明背景合成 |
| `SecureField` | partial | 原生密码输入框 |
| `TextEditor` | partial | 原生多行文本编辑器 |
| `ObservableObject` | partial | 跨渲染器共享模型失效通知；局部状态与生命周期保持独立 |
| `StateObject` | partial | 按挂载身份保留的延迟初始化对象 |
| `ObservedObject` | partial | 对象订阅与可写 KeyPath 绑定投影 |
| `EnvironmentObject` | partial | 作用域环境对象查找 |
| `.onAppear`, `.onDisappear` | partial | 挂载完成与卸载移除生命周期回调 |
| `.onChange` | partial | 渲染完成后基于 `Equatable` 的新旧值比较回调 |
| `.task` | partial | 可取消的 `@MainActor` 异步任务，当 `id` 变化时自动取消重启 |
| `.gesture` | partial | 支持 `DragGesture`、`TapGesture`、`SpatialTapGesture`；暂不支持多手势优先级仲裁 |
| `.onKeyPress` | partial | 原生键盘事件路由与向祖先冒泡；字符与键盘布局映射有限 |
| `.keyboardShortcut` | partial | 作用域键盘快捷键；Windows/Linux 上 `Command` 快捷键同时兼容 `Control` |
| `.popover` | partial | 带箭头外框、四向边缘自动翻转、外部点击/Escape 关闭及 `presentationBackgroundInteraction` 的根层气泡 |
| `.sheet` | partial | 桌面与 Web 端为模态卡片层；移动端为原生/双风格底部弹窗（Bottom Sheet） |
| `.confirmationDialog` | partial | 支持破坏性与取消角色的操作确认弹窗 |
| `.contextMenu` | partial | 右键触发的根层上下文菜单，选择菜单项后自动收起 |
| `withAnimation` | partial | 将同步状态更新标记为支持属性与布局插值的动画事务 |
| `.transition` | partial | 接收转场元数据；插入/移除过渡动画尚未驱动渲染插值 |
| `.accessibilityLabel` | partial | 映射至原生控件无障碍名称；纯绘制装饰节点仅保留元数据 |
| `.border` | supported | 形状描边叠加层 |
| `.cornerRadius` | partial | 圆弧裁剪几何 |

## 附加跨平台与 AppKit 桥接 API

| 符号 | 状态 | 备注 |
|---|---|---|
| `ViewThatFits` | partial | 选取首个理想尺寸满足请求轴向的候选视图，兜底选取末项；所有候选即时求值 |
| `TimelineView(.animation(...))` | partial | 可取消的定时日期刷新，支持自定义间隔与暂停；未绑定显示器垂直同步信号 |
| `ScrollViewReader`, `ScrollViewProxy.scrollTo` | partial | 支持显式 ID 定位、锚点、轴向边界钳制与重复跳转请求；无滚动插值动画 |
| `transformPreference`, `overlayPreferenceValue` | partial | 子节点偏好归约、有序变换及 `Equatable` 叠加层更新 |
| `LocalizedStringKey`, `LocalizedStringResource` | partial | 基于 `XCStringsCatalog` 的 `.xcstrings` 字符串目录查询与格式化插值 |
| `OpenURLAction`, `Text(AttributedString)` | partial | 链接点击调用作用域 `openURL`；支持前景色、背景色、字体、下划线与删除线等基础属性 |
| `Text.kerning` | partial | 在纯文本与拼接片段上保留字距追踪元数据 |
| `ButtonRole` | partial | 取消快捷键绑定与破坏性操作红色样式 |
| `alert(_:isPresented:actions:message:)` | partial | 桌面与 Web 端为居中模态面板；移动端映射原生/双风格警告框 |
| `saturation`, `grayscale` | partial | 变换显式前景色/背景色/边框色，而非后处理像素级滤镜 |
| `blur` | partial | 编译兼容的透明度降级近似，非高斯像素模糊滤镜 |
| `LongPressGesture` | partial | 编译兼容的手势包装类型，尚未实现按压时长与位移阈值计时器 |
| `background(_:in:)` | supported | 在内容背后填充指定形状 |
| `FocusState.Binding.wrappedValue` | supported | 直接读写保留的焦点状态值 |
| `textSelection`, `accessibilityIdentifier` | partial | 保留元数据；自绘文本尚未接入系统级划词选区桥接 |
| `NSHostingView`, `NSHostingController` | partial | 在 `CrossAppKit` 窗口、面板与分栏视图中嵌入独立的 `SwiftUIRuntime` `Renderer`（由 `CrossSwiftUI` 提供） |
| `NSViewRepresentable` | partial | 在 SwiftUI 布局树中挂载并更新 `CrossAppKit.NSView` 实例（由 `CrossSwiftUI` 提供） |
| `NSApplicationDelegateAdaptor` | supported | 在 Windows 与 Linux 上从 `App` 注入 `CrossAppKit.NSApplicationDelegate`（由 `CrossSwiftUI` 提供） |

## 尚未实现

| 符号 | 状态 | 备注 |
|---|---|---|
| `Window`, `Settings`, `DocumentGroup` | missing | 声明式多窗口场景类型（可通过 `CrossAppKit` 的 `NSWindow`/`NSPanel` 搭配 `NSHostingView` 创建额外窗口） |
| 同时/高优先级手势仲裁 | missing | `.simultaneousGesture` / `.highPriorityGesture` 仅保留签名兼容，未实现完整手势竞争状态机 |
| 后合成像素级 GPU 滤镜 | missing | `.brightness`、`.contrast` 及针对任意子树的真实高斯像素 `.blur` |
