# claude-env

One command. One tmux session per repo. A `main` window plus opt-in git worktree windows, each ready to run [Claude Code](https://claude.com/claude-code). Optional in-pane diff review via [difit](https://github.com/yoshiko-pg/difit).

Built for Linux. Tested with Ghostty, but works with any terminal that runs tmux.

```
claude-env REPO --add worktree1,worktree2
```

→ creates `<repo>-worktree1` and `<repo>-worktree2` worktrees if they don't exist, opens a tmux session with three windows, lets you switch with <kbd>F1</kbd>/<kbd>F2</kbd>/<kbd>F3</kbd>.

## Why

Parallel Claude Code sessions on isolated branches without context-switching the main agent. Each window has its own working tree → no `git stash` dance, no agent stepping on its own commits.

## Install

```bash
git clone https://github.com/EricBois/claude-env.git ~/projects/claude-env
cd ~/projects/claude-env
./install.sh
source ~/.bashrc
```

The installer:

- Copies `bin/claude-env` to `~/bin/`
- Adds `~/bin` to `PATH` in `.bashrc` / `.zshrc` (only if missing)
- Drops a sample presets file at `~/.config/claude-env/presets`
- Installs `config/tmux.conf` → `~/.tmux.conf` (only if you don't already have one)
- Installs `config/ghostty.conf` → `~/.config/ghostty/config` (only if you don't already have one)

Re-running is safe. The script never clobbers existing dotfiles.

## Dependencies

| Tool | Required | Why |
|------|----------|-----|
| `tmux` | yes | session + tab management |
| `git` | yes | worktrees |
| `claude` | yes | Claude Code CLI |
| `difit` | optional | `npm i -g difit` — diff viewer popup |
| `ghostty` | optional | the terminal the keybinds were tuned for |

## Usage

```bash
claude-env                     # pick preset interactively
claude-env REPO              # use preset
claude-env ~/code/foo          # raw path
claude-env --list              # show all presets
claude-env REPO --start      # auto-run `claude` in every window
claude-env REPO --ask        # prompt before starting claude
claude-env REPO --add worktree1,worktree2
claude-env REPO --add bugfix,review:origin/main
claude-env REPO --add a --add b,c
```

### `--add NAME[:BRANCH]` semantics

- Worktree path: `<repo>-NAME` (sibling of the repo)
- Branch: `BRANCH` if supplied, otherwise `NAME` itself
- Existing branch → checked out; missing branch → created with `git worktree add -b`
- Re-running with the same `--add` is idempotent (reuses worktree + tmux window)
- Works on first launch *and* against an already-attached session

### Presets file

Path: `~/.config/claude-env/presets`. One `name = path` per line. `~` expands to `$HOME`. `#` starts a comment.

```
REPO   = ~/projects/myrepo
app1     = ~/projects/app1
app2     = ~/projects/app2
```

## tmux shortcuts

Defaults shipped in `config/tmux.conf`:

| Keys | Action |
|------|--------|
| <kbd>F1</kbd> / <kbd>F2</kbd> / <kbd>F3</kbd> | jump to `main` / `worktree1` / `worktree2` (by name, TUI-safe) |
| <kbd>Alt</kbd>+<kbd>1/2/3</kbd> | same, but Alt may be eaten by Claude Code's TUI |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>←</kbd>/<kbd>→</kbd> | prev / next window |
| <kbd>Ctrl</kbd>+<kbd>b</kbd> <kbd>d</kbd> | `difit` diff viewer in a popup over current pane's cwd |
| <kbd>Ctrl</kbd>+<kbd>b</kbd> <kbd>Ctrl</kbd>+<kbd>d</kbd> | `difit` in background (browser only, no popup) |
| <kbd>Ctrl</kbd>+<kbd>b</kbd> <kbd>D</kbd> | detach session |
| <kbd>Ctrl</kbd>+<kbd>b</kbd> <kbd>r</kbd> | reload `~/.tmux.conf` |
| <kbd>Ctrl</kbd>+<kbd>b</kbd> <kbd>w</kbd> | window picker (always works) |
| mouse | click status bar tabs, scroll, resize panes |

To map an F-key to a different worktree name:

```tmux
bind -n F4 select-window -t bugfix
```

## Daily workflow

1. `claude-env REPO --add worktree1,worktree2`
2. <kbd>F2</kbd> → land in `worktree1` worktree, type `claude`, describe the task
3. <kbd>Ctrl</kbd>+<kbd>b</kbd> <kbd>d</kbd> → review the diff in `difit`, leave comments, paste exported prompt back to Claude
4. <kbd>F3</kbd> → start a parallel task in `worktree2` without touching `worktree1`
5. Detach with <kbd>Ctrl</kbd>+<kbd>b</kbd> <kbd>D</kbd>, close the terminal — session persists
6. Reopen: `claude-env REPO` reattaches everything

## Remote access (phone / laptop / anywhere)

Because tmux sessions persist server-side, you can drop into the same Claude Code session from another machine — including an Android phone via [Termux](https://termux.dev).

Two ways in:

- **SSH** — works everywhere, drops the session if the network flaps.
- **Mosh** — UDP-based, survives Wi-Fi → LTE handoffs, suspend/resume, and roaming. More stable on mobile; recommended over plain SSH when reachable.

For a zero-config private network between devices (no port forwarding, no public IP), put both ends on [Tailscale](https://tailscale.com). Then:

```bash
# from Termux on Android (or any client)
pkg install openssh mosh           # Termux
mosh <tailscale-host>              # or: ssh <tailscale-host>
claude-env REPO                  # reattaches the existing tmux session
```

The tmux session is persistent and reattachable, so closing Termux, switching networks, or losing signal does not lose state.

## Cleanup (intentionally manual)

`claude-env` never deletes anything. When you're done with a feature:

```bash
# from outside any tmux window
git -C ~/projects/myrepo worktree list
git -C ~/projects/myrepo worktree remove ../myrepo-worktree1
git -C ~/projects/myrepo branch -D worktree1
git -C ~/projects/myrepo worktree prune

tmux kill-session -t claude-myrepo   # optional
```

## Repo layout

```
claude-env/
├── README.md
├── install.sh
├── bin/
│   └── claude-env             # the launcher
├── config/
│   ├── ghostty.conf           # reference Ghostty config (Linux)
│   ├── tmux.conf              # F-key bindings, difit popup, status bar
│   └── presets.example        # sample presets file
└── docs/
    └── index.html             # standalone HTML guide
```

## Ghostty notes

The shipped `ghostty.conf` is Linux-only:

- `gtk-titlebar-style = tabs` — tabs merged into titlebar
- `ctrl+shift+{t,w,o,e,...}` keybinds (no `cmd+*`)
- Catppuccin auto light/dark

If you don't use Ghostty, ignore `config/ghostty.conf`. Everything else is terminal-agnostic.

## License

MIT
# claude-env
