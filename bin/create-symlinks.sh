#!/bin/bash
#
# dotfiles から各種設定ファイルへシンボリックリンクを張る。
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
  - Placement targets are defined in ./links (path, destination, tag)
  - Presets are defined in the Makefile; run 'make help' for the list
  - Existing files are skipped by default (use --force to overwrite)

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
      log_error "ディレクトリが無い: $1"
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
      log_error "ファイルが無い: $1"
      return 1
    fi
    ensure_dir "$(dirname "$dest")"
    create_symlink "$src" "$dest"
    ;;
  esac
}

create_symlink() {
  local src="$1" dest="$2"

  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Would create: $dest -> $src"
    return 0
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if [ "$FORCE" = true ]; then
      rm -f "$dest"
    else
      log_skip "$dest (already exists, use --force to overwrite)"
      return 0
    fi
  fi

  if ln -s "$src" "$dest"; then
    log_ok "$dest"
  else
    log_error "Failed to create link: $dest"
    return 1
  fi
}

# ============================================================
# エントリポイント
# ============================================================

main() {
  log_info "Dotfiles symlink creation script"
  log_info "Repository: $DOTFILES_ROOT"
  echo

  if [ ! -r "$LINKS_FILE" ]; then
    log_error "Cannot read link definitions: $LINKS_FILE"
    exit 1
  fi

  parse_options "$@"

  if [ ${#SELECTED_TAGS[@]} -eq 0 ]; then
    log_error "No configuration options specified"
    echo "Use --help for usage information"
    exit 1
  fi

  if [ "$DRY_RUN" = true ]; then
    log_info "DRY-RUN mode: No actual changes will be made"
    echo
  fi

  local src dest
  while read -r src dest; do
    link_entry "$src" "$dest"
  done < <(select_entries)

  echo
  if [ "$DRY_RUN" = true ]; then
    log_info "DRY-RUN completed. Run without --dry-run to apply changes."
  else
    log_ok "All symbolic links created successfully!"
  fi
}

main "$@"
