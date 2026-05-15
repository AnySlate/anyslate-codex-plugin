# AnySlate Codex Plugin

AnySlate for Codex connects Codex to the AnySlate AI Memory Layer through MCP and adds Codex-specific workflow guidance for automatic recall, checkpoints, artifacts, and continuation.

## What This Plugin Provides

- Registers the AnySlate MCP bridge through `@anyslate/mcp@latest`.
- Adds the `anyslate-memory` Codex skill.
- Keeps AI Memory tools separate from ordinary Markdown resource tools.
- Defaults setup guidance to the **AI Memory automation** token profile.
- Uses the real AnySlate brand assets: desktop app icon from `build/appicon.png`, raw light/dark logo variants from `anyslate-web/public/`, and a theme-safe plugin logo built from the actual light-mode logo.
- Provides validation scripts for local and publish checks.

## Requirements

- Node.js 18 or later.
- `npx` available on `PATH`.
- AnySlate Professional account with MCP access.
- AnySlate MCP token using the **AI Memory automation** profile.

## Token Setup

Create a token in AnySlate:

1. Open AnySlate.
2. Go to **AI Memory > Connections** or **Settings > MCP Tokens**.
3. Click **Create Token**.
4. Choose **AI Memory automation**.
5. Copy the `as_mcp_...` token once.

Create the local Codex env file:

```bash
plugins/anyslate-codex/scripts/install-user-env.sh
```

Then edit:

```bash
~/.anyslate/codex.env
```

Use `code ~/.anyslate/codex.env` or `nano ~/.anyslate/codex.env`. Do not run
the file with `sudo`; it is a config file, not a command.

Set:

```bash
ANYSLATE_TOKEN=as_mcp_your_token_here
ANYSLATE_MCP_URL=https://mcp.anyslate.io/mcp
```

Do not commit token values.
Do not store token values in repo-local `.anyslate/` files.

## Validate

```bash
plugins/anyslate-codex/scripts/check-anyslate-plugin.sh
```

If the token is not configured yet, the plugin file validation still runs but the script exits with status `2` after reporting the missing token.

## Development Endpoint

For UAT/dev MCP testing, set:

```bash
ANYSLATE_MCP_URL=https://anyslate-mcp-service-development.webmaster-744.workers.dev/mcp
```

Production default:

```bash
ANYSLATE_MCP_URL=https://mcp.anyslate.io/mcp
```

## How Automation Works

Codex plugin installation makes AnySlate tools available. The `anyslate-memory` skill tells Codex when to use them:

- `recall` at the start of non-trivial tasks.
- `read_memory` when recall finds a useful prior session.
- `import_chat` when a new sustained task needs a memory home.
- `checkpoint_session` after meaningful progress.
- `upload_artifact` before referencing durable generated files or reports.
- `append_decision` and `append_task` for first-class decisions and follow-ups.

The plugin intentionally does not use ordinary Markdown resource tools for AI Memory. Those tools are only for explicit user requests about normal AnySlate Markdown files.

## Publishing Checklist

For the full Git marketplace publishing flow, see
`docs/AI_MEMORY_LAYER/CODEX_PLUGIN_PUBLISHING.md` in the AnySlate repo.

Before publishing:

1. Remove any local token files from the package.
2. Run `plugins/anyslate-codex/scripts/check-anyslate-plugin.sh`.
3. Verify `.codex-plugin/plugin.json` has no placeholder values.
4. Verify `.mcp.json` points at `./scripts/anyslate-mcp.sh`.
5. Verify the skill mentions memory/resource tool separation.
6. Verify `assets/appicon.png`, `assets/logo-full-adaptive.png`, `assets/logo-full-light.png`, and `assets/logo-full-dark.png` are present.
7. Package only:
   - `.codex-plugin/plugin.json`
   - `.mcp.json`
   - `skills/`
   - `scripts/`
   - `assets/`
   - `README.md`

To build a clean Git marketplace artifact from the AnySlate repo:

```bash
plugins/anyslate-codex/scripts/package-marketplace.sh
```

Publish the generated `.artifacts/anyslate-codex-marketplace/` contents to a dedicated Git repo, then add that repo as a Codex marketplace.
