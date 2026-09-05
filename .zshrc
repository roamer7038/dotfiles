# ============================================================
# Zsh の基本動作
# ============================================================

# --- コア機能 ---

autoload -Uz colors
colors

autoload -Uz compinit
compinit -u

autoload -Uz vcs_info

# bash-completion 由来の補完定義を zsh でも使えるようにする
autoload -U +X bashcompinit && bashcompinit

bindkey -e

# Shift+Tab で補完候補を逆順にたどる
bindkey "^[[Z" reverse-menu-complete

# --- ヒストリー ---

HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000

setopt share_history            # 複数のシェル間でヒストリーを共有する
setopt hist_ignore_all_dups     # 重複したコマンドは古い方を消す
setopt hist_reduce_blanks
setopt hist_save_no_dups

# --- オプション ---

setopt print_eight_bit          # 日本語のファイル名を表示できるようにする
setopt no_beep
setopt ignore_eof               # Ctrl+D でログアウトしない
setopt interactive_comments     # コマンドラインでも # 以降をコメント扱いにする

setopt auto_cd                  # ディレクトリ名だけで cd する
setopt auto_pushd
setopt pushd_ignore_dups

setopt auto_list
setopt auto_menu
setopt auto_param_keys
setopt magic_equal_subst        # --opt=<パス> の右辺もファイル名補完の対象にする
setopt complete_in_word
setopt list_packed
setopt always_last_prompt

setopt equals                   # =command をそのコマンドの絶対パスに展開する
setopt globdots                 # ドットファイルも glob の対象にする
setopt rm_star_wait             # rm * は待ち時間を挟んで誤操作を防ぐ
setopt prompt_subst
setopt brace_ccl

# ============================================================
# プロンプト
# ============================================================

zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "+"
zstyle ':vcs_info:git:*' unstagedstr "-"

# 通常は緑地にブランチ名。rebase や merge の最中は赤地で操作名を前置する
zstyle ':vcs_info:*' formats '%K{022}%F{250} %b%u%c %f%k '
zstyle ':vcs_info:*' actionformats '%K{124}%F{250} %a %f%k%K{022}%F{250} %b%u%c %f%k '

precmd() { vcs_info }

# 左: [ユーザ@ホスト] カレントディレクトリ（3階層まで）
PROMPT="%F{034}%B[%n@%m]%b%f %F{075}%3~%f
%F{208}>%#%f "

# 右: VCS情報 + 現在時刻
RPROMPT='%B${vcs_info_msg_0_}%b%{${reset_color}%}%F{178}%B[%*]%b%f%{${reset_color}%}'

# ============================================================
# エイリアスと関数
# ============================================================

# --- エイリアス ---

alias l='ls'
alias s='ls'
alias ks='ls'
alias la='ls -a'
alias ll='ls -l'

# 末尾の空白が「次の語もエイリアス展開せよ」の指示になる
alias sudo='sudo '

alias -g L='| less'
alias -g G='| grep'

# --- 関数 ---

# SSH 先の tmux セッションに繋ぐ（無ければ作る）
ssht() {
  ssh -t $1 "tmux -u a || tmux -u new-session"
}
compdef _ssh_hosts ssht

# ============================================================
# 環境ごとの設定
# ============================================================

# --- Linux ---

if [[ "$OSTYPE" == linux* ]]; then
  # Ctrl+S / Ctrl+Q のフロー制御を切って、キーバインドとして使えるようにする
  stty start undef
  stty stop undef
  ttyctl -f
fi

# --- WSL2 ---

if [[ "$(uname -r)" == *microsoft* ]]; then
  # WSLg はレイアウトが JP に戻るため上書きする（x11-xkb-utils が必要）
  type setxkbmap > /dev/null 2>&1 && \
    setxkbmap -layout us

  export PATH=$PATH:/mnt/c/Users/$USER/AppData/Local/Programs/Microsoft\ VS\ Code/bin

  # Windows 側の既定のアプリでファイル・URL を開く
  function open() {
    /mnt/c/Windows/System32/cmd.exe /c start $(wslpath -w $1)
  }
  alias explorer='open'
  export BROWSER="$HOME/dotfiles/bin/wsl-chrome"

  # pwsh 7 を優先し、無ければ Windows PowerShell にフォールバックする
  if [ -x "/mnt/c/Program Files/PowerShell/7/pwsh.exe" ]; then
    alias powershell='/mnt/c/Program\ Files/PowerShell/7/pwsh.exe'
  else
    alias powershell='/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe'
  fi
fi

# ============================================================
# 共通設定と補完
# ============================================================

# --- 共通設定（bash と共有） ---

# PATH・配色・安全策のエイリアスは shell/common.sh にまとめてある
[ -r "$HOME/.config/shell/common.sh" ] && \
  source "$HOME/.config/shell/common.sh"

# --- 補完 ---

# list-colors は LS_COLORS を展開して覚えるため、それを設定する
# common.sh（dircolors）より後に置く必要がある
zstyle ':completion:*:default' list-colors ${LS_COLORS}
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([%0-9]#)*=0=01;31'

# 完全一致 → glob → 曖昧一致 の順に試す
zstyle ':completion:*' completer _complete _match _approximate

zstyle ':completion:*' use-cache true
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' ignore-parents parent pwd ..
zstyle ':completion:*:processes' command 'ps x -o pid,s,args'
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin

# ============================================================
# 外部設定・プラグインの読み込み
# ============================================================

# 環境ごとの設定（プロキシ、APIキーなど）の置き場所
if [ -d "$HOME/.config/profile.d" ]; then
  for file in "$HOME"/.config/profile.d/*.{sh,zsh}(N); do
    [ -r "$file" ] && source "$file"
  done
  unset file
fi

# 入力中のコマンドを履歴から先読みして提案する
if [ -d "$HOME/.zsh/zsh-autosuggestions" ]; then
  source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
fi

[ -n "${BUN_INSTALL:-}" ] && [ -s "$BUN_INSTALL/_bun" ] && \
  source "$BUN_INSTALL/_bun"

# ============================================================
# 実行環境の表示
# ============================================================

# Ranger や Vim の中から起動したシェルであることを右プロンプトに出す
[ -n "$RANGER_LEVEL" ] && RPROMPT='%F{165}%B (Ranger) %b%f'"$RPROMPT"
[ -n "$VIMRUNTIME" ] && RPROMPT='%F{034}%B (Vim) %b%f'"$RPROMPT"
