#!usr/bin/env bash

# A script that sets up dotfiles, preferred utilities, and neovim

function pause {
  read -p "$*"
}

# Packages that aren't platform specific
COMMON_PACKAGES="tree
git
zsh
htop"

if [[ "$OSTYPE" == "darwin"* ]]; then
  INSTALL_CMD="brew install"

  # rbenv/ruby-build are available through brew. 
  # OS X doesn't have watch by default.
  # Don't ask me why neovim needs to be installed that way :|
  OS_PACKAGES="rbenv
  ruby-build
  watch
  Caskroom/cask/google-chrome
  Caskroom/cask/flux
  Caskroom/cask/slack
  neovim/neovim/neovim"

  function os_prehook {
    # Install OS X package manager
    if which brew > /dev/null; then
      echo "Brew is already installed."
    else
      echo "If you haven't installed xcode and agreed to the
      license, do so now."
      pause "Hit enter to continue after your finished."

      echo "Installing brew!"
      ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

      brew doctor
    fi

    if which nvim > /dev/null; then
      echo "Neovim is already installed."
    else
      if [[ ! -d $HOME/.config ]]; then mkdir $HOME/.config; fi
    fi

    function os_posthook {
      echo ''
  }
fi

function rbenv_posthook {
  # if rbenv install ruby version isn't already spec'd with flag
  # make option to view version list and enter version to install
  rbenv rehash
  GEMS="bundler
  pry
  rubocop"
  for g in GEMS; do
    gem install g > /dev/null
  done
}

function pacmangr_installhook {
  for pac in COMMON_PACKAGES; do
    eval "$INSTALL_CMD pac" > /dev/null
  done
  for pac in OS_PACKAGES; do
    eval "$INSTALL_CMD pac" > /dev/null
  done
}

## LET THE GAMES BEGIN ##

# call prehooks
os_prehook

pacmangr_installhook

# TODO:
  # doing this as user ?
    # use https github prefix
  # doing this as repo owner ?
    # use ssh prefix

# make ssh key if one doesn't exist
if [[ -d $HOME/.ssh ]]; then
  read -s -p "What email do you want to use for the ssh key?> " email
  echo "Use default locations for ssh files"
  ssh-keygen -t rsa -b 4096 -C "$email"
  printf "\n"
  cat $HOME/.ssh/id_rsa.pub
  printf "\n"
  echo "Please add the above public ssh key to your github account."
  pause "Press enter once you've added the key."
else
  pause "Press enter if your ssh key (@ ~/.ssh/id_*.pub) is added to your github account."
fi

# clone dotfiles, nvim config and link
git clone git@github.com:clebrun/dotfiles $HOME/dotfiles > /dev/null
ln -s $HOME/dotfiles/{.zshrc,.gitconfig,.tmux.conf} $HOME/

git clone git@github.com:clebrun/nvim $HOME/.config/nvim
echo "Don't forget to run nvim and :PluginInstall"

# call posthooks
os_posthook
rbenv_posthook
