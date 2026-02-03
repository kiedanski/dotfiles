export PYENV_ROOT="$HOME/.pyenv"

command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
command -v pyenv >/dev/null && eval "$(pyenv init -)"


export EDITOR=nvim


# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/rebelde/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/rebelde/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/rebelde/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/rebelde/Downloads/google-cloud-sdk/completion.zsh.inc'; fi


# Hledger XPS
export LEDGER_FILE="$HOME/text/ledger/main.journal"



eval "$(/Users/rebelde/.local/bin/mise activate zsh)"
eval "$(pyenv virtualenv-init -)"

export PNPM_HOME="/Users/rebelde/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion