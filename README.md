# Dotfiles

Managed with [chezmoi](https://www.chezmoi.io/).

## Quick Start

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply kiedanski
```

Requires [1Password CLI](https://developer.1password.com/docs/cli/get-started/) (`op`) for secrets.

## Machine profiles

| Machine | desktop | tiling_wm | What gets installed |
|---|---|---|---|
| Linux dev laptop | true | true | Everything |
| TV (Ubuntu) | true | false | Shell + nvim + tmux + kitty, no bspwm |
| MacBook | true | false | Shell + nvim + tmux + kitty + LaunchAgents |
| Server | false | false | Shell + nvim + tmux + claude only |

## Secrets

- **API keys** — pulled from 1Password at apply time (Chezmoi vault)
- **SSH keys** — age-encrypted in repo, decrypted at apply time
- **Age key** — stored in 1Password, auto-retrieved on first run

## Day-to-day

```bash
chezmoi edit <file>       # edit managed file
chezmoi diff              # preview changes
chezmoi apply             # apply
chezmoi update            # pull + apply from remote
chezmoi cd                # go to source dir to commit/push
```

## External dependencies

Zsh plugins, oh-my-zsh, and tpm managed via `.chezmoiexternal.yaml` — no git submodules. Auto-cloned on `chezmoi apply`, refreshed weekly.
