# programs
alias v="nvim"
alias vim="nvim"
alias tmux='TERM=xterm-256color tmux -f "$XDG_CONFIG_HOME"/tmux/tmux.conf'

# dotfiles
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

#alias bhp="chatblade -c 4 -e -p bashhelp"

function bash_help_chatgpt() {
  chatblade -c 4 -e -p bashhelp "$1" | xargs -I{} echo {} | pbcopy
}
alias bhp=bash_help_chatgpt

alias S="source .venv/bin/activate"
alias I=".venv/bin/ipython"


alias cfg="cd ~/.config"
alias cfgn="cd ~/.config/nvim"
alias cfgz="cd ~/.config/zsh"

alias pnpx='pnpm dlx'

alias kbp="kubectl -n llamacloud"

alias tree="tree -I '__pycache__|.venv'"

# tmux session picker
alias ts='tmux-picker'
