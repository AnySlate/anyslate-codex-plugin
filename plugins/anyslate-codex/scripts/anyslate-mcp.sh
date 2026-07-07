#!/usr/bin/env bash
set -euo pipefail

# AnySlate MCP bridge launcher for the Codex plugin.
#
# Token loading order:
#   1. Existing ANYSLATE_TOKEN environment variable.
#   2. ANYSLATE_CODEX_ENV, if set.
#   3. ~/.anyslate/codex.env.
#
# The token file is intentionally outside the plugin directory so secrets are
# never committed with the publishable plugin artifact.

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$PLUGIN_DIR/../.." && pwd)"
DEFAULT_ENV_FILE="${HOME}/.anyslate/codex.env"
ENV_FILE="${ANYSLATE_CODEX_ENV:-$DEFAULT_ENV_FILE}"
REPO_ENV_FILE="$REPO_ROOT/.anyslate/codex.env"

if [ -z "${ANYSLATE_TOKEN:-}" ] && [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  set -a
  source "$ENV_FILE"
  set +a
fi

# Codex spawns MCP servers with a stripped PATH (/usr/bin:/bin:...), which omits
# Homebrew, /usr/local/bin, and nvm. Without this, `npx` is not found and the
# bridge never starts. Resolve a node runtime and prepend its bin dir to PATH.
resolve_node_on_path() {
  if command -v npx >/dev/null 2>&1 && command -v node >/dev/null 2>&1; then
    return 0
  fi

  local candidates=(
    "/opt/homebrew/bin"
    "/usr/local/bin"
    "${HOME}/.volta/bin"
    "${NVM_DIR:-$HOME/.nvm}/current/bin"
  )

  # nvm installs each version under versions/node/<ver>/bin; pick the newest.
  local nvm_versions="${NVM_DIR:-$HOME/.nvm}/versions/node"
  if [ -d "$nvm_versions" ]; then
    local latest
    latest="$(ls -1 "$nvm_versions" 2>/dev/null | sort -V | tail -n 1)"
    if [ -n "$latest" ]; then
      candidates+=("$nvm_versions/$latest/bin")
    fi
  fi

  local dir
  for dir in "${candidates[@]}"; do
    if [ -x "$dir/npx" ] && [ -x "$dir/node" ]; then
      export PATH="$dir:$PATH"
      return 0
    fi
  done
  return 1
}

resolve_node_on_path || true

ANYSLATE_MCP_URL="${ANYSLATE_MCP_URL:-https://mcp.anyslate.io/mcp}"

redact_token() {
  local token="${1:-}"
  if [ -z "$token" ]; then
    printf "missing"
  elif [ "${#token}" -le 14 ]; then
    printf "present"
  else
    printf "%s...%s" "${token:0:10}" "${token: -4}"
  fi
}

describe_mcp_url() {
  local url="${1:-}"
  if [ -z "$url" ]; then
    printf "missing"
  elif [ "$url" = "https://mcp.anyslate.io/mcp" ]; then
    printf "default"
  else
    printf "custom"
  fi
}

check_runtime() {
  local ok=true

  if ! command -v node >/dev/null 2>&1; then
    echo "node: missing"
    ok=false
  else
    echo "node: $(node --version)"
  fi

  if ! command -v npx >/dev/null 2>&1; then
    echo "npx: missing"
    ok=false
  else
    echo "npx: $(command -v npx)"
  fi

  echo "plugin_dir: $PLUGIN_DIR"
  echo "env_file: $ENV_FILE"
  if [ -f "$REPO_ENV_FILE" ] && [ "$ENV_FILE" != "$REPO_ENV_FILE" ]; then
    echo "repo_local_env: present at $REPO_ENV_FILE (ignored for safety)"
  fi
  echo "anyslate_mcp_url: $(describe_mcp_url "$ANYSLATE_MCP_URL")"
  echo "anyslate_token: $(redact_token "${ANYSLATE_TOKEN:-}")"

  if [ -z "${ANYSLATE_TOKEN:-}" ]; then
    echo "status: missing ANYSLATE_TOKEN"
    ok=false
  elif [ "$ANYSLATE_TOKEN" = "as_mcp_your_token_here" ]; then
    echo "status: placeholder token; replace it with a real AnySlate token"
    ok=false
  elif [[ "$ANYSLATE_TOKEN" != as_mcp_* && "$ANYSLATE_TOKEN" != as_oauth_* ]]; then
    echo "status: invalid token prefix; expected as_mcp_ or as_oauth_"
    ok=false
  else
    echo "status: ready"
  fi

  if [ "$ok" = true ]; then
    return 0
  fi
  return 1
}

case "${1:-}" in
  --check)
    check_runtime
    exit $?
    ;;
  --help|-h|help)
    cat <<'EOF'
anyslate-mcp.sh - Codex plugin launcher for AnySlate MCP

Usage:
  ./scripts/anyslate-mcp.sh          Start the AnySlate MCP stdio bridge
  ./scripts/anyslate-mcp.sh --check  Validate local runtime and token config

Configuration:
  ANYSLATE_TOKEN      Required. Create an AI Memory automation token in AnySlate.
  ANYSLATE_MCP_URL    Optional. Defaults to https://mcp.anyslate.io/mcp.
  ANYSLATE_CODEX_ENV  Optional env-file path. Defaults to ~/.anyslate/codex.env.

Recommended token profile:
  AI Memory automation: memory:read, memory:write, memory:search
EOF
    exit 0
    ;;
esac

if [ -z "${ANYSLATE_TOKEN:-}" ]; then
  cat >&2 <<EOF
[anyslate-codex] Missing ANYSLATE_TOKEN.

Create an AI Memory automation token in AnySlate, then either export it before
starting Codex or write it to:

  $DEFAULT_ENV_FILE

Do not put tokens under the repo .anyslate/ folder. That path is ignored by
the plugin by default to avoid committing or exposing secrets.

Example:
  mkdir -p ~/.anyslate
  umask 077
  cat > ~/.anyslate/codex.env <<'TOKEN_EOF'
ANYSLATE_TOKEN=as_mcp_your_token_here
ANYSLATE_MCP_URL=https://mcp.anyslate.io/mcp
TOKEN_EOF
EOF
  exit 1
fi

if [[ "$ANYSLATE_TOKEN" != as_mcp_* && "$ANYSLATE_TOKEN" != as_oauth_* ]]; then
  echo "[anyslate-codex] Invalid ANYSLATE_TOKEN. AnySlate MCP tokens start with as_mcp_ or as_oauth_." >&2
  exit 1
fi

if [ "$ANYSLATE_TOKEN" = "as_mcp_your_token_here" ]; then
  echo "[anyslate-codex] Replace the placeholder ANYSLATE_TOKEN in $ENV_FILE with a real AnySlate MCP token." >&2
  if [ -f "$REPO_ENV_FILE" ] && [ "$ENV_FILE" != "$REPO_ENV_FILE" ]; then
    echo "[anyslate-codex] Note: $REPO_ENV_FILE exists but is ignored for safety. Copy the token to $DEFAULT_ENV_FILE instead." >&2
  fi
  exit 1
fi

export ANYSLATE_TOKEN
export ANYSLATE_MCP_URL

exec npx -y @anyslate/mcp@latest
