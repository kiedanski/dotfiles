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
```

# Configuration

1. (Optional) Change the shell to ssh `chsh -s $(which zsh)`
2. Install oh-my-zsh: `git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.local/share/oh-my-zsh`
3. Create the folder `~/.local/share/zsh`
4. `git clone https://github.com/jeffreytse/zsh-vi-mode \
  $ZSH_CUSTOM/plugins/zsh-vi-mode`
5. Install tmux plugin manager: `git clone https://github.com/tmux-plugins/tpm $XDG_DATA_HOME/tmux/plugins/tpm`
6. Install brew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
7. Install tmux plugins from inside tmux: `<C-a> I`


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

# References

This config is based on [this guide](https://www.atlassian.com/git/tutorials/dotfiles)
