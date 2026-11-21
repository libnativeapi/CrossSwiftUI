# CrossSwift Skills

English | [简体中文](./README-ZH.md)

Agent skills for [CrossSwift](../README.md) (`crossswift`) — teaching coding agents how to inspect and build unmodified Apple projects with CrossSwift's cross-platform `xcodebuild` CLI (`CrossXcodeBuild` / `CrossXcodeBuildCLI`).

## Skills

| Skill | Covers | Typical requests |
| --- | --- | --- |
| [`xcodebuild`](xcodebuild/) | Inspecting and building unmodified `.xcodeproj` / `.xcworkspace` apps for Windows, Linux, WebAssembly, HarmonyOS, and Android | "build this Xcode project for Windows/Linux/Wasm/HarmonyOS/Android", "inspect schemes or build settings with CrossSwift xcodebuild" |

## Layout

```text
skills/
└── xcodebuild/
    ├── SKILL.md
    └── references/
        └── platforms.md
```

## Installing

```bash
npx skills add libnativeapi/crossswift
```

Add `-g` to install globally instead of into the current project.

## Source of truth

Content is distilled from [`Sources/CrossXcodeBuild/`](../Sources/CrossXcodeBuild/) and [`Sources/CrossXcodeBuildCLI/`](../Sources/CrossXcodeBuildCLI/). When this skill and the CLI disagree, trust `swift run xcodebuild --help` and update the skill.
