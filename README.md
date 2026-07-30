# TokenBar for Codex

<p align="center">
  <img src="docs/images/social-preview.png" alt="TokenBar for Codex — live token usage in the macOS menu bar" width="100%">
</p>

<p align="center">
  <a href="https://github.com/sang-ran/TokenBar-for-Codex/actions/workflows/build.yml"><img src="https://github.com/sang-ran/TokenBar-for-Codex/actions/workflows/build.yml/badge.svg" alt="Build status"></a>
  &nbsp; · &nbsp;
  <a href="https://github.com/sang-ran/TokenBar-for-Codex/releases"><strong>Download the latest alpha</strong></a>
  &nbsp; · &nbsp;
  <a href="README_zh-CN.md">简体中文</a>
</p>

TokenBar is a focused, native macOS menu-bar app for seeing the current Codex
task's token usage and account quota at a glance.

It stays out of the Dock and puts the useful numbers directly in the menu bar.
No provider framework, cost database, browser automation, widgets or background
daemon.

> [!IMPORTANT]
> TokenBar for Codex is an independent open-source project. It is not affiliated
> with, endorsed by, or maintained by OpenAI.

## Why TokenBar

- **Visible without a click:** current tokens and quota can stay in the menu bar.
- **Responsive:** active tasks are checked for new token events about every
  0.4 seconds.
- **Focused:** one small native app, with no third-party runtime dependencies.
- **Private:** no analytics, advertising, telemetry or update tracking.

## Features

- Live token count for the active Codex task
- Input, cached-input and output token breakdown
- Remaining 5-hour and weekly quota for subscription accounts
- Automatic token-only mode for API-key accounts
- One-line and two-line menu-bar layouts
- Optional low-quota warning colors
- Optional launch at login
- Native AppKit implementation with no third-party dependencies

The screenshot uses anonymous sample data from TokenBar's Debug-only QA mode.

## Performance

On the development Apple Silicon Mac, a typical idle measurement was near
`0%` CPU and about `24 MB` of physical memory. Values vary with macOS, Codex
activity and system configuration.

## Requirements

- Apple Silicon Mac
- macOS 14 Sonoma or later
- Codex desktop app or Codex CLI, signed in and used at least once

Xcode is **not** required when installing the prebuilt app.

## Install

1. Download `TokenBar-for-Codex-v0.1.0-alpha.zip` and its `.sha256` file from
   [Releases](https://github.com/sang-ran/TokenBar-for-Codex/releases).
2. Compare the archive's SHA-256 value with the checksum published on the
   Release page:

   ```bash
   shasum -a 256 TokenBar-for-Codex-v0.1.0-alpha.zip
   ```

3. Unzip it and move **TokenBar for Codex.app** to `/Applications`.
4. The current alpha is not notarized. Control-click the app and choose
   **Open** the first time.

TokenBar has no Dock icon. Its token count appears in the macOS menu bar.

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

TokenBar processes Codex usage information locally. Conversation content is not
sent to the developer. See [PRIVACY.md](PRIVACY.md) for the exact data flow and
limitations.

## Troubleshooting

- **The menu-bar value is `—`:** open Codex, start or resume a task, and wait
  for its first token event.
- **Quota is hidden:** this is expected for API-key accounts.
- **Quota is temporarily unavailable:** use the refresh button and confirm the
  installed Codex app or CLI is signed in.
- **macOS blocks the alpha:** Control-click the app and choose **Open**. This
  workaround will be removed after a Developer ID notarized release.

When reporting a problem, never attach conversation logs, credentials or the
contents of `~/.codex`.

## Build from source

Swift 5.10 or later is required.

```bash
swift test
Scripts/package.sh release
open ".build/TokenBar for Codex.app"
```

The default packaging path produces an ad-hoc signed, arm64-only application.
`Scripts/create_archive.sh` creates a clean zip without `__MACOSX` metadata.
Maintainer instructions for Developer ID signing, notarization and the future
Homebrew Cask are in [DISTRIBUTION.md](DISTRIBUTION.md).

For repeatable UI screenshots, Debug builds provide an anonymous QA window:

```bash
swift build
".build/debug/TokenBar" --qa-window
```

## Status

`v0.1.0-alpha` is an early public release. Codex's local storage and app-server
interfaces are not public compatibility guarantees, so future Codex versions
may require TokenBar updates.

## Contributing

Bug reports and focused pull requests are welcome. Please read
[CONTRIBUTING.md](CONTRIBUTING.md) and avoid including conversation content,
credentials or local Codex logs in public issues.

## License

[MIT](LICENSE)
