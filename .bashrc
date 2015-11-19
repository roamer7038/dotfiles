PS1='\[\e[1;32m\][\u@\h]\[\e[m\] \w \n\$ '

set -o vi

shopt -s histappend
shopt -s checkwinsize
shopt -s cdspell
shopt -s autocd

HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000

alias la='ls -a'
alias ll='ls -l'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -p'

case ${OSTYPE} in
    darwin*)
        export HOMEBREW_CASK_OPTS="--appdir=/Applications"
        if [ -f ~/.github_api_token ];then
                . ~/.github_api_token
        fi
        ;;
    linux*)
        export LSCOLORS=gxfxcxdxbxegedabagacad 
        alias ls='ls --color=auto'
        alias grep='grep --color=auto'
        alias fgrep='fgrep --color=auto'
        alias egrep='egrep --color=auto'
        ;;
esac

if ! shopt -oq posix; then
     if [ -f /usr/share/bash-completion/bash_completion ];then
        . /usr/share/bash-completion/bash_completion
     elif [ -f /etc/bash_completion ];then
        . /etc/bash_completion
     fi
fi

