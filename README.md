# Dotfiles

Managed with [chezmoi](https://www.chezmoi.io/).

## Quick Start

### New machine setup

```bash
# Install chezmoi and apply dotfiles in one command
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply kiedanski
```

You'll be prompted for:
- **Full name** / **Email** — used in git config
- **Desktop** — whether this machine has a GUI
- **Tiling WM** — whether to install bspwm/sxhkd/polybar configs

### Day-to-day usage

```bash
chezmoi edit ~/.config/nvim/init.lua   # edit a managed file
chezmoi diff                            # see what would change
chezmoi apply                           # apply changes
chezmoi cd                              # cd into source directory to commit/push
```

### Update from remote

```bash
chezmoi update
```

## Machine profiles

| Machine | desktop | tiling_wm | What gets installed |
|---|---|---|---|
| Linux dev laptop | true | true | Everything |
| TV (Ubuntu) | true | false | Shell + nvim + tmux + kitty, no bspwm |
| MacBook | true | false | Shell + nvim + tmux + kitty + LaunchAgents |
| Server | false | false | Shell + nvim + tmux + claude only |

## External dependencies

Zsh plugins, oh-my-zsh, and tmux plugin manager are managed via `.chezmoiexternal.yaml` — no more git submodules. They're automatically cloned on `chezmoi apply` and refreshed weekly.
