export LANG=ja_JP.UTF-8
export LSCOLORS=Exfxcxdxbxegedabagacad
export LESS='-i -M -R -x4'
export EDITOR=vim
export SYSTEMD_EDITOR="/usr/bin/vim" 

autoload -Uz colors
colors
autoload -Uz compinit
compinit -u
autoload -Uz vcs_info

bindkey -e

HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000

setopt print_eight_bit
setopt no_beep
setopt ignore_eof
setopt interactive_comments
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt equals
setopt share_history
setopt hist_ignore_all_dups
setopt hist_reduce_blanks
setopt auto_list
setopt auto_menu
setopt auto_param_keys
setopt magic_equal_subst
setopt globdots
setopt hist_save_no_dups
setopt rm_star_wait
setopt prompt_subst
setopt brace_ccl
setopt complete_in_word
setopt list_packed
setopt always_last_prompt

eval `dircolors`
zstyle ':completion:*:default' list-colors ${LS_COLORS}
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([%0-9]#)*=0=01;31'
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*' use-cache true
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' ignore-parents parent pwd ..
zstyle ':completion:*:processes' command 'ps x -o pid,s,args'
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin \
                   /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin

zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "+"
zstyle ':vcs_info:git:*' unstagedstr "-"
zstyle ':vcs_info:*' formats '%K{022}%F{250} %b%u%c %f%k '
zstyle ':vcs_info:*' actionformats '%K{124}%F{250} %a %f%k%K{022}%F{250} %b%u%c %f%k '

precmd() { vcs_info }

PROMPT="%F{034}%B[%n@%m]%b%f %F{075}%3~%f
%F{208}>%#%f "
RPROMPT='%B${vcs_info_msg_0_}%b%{${reset_color}%}%F{178}%B[%*]%b%f%{${reset_color}%}'

alias l='ls'
alias s='ls'
alias la='ls -a'
alias ll='ls -l'
alias ks='ls'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -p'
alias sudo='sudo '

alias -g L='| less'
alias -g G='| grep'

alias ssht='(){ssh -t $1 "tmux -u a || tmux -u new-session"}'

bindkey "^[[Z" reverse-menu-complete

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
    alias ls='ls -F --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias open='xdg-open'
    alias C='xsel --input --clipboard'
    stty start undef
    stty stop undef
    ttyctl -f
  ;;
esac

[[ -d ~/.local/bin ]] && \
  export PATH=$HOME/.local/bin:$PATH

[[ executable('go') ]] && \
  export GOPATH=$HOME/.go && \
  export GOBIN=$GOPATH/bin && \
  export PATH=$PATH:$GOBIN

[[ -d ~/.anyenv ]] && \
  export PATH=$HOME/.anyenv/bin:$PATH && \
  eval "$(anyenv init -)"

[[ -d ~/.yarn ]] && \
  export PATH="$HOME/.yarn/bin:$PATH"

[ -n "$RANGER_LEVEL" ] && \
  RPROMPT='%F{165}%B (Ranger) %b%f'"$RPROMPT"

[ -n "$VIMRUNTIME" ] && \
  RPROMPT='%F{034}%B (Vim) %b%f'"$RPROMPT"

