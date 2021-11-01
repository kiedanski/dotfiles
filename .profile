# Find operating system

# Check if file is in path
function is_bin_in_path {
  if [[ -n $ZSH_VERSION ]]; then
    builtin whence -p "$1" &> /dev/null
  else  # bash:
    builtin type -P "$1" &> /dev/null
  fi
  [[ $? -ne 0 ]] && return 1
  if [[ $# -gt 1 ]]; then
    shift  # We've just checked the first one
    is_bin_in_path "$@"
  fi
}

# Check if file exists
source_if_exists () {
	[[ -f "$1" ]] && source "$1"
}



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
