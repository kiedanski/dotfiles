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
