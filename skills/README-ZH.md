# CrossSwift 技能包（Skills）

[English](./README.md) | 简体中文

面向 [CrossSwift](../README-ZH.md)（`crossswift`）的编码智能体技能包——指导编码智能体使用 CrossSwift 的跨平台 `xcodebuild` 命令行工具（`CrossXcodeBuild` / `CrossXcodeBuildCLI`）检查并构建未修改的 Apple 工程。

## 技能列表

| 技能 | 覆盖范围 | 典型请求示例 |
| --- | --- | --- |
| [`xcodebuild`](xcodebuild/) | 检查并将未修改的 `.xcodeproj` / `.xcworkspace` 应用编译至 Windows、Linux、WebAssembly、HarmonyOS 与 Android | “把这个 Xcode 工程编译成 Windows/Linux/Wasm/HarmonyOS/Android 版本”、“用 CrossSwift xcodebuild 查看 schemes 或构建设置” |

## 目录结构

```text
skills/
└── xcodebuild/
    ├── SKILL.md
    └── references/
        └── platforms.md
```

## 安装方式

```bash
npx skills add libnativeapi/crossswift
```

添加 `-g` 可安装至全局环境，而非仅限当前项目。

## 权威来源

技能文档提炼自 [`Sources/CrossXcodeBuild/`](../Sources/CrossXcodeBuild/) 与 [`Sources/CrossXcodeBuildCLI/`](../Sources/CrossXcodeBuildCLI/)。若技能说明与命令行工具实际行为不一致，请以 `swift run xcodebuild --help` 为准并同步更新技能文档。
