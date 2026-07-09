---
name: anyslate-memory
description: Use AnySlate AI Memory from Codex. Auto-trigger for non-trivial coding, research, planning, debugging, review, deployment, or documentation tasks when the AnySlate MCP server is available; recall or surface prior context, checkpoint meaningful progress, upload artifacts with the right route, and keep AI Memory tools separate from ordinary Markdown resource tools.
---

# AnySlate AI Memory For Codex

Use this skill when Codex should preserve, retrieve, or continue durable work through AnySlate.

## Operating Goal

Make AnySlate useful without the user having to say "search memory", "create a checkpoint", "save this artifact", or "update memory" every turn.

MCP exposes tools. This skill decides when Codex should use them, which tool to choose, and which tools to avoid.

## Tool Surface Rules

Treat the live `tools/list` response as the source of truth for schemas and availability. The current AnySlate MCP surface is organized into two families.

**Markdown File Resources** are ordinary `.md` workspace file tools:

- `list_resources`
- `search_resources`
- `read_resource`
- `get_resource_versions`
- `create_resource`
- `update_resource`
- `update_resource_section`
- `delete_resource`

Use these only when the user explicitly asks to browse, create, edit, or delete normal AnySlate Markdown files. Do not use resource tools for AI Memory capture, checkpoints, decisions, continuation, or artifacts.

**AI Memory** tools are grouped by subsystem:

- Sessions: `list_memories`, `read_memory`, `search_memory`, `archive_session`, `dedupe_session`, `import_chat`
- Atoms: `append_decision`, `mark_decision_superseded`, `append_task`, `generate_continuation_prompt`
- Retrieval: `recall`, `surface_relevant`, `get_context_subgraph`, `expand_decision`, `get_related`, `search_files`
- Artifacts: `upload_artifact`, `attach_artifact_url`, `request_artifact_upload`, `begin_artifact_upload`, `upload_artifact_chunk`, `finish_artifact_upload`, `attach_artifact_to_checkpoint`, `get_artifact`
- Checkpoints: `checkpoint_session`, `get_checkpoint_status`, `retry_checkpoint`
- Privacy: `get_privacy_mode`, `set_session_sensitivity`
- Project briefs: `summarize_project`, `get_project_summary_diff`, `ask_project`
- Hygiene: `list_hygiene_findings`, `list_hygiene_events`, `get_memory_state`
- Compliance and audit: `query_audit_log`, `verify_audit_chain`, `bridge_verify`
- Tokens, activity, feedback: `list_handles`, `activity_submit`, `submit_surface_feedback`

`find_matching_memory` is legacy and must not be used. Use `surface_relevant` for proactive turn-level surfacing and `recall` for explicit prior-context retrieval.

Prefer an AnySlate **AI Memory automation** token. With that token, Codex should only see AI Memory tools. If both AI Memory and Markdown resource tools are visible, assume the token is full-access and follow the separation rule strictly.

## Start Of Task

For any non-trivial task:

1. Check whether AnySlate MCP memory tools are available.
2. If the user asks about prior work, decisions, context, project history, or "what did we do", call `recall` with a concise query made from the user's task, repo/project name, relevant file paths, and obvious product terms.
3. If the user is continuing a substantive current conversation and no explicit search phrase is needed, call `surface_relevant` with the recent user turn or short recent excerpt. This tool may intentionally abstain.
4. If a retrieval result identifies a useful session, call `read_memory` when full session context is needed.
5. If no active memory exists and the task is likely to span multiple replies, call `import_chat` once to create an active session.

Do not block the task if AnySlate is unavailable. Mention the connection issue once, then continue normally.

## Importing Sessions

Use `import_chat` to create a new AI Memory session from a complete or substantial transcript.

Important options:

- `source`: use `codex` for Codex work, `claude_code` for Claude Code, or another visible enum value from the live schema.
- `content`: raw transcript or compact structured conversation.
- `title`: optional human-readable title.
- `project`: stable project name so related memories cluster together.
- `tags`: small set of useful labels.
- `default_role`: use `user` when capturing a user's plain first message; otherwise omit or use the schema default.
- `client_import_id`: stable idempotency key for retries.
- `force_new_session`: only when intentionally importing a duplicate transcript.
- `parent_session_ids`: link continuation chains when this session continues prior sessions.
- `sensitivity`: only when the content is known to be `safe`, `pii`, `phi`, `payment`, or `legal_privileged`.

Do not store credentials, token values, private keys, full `.env` contents, payment data, or unrelated local files.

## Retrieval

Choose retrieval tools by intent:

- `surface_relevant({recent_excerpt, turn_history?, top_k?, mode?, include_explanations?})`: proactive memory surfacing at the start of substantive turns. Use `fast` for normal checks; use `balanced` or `thorough` only when latency is acceptable.
- `recall({query, atom_kinds?, top_k?, scope_override?})`: semantic/lexical search for explicit prior-context questions.
- `search_memory({q, limit?, scope_override?})`: title/tag keyword lookup for sessions, not body search.
- `list_memories({source?, project?, tags?, q?, limit?, offset?, scope_override?})`: browse session metadata.
- `read_memory({session_id})`: open one known session.
- `get_context_subgraph({topic, max_nodes?, include_node_types?, scope_override?})`: graph neighborhood around a known topic or decision.
- `expand_decision({decision_id})`: inspect a specific decision returned by recall or graph tools.
- `get_related({node_id, limit?})`: get graph neighbors for a known node.
- `search_files({q, limit?})`: filename lookup from the AI Memory surface. It is not file-body search.

Do not use `surface_relevant` as a replacement for explicit `recall` queries. Do not use `search_memory` for semantic body retrieval.

## Checkpoints

Use `checkpoint_session` for durable progress, reasoning, decisions, tests, deployments, blockers, topic shifts, and end-of-conversation summaries.

Valid `kind` values:

- `topic_shift`
- `decision_committed`
- `task_completed`
- `task_added`
- `artifact_produced`
- `milestone`
- `conversation_end`

Important options:

- `session_id`: active memory session.
- `notes`: one compact sentence or paragraph naming what happened.
- `conversation_excerpt`: optional recent turns when the merge needs context.
- `host_hint`: use `codex` when helpful.
- `artifact_refs`: artifact ids or `cloud://artifact/<id>` URIs. Required in practice for `artifact_produced`.
- `client_checkpoint_id`: stable idempotency key for retries.

When a decision supersedes an older decision, include the older decision's exact code-like identifier in `notes`. Plain prose like "reversing the earlier choice" is not reliable enough for the supersession classifier.

After creating a checkpoint, use `get_checkpoint_status` only when the user or task needs confirmation that the async merge landed. Use `retry_checkpoint` only after `get_checkpoint_status` shows a stuck or permanently failed checkpoint and the user explicitly wants a retry.

## Atoms

Use direct atom tools when the structure is already clear:

- `append_decision({session_id, decision})`: add a known decision.
- `append_task({session_id, task})`: add a known task.
- `mark_decision_superseded({new_decision_id, superseded_decision_id, justification?})`: only when the user explicitly confirms a supersession and the automatic classifier missed it.
- `generate_continuation_prompt({session_id, target_tool?, mode?, format?, length?})`: create a handoff prompt for another chat/tool or a later continuation.

Prefer `checkpoint_session` when the agent has richer context and the server should extract decisions/tasks from the notes.

## Artifacts

Capture durable artifacts before referencing them in checkpoints. Pick the route automatically from what you have.

**Always pass the real file name (with its extension) and an accurate `mime_type`/`filename`.** The stored file name and its type pill are derived from the extension; a recognised `mime_type` is the next signal. If you pass neither a dotted filename nor a real mime (e.g. you send `application/octet-stream` with no `path_hint`), the artifact is stored as a generic `<id>.bin` typed "code". Never send `application/octet-stream` when you know the true type, and never drop the extension from a name you already have.

1. Public or reachable URL: use `attach_artifact_url({session_id, url, kind?, language?, path_hint?})`. Prefer this for screenshots, images, PDFs, generated media, public files, and any binary already reachable over `http(s)`.
2. Local binary with direct HTTP egress available: use `request_artifact_upload({session_id, filename?, kind?})`, then PUT raw bytes to the returned upload URL. This avoids base64.
3. Inline text or binary up to the live inline limit: use `upload_artifact({session_id, content, kind?, mime_type?, language?, path_hint?})`. Text content can be plain UTF-8. Binary content must be base64 or a `data:<mime>;base64,...` URI paired with a binary `mime_type`.
4. MCP-only binary larger than the inline path supports: use `begin_artifact_upload({session_id, total_bytes, mime_type, sha256?, filename?, kind?, language?, path_hint?})`, repeat `upload_artifact_chunk({upload_id, chunk_index, content})` for base64 chunks, then call `finish_artifact_upload({upload_id})`.

Use `attach_artifact_to_checkpoint({checkpoint_id, artifact_ids})` when a checkpoint already exists and needs links to artifacts. Use `get_artifact({artifact_id})` to inspect stored artifact content or metadata.

Do not claim `artifact_produced` without storing or linking the actual artifact.

## Project, Hygiene, Privacy, And Audit

Use these tools only when the user intent matches the subsystem:

- Project briefs: `summarize_project`, `get_project_summary_diff`, `ask_project`
- Hygiene inspection: `list_hygiene_findings`, `list_hygiene_events`, `get_memory_state`
- Privacy: `get_privacy_mode`, `set_session_sensitivity`
- Compliance: `query_audit_log`, `verify_audit_chain`, `bridge_verify`

Do not run archive, dedupe, destructive resource operations, or sensitivity changes without explicit user intent or a strong stated reason.

## Handles And Scopes

Many tools accept optional `handle` or `scope_override`. Do not invent handles. Use the active token's default scope unless the user is intentionally narrowing or debugging scope.

Use `list_handles` only for debugging token/scope questions. It returns metadata, not secret material.

If a tool is missing from `tools/list`, adapt to the visible surface and explain that the token likely lacks the required scope. Do not assume stale documentation is correct.

## Low-Level Tools

`activity_submit` is for lifecycle hooks, git hooks, browser extension capture, and internal telemetry. Most Codex agents should ignore it and use `checkpoint_session` instead.

`submit_surface_feedback` requires a `feedback_id` from an actual `surface_relevant` result and an explicit user reaction (`accepted`, `dismissed`, `ignored`, or `not_now`). Do not fabricate feedback.

`request_artifact_upload` and the chunked upload trio are operational tools. Use them only when the artifact route requires them.

## End Of Task

Before the final response, checkpoint the outcome when AnySlate is available and the task was non-trivial.

The final checkpoint should include:

- status: completed, partially completed, blocked, or deferred
- changed files or deployed services
- decisions made
- tests/builds/deployments run and their results
- remaining risks or next steps

If no active session exists, create one with `import_chat` first only when the work is worth preserving. For tiny one-line answers, skip memory.

## Failure Handling

- Authentication error: tell the user to create or rotate an AnySlate MCP token.
- Permission error: tell the user to use the AI Memory automation profile or a token with the needed `memory:*` scope.
- Rate limit: continue without retry loops; checkpoint later if possible.
- Unknown tool: use `tools/list` live state and choose the nearest visible tool.
- Tool/runtime error: mention once, continue the task, and include the memory failure in the final note.

Never retry a failing AnySlate call more than once in the same turn unless the user explicitly asks.

## User-Facing Behavior

Do not narrate every memory call. The user asked for automation. Keep normal progress updates focused on the actual engineering work.

Mention AnySlate only when:

- memory context materially changed the answer
- a checkpoint/upload failed
- the user asks about memory
- setup, scope, or token rotation is needed

## Privacy And Safety

Never store:

- credentials or token values
- `.env` contents
- private keys
- payment/card data
- personal data not relevant to the task
- full third-party copyrighted documents unless the user explicitly provided them for this purpose and storage is appropriate

Summarize sensitive logs instead of uploading raw output.
