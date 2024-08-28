HOSTNAME=$(hostname)
if [[ "$HOSTNAME" =~ "tryolabs.com" ]]; then 

  alias v="$HOME/.local/bin/nvim.appimage"
  alias pyenv="/dataslow/danski/.pyenv/bin/pyenv"

  mkdir -p /dataslow/danksi/torch
  export TORCH_HOME="/dataslow/danski/torch"

fi


