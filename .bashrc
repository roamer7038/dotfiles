PS1='\[\e[1;32m\][\u@\h]\[\e[m\] \w \n\$ '
export SYSTEMD_EDITOR="/usr/bin/vim" 

shopt -s histappend
shopt -s checkwinsize
shopt -s cdspell
shopt -s dotglob
complete -c man which
complete -cf sudo

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
    export CLICOLOR=1
    export HOMEBREW_CASK_OPTS="--appdir=/Applications"
    alias ls='ls -G -F'
    alias C='pbcopy'
    alias airport='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport'
    [[ -d /Applications/MacVim.app ]] && \
      alias vi='env LANG=ja_JP.UTF-8 /Applications/MacVim.app/Contents/MacOS/Vim "$@"'

    [[ -f ~/.github_api_token ]] && \
      source  ~/.github_api_token
  ;;

  linux*)
    export LSCOLORS=gxfxcxdxbxegedabagacad 
    alias ls='ls -F --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias open='xdg-open'
    alias C='xsel --input --clipboard'
    stty start undef
    stty stop undef
  ;;
esac

if [ -d ~/.local/bin ]; then
  export PATH=$HOME/.local/bin:$PATH
fi

if type "go" > /dev/null 2>&1; then
  export GOPATH=$HOME/.go && \
  export GOBIN=$GOPATH/bin && \
  export PATH=$PATH:$GOBIN
fi

if [ -d ~/.anyenv ]; then
  export PATH=$HOME/.anyenv/bin:$PATH && \
  eval "$(anyenv init -)"
fi

if [ -d ~/.yarn ]; then
  export PATH="$HOME/.yarn/bin:$PATH"
fi

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ];then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ];then
    . /etc/bash_completion
  fi
fi

