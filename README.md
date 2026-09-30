# UsageMenu — Claude Code + Codex plan usage in the macOS menubar

Native SwiftUI `MenuBarExtra` app. Reuses the logins from your CLIs, no tokens to paste.

## What it shows

Menubar label: `CC 86% · CX 3%` (5-hour utilization for each).

Dropdown:
- **Claude Code** — Session (5h) + Weekly (7d) utilization bars with `resets in Xh Ym · 8:00 PM`. Opus/Sonnet weekly rows appear when non-zero.
- **Codex** — 5-hour + Weekly bars with reset countdowns, plan type (e.g. Plus), banked resets count, limit-reached warning.

Auto-refreshes every 5 min (30s countdown ticks). Manual Refresh button included.

## Data sources (verified on this Mac)

- Claude: `GET https://claude.ai/api/oauth/usage` with `Bearer` token from Keychain service `Claude Code-credentials` → `claudeAiOauth.accessToken`. Returns `five_hour.utilization` / `resets_at`, `seven_day.*`.
- Codex: `GET https://chatgpt.com/backend-api/codex/usage` with `Bearer <tokens.access_token>` + `ChatGPT-Account-Id` from `~/.codex/auth.json`. Returns `rate_limit.primary_window` (5h) and `secondary_window` (weekly) with `used_percent` + `reset_at` (unix).

If either CLI is logged out, that section shows the error with a hint to re-login.

## Build & run

```sh
chmod +x Scripts/build-app.sh
./Scripts/build-app.sh
open .build/UsageMenu.app
```

Optional install:
```sh
cp -R .build/UsageMenu.app /Applications/UsageMenu.app
open /Applications/UsageMenu.app
```

Launch at login: System Settings → General → Login Items → add UsageMenu.

## Notes

- Claude's `/api/oauth/usage` is rate-limited; the app caches and refetches every 5 min (same policy as `claude /usage`, which falls back to last-known within 60 min).
- Codex windows: `primary_window.limit_window_seconds = 18000` (5h), `secondary_window = 604800` (weekly). No universal reset clock — the app always uses the `reset_at` timestamp from your account.
- Bundle is ad-hoc signed (`LSUIElement=true`, no Dock icon). For distribution, sign with your Developer ID.
