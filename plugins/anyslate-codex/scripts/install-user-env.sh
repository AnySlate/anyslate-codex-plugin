#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ANYSLATE_CODEX_ENV:-$HOME/.anyslate/codex.env}"
CODEX_CONFIG="${CODEX_CONFIG:-$HOME/.codex/config.toml}"
LAUNCHER="$ROOT/scripts/anyslate-mcp.sh"

mkdir -p "$(dirname "$ENV_FILE")"
umask 077

configure_codex_mcp() {
  python3 - "$CODEX_CONFIG" "$LAUNCHER" <<'PY'
import json
import pathlib
import sys

config_path = pathlib.Path(sys.argv[1]).expanduser()
launcher = pathlib.Path(sys.argv[2]).resolve()
config_path.parent.mkdir(parents=True, exist_ok=True)

if not launcher.exists():
    raise SystemExit(f"missing AnySlate MCP launcher: {launcher}")

old = config_path.read_text() if config_path.exists() else ""
lines = old.splitlines()
out = []
skipping = False
removed = False

for line in lines:
    stripped = line.strip()
    if stripped.startswith("[") and stripped.endswith("]"):
        table = stripped.strip("[]").strip()
        # Replace the AnySlate MCP server and any nested subtables, while
        # preserving every other Codex setting exactly as-is.
        if table == "mcp_servers.anyslate" or table.startswith("mcp_servers.anyslate."):
            skipping = True
            removed = True
            continue
        skipping = False
    if not skipping:
        out.append(line)

block = "\n".join([
    "[mcp_servers.anyslate]",
    f"command = {json.dumps(str(launcher))}",
    "args = []",
    "startup_timeout_sec = 120",
    "",
])

new = "\n".join(out).rstrip()
if new:
    new += "\n\n"
new += block

if new != old:
    config_path.write_text(new)
    action = "updated" if removed or old else "created"
else:
    action = "unchanged"

print(f"{action}: {config_path}")
print(f"mcp_server: anyslate -> {launcher}")
PY
}

env_created=false
if [ -f "$ENV_FILE" ]; then
  echo "exists: $ENV_FILE"
  echo "No changes made. Edit this file manually if you need to rotate the token:"
  echo "  code $ENV_FILE"
  echo "or:"
  echo "  nano $ENV_FILE"
else

  cat > "$ENV_FILE" <<'EOF'
# AnySlate Codex plugin environment.
# Create an AI Memory automation token in AnySlate:
#   AI Memory > Connections or Settings > MCP Tokens > Create Token
#
# Recommended profile:
#   AI Memory automation (memory:read, memory:write, memory:search)

ANYSLATE_TOKEN=as_mcp_your_token_here
ANYSLATE_MCP_URL=https://mcp.anyslate.io/mcp
EOF

  chmod 600 "$ENV_FILE"
  env_created=true
  echo "created: $ENV_FILE"
  echo "Replace as_mcp_your_token_here with your AnySlate MCP token."
  echo "Edit the file; do not run it as a shell command."
fi

configure_codex_mcp

echo "Codex MCP server registration is idempotent and stores no token value."
echo "Restart Codex or open a new thread so the AnySlate MCP tools are loaded."
if [ "$env_created" = true ]; then
  echo "After adding the token, run:"
  echo "  $ROOT/scripts/check-anyslate-plugin.sh"
fi
