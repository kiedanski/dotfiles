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

# Sessions

### 2026-03-11 — Audio port switching + SSR recording toggle

#### Audio: wired headphones not switching

**Problem:** `~/.local/bin/select_audio` had "Laptop" and "Wired Headphones" as separate profiles, but both use the same ALSA sink (`HiFi__hw_sofhdadsp__sink`). The sink has two ports — `[Out] Speaker` and `[Out] Headphones` — but the script never switched ports, so audio always came out of speakers.

**Fix:** Added a 4th field to `STATIC_PROFILES` for sink port, and added `pactl set-sink-port "$sink" "$port"` to `apply_profile`. Port field is optional — omit for sinks that don't need it (e.g. HDMI, Bluetooth).

**Note:** `wpctl status` doesn't show ports — only nodes/sinks. Use `pactl list sinks | grep -A5 "Active Port"` to inspect port state.

#### SSR audio source sync

SSR hardcodes `audio_pulseaudio_source` in `~/.ssr/settings.conf`. Added a `sed -i` call at the end of `apply_profile` in `select_audio` to keep SSR's config in sync whenever the audio profile switches. Requires SSR restart to take effect if already open.

#### CapsLock+R recording toggle (`~/.local/bin/toggle-recording`)

**How it works:**
- First press: creates a FIFO at `/tmp/ssr-control.fifo`, touches `/tmp/ssr-recording` as state flag, spawns a keeper process to hold the FIFO write end open, launches SSR reading from the FIFO
- Second press: writes `record-save` to the FIFO, removes state (kills keeper), waits 1s, copies latest `.mkv` path to clipboard via `xclip`

**Things that didn't work:**
- `script -q -f /dev/null < "$FIFO" -c "simplescreenrecorder ..."` — works in a terminal but fails silently when invoked from sxhkd (no TTY available). Direct FIFO stdin works fine; the `ioctl` warning SSR logs is cosmetic.
- sxhkd binding used `toggle-recording` (bare name) — sxhkd doesn't inherit `~/.local/bin` in its PATH. Fix: use full path `/home/rbk/.local/bin/toggle-recording` in `sxhkdrc`.

**sxhkd binding:** `hyper + r` (CapsLock is remapped to Hyper/mod4)

**Video format:** MKV + h264 (crf=23) + AAC 128kbps — good default. MKV recovers from crashes better than MP4. To remux to MP4: `ffmpeg -i input.mkv -c copy output.mp4`.

### 2026-03-11 — bspwm scratchpad terminals

Set up two toggle-able floating terminal scratchpads via sxhkd + bspwm.

**Keybindings:**
- `super + shift + Return` — floating kitty terminal
- `hyper + n` — floating kitty + nvim editing `~/notes/notes.md`

**Files:**
- `~/.config/bspwm/scripts/scratchpad`
- `~/.config/bspwm/scripts/scratchpad-notes`

**bspwm rules** (in `bspwmrc`): `state=floating sticky=on rectangle=900x500+510+270`

**Gotcha:** `xdotool search --class` is regex-based — `"scratchpad"` matches `"scratchpad-notes"`.
Fix: anchor with `^${WM_CLASS}$` in both scripts.

**Behavior:** toggle hides/shows the window (bspc `hidden` flag). Closing and re-triggering
spawns a fresh instance. `sticky=on` keeps it accessible from any desktop.

# References

This config is based on [this guide](https://www.atlassian.com/git/tutorials/dotfiles)
