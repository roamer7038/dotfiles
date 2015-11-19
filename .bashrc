PS1='\[\e[1;32m\][\u@\h]\[\e[m\] \w \n\$ '

set -o vi

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
        
        ;;
esac
