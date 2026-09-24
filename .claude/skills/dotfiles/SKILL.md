---
name: dotfiles
description: Change the user's personal configuration (zsh, starship, nvim, hyprland, quickshell, tmux, ghostty, lazygit, tinty themes, ~/.local/bin scripts, etc.) that is tracked in the bare dotfiles repo at ~/.dotfiles. Use whenever the user wants to add, change or remove config in their home directory.
---

# Dotfiles

The user's config lives in a **bare git repo**: git dir `~/.dotfiles`, work tree `$HOME`,
remote `git@github.com:envilogger/dotfiles.git` (branch `master`).

## Running git on it

The user's alias is `dot` (`lazydot` for lazygit). In your own shell, spell it out, since
aliases may be missing and oh-my-zsh's `g`/`dot` aliases break function definitions:

```sh
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" status --short
```

When talking to the user, use `dot ...` in examples.

`status.showUntrackedFiles=no` is set, so **new files are invisible to `dot status`**
until they are added. Use `dot ls-files` to see what is tracked.

## Hard rules

1. **Never commit, amend, push, rebase or merge.** The user commits and pushes themselves.
   At the end, you may suggest a commit message.
2. **New files get intent-to-add, not staged.** When you create a file that belongs in the
   dotfiles, run `dot add -N <path>`. This records the path in the index so it shows up in
   `dot status` and `dot diff`, but it stages no content. Only do a full `dot add` if the
   user explicitly asks for staging. Never add whole directories, and never use `dot add -A`
   or `dot add .`, because the work tree is all of `$HOME`.
3. **Never run commands that discard work in the work tree.** Do not run `dot clean`,
   `dot checkout -- <path>`, `dot restore`, `dot reset --hard` or `dot stash`: with the work
   tree at `$HOME`, they can wipe real files. If one of these seems necessary, explain why
   and let the user run it.
4. **Two machines share this repo.** See "Machine-specific config" below.
5. **Nothing secret, private or corporate goes into the repo.** Private and corporate
   config belongs in `~/.private`, and secrets go in neither repo. See "Privacy" and
   "Private repo" below.

## Machines

| Hostname (`$HOST`) | Machine |
|---|---|
| `archibook` | laptop (battery, laptop screen) |
| `archistation` | office desktop |

Both run Arch Linux with Hyprland. Check the current one with `cat /etc/hostname`.

### Machine-specific config

Before writing config, ask yourself whether it only makes sense on one machine. Typical
cases are:
- monitor names, resolutions, scaling and layout
- GPU and driver settings
- battery, backlight and power management
- input devices and keyboard layouts
- absolute paths to disks or mounts
- tools installed on only one machine

If it is machine-specific, **tell the user before writing it** and offer options such as:
- **Branch on hostname inside the shared file.** This is the existing pattern: `.zshrc` does
  `case "$HOST" in archibook) ... ;; archistation) ... ;; esac`. Many tools have an
  equivalent, for example a Lua `if` on the hostname in `hyprland.lua`.
- **Split it into a per-machine file** that the shared config includes (for example
  `…/host-archibook.conf`), and commit one file for each machine.
- **Keep it local and untracked.** Put it in a file the shared config includes only if it
  exists, and don't add that file to the repo.

Also mention it when a change needs follow-up on the other machine, such as installing a
package. The other machine only gets the change after the user pulls.

## Privacy

The repo is on GitHub, so treat everything in it as public. Before adding content, or when
reviewing a diff, look for:
- **Secrets:** tokens, API keys, passwords, private keys, OTP seeds, `.env` values, cookies.
- **Private data:** emails, phone numbers, home or network addresses, internal hostnames,
  SSH host lists, VPN config.
- **Corporate details:** employer or client names, AWS account/profile names, cluster names,
  internal URLs, work repo paths, work-only tooling.

Where such content goes:
- **Secrets:** the user's password manager, read at runtime with `op`. They go in neither repo.
- **Private or corporate config and scripts:** `~/.private` (see below).

Tell the user what went where. When you notice existing tracked content that breaks these
rules, point it out and offer to move it to `~/.private`, but don't move it unasked.

Keep the public repo generic, including this skill: don't name employers, clients,
accounts or private tools here. Describe them by kind instead ("work AWS helpers").

## Private repo (`~/.private`)

A separate, **normal** (not bare) private git repo with its own remote, cloned on both
machines. It holds anything that must not be public: work helpers, internal names, private
scripts. Read `~/.private/AGENTS.md` before changing it. In short:

- `zsh/*.zsh` holds aliases and functions grouped by topic. `~/.zshrc` sources them after
  `aliases.zsh`, so they can override public definitions.
- `bin/` holds scripts and is on `PATH`.
- It is optional. `~/.zshrc` skips it when the folder isn't there, so public config must
  never depend on it.
- The same hard rules apply there: never commit or push, new files get `git add -N`, and
  no secrets. Use plain `git -C ~/.private …` for it, not `dot`.
- When a change adds files to it, remind the user to pull it on the other machine.

## Repo conventions

- **Generated files are ignored per folder.** tinty writes generated theme files through
  `tinty-hook.sh`, and each app folder has its own `.gitignore` listing them (with a
  `# Generated by tinty-hook.sh…` comment). Follow this pattern for any generated file,
  and don't commit build output, caches or logs.
- **Read `AGENTS.md` first when a folder has one** (for example `.config/quickshell/AGENTS.md`).
- **Where zsh config lives:**
  - `.zshrc`: oh-my-zsh setup and machine detection. `ZSH_THEME=""`, and starship
    draws the prompt.
  - `$ZSH_CUSTOM` is `~/.config/zsh`: `aliases.zsh` holds aliases and shell functions.
  - `~/.private/zsh/*.zsh` and `~/.private/bin` are loaded right after `aliases.zsh`.
  - Prompt: `.config/starship.toml`. Machine and SSH info reaches it through the
    `STARSHIP_*` environment variables that `.zshrc` exports.
- **Match the style of the file you edit.** Keep comments short.

## Workflow

1. Read the files involved and check whether they're tracked (`dot ls-files <path>`).
2. Before editing, raise any machine-specific or privacy concerns and let the user choose.
3. Make the change.
4. Validate it where a check exists: `zsh -n`, `starship prompt` for a test render,
   `hyprctl reload` or config-check commands, `nvim --headless` and so on. Tell the user
   what you could not verify.
5. Run `dot add -N` for any new file that belongs in the repo.
6. Finish with a summary:
   - what changed, per file
   - `dot status --short`
   - anything to do on the other machine
   - a suggested commit message, without committing
