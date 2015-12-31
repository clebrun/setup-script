# A script that sets up dotfiles, preferred utilities, and neovim

GITHUB_USERNAME="clebrun"

function pause {
  read -p "$*"
}

# Packages that aren't platform specific
COMMON_PACKAGES=(tree git zsh htop tmux) 

# OS entries need 4 things:
  # INSTALL_CMD
  # OS_PACKAGES
  # os_prehook
  # os_posthook

# if OS = OS X
if [[ "$OSTYPE" == "darwin"* ]]; then
  INSTALL_CMD="brew install"

  # rbenv/ruby-build are available through brew. 
  # OS X doesn't have watch by default.
  # Don't ask me why neovim needs to be installed that way :|
  OS_PACKAGES=(rbenv ruby-build watch Caskroom/cask/google-chrome Caskroom/cask/flux Caskroom/cask/slack neovim/neovim/neovim)

  function os_prehook {
    # Install OS X package manager
    echo "If you haven't installed xcode and agreed to the license, do so now."
    pause "Hit enter to continue if you've agreed. "

    if which brew > /dev/null; then
      echo "Brew is already installed."
    else
      echo "Installing brew!"
      ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

      brew doctor
    fi

    # make .config directory
    if [[ ! -d $HOME/.config ]]; then mkdir $HOME/.config; fi

    function os_posthook {
      sudo chsh -s $(which zsh) $(whoami)
    }
  }
fi

# if OS = Linux
if [[ "$OSTYPE" == "linux-gnu" ]]; then
  # TODO: let user specify INSTALL_CMD as flag
  
  read -p "Please put in the package manager command, including sudo if needed.
  e.g. apt-get
  " PAC_MAN

  INSTALL_CMD="$PAC_MAN install"

  OS_PACKAGES=(wget)

  function os_prehook {
    $PAC_MAN update
  }

  function os_posthook {
    git clone git://github.com/sstephenson/rbenv.git $HOME/.rbenv
    mkdir $HOME/.rbenv/plugins
    git clone git://github.com/rbenv/ruby-build.git $HOME/.rbenv/plugins/ruby-build

    sudo chsh -s $(which zsh) $(whoami)
  }
fi

function rbenv_posthook {
  # if rbenv install ruby version isn't already spec'd with flag
  # make option to view version list and enter version to install
  rbenv rehash
  GEMS=(bundler pry rubocop)
  for g in GEMS; do
    gem install $g > /dev/null
  done
}

function pacmangr_installhook {
  for pac in $COMMON_PACKAGES; do
    $INSTALL_CMD $pac > /dev/null
  done
  for pac in $OS_PACKAGES; do
    $INSTALL_CMD $pac > /dev/null
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
  pause "Press enter once you've added the key. "
else
  pause "Press enter if your ssh key (@ ~/.ssh/id_*.pub) is added to your github account. "
fi

# clone dotfiles, nvim config and link
git clone git@github.com:$GITHUB_USERNAME/dotfiles $HOME/dotfiles > /dev/null
ln -s $HOME/dotfiles/{.zshrc,.gitconfig,.tmux.conf} $HOME/

git clone git@github.com:$GITHUB_USERNAME/nvim $HOME/.config/nvim
echo "Don't forget to run nvim and :PluginInstall"

git clone git@github.com:$GITHUB_USERNAME/zshrc $HOME/.zsh
echo "... and run setup_script in $HOME/.zsh"

# call posthooks
os_posthook
rbenv_posthook
