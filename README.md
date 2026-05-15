# AnySlate Codex Plugin Marketplace

This repository is the Codex plugin marketplace for AnySlate.

## What It Installs

- The **AnySlate** Codex plugin.
- The AnySlate MCP bridge through `@anyslate/mcp`.
- The `anyslate-memory` skill for automatic recall, checkpoints, artifacts, decisions, tasks, and continuation prompts.

## Install In Codex

1. Open **Plugins** in Codex.
2. Choose **Create** or **Add marketplace**.
3. Add this marketplace:

```text
AnySlate/anyslate-codex-plugin
```

or:

```text
https://github.com/AnySlate/anyslate-codex-plugin.git
```

4. Use Git ref `main`.
5. Install **AnySlate** from the marketplace.

## Token Setup

Create an **AI Memory automation** MCP token in AnySlate, then run:

```bash
plugins/anyslate-codex/scripts/install-user-env.sh
```

Edit:

```bash
~/.anyslate/codex.env
```

Set:

```bash
ANYSLATE_TOKEN=as_mcp_your_token_here
ANYSLATE_MCP_URL=https://mcp.anyslate.io/mcp
```

For development/UAT MCP testing:

```bash
ANYSLATE_MCP_URL=https://anyslate-mcp-service-development.webmaster-744.workers.dev/mcp
```

Do not commit token values.

## Validate

```bash
plugins/anyslate-codex/scripts/check-anyslate-plugin.sh
```

Expected result:

```text
[anyslate-codex] ready
```

## First Smoke Test

Start a new Codex chat and ask:

```text
Use AnySlate AI Memory. Recall prior context for this repo and summarize the top matches. Do not modify files.
```

Then create and recall a small checkpoint to confirm write access.
