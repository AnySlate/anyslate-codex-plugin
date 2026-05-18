---
name: anyslate-memory
description: Use AnySlate AI Memory from Codex. Auto-trigger for non-trivial coding, research, planning, debugging, review, deployment, or documentation tasks when the AnySlate MCP server is available; recall prior context before work, checkpoint meaningful progress, upload durable artifacts, and keep AI Memory tools separate from ordinary Markdown resource tools.
---

# AnySlate AI Memory For Codex

Use this skill when Codex should preserve or retrieve durable context through AnySlate.

## Operating Goal

Make AnySlate useful without the user having to say "create a checkpoint" or "update memory" every turn.

MCP exposes tools; this skill decides when Codex should use them.

## Tool Surface Rules

AnySlate has two MCP tool families:

- **AI Memory tools**: `recall`, `search_memory`, `find_matching_memory`, `list_memories`, `read_memory`, `import_chat`, `checkpoint_session`, `upload_artifact`, `attach_artifact_url`, `request_artifact_upload`, `get_artifact`, `append_decision`, `append_task`, `generate_continuation_prompt`, `get_checkpoint_status`, `get_context_subgraph`, `expand_decision`, `get_related`, `list_handles`.
- **Ordinary Markdown resource tools**: `list_resources`, `search_resources`, `read_resource`, `get_resource_versions`, `create_resource`, `update_resource`, `update_resource_section`, `delete_resource`.

Do not use ordinary Markdown resource tools for AI Memory. Resource tools are only for explicit user requests about normal AnySlate Markdown files outside the memory layer.

Prefer an AnySlate **AI Memory automation** token. With that token, Codex should only see memory tools. If both memory and resource tools are visible, assume the token is full-access and follow the separation rule strictly.

## Start Of Task

For any non-trivial task, do this before implementation or analysis:

1. Check whether AnySlate MCP memory tools are available.
2. Call `recall` with a concise query made from the user's task, repo/project name, relevant file paths, and obvious product terms.
3. If `recall` returns a likely session, call `read_memory` for the best match when more detail is needed.
4. If the task clearly continues a prior session, keep that `session_id` as the active memory target.
5. If no relevant memory exists and the task is likely to span multiple replies, call `import_chat` once to create an active session.

Do not block the task if AnySlate is unavailable. Mention the connection issue once, then continue normally.

## During Work

Checkpoint when something durable happens:

- a technical decision is made
- a requirement is clarified
- a bug/root cause is found
- implementation starts or changes direction
- tests, lint, build, migration, deployment, or smoke checks finish
- a file/artifact/report/config/output is created
- the user redirects the task
- work pauses with a known next step

Use:

- `checkpoint_session` for general progress, reasoning, decisions, tests, deployments, blockers, and next actions.
- `append_decision` for a single important decision that should become a first-class decision.
- `append_task` for a task/follow-up the user expects to track.
- Capture a durable artifact before referencing it. Pick the tool automatically by what you have — never base64-encode a binary:
  - `attach_artifact_url` — the file is reachable at a public http(s) URL, or your environment can expose it at one. The server fetches the bytes; you spend no tokens encoding them.
  - `request_artifact_upload` — a binary file you produced locally (image, PDF, diagram, archive, code bundle) with no URL. It returns a one-time `upload_url`; PUT the raw file bytes to it with your normal HTTP tool — no base64.
  - `upload_artifact` — small inline TEXT only: markdown report, JSON/YAML config, patch summary, test output, design doc, code snippet. This tool rejects binary content.

Keep checkpoint text compact and factual. Do not upload secrets, raw tokens, private keys, `.env` values, full logs with credentials, or unrelated local files.

## End Of Task

Before the final response, checkpoint the outcome when AnySlate is available and the task was non-trivial.

The final checkpoint should include:

- status: completed, partially completed, blocked, or deferred
- changed files or deployed services
- decisions made
- tests/builds/deployments run and their results
- remaining risks or next steps

If no active session exists, create one with `import_chat` first only when the work is worth preserving. For tiny one-line answers, skip memory.

## Live Connector Updates

Treat MCP tool visibility as live state:

- Do not assume resource tools or memory tools are available from stale documentation.
- If a call says a tool is unknown, adapt to the current visible tool set and continue.
- If memory tools disappear, report that the AnySlate token likely lacks `memory:*` scopes.
- If resource tools are visible during an AI Memory task, ignore them unless the user explicitly asks to manage ordinary Markdown files.
- If the user asks to rotate or change the connector, direct them to create a new **AI Memory automation** MCP token and update `ANYSLATE_TOKEN`; never write token values into tracked files.

## Query Patterns

Use these query shapes for recall:

- Implementation task: `<repo> <feature> <files> prior decisions blockers`
- Bug fix: `<error> <component> root cause previous fix`
- Deployment: `<service> deploy migration env smoke test`
- Product planning: `<module> requirements decisions open questions`
- Continuation: `<topic> continue last session active tasks`

## Failure Handling

- Authentication error: tell the user to create or rotate an AnySlate MCP token.
- Permission error: tell the user to use the AI Memory automation profile.
- Rate limit: continue without retry loops; checkpoint later if possible.
- Tool/runtime error: mention once, continue the task, and include the memory failure in the final note.

Never retry a failing AnySlate call more than once in the same turn unless the user explicitly asks.

## User-Facing Behavior

Do not narrate every memory call. The user asked for automation. Keep normal progress updates focused on the actual engineering work.

Mention AnySlate only when:

- memory context materially changed the answer
- a checkpoint/upload failed
- the user asks about memory
- setup or token rotation is needed

## Privacy And Safety

Never store:

- credentials or token values
- `.env` contents
- private keys
- payment/card data
- personal data not relevant to the task
- full third-party copyrighted documents unless the user explicitly provided them for this purpose and storage is appropriate

Summarize sensitive logs instead of uploading raw output.
