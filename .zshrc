export PATH=/usr/bin:/boot/dietpi:/bin:/usr/sbin:/sbin:$PATH

#set history size
export HISTSIZE=1000000
#save history after logout
export SAVEHIST=1000000
#history file
export HISTFILE=~/.zhistory
#append into history file
setopt INC_APPEND_HISTORY
#save only one command if 2 common are same and consistent
setopt HIST_IGNORE_DUPS
#add timestamp for each entry
setopt EXTENDED_HISTORY
#Ignore some commands
export HISTORY_IGNORE="(ls|vault|history)"
#Share History between terminals
setopt SHARE_HISTORY
#Append history rather then overwritting
setopt APPEND_HISTORY

setopt interactivecomments

eval "$(starship init zsh)"

export EDITOR="vim"

source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

source ~/.aliases

FPATH="$HOME/.docker/completions:$FPATH"
autoload -Uz compinit && compinit

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "${key[Up]}" up-line-or-beginning-search # Up
bindkey "${key[Down]}" down-line-or-beginning-search # Down

zstyle ':completion:*' menu select

/boot/dietpi/dietpi-login