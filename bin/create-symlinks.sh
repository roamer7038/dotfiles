#!/bin/bash
#
# dotfiles から各種設定ファイルへシンボリックリンクを張る。
# 配置対象は links（パス・配置先・タグの3列）に定義されている。
# タグを指定して対象を選ぶ。使い方は --help を参照。

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DOTFILES_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
LINKS_FILE="$DOTFILES_ROOT/links"

# ============================================================
# 設定
# ============================================================

# --- 設定フラグ ---
SELECTED_TAGS=()
DRY_RUN=false
FORCE=false

# 既存でも置き換えてよい配置先。prepare_bashrc が設定する
REPLACEABLE=""

# --- ログ出力 ---

if [ -t 1 ]; then
  N=$'\033[0m' G=$'\033[0;32m' Y=$'\033[0;33m' B=$'\033[0;34m' R=$'\033[0;31m'
else N='' G='' Y='' B='' R=''; fi
log_info() { echo "$B[INFO]$N $*"; }
log_ok() { echo "$G[OK]$N $*"; }
log_skip() { echo "$Y[SKIP]$N $*"; }
log_warn() { echo "$Y[WARN]$N $*"; }
log_error() { echo "$R[ERROR]$N $*" >&2; }
log_verbose() { [ "${VERBOSE:-false}" = true ] && echo "$B[VERBOSE]$N $*" || :; }

# ============================================================
# 使い方と引数解析
# ============================================================

show_usage() {
  cat <<EOM
Usage: $(basename "$0") [OPTIONS] <tag>...

Dotfiles setup script - Create symbolic links defined in ./links

OPTIONS:
  -n, --dry-run   Show what would be done without creating links
  -f, --force     Overwrite existing files (default: skip existing files)
  -h, --help      Display this help message

TAGS:
  $(all_tags)

EXAMPLES:
  $(basename "$0") basic
  $(basename "$0") basic vim agent
  $(basename "$0") --dry-run basic vim agent x11 gui

NOTES:
  - Link targets are defined in ./links (path, destination, tag)
  - Presets are defined in the Makefile; run 'make help' for the list

EOM
  exit 0
}

parse_options() {
  if [ $# -eq 0 ]; then
    show_usage
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
    -n | --dry-run)
      DRY_RUN=true
      shift
      ;;
    -f | --force)
      FORCE=true
      shift
      ;;
    -h | --help)
      show_usage
      ;;
    -*)
      log_error "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
    *)
      known_tag "$1" || {
        log_error "Unknown tag: $1"
        echo "Available tags: $(all_tags)"
        exit 1
      }
      SELECTED_TAGS+=("$1")
      shift
      ;;
    esac
  done
}

# links に現れるタグの一覧
all_tags() {
  awk '$1 !~ /^#/ && NF == 3 { print $3 }' "$LINKS_FILE" | sort -u | tr '\n' ' '
}

known_tag() {
  case " $(all_tags)" in
  *" $1 "*) return 0 ;;
  *) return 1 ;;
  esac
}

# ============================================================
# リンクの作成
# ============================================================

# 配置先ディレクトリを用意する。DRY-RUN では作らない。
ensure_dir() {
  [ "$DRY_RUN" = true ] && return 0
  mkdir -p "$1"
}

# links を読み、選択されたタグに合う行を "<パス> <配置先>" で出力する
select_entries() {
  local src dest tag

  while read -r src dest tag; do
    case "$src" in '' | '#'*) continue ;; esac
    has_tag "$tag" || continue
    printf '%s %s\n' "$src" "$HOME/${dest#\~/}"
  done <"$LINKS_FILE"
}

# 選択されたタグに $1 が含まれるか
has_tag() {
  local t
  for t in "${SELECTED_TAGS[@]}"; do
    [ "$t" = "$1" ] && return 0
  done
  return 1
}

# links の1件を配置する。両側が / で終わる対はディレクトリ内を展開する
link_entry() {
  local src="$DOTFILES_ROOT/$1" dest="$2" file

  case "$1" in
  */)
    if [ ! -d "$src" ]; then
      log_error "Directory not found: $1"
      return 1
    fi
    ensure_dir "${dest%/}"
    for file in "$src"*; do
      [ -e "$file" ] || continue
      create_symlink "$file" "${dest%/}/$(basename "$file")"
    done
    ;;
  *)
    if [ ! -e "$src" ]; then
      log_error "File not found: $1"
      return 1
    fi
    ensure_dir "$(dirname "$dest")"
    create_symlink "$src" "$dest"
    ;;
  esac
}

create_symlink() {
  local src="$1" dest="$2"

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if [ "$FORCE" = true ] || [ "$dest" = "$REPLACEABLE" ]; then
      [ "$DRY_RUN" = true ] || rm -f "$dest"
    else
      log_skip "$dest (already exists, use --force to overwrite)"
      return 0
    fi
  fi

  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Would create: $dest -> $src"
    return 0
  fi

  if ln -s "$src" "$dest"; then
    log_ok "$dest"
  else
    log_error "Failed to create link: $dest"
    return 1
  fi
}

# Ubuntu は新規ユーザへ /etc/skel/.bashrc を必ずコピーするため、~/.bashrc は
# 常に存在し、既存ファイルとして飛ばされてしまう。既定のままのコピーは
# 利用者の設定ではないので置き換えの対象にする。
# 手が入っていれば利用者のファイルなので、他の配置対象と同じく飛ばす。
prepare_bashrc() {
  local dest="$1"

  # 配置済み（リンク）または未作成なら何もしない
  [ -f "$dest" ] && [ ! -L "$dest" ] || return 0

  cmp -s "$dest" /etc/skel/.bashrc || return 0

  REPLACEABLE="$dest"
  log_info "Distro default, will be replaced: $dest"
}

# ============================================================
# エントリポイント
# ============================================================

main() {
  if [ ! -r "$LINKS_FILE" ]; then
    log_error "Cannot read link definitions: $LINKS_FILE"
    exit 1
  fi

  parse_options "$@"

  log_info "dotfiles: $DOTFILES_ROOT"
  echo

  if [ ${#SELECTED_TAGS[@]} -eq 0 ]; then
    log_error "No tag specified"
    echo "Use --help for usage information"
    exit 1
  fi

  if [ "$DRY_RUN" = true ]; then
    log_info "DRY-RUN: nothing is created"
    echo
  fi

  local src dest
  while read -r src dest; do
    [ "$dest" = "$HOME/.bashrc" ] && prepare_bashrc "$dest"
    link_entry "$src" "$dest"
  done < <(select_entries)

  echo
  if [ "$DRY_RUN" = true ]; then
    log_info "DRY-RUN completed. Run without --dry-run to apply."
  else
    log_ok "All symbolic links created successfully!"
  fi
}

main "$@"
