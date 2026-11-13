PATH=":$PATH:"
for dir in "$HOME/.local/share/mise/shims" "$HOME/.local/bin"; do
  PATH=${PATH//:$dir:/:}
done
PATH=${PATH#:}
PATH=${PATH%:}
export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"
unset dir

export EDITOR=vi
export SUDO_EDITOR=vi

[[ $- != *i* ]] && return

shopt -s histappend
HISTCONTROL=ignoreboth
HISTSIZE=32768
HISTFILESIZE=$HISTSIZE

[[ -v BASH_COMPLETION_VERSINFO ]] || source /usr/share/bash-completion/bash_completion 2>/dev/null
command -v mise >/dev/null && eval "$(mise activate bash)"

alias ls='ls --color=auto'
PS1='\w \$ '
