# export LANG=ja_JP.UTF-8
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
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin

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

function ssht { ssh -t $1 "tmux -u a || tmux -u new-session" }
compdef _ssh_hosts ssht

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
    # alias open='xdg-open'
    alias C='xsel --input --clipboard'
    stty start undef
    stty stop undef
    ttyctl -f

    # WSL2
    if [[ "$(uname -r)" == *microsoft* ]]; then
      # keyboard layout for WSLg (require: x11-xkb-utils)
      type setxkbmap > /dev/null 2>&1 && \
        setxkbmap -layout us

      # Add VSCode Path
      export PATH=$PATH:/mnt/c/Users/$USER/AppData/Local/Programs/Microsoft\ VS\ Code/bin

      # Open Windows Explorer
      function open() { /mnt/c/Windows/System32/cmd.exe /c start $(wslpath -w $1) }
      alias explorer='open'

      # Set env BROWSER
      export BROWSER="$HOME/dotfiles/bin/chrome-browser"
    fi
  ;;
esac

# Add custom bin directories to PATH
[ -d ~/.local/bin ] && \
  export PATH=$HOME/.local/bin:$PATH

# Add snap bin directories to PATH
[ -d ~/snap/bin ] && \
  export PATH=$HOME/snap/bin:$PATH

# Add anyenv to PATH
[ -d ~/.anyenv ] || [ -d ~/.config/anyenv ] && \
  export PATH=$HOME/.anyenv/bin:$PATH && \
  export GOENV_GOPATH_PREFIX=$HOME/.go && \
  eval "$(anyenv init -)"
  type go > /dev/null 2>&1 && \
    export GOPATH=`echo $GOPATH | sed -e 's/go/.go/g'`

type go > /dev/null 2>&1 && \
  export GOPATH=$HOME/.go && \
  export GOBIN=$GOPATH/bin && \
  export PATH=$PATH:$GOBIN

type ruby > /dev/null 2>&1 && \
  export PATH="$(ruby -e 'print Gem.user_dir')/bin:$PATH"

# Add yarn to PATH
[ -d ~/.yarn ] && \
  export PATH="$HOME/.yarn/bin:$PATH"

[ -n "$RANGER_LEVEL" ] && \
  RPROMPT='%F{165}%B (Ranger) %b%f'"$RPROMPT"

[ -n "$VIMRUNTIME" ] && \
  RPROMPT='%F{034}%B (Vim) %b%f'"$RPROMPT"

autoload -U +X bashcompinit && bashcompinit

# Extends

# Load scripts and environment variables from ~/.config/profile.d/
if [ -d "$HOME/.config/profile.d" ]; then
  for file in "$HOME"/.config/profile.d/*.{sh,zsh}(N); do
    if [ -r "$file" ]; then
      source "$file"
    fi
  done
  unset file
fi

# Load zsh auto suggestion plugin
if [ -d "$HOME/.zsh/zsh-autosuggestions" ]; then
  source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
fi

