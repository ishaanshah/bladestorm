#!/usr/bin/env bash

user=ubuntu
user_home=$(getent passwd $user | cut -d : -f 6)
if [[ $EUID > 0 ]]
then
        echo "Script should be run as root"
        exit
fi

set -e

# Install and configure shell
if ! command -v zsh &> /dev/null
then
        echo "Installing ZSH"
        apt install -y zsh
fi

if ! grep "^$user" /etc/passwd | grep "zsh" &> /dev/null
then
        echo "Changing default shell to ZSH"
        chsh -s $(which zsh) $user
fi

echo "Installing/Updating Starship"
sh -c "$(curl -fsSL https://starship.rs/install.sh)"

echo "Configuring ZSH"
sudo -u $user cat > $user_home/.zshrc <<EOL
HISTSIZE="10000"
SAVEHIST="50000"

setopt HIST_FCNTL_LOCK
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
setopt autocd

GPG_TTY="$(tty)"
export GPG_TTY

# Aliases
alias c='clear'
alias grep='grep --color=auto'
alias ls='ls --color=auto'
alias l='ls -l'
alias la='ls -a'
alias lh='ls -alh'
alias ll='ls -l'
alias lla='ls -la'

eval "$(starship init zsh)"
EOL

echo "Configuring Starship"
sudo -u $user mkdir -p $user_home/.config
sudo -u $user touch $user_home/.config/starship.toml
sudo -u $user cat > $user_home/.config/starship.toml <<EOL
# Inserts a blank line between shell prompts
add_newline = false
EOL

# Install and configure docker stuff
if ! command -v docker &> /dev/null
then
        echo "Installing docker"
        apt install -y docker
fi

if ! command -v docker-compose &> /dev/null
then
        echo "Installing docker-compose"
        apt install -y docker-compose
fi

if ! groups $user | grep docker &> /dev/null
then
        echo "Adding user to 'docker' group"
        groupadd docker
        usermod -aG docker $user
fi

echo "Setup done, relogin for changes to reflect"
