# ~/.bashrc: executed by bash(1) for non-login shells.
# Ubuntu WSL optimized - merged from default and custom configs

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History management (both files)
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000

# Shell options (merged: default + custom enhancements)
shopt -s checkwinsize
shopt -s cdspell
shopt -s dotglob

# Completions (both files + custom)
complete -c man which
complete -cf sudo
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# lesspipe support (default)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Chroot detection (default, usually unused in WSL)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Colored prompt with xterm title (default + custom style)
case "$TERM" in
    xterm*|rxvt*)
        PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]\[\e[1;32m\][\u@\h]\[\e[m\] \w \n\$ "
        ;;
    xterm-color|*-256color)
        color_prompt=yes;;
esac

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# Editor (custom)
export SYSTEMD_EDITOR="/usr/bin/vim"

# PATH extensions (custom, yarn removed)
if [ -d ~/.local/bin ]; then
  export PATH=$HOME/.local/bin:$PATH
fi

if type "go" > /dev/null 2>&1; then
  export GOPATH=$HOME/.go
  export GOBIN=$GOPATH/bin
  export PATH=$PATH:$GOBIN
fi

if [ -d ~/.anyenv ]; then
  export PATH=$HOME/.anyenv/bin:$PATH
  eval "$(anyenv init -)"
fi

# Linux colors & aliases (merged both files)
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto -F'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# ls aliases (merged)
alias l='ls -CF'
alias la='ls -A'
alias ll='ls -alF'

# Safety aliases (custom)
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -p'

# Utility aliases (default + custom)
alias open='xdg-open'
alias C='xsel --input --clipboard'
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^[[:space:]]*[0-9]\+[[:space:]]*//;s/[;&|]\s*alert$//'\'')"'

# Load additional aliases (default)
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
