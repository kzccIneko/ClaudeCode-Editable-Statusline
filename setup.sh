#!/usr/bin/env bash
# Claude Code Statusline — Mac / Linux one-click setup
set -e

DIR="$HOME/.claude"
SCRIPT_PATH="$DIR/statusline.sh"
CFG_PATH="$DIR/statusline-config.json"
SETTINGS_PATH="$DIR/settings.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================"
echo " Claude Code Statusline Setup (Mac/Linux)"
echo "========================================"
echo ""

# ── 1. Ensure .claude exists ──
mkdir -p "$DIR"

# ── 2. Copy statusline script ──
if [ -f "$SCRIPT_DIR/statusline.sh" ]; then
    cp "$SCRIPT_DIR/statusline.sh" "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    echo "[1/3] statusline.sh -> $SCRIPT_PATH"
else
    echo "ERROR: statusline.sh not found. Run from the project folder."
    exit 1
fi

# ── 3. Copy config (never overwrite existing) ──
if [ ! -f "$CFG_PATH" ]; then
    if [ -f "$SCRIPT_DIR/statusline-config.json" ]; then
        cp "$SCRIPT_DIR/statusline-config.json" "$CFG_PATH"
        echo "[2/3] statusline-config.json -> $CFG_PATH"
    fi
else
    echo "[2/3] Config already exists, skipped (delete it to reinstall default)"
fi

# ── 4. Update settings.json ──
STATUSLINE_JSON='{"type":"command","command":"bash '"$SCRIPT_PATH"'"}'

if [ -f "$SETTINGS_PATH" ]; then
    python3 -c "
import json
with open('$SETTINGS_PATH') as f:
    s = json.load(f)
s['statusLine'] = json.loads('''$STATUSLINE_JSON''')
with open('$SETTINGS_PATH', 'w') as f:
    json.dump(s, f, indent=2, ensure_ascii=False)
    f.write('\n')
" 2>/dev/null || {
    echo "WARNING: Could not auto-update settings.json"
    echo "Please manually add to $SETTINGS_PATH:"
    echo "  \"statusLine\": $STATUSLINE_JSON"
    exit 1
}
    echo "[3/3] settings.json updated"
else
    echo "{\"statusLine\": $STATUSLINE_JSON}" > "$SETTINGS_PATH"
    echo "[3/3] settings.json created"
fi

echo ""
echo "Setup complete! Restart Claude Code to see the statusline."
echo ""
echo "Customize: edit ~/.claude/statusline-config.json"
echo "  - Add/remove/reorder modules in 'line1' and 'line2'"
echo "  - Set 'colors' to false to disable ANSI colors"
echo "  - Available: model, effort, session, git, ctx, cache, tokens, cost, rate5h, rate7d"
