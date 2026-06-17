[English](README.md) | [中文](README_CN.md)

# Claude Code Statusline

[Claude Code](https://claude.ai/code) CLI 的模块化、可自定义状态栏。支持 Windows、macOS、Linux，兼容任何模型（Claude、DeepSeek 等）。

## 效果预览

```
Sonnet 4.6 [Pro]  /max [my-session]  my-project (main)
Ctx: 42%  Cache: 96%  In: 13k  Out: 8k  ~$0.23  5h: 12% -> 21:00  7d: 45% -> Thu 00:00
```

- **第一行**：模型名、effort 等级、会话名、git 仓库 + 分支
- **第二行**：上下文用量、缓存命中率、token 输入/输出、费用、速率限制
- **颜色**：绿 = 健康，黄 = 警告，红 = 告急

## 一键安装

### Windows
```powershell
powershell -ExecutionPolicy Bypass -File setup.ps1
```

### Mac / Linux
```bash
chmod +x setup.sh && ./setup.sh
```

安装后重启 Claude Code 即可。

## 模块化配置

编辑 `~/.claude/statusline-config.json`，自由选择要显示的模块：

```json
{
  "line1": ["model", "effort", "session", "git"],
  "line2": ["ctx", "cache", "tokens", "cost", "rate5h", "rate7d"],
  "colors": true,
  "session_max_len": 24
}
```

### 可用模块

| 键名 | 显示内容 | 示例 |
|-----|---------|------|
| `model` | 模型显示名 | `Sonnet 4.6 [Pro]` |
| `effort` | Effort 等级 | `/max` |
| `session` | 会话名（可截断） | `[my-session]` |
| `git` | Git 仓库 + 分支 | `project (main)` |
| `ctx` | 上下文窗口用量 % | `Ctx: 42%` |
| `cache` | Prompt Cache 命中率 % | `Cache: 96%` |
| `tokens` | 输入/输出 token 数 | `In: 13k Out: 8k` |
| `cost` | 本次会话估算费用 | `~$0.23` |
| `rate5h` | 5 小时滚动用量 + 重置时间 | `5h: 12% -> 21:00` |
| `rate7d` | 7 天用量 + 重置时间 | `7d: 45% -> Thu 00:00` |

### 配置示例

**极简** — 只要模型 + git + 上下文用量：
```json
{
  "line1": ["model", "git"],
  "line2": ["ctx", "tokens"]
}
```

**关注费用**：
```json
{
  "line1": ["model"],
  "line2": ["tokens", "cost", "rate5h"]
}
```

**关闭颜色**（终端不支持 ANSI 时）：
```json
{
  "colors": false
}
```

## FAQ

### 会额外消耗 token 吗？
不会。状态栏读取 Claude Code 本地维护的 session 元数据——零 API 调用、零 token 消耗。

### 速率限制没显示？
某些 API 提供商（如 DeepSeek）不返回速率限制信息，脚本会自动跳过不可用字段。

### 安装路径不同会影响吗？
不影响。安装脚本只操作 `~/.claude/`——Claude Code 固定读取的用户配置目录，与二进制文件安装位置无关。支持 CLI、npm 全局安装和桌面版（Claudian）。

### 使用 Claude 桌面版（Claudian）？
如果全局配置不生效，在项目的 `.claude/settings.json` 中添加：

```json
{
  "statusLine": {
    "type": "command",
    "command": "powershell -NoProfile -NonInteractive -File \"%USERPROFILE%\\.claude\\statusline.ps1\""
  }
}
```

### 如何重置为默认配置？
删除 `~/.claude/statusline-config.json` 后重新运行 `setup.ps1` 或 `setup.sh`。

### 如何卸载？
从 `~/.claude/settings.json` 中移除 `statusLine` 字段，然后删除 `~/.claude/statusline.ps1`（或 `.sh`）和 `~/.claude/statusline-config.json`。

## 文件结构

```
claude-code-statusline/
├── setup.ps1               Windows 一键安装
├── setup.sh                Mac/Linux 一键安装
├── statusline.ps1          Windows 模块化脚本
├── statusline.sh           Mac/Linux 模块化脚本
├── statusline-config.json  默认配置（用户可自定义）
├── LICENSE                 MIT
├── .gitignore
├── README.md               英文文档
└── README_CN.md            中文文档
```

## License

MIT
