#!/usr/bin/env bash
# Claude Code Statusline — modular bash script
# Reads config from ~/.claude/statusline-config.json
# Each field in line1/line2 is a self-contained module.

input=$(cat)
[ -z "$input" ] && exit 0

# ── JSON helper ──
json_val() {
    python3 -c "
import json,sys
d=json.load(sys.stdin)
keys='$1'.split('.')
v=d
for k in keys:
    if isinstance(v,dict) and k in v: v=v[k]
    else: sys.exit(1)
if isinstance(v,bool): print('true' if v else 'false')
elif v is None: sys.exit(1)
else: print(v)
" <<< "$input" 2>/dev/null
}

# ── Load config ──
CFG="$HOME/.claude/statusline-config.json"
LINE1_KEYS="model effort session git"
LINE2_KEYS="ctx cache tokens cost rate5h rate7d"
USE_COLORS=true
SESS_MAX=24

if [ -f "$CFG" ]; then
    LINE1_KEYS=$(python3 -c "
import json
c=json.load(open('$CFG'))
print(' '.join(c.get('line1',['model','effort','session','git'])))
" 2>/dev/null || echo "$LINE1_KEYS")
    LINE2_KEYS=$(python3 -c "
import json
c=json.load(open('$CFG'))
print(' '.join(c.get('line2',['ctx','cache','tokens','cost','rate5h','rate7d'])))
" 2>/dev/null || echo "$LINE2_KEYS")
    USE_COLORS=$(python3 -c "
import json
c=json.load(open('$CFG'))
print('true' if c.get('colors',True) else 'false')
" 2>/dev/null || echo "true")
    SESS_MAX=$(python3 -c "
import json
c=json.load(open('$CFG'))
print(c.get('session_max_len',24))
" 2>/dev/null || echo "24")
fi

# ── Colors ──
if [ "$USE_COLORS" = "true" ]; then
    G='\033[32m'; Y='\033[33m'; R='\033[31m'; C='\033[36m'; E='\033[0m'
else
    G=''; Y=''; R=''; C=''; E=''
fi

# ── Helpers ──
pct_bad() {
    local n=$(printf "%.0f" "$1" 2>/dev/null)
    if   [ "$n" -ge 76 ]; then printf "${R}%s%%${E}" "$n"
    elif [ "$n" -ge 51 ]; then printf "${Y}%s%%${E}" "$n"
    else                      printf "${G}%s%%${E}" "$n"
    fi
}
pct_good() {
    local n=$(printf "%.0f" "$1" 2>/dev/null)
    if   [ "$n" -ge 71 ]; then printf "${G}%s%%${E}" "$n"
    elif [ "$n" -ge 41 ]; then printf "${Y}%s%%${E}" "$n"
    else                      printf "${R}%s%%${E}" "$n"
    fi
}

# ═══════════════════ MODULES ═══════════════════
m_model() {
    local v=$(json_val 'model.display_name')
    echo "${v:-Unknown}"
}
m_effort() {
    local v=$(json_val 'effort.level')
    [ -n "$v" ] && echo "/$v"
}
m_session() {
    local v=$(json_val 'session_name')
    [ -z "$v" ] && return
    [ "${#v}" -gt "$SESS_MAX" ] && v="${v:0:$((SESS_MAX-2))}.."
    echo "[$v]"
}
m_git() {
    local cwd=$(json_val 'workspace.current_dir')
    [ -z "$cwd" ] && { echo "no git"; return; }
    git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1 || { echo "no git"; return; }
    local repo=$(basename "$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)")
    local branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
    echo "$repo ($branch)"
}
m_ctx() {
    local v=$(json_val 'context_window.used_percentage')
    if [ -n "$v" ] && [ "$v" != "None" ]; then
        printf "Ctx: %s" "$(pct_bad "$v")"
    fi
}
m_cache() {
    local cr=$(json_val 'context_window.current_usage.cache_read_input_tokens'); cr=${cr:-0}
    local ci=$(json_val 'context_window.current_usage.input_tokens'); ci=${ci:-0}
    local t=$((cr + ci))
    if [ "$t" -gt 0 ]; then
        local cp=$(python3 -c "print(round($cr/$t*100))")
        printf "Cache: %s" "$(pct_good "$cp")"
    fi
}
m_tokens() {
    local i=$(json_val 'context_window.total_input_tokens')
    local o=$(json_val 'context_window.total_output_tokens')
    if [ -n "$i" ] && [ -n "$o" ] && [ "$i" != "None" ] && [ "$o" != "None" ]; then
        local ik=$(python3 -c "print(f'{int($i)/1000:.0f}k')")
        local ok=$(python3 -c "print(f'{int($o)/1000:.0f}k')")
        printf "${C}In:${E} %s  ${C}Out:${E} %s" "$ik" "$ok"
    fi
}
m_cost() {
    local v=$(json_val 'cost.total_cost_usd')
    if [ -n "$v" ] && [ "$v" != "None" ]; then
        local cf=$(python3 -c "
c=float($v)
if c<0.01: print(f'{c:.4f}')
else: print(f'{c:.2f}')
")
        printf "${C}~\$%s${E}" "$cf"
    fi
}
m_rate5h() {
    local p=$(json_val 'rate_limits.five_hour.used_percentage')
    [ -z "$p" ] || [ "$p" = "None" ] && return
    local s="5h: $(pct_bad "$p")"
    local at=$(json_val 'rate_limits.five_hour.resets_at')
    if [ -n "$at" ] && [ "$at" != "None" ]; then
        local ts=$(date -r "$at" "+%H:%M" 2>/dev/null || date -d "@$at" "+%H:%M" 2>/dev/null)
        [ -n "$ts" ] && s="$s -> ${ts}"
    fi
    echo "$s"
}
m_rate7d() {
    local p=$(json_val 'rate_limits.seven_day.used_percentage')
    [ -z "$p" ] || [ "$p" = "None" ] && return
    local s="7d: $(pct_bad "$p")"
    local at=$(json_val 'rate_limits.seven_day.resets_at')
    if [ -n "$at" ] && [ "$at" != "None" ]; then
        local ts=$(date -r "$at" "+%a %H:%M" 2>/dev/null || date -d "@$at" "+%a %H:%M" 2>/dev/null)
        [ -n "$ts" ] && s="$s -> ${ts}"
    fi
    echo "$s"
}

# ── Build a line from module keys ──
build_line() {
    local out=""
    for mod in $1; do
        local val
        case "$mod" in
            model)  val=$(m_model) ;;
            effort) val=$(m_effort) ;;
            session) val=$(m_session) ;;
            git)    val=$(m_git) ;;
            ctx)    val=$(m_ctx) ;;
            cache)  val=$(m_cache) ;;
            tokens) val=$(m_tokens) ;;
            cost)   val=$(m_cost) ;;
            rate5h) val=$(m_rate5h) ;;
            rate7d) val=$(m_rate7d) ;;
        esac
        if [ -n "$val" ]; then
            if [ -n "$out" ]; then out="$out  $val"
            else out="$val"
            fi
        fi
    done
    echo "$out"
}

build_line "$LINE1_KEYS"
build_line "$LINE2_KEYS"
