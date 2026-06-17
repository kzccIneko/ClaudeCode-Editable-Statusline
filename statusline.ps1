# Claude Code Statusline — modular PowerShell script
# Reads config from ~/.claude/statusline-config.json
# Each field in line1/line2 is a self-contained module.

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$mem = New-Object System.IO.MemoryStream
$buf = New-Object byte[] 4096
$stdin = [Console]::OpenStandardInput()
while (($n = $stdin.Read($buf, 0, $buf.Length)) -gt 0) {
    $mem.Write($buf, 0, $n)
}
$raw = [System.Text.Encoding]::UTF8.GetString($mem.ToArray())
$mem.Dispose()
if (-not $raw -or $raw.Trim().Length -eq 0) { exit 0 }

try { $d = $raw | ConvertFrom-Json } catch { exit 0 }

# ── Load config ──
$cfgPath = "$env:USERPROFILE\.claude\statusline-config.json"
$cfg = @{
    line1 = @('model', 'effort', 'session', 'git')
    line2 = @('ctx', 'cache', 'tokens', 'cost', 'rate5h', 'rate7d')
    colors = $true
    session_max_len = 24
}
if (Test-Path $cfgPath) {
    try {
        $userCfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
        if ($userCfg.line1) { $cfg.line1 = $userCfg.line1 }
        if ($userCfg.line2) { $cfg.line2 = $userCfg.line2 }
        if ($null -ne $userCfg.colors) { $cfg.colors = $userCfg.colors }
        if ($userCfg.session_max_len) { $cfg.session_max_len = $userCfg.session_max_len }
    } catch { }
}

# ── ANSI ──
$esc = [char]27
$G=""; $Y=""; $R=""; $C=""; $E=""
if ($cfg.colors) {
    $G = "$esc[32m"; $Y = "$esc[33m"; $R = "$esc[31m"; $C = "$esc[36m"; $E = "$esc[0m"
}

# ── Shared helpers ──
function pct($v, $type) {
    $n = [math]::Round($v)
    if ($type -eq 'bad') {
        if ($n -ge 76) { "$R${n}%$E" }
        elseif ($n -ge 51) { "$Y${n}%$E" }
        else { "$G${n}%$E" }
    } else {
        if ($n -ge 71) { "$G${n}%$E" }
        elseif ($n -ge 41) { "$Y${n}%$E" }
        else { "$R${n}%$E" }
    }
}

# ═══════════════════ MODULES ═══════════════════
# Each module returns a display string or $null

function m_model {
    if ($d.model.display_name) { return $d.model.display_name }
    return 'Unknown'
}

function m_effort {
    if ($d.effort.level) { return "/$($d.effort.level)" }
    return $null
}

function m_session {
    $s = $d.session_name
    if (-not $s) { return $null }
    $max = $cfg.session_max_len
    if ($s.Length -gt $max) { $s = $s.Substring(0, $max - 2) + '..' }
    return "[$s]"
}

function m_git {
    $cwd = if ($d.workspace.current_dir) { $d.workspace.current_dir } else { '' }
    if (-not $cwd) { return 'no git' }
    $gitDir = Join-Path $cwd '.git'
    if (-not (Test-Path $gitDir)) { return 'no git' }
    try {
        $repo   = Split-Path (git -C $cwd rev-parse --show-toplevel 2>$null) -Leaf
        $branch = git -C $cwd symbolic-ref --short HEAD 2>$null
        if (-not $branch) { $branch = git -C $cwd rev-parse --short HEAD 2>$null }
        return "$repo ($branch)"
    } catch { return 'no git' }
}

function m_ctx {
    $v = $d.context_window.used_percentage
    if ($null -ne $v -and $v -ne '') { return "Ctx: $(pct $v 'bad')" }
    return $null
}

function m_cache {
    $cr = if ($d.context_window.current_usage.cache_read_input_tokens) { $d.context_window.current_usage.cache_read_input_tokens } else { 0 }
    $ci = if ($d.context_window.current_usage.input_tokens) { $d.context_window.current_usage.input_tokens } else { 0 }
    $t = $cr + $ci
    if ($t -gt 0) {
        $cp = [math]::Round($cr / $t * 100)
        return "Cache: $(pct $cp 'good')"
    }
    return $null
}

function m_tokens {
    $i = $d.context_window.total_input_tokens
    $o = $d.context_window.total_output_tokens
    if ($null -ne $i -and $null -ne $o -and $i -ne '' -and $o -ne '') {
        $ik = "{0:F0}k" -f ($i / 1000)
        $ok = "{0:F0}k" -f ($o / 1000)
        return "${C}In:${E} ${ik}  ${C}Out:${E} ${ok}"
    }
    return $null
}

function m_cost {
    $c = $d.cost.total_cost_usd
    if ($null -ne $c -and $c -ne '') {
        $cf = if ([double]$c -lt 0.01) { "{0:F4}" -f $c } else { "{0:F2}" -f $c }
        return "${C}~`$${cf}${E}"
    }
    return $null
}

function m_rate5h {
    $p = $d.rate_limits.five_hour.used_percentage
    if ($null -eq $p -or $p -eq '') { return $null }
    $s = "5h: $(pct $p 'bad')"
    $at = $d.rate_limits.five_hour.resets_at
    if ($null -ne $at -and $at -ne '') {
        $ts = ([DateTimeOffset]::FromUnixTimeSeconds([long]$at)).LocalDateTime.ToString('HH:mm')
        $s += " -> ${ts}"
    }
    return $s
}

function m_rate7d {
    $p = $d.rate_limits.seven_day.used_percentage
    if ($null -eq $p -or $p -eq '') { return $null }
    $s = "7d: $(pct $p 'bad')"
    $at = $d.rate_limits.seven_day.resets_at
    if ($null -ne $at -and $at -ne '') {
        $ts = ([DateTimeOffset]::FromUnixTimeSeconds([long]$at)).LocalDateTime.ToString('ddd HH:mm')
        $s += " -> ${ts}"
    }
    return $s
}

# ── Module dispatcher ──
$modules = @{
    model   = ${function:m_model}
    effort  = ${function:m_effort}
    session = ${function:m_session}
    git     = ${function:m_git}
    ctx     = ${function:m_ctx}
    cache   = ${function:m_cache}
    tokens  = ${function:m_tokens}
    cost    = ${function:m_cost}
    rate5h  = ${function:m_rate5h}
    rate7d  = ${function:m_rate7d}
}

function build-line($keys) {
    $items = @()
    foreach ($k in $keys) {
        if ($modules.ContainsKey($k)) {
            $val = & $modules[$k]
            if ($null -ne $val -and $val -ne '') { $items += $val }
        }
    }
    return ($items -join '  ')
}

$line1 = build-line $cfg.line1
$line2 = build-line $cfg.line2

Write-Output $line1
Write-Output $line2
