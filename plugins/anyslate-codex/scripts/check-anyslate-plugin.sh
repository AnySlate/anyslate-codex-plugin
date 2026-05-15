#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[anyslate-codex] validating plugin files"

python3 - "$ROOT" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
manifest = root / ".codex-plugin" / "plugin.json"
mcp = root / ".mcp.json"
skill = root / "skills" / "anyslate-memory" / "SKILL.md"

for path in (manifest, mcp, skill):
    if not path.exists():
        raise SystemExit(f"missing required file: {path}")

data = json.loads(manifest.read_text())
if data.get("name") != "anyslate-codex":
    raise SystemExit("plugin name must be anyslate-codex")
if "[TODO:" in manifest.read_text():
    raise SystemExit("plugin manifest still contains TODO placeholders")
if data.get("mcpServers") != "./.mcp.json":
    raise SystemExit("plugin manifest must point mcpServers to ./.mcp.json")
if data.get("skills") != "./skills/":
    raise SystemExit("plugin manifest must point skills to ./skills/")

interface = data.get("interface", {})
icon = interface.get("composerIcon")
logo = interface.get("logo")
if icon != "./assets/appicon.png":
    raise SystemExit("plugin composerIcon must use the real AnySlate app icon at ./assets/appicon.png")
if logo != "./assets/logo-full-adaptive.png":
    raise SystemExit("plugin logo must use the theme-safe AnySlate logo at ./assets/logo-full-adaptive.png")
for rel in (icon, logo):
    asset = root / rel.removeprefix("./")
    if not asset.exists():
        raise SystemExit(f"missing plugin brand asset: {rel}")
for rel in ("./assets/logo-full-light.png", "./assets/logo-full-dark.png"):
    asset = root / rel.removeprefix("./")
    if not asset.exists():
        raise SystemExit(f"missing raw AnySlate logo variant: {rel}")

mcp_data = json.loads(mcp.read_text())
server = mcp_data.get("mcpServers", {}).get("anyslate")
if not server:
    raise SystemExit("missing anyslate MCP server")
if server.get("command") != "./scripts/anyslate-mcp.sh":
    raise SystemExit("anyslate MCP server must use ./scripts/anyslate-mcp.sh")

skill_text = skill.read_text()
for needle in (
    "recall",
    "checkpoint_session",
    "upload_artifact",
    "Do not use ordinary Markdown resource tools for AI Memory",
):
    if needle not in skill_text:
        raise SystemExit(f"skill missing required guidance: {needle}")

print("json: ok")
PY

if [ ! -x "$ROOT/scripts/anyslate-mcp.sh" ]; then
  echo "launcher is not executable: $ROOT/scripts/anyslate-mcp.sh" >&2
  exit 1
fi

if [ ! -x "$ROOT/scripts/install-user-env.sh" ]; then
  echo "env installer is not executable: $ROOT/scripts/install-user-env.sh" >&2
  exit 1
fi

echo "[anyslate-codex] runtime check"
if "$ROOT/scripts/anyslate-mcp.sh" --check; then
  echo "[anyslate-codex] ready"
else
  echo "[anyslate-codex] plugin files are valid, but local token/runtime setup is incomplete"
  echo "[anyslate-codex] fix: edit ~/.anyslate/codex.env and replace as_mcp_your_token_here"
  echo "[anyslate-codex] do not run ~/.anyslate/codex.env with sudo; it is a config file, not a command"
  exit 2
fi
