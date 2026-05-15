#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${ANYSLATE_CODEX_ENV:-$HOME/.anyslate/codex.env}"

mkdir -p "$(dirname "$ENV_FILE")"
umask 077

if [ -f "$ENV_FILE" ]; then
  echo "exists: $ENV_FILE"
  echo "No changes made. Edit this file manually if you need to rotate the token:"
  echo "  code $ENV_FILE"
  echo "or:"
  echo "  nano $ENV_FILE"
  exit 0
fi

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
echo "created: $ENV_FILE"
echo "Replace as_mcp_your_token_here with your AnySlate MCP token."
echo "Edit the file; do not run it as a shell command."
