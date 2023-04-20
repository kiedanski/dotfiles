HOSTNAME=$(hostname)
if [[ "$HOSTNAME" =~ "tryolabs.com" ]]; then 

  alias v="$HOME/.local/bin/nvim.appimage"
  alias poetry="/dataslow/danski/.poetry/bin/poetry"
  alias pyenv="/dataslow/danski/.pyenv/bin/pyenv"
fi


