# UsageMenu — Claude Code + Codex plan usage in the macOS menubar

Native SwiftUI `MenuBarExtra` app. Reuses the logins from your CLIs, no tokens to paste.

## What it shows

Menubar label: `CC 86% · CX 3%` (5-hour utilization for each).

Dropdown:
- **Claude Code** — Session (5h) + Weekly (7d) utilization bars with `resets in Xh Ym · 8:00 PM`. Opus/Sonnet weekly rows appear when non-zero.
- **Codex** — 5-hour + Weekly bars with reset countdowns, plan type (e.g. Plus), banked resets count, limit-reached warning.

Auto-refreshes every 5 min (30s countdown ticks). Manual Refresh button included.

## Endpoints

> **Unofficial.** Neither endpoint is a documented public API. They are the internal endpoints the official CLIs use, and the app mimics those CLIs' `User-Agent`. They can change or disappear without notice; use at your own risk and within each provider's terms. Credentials are only read locally and only sent to the provider that issued them.

### Claude Code

```
GET https://claude.ai/api/oauth/usage
Authorization: Bearer <accessToken>
anthropic-beta: oauth-2025-04-20
User-Agent: claude-code/<version>
```

Token: macOS Keychain, generic password, service `Claude Code-credentials`. Value is JSON; the token is at `claudeAiOauth.accessToken`. Created by `claude login`.

Response fields used (all optional):

| Field | Meaning |
|---|---|
| `five_hour.utilization` | Session (5h) usage, percent 0–100 |
| `five_hour.resets_at` | ISO-8601 reset time |
| `seven_day.*` | Weekly window, same shape |
| `seven_day_opus.*`, `seven_day_sonnet.*` | Per-model weekly windows |
| `*.limit_dollars`, `used_dollars`, `remaining_dollars` | Dollar figures, when present |
| `limits[]` | `kind`, `group`, `percent`, `severity`, `resets_at` |
| `extra_usage.is_enabled`, `disabled_reason` | Extra-usage status |

Rate-limited: the app refetches every 5 min.

### Codex

```
GET https://chatgpt.com/backend-api/codex/usage
Authorization: Bearer <tokens.access_token>
ChatGPT-Account-Id: <tokens.account_id>
User-Agent: codex-cli/<version>
```

Token: `~/.codex/auth.json`, keys `tokens.access_token` and `tokens.account_id`. Created by `codex login`.

Response fields used (all optional):

| Field | Meaning |
|---|---|
| `plan_type` | e.g. `plus` |
| `rate_limit.allowed`, `limit_reached` | Current limit state |
| `rate_limit.primary_window` | 5h window (`limit_window_seconds = 18000`) |
| `rate_limit.secondary_window` | Weekly window (`limit_window_seconds = 604800`) |
| `*_window.used_percent` | Usage, percent 0–100 |
| `*_window.reset_at` | Reset time, unix seconds |
| `*_window.reset_after_seconds` | Seconds until reset |
| `credits.has_credits`, `balance`, `unlimited` | Credit balance |
| `rate_limit_reset_credits.available_count` | Banked resets |

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

- Codex has no universal reset clock; the app always uses the `reset_at` timestamp from your account.
- Bundle is ad-hoc signed (`LSUIElement=true`, no Dock icon). For distribution, sign with your Developer ID.

## License

MIT — see [LICENSE](LICENSE).
