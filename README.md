# TokenBar for Codex

[简体中文](README_zh-CN.md)

A lightweight, native macOS menu-bar app for monitoring the current Codex task's
token usage and account quota.

TokenBar stays out of the Dock and puts the useful numbers directly in the menu
bar. It is intentionally focused: no provider framework, cost database,
browser automation, widgets, or background daemon.

> [!IMPORTANT]
> TokenBar for Codex is an independent open-source project. It is not affiliated
> with, endorsed by, or maintained by OpenAI.

## Features

- Live token count for the active Codex task
- Input, cached-input, and output token breakdown
- Remaining 5-hour and weekly quota for subscription accounts
- Token-only mode for API-key accounts
- One-line and two-line menu-bar layouts
- Optional low-quota warning colors
- Optional launch at login
- Native AppKit implementation with no third-party dependencies

## Requirements

- Apple Silicon Mac
- macOS 14 Sonoma or later
- Codex desktop app or Codex CLI, signed in and used at least once

Xcode is **not** required when installing the prebuilt app.

## Install

1. Download `TokenBar-for-Codex-v0.1.0-alpha.zip` from
   [Releases](https://github.com/sang-ran/TokenBar-for-Codex/releases).
2. Unzip it and move **TokenBar for Codex.app** to `/Applications`.
3. Because the current alpha is not notarized, Control-click the app and choose
   **Open** the first time.

The app has no Dock icon. Its token count appears in the macOS menu bar.

## How it works

TokenBar reads token-count events incrementally from the active task under
`~/.codex`. It does not parse the whole task log on every refresh. While a task
is active, it checks for new events about every 0.4 seconds; the interval backs
off to at most 1 second when idle.

For subscription accounts, quota is refreshed every five minutes through the
installed Codex read-only app server. A manual refresh button is available in
the popover. API-key accounts automatically hide quota because subscription
quota windows do not apply.

## Privacy

TokenBar has no analytics, advertising, telemetry, or update tracker. Conversation
content is not sent to the developer. See [PRIVACY.md](PRIVACY.md) for details.

## Build from source

Swift 6.2 or later is recommended.

```bash
swift test
Scripts/package.sh release
open ".build/TokenBar for Codex.app"
```

The packaging script produces an ad-hoc signed, arm64-only application.

## Status

`v0.1.0-alpha` is an early public release. Codex's local storage and app-server
interfaces are not public compatibility guarantees, so future Codex versions
may require TokenBar updates.

## Contributing

Bug reports and focused pull requests are welcome. Please read
[CONTRIBUTING.md](CONTRIBUTING.md) and avoid including conversation content,
credentials, or local Codex logs in public issues.

## License

[MIT](LICENSE)
