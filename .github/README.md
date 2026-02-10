# This are my dotfiles

# Setup on a new machine

```sh
git clone --bare git@github.com:kiedanski/dotfiles.git $HOME/.cfg
function config {
   /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME $@
}
mkdir -p .config-backup
config checkout
if [ $? = 0 ]; then
  echo "Checked out config.";
  else
    echo "Backing up pre-existing dot files.";
    config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} .config-backup/{}
fi;
config checkout
config config status.showUntrackedFiles no

mkdir -p ~/.local/share/zsh
git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.local/share/oh-my-zsh
```

# Configuration

1. (Optional) Change the shell to ssh `chsh -s $(which zsh)`
2. Install oh-my-zsh: `git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.local/share/oh-my-zsh`
3. `git clone https://github.com/jeffreytse/zsh-vi-mode \
  $ZSH_CUSTOM/plugins/zsh-vi-mode`
4. Install tmux plugin manager: `git clone https://github.com/tmux-plugins/tpm $XDG_DATA_HOME/tmux/plugins/tpm`
5. Install brew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
6. Install tmux plugins from inside tmux: `<C-a> I`


Tools to install:

```sh
jq
jc
neovim
tmux
ripgrep
fd
ffmpeg
xsv
```

# Window Manager Setup (bspwm + sxhkd)

## Install packages

```sh
sudo apt update
sudo apt install bspwm sxhkd rofi nitrogen picom feh alacritty polybar -y
```

**Package descriptions:**
- `bspwm` - Binary space partitioning window manager
- `sxhkd` - Simple X hotkey daemon
- `rofi` - Application launcher
- `alacritty` - Terminal emulator
- `nitrogen` or `feh` - Wallpaper setter
- `picom` - Compositor for transparency/effects
- `polybar` - Status bar (optional)

## Configuration

Configuration files are located at:
- `~/.config/bspwm/bspwmrc` - bspwm configuration
- `~/.config/sxhkd/sxhkdrc` - hotkey bindings

## Enable bspwm

Add to `~/.xinitrc`:
```sh
exec bspwm
```

Or select bspwm from your display manager.

## Key Bindings (Super = Windows key)

**Essential:**
- `Super + Enter` - Open terminal
- `Super + d` - Application launcher (rofi)
- `Super + q` - Close window
- `Super + Shift + q` - Kill window
- `Super + Alt + r` - Restart bspwm
- `Super + Alt + q` - Quit bspwm
- `Super + Escape` - Reload sxhkd config

**Window Management:**
- `Super + h/j/k/l` - Focus window (left/down/up/right)
- `Super + Shift + h/j/k/l` - Move window
- `Super + 1-9,0` - Switch to desktop 1-10
- `Super + Shift + 1-9,0` - Send window to desktop
- `Super + f` - Fullscreen
- `Super + t` - Tiled mode
- `Super + s` - Floating mode
- `Super + m` - Toggle monocle (maximized) layout

**Resizing:**
- `Super + Alt + h/j/k/l` - Expand window
- `Super + Alt + Shift + h/j/k/l` - Contract window
- `Super + Arrow keys` - Move floating window

# References

This config is based on [this guide](https://www.atlassian.com/git/tutorials/dotfiles)
