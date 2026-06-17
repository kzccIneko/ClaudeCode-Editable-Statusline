# Claude Code Statusline

Modular, user-configurable status bar for [Claude Code](https://claude.ai/code) CLI. Works on Windows, macOS, and Linux. Works with any model (Claude, DeepSeek, etc. via Anthropic API route).

## Preview

```
deepseek-v4-pro /max [my-session]  my-project (main)
Ctx: 42%  Cache: 96%  In: 13k  Out: 8k  ~$0.04  5h: 12% -> 21:00  7d: 45% -> Thu 00:00
```

- **Line 1**: model name, effort level, session name, git repo + branch
- **Line 2**: context usage, cache hit rate, token I/O, cost, rate limits
- **Colors**: green = good, yellow = warning, red = high

## One-Click Setup

### Windows
```powershell
powershell -ExecutionPolicy Bypass -File setup.ps1
```

### Mac / Linux
```bash
chmod +x setup.sh && ./setup.sh
```

Restart Claude Code after setup.

## Modular Configuration

Edit `~/.claude/statusline-config.json` to pick exactly what you want:

```json
{
  "line1": ["model", "effort", "session", "git"],
  "line2": ["ctx", "cache", "tokens", "cost", "rate5h", "rate7d"],
  "colors": true,
  "session_max_len": 24
}
```

### Available Modules

| Key | Displays | Example |
|-----|----------|---------|
| `model` | Model display name | `deepseek-v4-pro` |
| `effort` | Effort level | `/max` |
| `session` | Session name (truncatable) | `[my-session]` |
| `git` | Git repo + branch | `project (main)` |
| `ctx` | Context window usage % | `Ctx: 42%` |
| `cache` | Prompt cache hit rate % | `Cache: 96%` |
| `tokens` | Input/output token counts | `In: 13k Out: 8k` |
| `cost` | Estimated session cost | `~$0.04` |
| `rate5h` | 5-hour rate limit + reset | `5h: 12% -> 21:00` |
| `rate7d` | 7-day rate limit + reset | `7d: 45% -> Thu 00:00` |

### Examples

**Minimal** — only model + git + context:
```json
{
  "line1": ["model", "git"],
  "line2": ["ctx", "tokens"]
}
```

**Cost-focused**:
```json
{
  "line1": ["model"],
  "line2": ["tokens", "cost", "rate5h"]
}
```

**No colors** (for terminals that don't support ANSI):
```json
{
  "colors": false
}
```

## FAQ

### Does this consume extra tokens?
No. The statusline reads from Claude Code's local session metadata — zero API calls, zero token cost.

### My rate limits don't show up
Some API providers (e.g. DeepSeek) don't report rate limit info. The script gracefully skips unavailable fields.

### Does this work regardless of where Claude Code is installed?
Yes. The setup only touches `~/.claude/` — Claude Code's standard user config directory, independent of binary location. Works with CLI, npm global install, and Claude for Desktop (Claudian).

### Using Claude for Desktop (Claudian)?
If the global config doesn't take effect, add `statusLine` to your project's `.claude/settings.json` instead:

```json
{
  "statusLine": {
    "type": "command",
    "command": "powershell -NoProfile -NonInteractive -File \"%USERPROFILE%\\.claude\\statusline.ps1\""
  }
}
```

### How do I reset to default config?
Delete `~/.claude/statusline-config.json` and re-run `setup.ps1` / `setup.sh`.

### How do I uninstall?
Remove the `statusLine` field from `~/.claude/settings.json`, then delete `~/.claude/statusline.ps1` (or `.sh`) and `~/.claude/statusline-config.json`.

## Files

```
claude-code-statusline/
├── setup.ps1               Windows one-click setup
├── setup.sh                Mac/Linux one-click setup
├── statusline.ps1          Windows statusline script (modular)
├── statusline.sh           Mac/Linux statusline script (modular)
├── statusline-config.json  Default config (user-customizable)
├── LICENSE                 MIT
├── .gitignore
└── README.md
```

## License

MIT
