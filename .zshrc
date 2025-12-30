# ============================================================
# 基本環境変数
# ============================================================

# ロケール設定（必要に応じてコメントアウトを解除）
# export LANG=ja_JP.UTF-8

# lsコマンドの色設定
export LSCOLORS=Exfxcxdxbxegedabagacad

# lessコマンドのオプション
# -i: 検索時に大文字小文字を区別しない
# -M: 詳細なプロンプト表示
# -R: ANSIカラーエスケープシーケンスを解釈
# -x4: タブ幅を4に設定
export LESS='-i -M -R -x4'

# デフォルトエディタ
export EDITOR=vim
export SYSTEMD_EDITOR="/usr/bin/vim"

# ============================================================
# Zsh コア機能の初期化
# ============================================================

# カラー機能を有効化
autoload -Uz colors
colors

# 補完機能を有効化
autoload -Uz compinit
compinit -u

# VCS（バージョン管理システム）情報表示機能
autoload -Uz vcs_info

# Bash互換の補完を有効化
autoload -U +X bashcompinit && bashcompinit

# Emacsキーバインドを使用
bindkey -e

# Shift+Tabで補完候補を逆順に移動
bindkey "^[[Z" reverse-menu-complete

# ============================================================
# ヒストリー設定
# ============================================================

HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000

# ヒストリー関連のオプション
setopt share_history            # 複数のシェル間でヒストリーを共有
setopt hist_ignore_all_dups     # 重複するコマンドは古い方を削除
setopt hist_reduce_blanks       # 余分な空白を削除してヒストリーに保存
setopt hist_save_no_dups        # ヒストリー保存時に重複を除外

# ============================================================
# 一般的なZshオプション
# ============================================================

# 表示・入力関連
setopt print_eight_bit          # 日本語ファイル名を表示可能に
setopt no_beep                  # ビープ音を無効化
setopt ignore_eof               # Ctrl+Dでログアウトしない
setopt interactive_comments     # コマンドライン上でコメント（#以降）を使用可能に

# ディレクトリ移動関連
setopt auto_cd                  # ディレクトリ名のみでcdを実行
setopt auto_pushd               # cdでディレクトリスタックに自動追加
setopt pushd_ignore_dups        # ディレクトリスタックに重複を追加しない

# 補完関連
setopt auto_list                # 補完候補を自動的にリスト表示
setopt auto_menu                # 補完候補を順次選択できるようにする
setopt auto_param_keys          # カッコの対応を自動補完
setopt magic_equal_subst        # =以降でもファイル名補完を有効化
setopt complete_in_word         # 単語の途中でも補完を開始
setopt list_packed              # 補完候補を詰めて表示
setopt always_last_prompt       # 補完時にカーソル位置を保持

# その他
setopt equals                   # =commandでコマンドのパスを展開
setopt globdots                 # ドットファイルも glob 対象に含める
setopt rm_star_wait             # rm * を実行する前に確認
setopt prompt_subst             # プロンプトで変数展開・コマンド置換を有効化
setopt brace_ccl                # ブレース展開を有効化

# ============================================================
# 補完システムの設定
# ============================================================

# dircolorsの設定を読み込み（Linux環境）
eval `dircolors`

# 補完候補に色をつける
zstyle ':completion:*:default' list-colors ${LS_COLORS}

# killコマンドの補完候補に色をつける
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([%0-9]#)*=0=01;31'

# 補完方法の設定
# _complete: 通常の補完
# _match: glob パターンマッチ
# _approximate: 曖昧補完
zstyle ':completion:*' completer _complete _match _approximate

# 補完結果をキャッシュして高速化
zstyle ':completion:*' use-cache true

# 大文字小文字を区別しない補完
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# 親ディレクトリを補完候補から除外
zstyle ':completion:*' ignore-parents parent pwd ..

# プロセスリストの補完設定
zstyle ':completion:*:processes' command 'ps x -o pid,s,args'

# sudoコマンドのPATH設定
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin

# ============================================================
# VCS（バージョン管理）情報の設定
# ============================================================

# Gitリポジトリの変更をチェック
zstyle ':vcs_info:git:*' check-for-changes true

# ステージされた変更がある場合の表示
zstyle ':vcs_info:git:*' stagedstr "+"

# ステージされていない変更がある場合の表示
zstyle ':vcs_info:git:*' unstagedstr "-"

# 通常時のフォーマット（ブランチ名、変更状態を表示）
zstyle ':vcs_info:*' formats '%K{022}%F{250} %b%u%c %f%k '

# アクション実行時のフォーマット（rebase、merge時など）
zstyle ':vcs_info:*' actionformats '%K{124}%F{250} %a %f%k%K{022}%F{250} %b%u%c %f%k '

# コマンド実行前にVCS情報を更新
precmd() { vcs_info }

# ============================================================
# プロンプトの設定
# ============================================================

# 左プロンプト: [ユーザー名@ホスト名] カレントディレクトリ（3階層まで）
PROMPT="%F{034}%B[%n@%m]%b%f %F{075}%3~%f
%F{208}>%#%f "

# 右プロンプト: VCS情報 + 現在時刻
RPROMPT='%B${vcs_info_msg_0_}%b%{${reset_color}%}%F{178}%B[%*]%b%f%{${reset_color}%}'

# ============================================================
# エイリアスの設定
# ============================================================

# 基本コマンドのエイリアス
alias l='ls'
alias s='ls'
alias la='ls -a'
alias ll='ls -l'
alias ks='ls'

# 安全なファイル操作（上書き前に確認）
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# ディレクトリ作成時に親ディレクトリも自動作成
alias mkdir='mkdir -p'

# sudoコマンドでエイリアスを有効化
alias sudo='sudo '

# グローバルエイリアス（パイプと組み合わせて使用）
alias -g L='| less'
alias -g G='| grep'

# ============================================================
# 関数の定義
# ============================================================

# SSH接続してtmuxセッションにアタッチまたは新規作成
function ssht {
  ssh -t $1 "tmux -u a || tmux -u new-session"
}
compdef _ssh_hosts ssht

# ============================================================
# OS固有の設定
# ============================================================

case ${OSTYPE} in
  linux*)
    # Linuxでのlsとgrepに色をつける
    alias ls='ls -F --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    
    # クリップボードコピー用エイリアス
    alias C='xsel --input --clipboard'
    
    # Ctrl+S/Qによる端末のフロー制御を無効化
    stty start undef
    stty stop undef
    ttyctl -f

    # WSL2環境の検出と設定
    if [[ "$(uname -r)" == *microsoft* ]]; then
      # WSLgのキーボードレイアウト設定（x11-xkb-utilsが必要）
      type setxkbmap > /dev/null 2>&1 && \
        setxkbmap -layout us

      # VSCodeのパスを追加
      export PATH=$PATH:/mnt/c/Users/$USER/AppData/Local/Programs/Microsoft\ VS\ Code/bin

      # Windowsエクスプローラーを開く関数
      function open() {
        /mnt/c/Windows/System32/cmd.exe /c start $(wslpath -w $1)
      }
      alias explorer='open'

      # ブラウザ環境変数の設定
      export BROWSER="$HOME/dotfiles/bin/chrome-browser"
    fi
    ;;
esac

# ============================================================
# PATH設定
# ============================================================

# カスタムbinディレクトリ
[ -d ~/.local/bin ] && \
  export PATH=$HOME/.local/bin:$PATH

# Snap パッケージのbinディレクトリ
[ -d ~/snap/bin ] && \
  export PATH=$HOME/snap/bin:$PATH

# anyenv（各言語のバージョン管理ツール）
if [ -d ~/.anyenv ] || [ -d ~/.config/anyenv ]; then
  export PATH=$HOME/.anyenv/bin:$PATH
  export GOENV_GOPATH_PREFIX=$HOME/.go
  eval "$(anyenv init -)"
  
  # Go言語のパス設定（anyenv経由でインストールされた場合）
  if type go > /dev/null 2>&1; then
    export GOPATH=$(echo $GOPATH | sed -e 's/go/.go/g')
  fi
fi

# Go言語の環境変数設定（anyenv以外でインストールされた場合も考慮）
if type go > /dev/null 2>&1; then
  export GOPATH=${GOPATH:-$HOME/.go}
  export GOBIN=$GOPATH/bin
  export PATH=$PATH:$GOBIN
fi

# Ruby（gem）のパス設定
if type ruby > /dev/null 2>&1; then
  export PATH="$(ruby -e 'print Gem.user_dir')/bin:$PATH"
fi

# Yarn（JavaScriptパッケージマネージャ）のパス設定
[ -d ~/.yarn ] && \
  export PATH="$HOME/.yarn/bin:$PATH"

# ============================================================
# 特殊環境の検出とプロンプト表示
# ============================================================

# Rangerファイルマネージャー内での実行を検出
[ -n "$RANGER_LEVEL" ] && \
  RPROMPT='%F{165}%B (Ranger) %b%f'"$RPROMPT"

# Vim内のターミナルでの実行を検出
[ -n "$VIMRUNTIME" ] && \
  RPROMPT='%F{034}%B (Vim) %b%f'"$RPROMPT"

# ============================================================
# 外部スクリプト・プラグインの読み込み
# ============================================================

# ~/.config/profile.d/ 配下のスクリプトを読み込み
if [ -d "$HOME/.config/profile.d" ]; then
  for file in "$HOME"/.config/profile.d/*.{sh,zsh}(N); do
    if [ -r "$file" ]; then
      source "$file"
    fi
  done
  unset file
fi

# Zsh auto-suggestions プラグイン
# コマンド履歴に基づいて入力補完を提案
if [ -d "$HOME/.zsh/zsh-autosuggestions" ]; then
  source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
fi
