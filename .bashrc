# bash が対話シェルとして起動したときに読み込まれる。
# Ubuntu の既定（/etc/skel/.bashrc）を土台に、zsh 側と揃えたい設定を足してある。
# PATH・環境変数・エイリアス・関数・OS 別の設定は
# config/profile.d/00-common.sh 側にあり、bash と zsh の双方から読む。

# 対話シェルでなければ何もしない
case $- in
  *i*) ;;
  *) return ;;
esac

# ============================================================
# Bash の基本動作
# ============================================================

# --- ヒストリー ---

# 空白で始まる行と重複した行を記録しない。
# erasedups は既に同じ行があれば古い方を消す（zsh の hist_ignore_all_dups に相当）
HISTCONTROL=ignoreboth:erasedups
HISTSIZE=1000000
HISTFILESIZE=1000000

# 上書きせず追記する
shopt -s histappend

# 複数のシェル間でヒストリーを共有する（zsh の share_history に相当）。
# -a で自分の分を書き出し、-n で前回以降に増えた行だけを取り込む。
# -r はプロンプトのたびに履歴ファイル全体を読み直すため使わない
PROMPT_COMMAND="history -a; history -n${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# --- シェルオプション ---

# ウィンドウサイズの変更を LINES と COLUMNS に反映する
shopt -s checkwinsize

shopt -s autocd                 # ディレクトリ名だけで cd する（zsh の auto_cd）
shopt -s cdspell                # cd のタイプミスを補正する
shopt -s dotglob                # ドットファイルも glob の対象にする（zsh の globdots）
shopt -s globstar               # ** で再帰的にマッチする（zsh は既定で有効）

# Ctrl+D では終了しにくくする（zsh の ignore_eof に相当）
IGNOREEOF=10

# --- 補完 ---

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# --- キーバインドと補完の表示 ---
#
# readline の設定。zsh の zstyle や setopt に対応するものを揃えてある。

bind 'set completion-ignore-case on'       # 大小文字を区別しない（zsh の matcher-list）
bind 'set show-all-if-ambiguous on'        # 曖昧なら一覧をすぐ出す（zsh の auto_list）
bind 'set colored-stats on'                # LS_COLORS で候補を色分けする（zsh の list-colors）
bind 'set menu-complete-display-prefix on' # 共通の接頭辞を先に確定させる
bind 'set bell-style none'                 # ベルを鳴らさない（zsh の no_beep）

# Shift+Tab で補完候補を逆順にたどる（zsh の reverse-menu-complete）
bind '"\e[Z": menu-complete-backward'

# ============================================================
# プロンプト
# ============================================================

# chroot の中にいる場合はプロンプトに名前を出す
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

# 端末が色に対応していれば色付きにする
case "$TERM" in
  xterm-color | *-256color) color_prompt=yes ;;
esac

# 上の判定で拾えない端末では、force_color_prompt=yes を設定しておくと
# tput で対応を確かめたうえで色を使う
if [ -n "${force_color_prompt:-}" ]; then
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

# xterm 系ではウィンドウタイトルに user@host:dir を出す
case "$TERM" in
  xterm* | rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
esac

# ============================================================
# 設定の読み込み
# ============================================================

# PATH・環境変数・配色・安全策のエイリアスは ~/.config/profile.d/ から読む。
# dotfiles が置く 00-common.sh が先、利用者が置いたファイルが後になる。
# Zsh 専用の *.zsh は対象にしない。glob がマッチしないと文字列のまま残るので -r で弾く
if [ -d "$HOME/.config/profile.d" ]; then
  for file in "$HOME"/.config/profile.d/*.sh; do
    [ -r "$file" ] && . "$file"
  done
  unset file
fi
