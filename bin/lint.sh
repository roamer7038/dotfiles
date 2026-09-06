#!/bin/bash
#
# リポジトリの静的検査。何も変更しない（環境を見るのは doctor.sh）。
# 構文、書式（.editorconfig 準拠）、Makefile の全ターゲット、
# create-symlinks.sh のドライラン、ドキュメントの相対リンク、
# README の bin/ 一覧と実体の一致、links の書式を確認する。
#
#   lint.sh
#
# 問題が無ければ 0、あれば 1 を返す。
# shfmt が入っていれば整形差分も見る（無ければその項目だけ飛ばす）。

set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DOTFILES_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

# ============================================================
# 準備と共通処理
# ============================================================

if [ -t 1 ]; then
  N=$'\033[0m' G=$'\033[0;32m' Y=$'\033[0;33m' B=$'\033[0;34m' R=$'\033[0;31m'
else N='' G='' Y='' B='' R=''; fi
log_info() { echo "$B[INFO]$N $*"; }
log_ok() { echo "$G[OK]$N $*"; }
log_skip() { echo "$Y[SKIP]$N $*"; }
log_warn() { echo "$Y[WARN]$N $*"; }
log_error() { echo "$R[ERROR]$N $*" >&2; }
log_verbose() { [ "${VERBOSE:-false}" = true ] && echo "$B[VERBOSE]$N $*" || :; }

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
    zsh) zsh -n "$f" 2>&1 || fail "zsh syntax error: $f" ;;
    sh) sh -n "$f" 2>&1 || fail "sh syntax error: $f" ;;
    *) bash -n "$f" 2>&1 || fail "bash syntax error: $f" ;;
    esac
    n=$((n + 1))
  done

  # rc ファイルは shebang を持たないので個別に見る
  zsh -n .zshrc || fail "zsh syntax error: .zshrc"
  bash -n .bashrc || fail "bash syntax error: .bashrc"
  sh -n config/profile.d/00-common.sh ||
    fail "sh syntax error: config/profile.d/00-common.sh"
  n=$((n + 3))

  log_ok "Shell syntax: $n file(s)"
}

check_vim() {
  # .vimrc は vim-plug が無ければ取得しに行くため、未導入の環境では
  # 読み込んだ時点で変更が発生してしまう。その場合は飛ばす。
  if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
    log_skip "Vim config: skipped, vim-plug not installed (loading it would install plugins)"
    return
  fi

  if vim -Nu .vimrc -c 'qa!' >/dev/null 2>&1; then
    log_ok "Vim config: loads"
  else
    fail ".vimrc failed to load"
  fi
}

check_tmux() {
  local sock=check-$$

  if tmux -L "$sock" -f .tmux.conf new-session -d 2>&1 | grep -q .; then
    fail ".tmux.conf failed to load"
  else
    log_ok "tmux config: loads"
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
  [ -n "$found" ] && fail "Tab indentation:"$'\n'"$found"

  found=$(git ls-files | grep -vE '\.md$' | xargs grep -lP '[ \t]+$' 2>/dev/null) || true
  [ -n "$found" ] && fail "Trailing whitespace:"$'\n'"$found"

  found=$(git ls-files | xargs grep -lP '\r$' 2>/dev/null) || true
  [ -n "$found" ] && fail "CRLF line endings:"$'\n'"$found"

  found=""
  for f in $(git ls-files); do
    [ -f "$f" ] || continue
    [ -s "$f" ] || continue
    [ -n "$(tail -c1 "$f")" ] && found="$found$f"$'\n'
  done
  [ -n "$found" ] && fail "Missing final newline:"$'\n'"$found"

  log_ok "Format: conforms to .editorconfig"
}

check_shfmt() {
  local diff

  if ! command -v shfmt >/dev/null 2>&1; then
    log_skip "shfmt not found: formatting not checked"
    return
  fi

  diff=$(shfmt -d -i 2 bin config/profile.d 2>&1) || true
  if [ -n "$diff" ]; then
    fail "Differs from shfmt output (run 'make fmt')"
    echo "$diff" | head -40
  else
    log_ok "shfmt: formatted"
  fi
}

# --- 動作 ---

check_make() {
  local t n=0

  # 一覧を持たず .PHONY から取るので、ターゲットを増やしても追従する
  for t in $(make --no-print-directory -p 2>/dev/null |
    sed -n 's/^\.PHONY: //p' | tr ' ' '\n' | sort -u); do
    make -n "$t" >/dev/null 2>&1 || fail "make $t does not resolve"
    n=$((n + 1))
  done

  # プリセットの一覧も Makefile の PRESETS から取る（プリセット定義は Makefile だけにある）
  for t in $(sed -n 's/^PRESETS[[:space:]]*:=[[:space:]]*//p' Makefile); do
    make -n "dry-run-$t" >/dev/null 2>&1 || fail "make dry-run-$t does not resolve"
    n=$((n + 1))
  done

  log_ok "Makefile: $n target(s) resolve"
}

check_dry_run() {
  local p

  # プリセットの一覧は Makefile の PRESETS から取る（プリセット定義は Makefile だけにある）
  for p in $(sed -n 's/^PRESETS[[:space:]]*:=[[:space:]]*//p' Makefile); do
    make "dry-run-$p" >/dev/null 2>&1 || fail "make dry-run-$p failed"
  done

  ./bin/create-symlinks.sh --help >/dev/null 2>&1 || fail "create-symlinks.sh --help failed"

  log_ok "create-symlinks.sh: dry run passed for every preset"
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
    fail "Broken relative links in docs:"$'\n'"$missing"
  else
    log_ok "Docs: relative links resolve"
  fi
}

# bin/ にスクリプトを足して README に書き忘れる、を防ぐ
check_bin_table() {
  local f name missing=""

  for f in $(git ls-files bin/); do
    name=$(basename "$f")
    grep -q "^| \`$name\`" README.md || missing="$missing  $name"$'\n'
  done

  if [ -n "$missing" ]; then
    fail "Scripts missing from the bin/ table in README:"$'\n'"$missing"
  else
    log_ok "README: bin/ table matches the repository"
  fi
}

# --- links の書式 ---

check_links_file() {
  local src dest tag extra line=0 n=0 s_dir d_dir fail_before=$FAIL

  while read -r src dest tag extra; do
    line=$((line + 1))
    case "$src" in '' | '#'*) continue ;; esac

    if [ -z "$tag" ] || [ -n "$extra" ]; then
      fail "links:$line expected 3 columns: $src"
      continue
    fi

    s_dir=no
    d_dir=no
    case "$src" in */) s_dir=yes ;; esac
    case "$dest" in */) d_dir=yes ;; esac
    [ "$s_dir" = "$d_dir" ] || fail "links:$line trailing / on one side only: $src $dest"

    case "$dest" in
    '~/'*) ;;
    *) fail "links:$line destination does not start with ~/: $dest" ;;
    esac

    [ -e "$src" ] || fail "links:$line source not found: $src"
    n=$((n + 1))
  done <links

  if [ "$FAIL" -eq "$fail_before" ]; then
    log_ok "links: $n entries"
  fi
}

# links のタグと Makefile のプリセット定義が食い違っていないかを見る。
# links 自身からタグ集合を作ると自分自身との照合になり何も検出できないため、
# 独立した情報源である Makefile の TAGS_* と突き合わせる
check_tags() {
  local in_links in_make t fail_before=$FAIL

  in_links=$(awk '$1 !~ /^#/ && NF == 3 { print $3 }' links | sort -u)
  in_make=$(sed -n 's/^TAGS_[a-z]*[[:space:]]*:=[[:space:]]*//p' Makefile |
    tr ' ' '\n' | grep -v '^$' | sort -u)

  for t in $in_links; do
    echo "$in_make" | grep -qx "$t" ||
      fail "Tag $t in links is not used by any preset in Makefile"
  done

  for t in $in_make; do
    echo "$in_links" | grep -qx "$t" ||
      fail "Tag $t used by a preset in Makefile is not in links"
  done

  if [ "$FAIL" -eq "$fail_before" ]; then
    log_ok "Tags: links and the presets in Makefile agree"
  fi
}

# ============================================================
# エントリポイント
# ============================================================

log_info "dotfiles: $DOTFILES_ROOT"
echo

check_links_file
check_tags
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
  log_error "$FAIL problem(s)"
  exit 1
fi

log_ok "All checks passed"
