# Privacy

TokenBar for Codex is designed to keep its work local.

## Data accessed

- The active Codex task metadata and token-count events stored under `~/.codex`
- Codex account type and rate-limit windows exposed by the locally installed
  Codex read-only app server
- TokenBar preferences stored in macOS `UserDefaults`

## Data handling

- TokenBar reads only the fields needed to display token usage and quota.
- Conversation text is not collected or sent to the developer.
- TokenBar contains no analytics, advertising, telemetry, crash-reporting SDK,
  or update tracker.
- TokenBar does not store API keys or account credentials.
- Quota requests are made through the user's installed Codex executable and are
  therefore subject to Codex and OpenAI's own data practices.

Uninstalling the app removes the executable. macOS may retain its small
preference record until it is removed from the user's preferences.
