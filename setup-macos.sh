#!/bin/bash
PACKAGES="n mas tmux wget tree"
CASK_PACKAGES="font-fira-code-nerd-font zoom obs microsoft-teams visual-studio-code discord firefox iterm2"

#App list: 1password Word Excel PowerPoint OneDrive Afphoto Goodnotes Slack
MAS_APPS="1333542190 462054704 462058435 462062816 823766827 824183456 1444383602 803453959"

# install homebrew

which -s brew
if [[ $? != 0 ]] ; then
    # Install Homebrew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    brew update
fi

brew install $PACKAGES

brew tap homebrew/cask-fonts

# avoid cask quitting if application already installed
for P in $CASK_PACKAGES; do
    brew install --cask $P
done

brew cleanup -s

# install Mac App Store apps
mas install $MAS_APPS

# install pure prompt
sh install-pure.sh
