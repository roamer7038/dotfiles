export LANG=ja_JP.UTF-8
export LSCOLORS=Exfxcxdxbxegedabagacad
export LESS='-i -M -R -x4'

autoload -Uz colors
colors

which screenfetch > /dev/null 2>&1 && screenfetch
function _ssh {
      compadd `fgrep 'Host ' ~/.ssh/config | awk '{print $2}' | sort`;
}

bindkey -e

HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000

PROMPT="%{${fg[green]}%}[%n@%m]%{${reset_color}%} %~
%# "

fpath=(/usr/local/share/zsh-completions $fpath)
autoload -Uz compinit
compinit -u

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' ignore-parents parent pwd ..
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin \
                   /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin
zstyle ':completion:*:processes' command 'ps x -o pid,s,args'

setopt print_eight_bit
setopt no_beep
setopt ignore_eof
setopt interactive_comments
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt share_history
setopt hist_ignore_all_dups
setopt hist_reduce_blanks
setopt auto_menu
setopt auto_param_keys
setopt magic_equal_subst
setopt globdots

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
        export PATH=$HOME/.nodebrew/current/bin:$PATH
        alias ls='ls -G -F'
        alias airport='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport'
        if [ -d /Applications/MacVim.app ];then
                alias vi='env LANG=ja_JP.UTF-8 /Applications/MacVim.app/Contents/MacOS/Vim "$@"'
        fi
        if [ -f ~/.github_api_token ];then
                . ~/.github_api_token
        fi
        ;;
    linux*)
        alias ls='ls -F --color=auto'
        which vim > /dev/null 2>&1 && alias vi=vim
        ;;
esac

