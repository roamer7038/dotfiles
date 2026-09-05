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
# エイリアス
# ============================================================

# 共通のエイリアスは 00-common.sh 側にある。ここは zsh 固有の記法のみ。

# グローバルエイリアス（コマンドの途中でも展開される）
alias -g L='| less'
alias -g G='| grep'

# ============================================================
# OS ごとの設定
# ============================================================
#
# シェルを問わない設定（WSL2 の open や BROWSER など）は 00-common.sh 側にある。
# ここには zsh 固有の記法が要るものだけを置く。

# --- Linux ---

if [[ "$OSTYPE" == linux* ]]; then
  # Ctrl+S / Ctrl+Q のフロー制御を切って、キーバインドとして使えるようにする
  stty start undef
  stty stop undef
  ttyctl -f
fi

# ============================================================
# 設定の読み込みと補完
# ============================================================

# --- profile.d（bash と共有） ---

# PATH・環境変数・配色・安全策のエイリアスは ~/.config/profile.d/ から読む。
# dotfiles が置く 00-common.sh が先、利用者が置いたファイルが後になる。
# 後段の list-colors が LS_COLORS を必要とするため、補完設定より前に置く
if [ -d "$HOME/.config/profile.d" ]; then
  for file in "$HOME"/.config/profile.d/*.(sh|zsh)(N); do
    [ -r "$file" ] && source "$file"
  done
  unset file
fi

# --- 補完 ---

# list-colors は LS_COLORS を展開して覚えるため、それを設定する
# 00-common.sh（dircolors）より後に置く必要がある
zstyle ':completion:*:default' list-colors ${LS_COLORS}
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([%0-9]#)*=0=01;31'

# 完全一致 → glob → 曖昧一致 の順に試す
zstyle ':completion:*' completer _complete _match _approximate

zstyle ':completion:*' use-cache true
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' ignore-parents parent pwd ..
zstyle ':completion:*:processes' command 'ps x -o pid,s,args'
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin

# 00-common.sh の ssht にホスト名の補完を効かせる
compdef _ssh_hosts ssht

# ============================================================
# プラグインの読み込み
# ============================================================

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
