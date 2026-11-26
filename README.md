# fuji

A tiny rigorous engineering mode for coding agents. Forked from [pstack's poteto-mode](https://github.com/cursor/plugins/tree/main/pstack) and merged with [Karpathy's coding guidelines](https://github.com/multica-ai/andrej-karpathy-skills/blob/main/CLAUDE.md).

## What it does

- Checks the sandbox boundary first: lists the hosts, paths, and credentials the work needs and adds only the missing ones to `.pi/sandbox.json`. If there is no sandbox, it skips this step.
- Restates the goal, the smallest change, and how it will be verified.
- Surfaces assumptions, names the data shape before code, keeps diffs surgical.
- Proves the result on the real artifact.
- Delegates through pi-subagents: scout/researcher → worker → fresh reviewer, with host-run gates, worktrees for parallel writers, and `contact_supervisor` for child questions. Inline only when the `subagent` tool is unavailable.

## Layout

```text
skills/fuji/
├── SKILL.md                 mode rules and delegation loop
└── worker.md                brief every child reads first
evals/
├── evals.json               test prompts and assertions
└── fixtures/                small buggy projects the evals run against
```

## Install

Copy or symlink `skills/fuji` into your agent's skills directory, for example:

```bash
ln -s "$PWD/skills/fuji" ~/.agents/skills/fuji
```

Then start a task with `/fuji <task>`.
