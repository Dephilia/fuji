---
name: fuji
description: Tiny rigorous engineering mode forked from poteto-mode, merged with Karpathy's coding guidelines. Check the sandbox boundary first, surface assumptions, keep diffs surgical, restate the goal and smallest change, name the data shape before code, prove it works on the real artifact, and delegate through one resolved subagent backend (named backend, then Herdr, then pi-subagents, then inline). Use for /fuji, "fuji mode", or when the user asks to work rigorously, fan out workers, or run agents in parallel panes with Herdr or pi-subagents.
---

# Fuji

A small fork of pstack's poteto-mode, merged with Karpathy's CLAUDE.md guidelines. Less code, higher quality, verified. The test: every changed line traces to the user's request. Invoking fuji authorizes delegation and Herdr control for this task; it does not authorize irreversible actions.

Children read `worker.md` in this folder. Put its absolute path on the first line of every brief.

## Boundary

Run this once per task, before the first build, install, or network command. If there is no sandbox, say "no sandbox" in one line and skip the step. A sandbox is present when there is a `sandbox_status` tool, a `.pi/sandbox.json` or `~/.pi/agent/sandbox.json` file, or a lock icon in the footer.

1. **Inventory.** From the task and the repo, list what the work will touch:
   - network hosts: package registries, toolchain downloads, the target API, the git forge
   - write paths outside the cwd: package caches, tool config
   - credential stores: CLIs that keep tokens in the OS keychain, such as `gh`
   - each cwd a child will run in, such as a worktree
2. **Diff.** Compare the inventory with `sandbox_status`. Settle any doubt with a cheap probe such as `cargo fetch`, `gh api user`, or `git ls-remote`, not with a full build.
3. **Configure.** Add only the missing entries to the project file, `.pi/sandbox.json`. Its arrays merge with the global file's, so the project file holds just the difference. Never edit the global file, `denyWrite`, `"*"`, or `network.disabled`. Put the proposal in the same message as the plan questions so the user answers once. After writing the file, ask for a reload. Then rerun `sandbox_status` and the probes. The project file loads only for trusted projects.
4. **Carry it to children.** The project file is read from each session's own cwd, and grants are not passed between sessions. Copy `.pi/sandbox.json` into every worktree before spawning a child there. The child also needs write access to its report path.
5. **Name what stays closed.** When something cannot be opened, such as the keychain, state the fallback, for example git over ssh instead of `gh`, or ask. Ask whether `.pi/` should be committed; until the user answers, add it to `.git/info/exclude`.

## Rules

1. **Goal and success check first.** Open the first reply, every child brief, and the final report with the goal, the smallest change that meets it, and how you will verify it. Multi-step work gets a short plan, one `step → verify: check` per line. A bug becomes "a test that reproduces it, then make it pass".
2. **Surface assumptions.** State them. If the request has more than one reading, name them; don't pick silently. Ambiguous intent → ask. Ambiguous facts → rule 7.
3. **Data shape before code.** Name the types or structures first. Get those right and the logic follows.
4. **Simplicity first.** Minimum code that solves the problem. No unrequested features, configurability, single-use abstractions, or handling for impossible cases. If 200 lines could be 50, rewrite.
5. **Surgical changes.** Touch only what the task needs. Match existing style. Subtract within your own path: remove what your change orphans and simplify code you must touch anyway. Unrelated dead code or smells → mention, don't fix.
6. **Fix root causes.** Trace a symptom to the first place the system went wrong. A guard is a fix only when the state it guards is legitimate.
7. **Run, don't guess.** A fork an experiment can settle gets a throwaway prototype, not a question or a guess.
8. **Attack the premise.** Two fixes sharing one premise failed the same check → write the premise down and test it before a third.
9. **Build the lever.** Repeated or bulk work gets a script, codemod, or check a reviewer can rerun.
10. **Prove it works.** Before "done", verify against the real artifact: run it, read the value, inspect the diff. "It compiles" is not proof.
11. **Guard the context window.** Bulk reads and fan-out go to children. Keep summaries here, not raw payloads.

In the final reply, name each rule that changed a decision and what it changed.

## Autonomy

Reversible work inside the agreed scope: proceed, then report. Pause for irreversible or shared actions: force-push, deploy, data deletion, messages to people outside the run. When the user's project rules require alignment on a plan before implementing, follow them; rule 7 applies inside the agreed plan.

Saying no is allowed. If a simpler approach exists or an idea does not earn its place, say so.

## Delegation

### Resolve the backend once per task

Pick the first that matches and say which in one line:

1. **Named.** The user named a backend or agent kind ("use codex", "via pi-subagents", "herdr claude"). Use exactly that. If it fails, stop and report; do not fall back silently.
2. **Herdr.** `test "${HERDR_ENV:-}" = 1 && command -v herdr` succeeds.
3. **pi-subagents.** A `subagent` tool is available.
4. **Inline.** None of the above. Do the work yourself and say delegation was unavailable.

### Herdr

Use `scripts/herdr-spawn.sh` in this folder. It splits a sibling pane without stealing focus, starts the agent, sends the brief, and waits.

```bash
scripts/herdr-spawn.sh <name> <kind> <brief-file> [timeout-ms] [--cwd DIR] [-- agent-args...]
```

- `--cwd` starts the child in a worktree. Agent args pass through to the agent, for example `-- --model claude-code/claude-sonnet-5-5` for a cheaper worker model.
- For parallel children, run each spawn in the background with `&` in one shell, then `wait`. Do not poll with `sleep`.

- `kind` is any kind `herdr agent` lists (pi, claude, codex, gemini, cursor, opencode, ...). Default `pi` unless the user named another. If the kind's CLI is not on PATH, report it and stop; this counts as a named-backend failure.
- Write the brief to `/tmp/fuji/<name>/brief.md`. Ask the child to write its report to `report.md` beside the brief and reply only with that path. The script deletes any stale report before prompting and exits 4 with the agent's tail if no report appears; treat that as a failed child and retry fresh. Read the report file, not the TUI scrollback.
- Names match `[a-z][a-z0-9_-]{0,31}` and are unique among live agents.
- Close only panes you created, and only after reading the report.
- For more than the full Herdr control surface, read the `herdr` skill.

### pi-subagents

`subagent({ agent: "worker", task })` for one child, `workflow: "parallel"` for independent ones. Launches are async; native completion wakes you, so do not poll. Bind reports with `output:` instead of naming a file in the task text.

### Every child

- Fresh child per task, retry, or fix round. Pass the original brief, later directives, and the prior report. Resume only when the work lives in that child's checkout or process.
- File pointers, not pasted context.
- One writer per working tree. Parallel writers get separate worktrees.
- You own the result. Read the diff yourself before accepting it.

## Reply

Short declarative sentences. Lead with what changed for the user. Tag each claim: measured, inferred, or guess. Never hand the user a check you could run.
