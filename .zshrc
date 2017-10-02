export LANG=ja_JP.UTF-8
export LSCOLORS=Exfxcxdxbxegedabagacad
export LESS='-i -M -R -x4'
export EDITOR=vim

autoload -Uz colors
colors
autoload -Uz compinit
compinit -u
autoload -Uz vcs_info

[[ -d ~/.rbenv  ]] && \
    export PATH=${HOME}/.rbenv/bin:${PATH} && \
    eval "$(rbenv init -)"

[[ -d ~/.nodebrew ]] && \
    export PATH=$HOME/.nodebrew/current/bin:$PATH

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
setopt auto_menu
setopt auto_param_keys
setopt magic_equal_subst
setopt globdots
setopt hist_save_no_dups
setopt rm_star_wait
setopt prompt_subst

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' ignore-parents parent pwd ..
zstyle ':completion:*:processes' command 'ps x -o pid,s,args'
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin \
                   /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin

zstyle ':vcs_info:*' formats '%K{022}%F{250} %b %f%k '
zstyle ':vcs_info:*' actionformats '%K{124}%F{250} %a %f%k%K{022}%F{250} %b %f%k '

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

# C で標準出力をクリップボードにコピーする
if which pbcopy >/dev/null 2>&1 ; then
    # Mac
    alias -g C='| pbcopy'
elif which xsel >/dev/null 2>&1 ; then
    # Linux
    alias -g C='| xsel --input --clipboard'
elif which putclip >/dev/null 2>&1 ; then
    # Cygwin
    alias -g C='| putclip'
fi

case ${OSTYPE} in
    darwin*)
        export CLICOLOR=1
        export HOMEBREW_CASK_OPTS="--appdir=/Applications"       
        alias ls='ls -G -F'
        alias airport='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport'
        [[ -d /Applications/MacVim.app ]] && \
            alias vi='env LANG=ja_JP.UTF-8 /Applications/MacVim.app/Contents/MacOS/Vim "$@"'
        [[ -f ~/.github_api_token ]] && \
            source  ~/.github_api_token
        ;;
    linux*)
        alias ls='ls -F --color=auto'
        ;;
esac

# 同期したくない固有設定
[[ -e ~/.zsh_extra ]] && source ~/.zsh_extra
