case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac

export EDITOR=vim
export SUDO_EDITOR=vim

[[ $- != *i* ]] && return

shopt -s histappend
HISTCONTROL=ignoreboth
HISTSIZE=32768
HISTFILESIZE=$HISTSIZE

[[ -v BASH_COMPLETION_VERSINFO ]] || source /usr/share/bash-completion/bash_completion 2>/dev/null

alias ls='ls --color=auto'
PS1='\w \$ '
