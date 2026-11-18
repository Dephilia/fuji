# fuji

A tiny rigorous engineering mode for coding agents. Forked from [pstack's poteto-mode](https://github.com/cursor/plugins/tree/main/pstack) and merged with [Karpathy's coding guidelines](https://github.com/multica-ai/andrej-karpathy-skills/blob/main/CLAUDE.md).

## What it does

- Checks the sandbox boundary first: lists the hosts, paths, and credentials the work needs, adds only the missing ones to `.pi/sandbox.json`, and copies that file into child worktrees. If there is no sandbox, it skips this step.
- Restates the goal, the smallest change, and how it will be verified.
- Surfaces assumptions, names the data shape before code, keeps diffs surgical.
- Proves the result on the real artifact.
- Delegates through one resolved backend: a named backend, then [Herdr](https://herdr.dev) (any agent kind: pi, claude, codex, ...), then pi-subagents, then inline.

## Layout

```text
skills/fuji/
├── SKILL.md                 mode rules and backend resolution
├── worker.md                brief every child reads first
└── scripts/
    ├── herdr-spawn.sh       open a child in a children tab, send a brief, wait
    └── herdr-close.sh       close child panes by name or pane id
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
