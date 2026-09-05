#!/bin/bash
#
# リポジトリ全体の静的チェック。何も変更しない。
# 構文、書式（.editorconfig 準拠）、Makefile の全ターゲット、
# create-symlinks.sh のドライラン、ドキュメントの相対リンク、
# README の bin/ 一覧と実体の一致を確認する。
#
#   check.sh
#
# 問題が無ければ 0、あれば 1 を返す。
# shfmt が入っていれば整形差分も見る（無ければその項目だけ飛ばす）。

set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DOTFILES_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

# ============================================================
# 準備と共通処理
# ============================================================

source "$SCRIPT_DIR/lib/log.sh"

cd "$DOTFILES_ROOT"

FAIL=0

fail() {
  log_error "$*"
  FAIL=$((FAIL + 1))
}

# シェルスクリプトを shebang で判別して列挙する
shell_files() {
  local f
  for f in $(git ls-files); do
    case "$f" in
    *.sh) echo "$f" ;;
    *)
      [ -f "$f" ] || continue
      head -c 2 "$f" 2>/dev/null | grep -q '#!' || continue
      head -1 "$f" | grep -qE 'sh$|sh ' && echo "$f"
      ;;
    esac
  done
}

# ============================================================
# 検査項目
# ============================================================

# --- 構文 ---

check_syntax() {
  local f interp n=0

  for f in $(shell_files); do
    interp=$(head -1 "$f" | grep -oE '\b(bash|sh|zsh)$') || interp=bash
    case "$interp" in
    zsh) zsh -n "$f" 2>&1 || fail "zsh 構文エラー: $f" ;;
    sh) sh -n "$f" 2>&1 || fail "sh 構文エラー: $f" ;;
    *) bash -n "$f" 2>&1 || fail "bash 構文エラー: $f" ;;
    esac
    n=$((n + 1))
  done

  # rc ファイルは shebang を持たないので個別に見る
  zsh -n .zshrc || fail "zsh 構文エラー: .zshrc"
  bash -n .bashrc || fail "bash 構文エラー: .bashrc"
  sh -n config/profile.d/00-common.sh ||
    fail "sh 構文エラー: config/profile.d/00-common.sh"
  n=$((n + 3))

  log_ok "シェル構文: $n ファイル"
}

check_vim() {
  # .vimrc は vim-plug が無ければ取得しに行くため、未導入の環境では
  # 読み込んだ時点で変更が発生してしまう。その場合は飛ばす。
  if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
    log_skip "Vim 設定: vim-plug 未導入のため未確認（読み込むと導入が走る）"
    return
  fi

  if vim -Nu .vimrc -c 'qa!' >/dev/null 2>&1; then
    log_ok "Vim 設定: 読み込み可能"
  else
    fail ".vimrc の読み込みに失敗"
  fi
}

check_tmux() {
  local sock=check-$$

  if tmux -L "$sock" -f .tmux.conf new-session -d 2>&1 | grep -q .; then
    fail ".tmux.conf の読み込みでエラー"
  else
    log_ok "tmux 設定: 読み込み可能"
  fi
  tmux -L "$sock" kill-server 2>/dev/null
}

# --- 書式（.editorconfig 準拠）---

# Makefile と .gitconfig は形式上タブが要る。Markdown は
# 行末の空白2つが改行を意味するため、いずれも対象から外す。
check_format() {
  local f found

  found=$(git ls-files | grep -vE '^(Makefile|\.gitconfig|.*\.md)$' |
    xargs grep -lP '^\t' 2>/dev/null) || true
  [ -n "$found" ] && fail "インデントにタブを使っている:"$'\n'"$found"

  found=$(git ls-files | grep -vE '\.md$' | xargs grep -lP '[ \t]+$' 2>/dev/null) || true
  [ -n "$found" ] && fail "行末に空白がある:"$'\n'"$found"

  found=$(git ls-files | xargs grep -lP '\r$' 2>/dev/null) || true
  [ -n "$found" ] && fail "CRLF 改行が混ざっている:"$'\n'"$found"

  found=""
  for f in $(git ls-files); do
    [ -f "$f" ] || continue
    [ -s "$f" ] || continue
    [ -n "$(tail -c1 "$f")" ] && found="$found$f"$'\n'
  done
  [ -n "$found" ] && fail "末尾に改行が無い:"$'\n'"$found"

  log_ok "書式: .editorconfig に準拠"
}

check_shfmt() {
  local diff

  if ! command -v shfmt >/dev/null 2>&1; then
    log_skip "shfmt が無いため整形差分は未確認（make fmt の説明を参照）"
    return
  fi

  diff=$(shfmt -d -i 2 bin config/profile.d 2>&1) || true
  if [ -n "$diff" ]; then
    fail "shfmt の整形結果と差がある（make fmt で修正）"
    echo "$diff" | head -40
  else
    log_ok "shfmt: 整形済み"
  fi
}

# --- 動作 ---

check_make() {
  local t n=0

  # 一覧を持たず .PHONY から取るので、ターゲットを増やしても追従する
  for t in $(make --no-print-directory -p 2>/dev/null |
    sed -n 's/^\.PHONY: //p' | tr ' ' '\n' | sort -u); do
    make -n "$t" >/dev/null 2>&1 || fail "make $t が解決できない"
    n=$((n + 1))
  done

  for t in minimal standard desktop full agent; do
    make -n "dry-run-$t" >/dev/null 2>&1 || fail "make dry-run-$t が解決できない"
    n=$((n + 1))
  done

  log_ok "Makefile: $n ターゲットが解決できる"
}

check_dry_run() {
  local p

  for p in minimal standard desktop full agent; do
    ./bin/create-symlinks.sh --preset "$p" --dry-run >/dev/null 2>&1 ||
      fail "create-symlinks.sh --preset $p --dry-run が失敗"
  done

  ./bin/create-symlinks.sh --help >/dev/null 2>&1 || fail "create-symlinks.sh --help が失敗"

  log_ok "create-symlinks.sh: 全プリセットのドライランが成功"
}

check_docs() {
  local line src target missing=""

  # 相対リンクだけを見る（http... とページ内アンカーは対象外）
  while IFS= read -r line; do
    src=${line%%:*}
    target=${line#*:}

    case "$target" in
    http*) continue ;;
    esac

    [ -e "$(dirname "$src")/$target" ] || missing="$missing  $src -> $target"$'\n'
  done < <(grep -oPH '\]\(\K[^)#]+' README.md docs/*.md 2>/dev/null)

  if [ -n "$missing" ]; then
    fail "参照先の無いドキュメントリンク:"$'\n'"$missing"
  else
    log_ok "ドキュメント: 相対リンクは有効"
  fi
}

# bin/ にスクリプトを足して README に書き忘れる、を防ぐ
check_bin_table() {
  local f name missing=""

  for f in $(git ls-files bin/ | grep -v '^bin/lib/'); do
    name=$(basename "$f")
    grep -q "^| \`$name\`" README.md || missing="$missing  $name"$'\n'
  done

  if [ -n "$missing" ]; then
    fail "README の bin/ 一覧に無いスクリプト:"$'\n'"$missing"
  else
    log_ok "README: bin/ の一覧は実体と一致"
  fi
}

# ============================================================
# エントリポイント
# ============================================================

log_info "dotfiles: $DOTFILES_ROOT"
echo

check_syntax
check_vim
check_tmux
check_format
check_shfmt
check_make
check_dry_run
check_docs
check_bin_table
echo

if [ "$FAIL" -gt 0 ]; then
  log_error "$FAIL 件の問題"
  exit 1
fi

log_ok "すべて通過"
