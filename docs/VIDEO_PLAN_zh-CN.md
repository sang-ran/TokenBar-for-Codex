# TokenBar 首发短视频方案

目标：用 20–25 秒说明一个核心价值——无需打开额外页面，也能在 macOS
菜单栏实时看到 Codex Token 用量和配额。

## 画面规格

- 主版本：1920×1080、30 fps、16:9
- 竖屏裁切版：1080×1920，用于小红书、即刻等平台
- 使用浅色 macOS 菜单栏，放大到观众能读清数字
- 关闭通知，隐藏用户名、邮箱、桌面文件和真实对话
- 录制前退出其他 Token 监控应用，只保留 TokenBar

## 25 秒分镜

| 时间 | 画面 | 屏幕字幕 |
| --- | --- | --- |
| 0–3 秒 | Codex 开始执行一个不含隐私的演示任务 | 用 Codex 时，Token 用了多少？ |
| 3–8 秒 | 特写菜单栏，Token 数字随任务变化 | 实时显示，不用反复点击 |
| 8–14 秒 | 点击 TokenBar，展示当前任务、Input、Cached、Output | 用量明细，一眼看清 |
| 14–18 秒 | 展示 5 小时与每周配额 | 配额也在同一个地方 |
| 18–22 秒 | 快速显示“Native AppKit / Local only / No telemetry” | 原生、轻量、本地处理 |
| 22–25 秒 | 应用图标、名称和 GitHub 地址 | 开源下载：sang-ran/TokenBar-for-Codex |

## 旁白

> 我做了一个极简的 macOS 菜单栏工具 TokenBar。它会实时显示当前 Codex
> 任务的 Token 用量和账号配额，不用再打开额外页面。原生 Swift 编写，
> 本地处理，没有遥测。项目已经开源。

不配旁白时，直接使用上表中的六段字幕。

## 安全的演示任务

新建一个专门用于录屏的 Codex 任务，内容可以是：

> 生成一个包含 20 个示例项目的 Markdown 待办清单，每项补充一句说明。

不要录制已有任务、真实代码仓库、账号页面或 `~/.codex` 内容。

## 录制顺序

1. 使用 Debug QA 窗口拍摄静态详情画面：

   ```bash
   swift build
   ".build/debug/TokenBar" --qa-window
   ```

2. 使用正式版和新的演示任务录制菜单栏数字变化。
3. 分别录制菜单栏特写、弹窗详情和结尾品牌页。
4. 后期只做裁切、放大、字幕和简单淡入淡出，避免花哨转场。

## 发布配文

> 做了一个开源的 macOS 菜单栏工具 TokenBar for Codex，可以实时显示当前
> Token 用量和限额百分比。它使用原生 AppKit 编写，空闲 CPU 接近 0%，
> 数据在本地处理，不包含遥测。目前支持 Apple Silicon 和 macOS 14+。
>
> GitHub：https://github.com/sang-ran/TokenBar-for-Codex
