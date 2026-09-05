# bash が非ログインの対話シェルとして起動したときに読み込まれる。
# Zsh と共通の設定は shell/common.sh 側にある。

# 対話シェルでなければ何もしない
case $- in
  *i*) ;;
  *) return ;;
esac

# --- ヒストリー ---

HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend

# --- シェルオプション ---

shopt -s checkwinsize
shopt -s cdspell                # cd のタイプミスを補正する
shopt -s dotglob                # ドットファイルも glob の対象にする

# --- 補完 ---

complete -c man which
complete -cf sudo

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# --- プロンプト ---

if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

case "$TERM" in
  xterm* | rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]\[\e[1;32m\][\u@\h]\[\e[m\] \w \n\$ "
    ;;
  xterm-color | *-256color)
    color_prompt=yes
    ;;
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

# --- エイリアス ---

alias l='ls -CF'
alias la='ls -A'
alias ll='ls -alF'
alias open='xdg-open'

# 直前のコマンドの成否をデスクトップ通知で知らせる（長い処理の末尾に `; alert`）
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^[[:space:]]*[0-9]\+[[:space:]]*//;s/[;&|]\s*alert$//'\'')"'

# --- 共通設定（Zsh と共有） ---

# PATH・配色・安全策のエイリアスは shell/common.sh にまとめてある
[ -r "$HOME/.config/shell/common.sh" ] && . "$HOME/.config/shell/common.sh"

# --- 外部設定の読み込み ---

# less で書庫やバイナリも読めるようにする
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

[ -f ~/.bash_aliases ] && . ~/.bash_aliases
