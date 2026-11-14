#!/usr/bin/env bash
# One-command setup for Premiere Pro Bridge (macOS).
set -euo pipefail

cd "$(dirname "$0")"
ROOT="$(pwd)"
SERVER="$ROOT/dist/index.js"
NAME="premiere-pro"

step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
warn() { printf '\033[33m!  %s\033[0m\n' "$1"; }
ok()   { printf '\033[32m✓  %s\033[0m\n' "$1"; }

step "Checking Node.js"
command -v node >/dev/null || { echo "Node.js not found. Install it: brew install node@22"; exit 1; }
major="$(node -p 'process.versions.node.split(".")[0]')"
if [ "$major" -lt 20 ]; then
  echo "Node $major is too old. Need 20, 22, or 24+."; exit 1
elif [ "$major" = 21 ] || [ "$major" = 23 ]; then
  warn "Node $major is not officially supported (use 20, 22, or 24+). Continuing anyway."
else
  ok "Node $(node -v)"
fi

step "Installing dependencies and building"
npm ci --no-fund --no-audit --loglevel=error
npm run build --silent
ok "Built $SERVER"

step "Installing the Premiere panel (CEP connector)"
node "$SERVER" --install-cep

step "Checking optional FFmpeg (needed for trim_clip, slip_edit, detect_silence)"
if command -v ffprobe >/dev/null; then ok "ffprobe found"; else warn "ffprobe missing. Install with: brew install ffmpeg"; fi

step "Connecting AI clients"
if command -v claude >/dev/null; then
  claude mcp remove -s user "$NAME" >/dev/null 2>&1 || true
  claude mcp add -s user "$NAME" -- node "$SERVER" >/dev/null
  ok "Claude Code: added '$NAME' (user scope)"
else
  warn "Claude Code CLI not found, skipped"
fi

DESKTOP_DIR="$HOME/Library/Application Support/Claude"
if [ -d "$DESKTOP_DIR" ]; then
  CONFIG="$DESKTOP_DIR/claude_desktop_config.json"
  [ -f "$CONFIG" ] && cp "$CONFIG" "$CONFIG.bak"
  node -e '
    const fs = require("fs");
    const [file, name, node, server] = process.argv.slice(1);
    const cfg = fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, "utf8")) : {};
    cfg.mcpServers = { ...cfg.mcpServers, [name]: { command: node, args: [server] } };
    fs.writeFileSync(file, JSON.stringify(cfg, null, 2) + "\n");
  ' "$CONFIG" "$NAME" "$(command -v node)" "$SERVER"
  ok "Claude Desktop: added '$NAME' (backup at claude_desktop_config.json.bak)"
else
  warn "Claude Desktop not found, skipped"
fi

step "Local check"
node "$SERVER" --doctor | grep -E '^(Ready|Not|Needs|Fail|Premiere MCP)' || true

cat <<'EOF'

Done. Last steps:
  1. Fully quit and reopen Premiere Pro, then open a project.
  2. Window > Extensions > MCP for Adobe Premiere Pro  (panel should say Running)
  3. Restart Claude, then ask:  Run verify_premiere_connection. Make no changes.
EOF
