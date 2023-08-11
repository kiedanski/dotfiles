eval "$(github-copilot-cli alias -- "$0")"

export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"





# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/rebelde/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/rebelde/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/rebelde/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/rebelde/Downloads/google-cloud-sdk/completion.zsh.inc'; fi
