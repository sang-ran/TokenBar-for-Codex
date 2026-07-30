# Contributing

Thanks for helping improve TokenBar for Codex.

## Before opening an issue

- Check existing issues first.
- State the macOS and Codex versions.
- Describe the expected and actual behavior.
- Never attach credentials, conversation content, or unredacted files from
  `~/.codex`.

## Development

The project targets Apple Silicon and macOS 14 or later. It is implemented with
AppKit and intentionally has no third-party dependencies.

```bash
swift test
swift build
Scripts/package.sh release
```

Keep changes focused on live token and quota monitoring. Run the tests before
opening a pull request.
