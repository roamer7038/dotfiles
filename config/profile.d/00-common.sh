# bash と zsh の双方から読み込む共通設定。
# どちらからも読めるよう POSIX sh の範囲で書き、シェル固有の記法は使わない。
# ~/.config/profile.d/ へ配置され、名前順で最初に読まれる。
# 利用者が同じディレクトリに置いたファイルは後に読まれ、ここの値を上書きできる。

# ============================================================
# 環境変数
# ============================================================

export EDITOR=vim
export SYSTEMD_EDITOR=/usr/bin/vim

# -i: 検索で大小文字を区別しない / -M: 詳細プロンプト
# -R: 色のエスケープを解釈 / -x4: タブ幅4
export LESS='-i -M -R -x4'

# BSD ls 用の配色（GNU ls は後段の dircolors が設定する LS_COLORS を使う）
export LSCOLORS=Exfxcxdxbxegedabagacad

# ============================================================
# PATH
# ============================================================
#
# 前方に足すため、後に書いたものほど優先される。
# anyenv の shim は go・ruby の探索より前に置く必要があるので順序を変えない。

[ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"
[ -d /snap/bin ] && PATH="/snap/bin:$PATH"

# anyenv は ~/.anyenv と ~/.config/anyenv のどちらにも入りうる
if [ -d "$HOME/.anyenv" ] || [ -d "$HOME/.config/anyenv" ]; then
  PATH="$HOME/.anyenv/bin:$PATH"
  export GOENV_GOPATH_PREFIX="$HOME/.go"
  eval "$(anyenv init -)"
fi

# goenv 以外で入れた Go でも go install 先を通す
if command -v go >/dev/null 2>&1; then
  export GOPATH="${GOPATH:-$HOME/.go}"
  export GOBIN="$GOPATH/bin"
  PATH="$PATH:$GOBIN"
fi

# gem install --user-install の配置先
if command -v ruby >/dev/null 2>&1; then
  PATH="$(ruby -e 'print Gem.user_dir')/bin:$PATH"
fi

[ -d "$HOME/.yarn" ] && PATH="$HOME/.yarn/bin:$PATH"

if [ -d "$HOME/.bun" ]; then
  export BUN_INSTALL="$HOME/.bun"
  PATH="$BUN_INSTALL/bin:$PATH"
fi

export PATH

# ============================================================
# 配色
# ============================================================

if command -v dircolors >/dev/null 2>&1; then
  if [ -r "$HOME/.dircolors" ]; then
    eval "$(dircolors -b "$HOME/.dircolors")"
  else
    eval "$(dircolors -b)"
  fi

  alias ls='ls -F --color=auto'
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

# ============================================================
# エイリアス
# ============================================================

# 上書き・削除の前に確認する
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias mkdir='mkdir -p'

# 標準入力をクリップボードへ
alias C='xsel --input --clipboard'
