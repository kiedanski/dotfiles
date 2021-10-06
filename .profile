# Find operating system



ISMAC=false
ISLINUX=false
[[ "$OSTYPE" =~ "darwin" ]] && ISMAC=true
[[ "$OSTYPE" =~ "linux-gnu" ]] && ISLINUX=true
export ISMAC
export ISLINUX


# Basic XGD configs
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# Local executables
export PATH="$HOME/.local/bin:$PATH"

# Bash
mkdir -p "$XDG_DATA_HOME/bash"
export HISTCONTROL="ignoreboth:erasedups"

# Enable bash completition on OSX
$ISMAC && [[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"



# Less history
export LESSHISTFILE="$XDG_CACHE_HOME"/less/history

# Bash history
export HISTFILE="$XDG_DATA_HOME"/bash/history


# Use neovim is avaialbe 
if command -v nvim >/dev/null 2>&1; then
	export VISUAL="nvim"
	export EDITOR="nvim"
fi


# LS
LS_COLORS=$LS_COLORS:'di=0;35:'
export LS_COLORS

# Source bash
source "$XDG_CONFIG_HOME/bash/bashrc"
