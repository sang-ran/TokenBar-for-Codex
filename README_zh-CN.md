# TokenBar for Codex

[English](README.md)

一个轻量、原生的 macOS 菜单栏应用，用于实时查看当前 Codex 任务的 token
用量与账号配额。

TokenBar 不占用 Dock，只把真正有用的数字放在菜单栏。项目刻意保持简单：
没有多服务商框架、费用数据库、浏览器自动化、桌面组件或常驻后台服务。

> [!IMPORTANT]
> TokenBar for Codex 是独立开源项目，与 OpenAI 无隶属、背书或维护关系。

## 功能

- 实时显示当前 Codex 任务的 token 数量
- 显示 Input、Cached Input 和 Output 明细
- 订阅账号显示 5 小时及每周剩余配额
- API Key 账号自动切换为仅 token 模式
- 菜单栏单行、双行两种样式
- 可选的低配额警告颜色
- 可选登录时自动启动
- 纯 AppKit 实现，无第三方依赖

## 系统要求

- Apple Silicon（M 系列芯片）Mac
- macOS 14 Sonoma 或更高版本
- 已登录并至少使用过一次的 Codex 桌面版或 Codex CLI

安装预编译版本**不需要 Xcode**。

## 安装

1. 从 [Releases](https://github.com/sang-ran/TokenBar-for-Codex/releases)
   下载 `TokenBar-for-Codex-v0.1.0-alpha.zip`。
2. 解压后将 **TokenBar for Codex.app** 移入“应用程序”文件夹。
3. 当前 Alpha 尚未经过 Apple 公证，第一次运行请按住 Control 点击应用，
   再选择“打开”。

应用不会显示 Dock 图标，token 数量会直接出现在 macOS 菜单栏。

## 刷新机制

TokenBar 增量读取 `~/.codex` 中当前任务的 token 事件，不会在每次刷新时
重新扫描整个日志。任务活跃时约每 0.4 秒检查一次；空闲后最长每 1 秒
检查一次，在响应速度和资源占用之间保持平衡。

订阅账号的配额通过本机 Codex 的只读 app-server 每 5 分钟刷新一次，
弹窗内也可手动刷新。API Key 账号没有订阅配额窗口，因此会自动隐藏配额。

## 隐私

TokenBar 不包含统计分析、广告、遥测或更新跟踪。对话内容不会发送给开发者。
详情见 [PRIVACY.md](PRIVACY.md)。

## 从源码构建

需要 Swift 5.10 或更高版本：

```bash
swift test
Scripts/package.sh release
open ".build/TokenBar for Codex.app"
```

打包脚本会生成一个仅支持 arm64、使用 ad-hoc 签名的应用。

## 当前状态

`v0.1.0-alpha` 是首个公开测试版本。Codex 的本地存储与 app-server
接口并非公开的兼容性承诺，后续 Codex 更新可能需要 TokenBar 同步适配。

## 参与贡献

欢迎提交问题和目标明确的 Pull Request。请先阅读
[CONTRIBUTING.md](CONTRIBUTING.md)，并且不要在公开 Issue 中附带对话内容、
账号凭据或本地 Codex 日志。

## 许可证

[MIT](LICENSE)
