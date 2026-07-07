# AnySlate For Codex

Connect Codex to AnySlate AI Memory so Codex can recall prior work, checkpoint decisions, save useful artifacts, and continue long-running projects across sessions.

## What You Get

- AnySlate AI Memory tools inside Codex.
- Automatic workflow guidance for recall, checkpoints, decisions, tasks, and continuation prompts.
- A local MCP bridge powered by `@anyslate/mcp`.
- Token storage outside your projects and outside this plugin repository.

## Requirements

- Codex desktop app.
- Node.js 18 or newer with `npx` available.
- AnySlate account with MCP access.
- An AnySlate MCP token. The recommended token profile is **AI Memory automation**.

## Install The Marketplace In Codex

1. Open Codex.
2. Go to **Plugins**.
3. Choose **Add marketplace**.
4. Add this repository:

```text
https://github.com/AnySlate/anyslate-codex-plugin.git
```

5. Use Git ref:

```text
main
```

6. Install **AnySlate** from the marketplace.

## Configure The Token

Create an AnySlate MCP token in the AnySlate app, then run this from the plugin marketplace folder:

```bash
plugins/anyslate-codex/scripts/install-user-env.sh
```

The installer:

- creates `~/.anyslate/codex.env` if it does not exist
- registers the AnySlate MCP server in `~/.codex/config.toml`
- does not store token values in Codex config

Edit the token file:

```bash
code ~/.anyslate/codex.env
```

or:

```bash
nano ~/.anyslate/codex.env
```

Set:

```bash
ANYSLATE_TOKEN=as_mcp_your_token_here
ANYSLATE_MCP_URL=https://mcp.anyslate.io/mcp
```

Restart Codex or open a new thread after changing MCP setup.

## Verify Setup

Run:

```bash
plugins/anyslate-codex/scripts/check-anyslate-plugin.sh
```

Expected final line:

```text
[anyslate-codex] ready
```

Then start a new Codex thread and ask:

```text
Use AnySlate AI Memory. Recall prior context for this repo and summarize the top matches. Do not modify files.
```

If setup is healthy, Codex should use AnySlate MCP tools directly instead of falling back to manual shell commands.

## Security Notes

- Do not commit `~/.anyslate/codex.env`.
- Do not put MCP tokens in project `.env` files.
- Do not paste token values into screenshots or bug reports.
- Rotate a token if it has been exposed.
