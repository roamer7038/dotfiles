#!/bin/bash
#
# dotfiles から各種設定ファイルへシンボリックリンクを張る。
# プリセットまたは個別オプションで対象を選ぶ。使い方は --help を参照。

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DOTFILES_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

# ============================================================
# 設定
# ============================================================

# --- 設定フラグ ---
PRESET=""
ENABLE_BASIC=false
ENABLE_VIM=false
ENABLE_X11=false
ENABLE_GUI=false
ENABLE_I3WM=false
ENABLE_AGENT=false
DRY_RUN=false
FORCE=false
VERBOSE=false

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

source "$SCRIPT_DIR/lib/targets.sh"

# ============================================================
# 使い方と引数解析
# ============================================================

show_usage() {
  cat <<EOM
Usage: $(basename "$0") [OPTIONS]

Dotfiles setup script - Create symbolic links for configuration files

PRESET OPTIONS:
  --preset minimal     Basic dotfiles only (.bashrc, .zshrc, .tmux.conf, etc.)
  --preset standard    Minimal + Vim + AI agent configuration
  --preset desktop     Standard + X11 + GUI applications (excluding i3wm)
  --preset full        All configurations
  --preset agent       AI agent configs only (for already-setup environments)

INDIVIDUAL OPTIONS:
  --basic, --dotfiles  Basic dotfiles (.bashrc, .zshrc, .tmux.conf, .gitconfig,
                       .latexmkrc), the shared config/profile.d, and the
                       helper commands (pane, multissh, wsl-chrome) in
                       ~/.local/bin
  --vim                Vim configuration files
  --x11, --xorg        X Window System configuration
  --gui                GUI application configs (terminator, dunst, ranger)
  --i3wm, --i3         i3 window manager configuration (auto-enables --gui)
  --agent              AI agent configs (Claude Code: ~/.claude)
  --all                All configurations (same as --preset full)

OTHER OPTIONS:
  -n, --dry-run        Show what would be done without actually creating links
  -f, --force          Overwrite existing files (default: skip existing files)
  -v, --verbose        Show detailed output
  -h, --help           Display this help message

EXAMPLES:
  $(basename "$0") --preset minimal
  $(basename "$0") --preset desktop
  $(basename "$0") --basic --vim --x11
  $(basename "$0") --all --dry-run
  $(basename "$0") --gui --i3wm --force

NOTES:
  - i3wm configuration requires GUI configs, so --gui is auto-enabled with --i3wm
  - Existing files are skipped by default (use --force to overwrite)
  - Use --dry-run to preview changes before applying them

EOM
  exit 0
}

parse_options() {
  if [ $# -eq 0 ]; then
    show_usage
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --preset)
      if [ -z "$2" ] || [[ "$2" == --* ]]; then
        log_error "Option --preset requires an argument"
        exit 1
      fi
      PRESET="$2"
      shift 2
      ;;
    --basic | --dotfiles)
      ENABLE_BASIC=true
      shift
      ;;
    --vim)
      ENABLE_VIM=true
      shift
      ;;
    --x11 | --xorg)
      ENABLE_X11=true
      shift
      ;;
    --gui)
      ENABLE_GUI=true
      shift
      ;;
    --i3wm | --i3)
      ENABLE_I3WM=true
      shift
      ;;
    --agent)
      ENABLE_AGENT=true
      shift
      ;;
    --all)
      ENABLE_BASIC=true
      ENABLE_VIM=true
      ENABLE_X11=true
      ENABLE_GUI=true
      ENABLE_I3WM=true
      ENABLE_AGENT=true
      shift
      ;;
    -n | --dry-run)
      DRY_RUN=true
      shift
      ;;
    -f | --force)
      FORCE=true
      shift
      ;;
    -v | --verbose)
      VERBOSE=true
      shift
      ;;
    -h | --help)
      show_usage
      ;;
    *)
      log_error "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
    esac
  done
}

# ============================================================
# プリセットの解決
# ============================================================

apply_preset() {
  if [ -z "$PRESET" ]; then
    return
  fi

  log_info "Applying preset: $PRESET"

  case "$PRESET" in
  minimal)
    ENABLE_BASIC=true
    ;;
  standard)
    ENABLE_BASIC=true
    ENABLE_VIM=true
    ENABLE_AGENT=true
    ;;
  desktop)
    ENABLE_BASIC=true
    ENABLE_VIM=true
    ENABLE_X11=true
    ENABLE_GUI=true
    ENABLE_AGENT=true
    ;;
  full)
    ENABLE_BASIC=true
    ENABLE_VIM=true
    ENABLE_X11=true
    ENABLE_GUI=true
    ENABLE_I3WM=true
    ENABLE_AGENT=true
    ;;
  agent)
    ENABLE_AGENT=true
    ;;
  *)
    log_error "Unknown preset: $PRESET"
    echo "Available presets: minimal, standard, desktop, full, agent"
    exit 1
    ;;
  esac
}

resolve_dependencies() {
  # i3wmを有効にする場合、自動的にGUI設定も有効にする
  if [ "$ENABLE_I3WM" = true ]; then
    log_verbose "Enabling --gui (required by --i3wm)"
    ENABLE_GUI=true
  fi
}

# ============================================================
# リンクの作成
# ============================================================

# 配置先ディレクトリを用意する。DRY-RUN では作らない。
ensure_dir() {
  [ "$DRY_RUN" = true ] && return 0
  mkdir -p "$1"
}

# config/<dir>/ 配下を ~/.config/<dir>/ へ配置する
link_config_dir() {
  local dir="$1"
  local src_dir="$DOTFILES_ROOT/config/$dir"
  local dest_dir="$HOME/.config/$dir"
  local file filename

  if [ ! -d "$src_dir" ]; then
    log_verbose "Source directory not found: $src_dir"
    return
  fi

  ensure_dir "$dest_dir"

  for file in "$src_dir"/*; do
    [ -e "$file" ] || continue
    filename=$(basename "$file")
    create_symlink "$file" "$dest_dir/$filename" "$dir/$filename"
  done
}

create_symlink() {
  local src="$1"
  local dest="$2"
  local description="$3"

  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Would create: $dest -> $src"
    return 0
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if [ "$FORCE" = true ]; then
      log_verbose "Removing existing: $dest"
      rm -f "$dest"
    else
      log_skip "$dest (already exists, use --force to overwrite)"
      return 0
    fi
  fi

  if ln -s "$src" "$dest" 2>/dev/null; then
    log_ok "$description: $dest"
  else
    log_error "Failed to create link: $dest"
    return 1
  fi
}

create_basic_links() {
  log_info "Creating basic dotfiles..."

  local file
  for file in "${DOTFILES_BASIC[@]}"; do
    local src="$DOTFILES_ROOT/$file"
    local dest="$HOME/$file"

    if [ -f "$src" ]; then
      create_symlink "$src" "$dest" "$file"
    else
      log_verbose "Source file not found: $src"
    fi
  done

  # bash と zsh の共通設定は profile.d のドロップインとして置く
  local dir
  for dir in "${DOTFILES_SHELL_DIRS[@]}"; do
    link_config_dir "$dir"
  done
}

# コマンドとして直接呼ぶスクリプトを PATH の通った場所へ置く。
# フックや設定ファイルから絶対パスで呼ばれるものは対象にしない。
create_command_links() {
  log_info "Creating command links..."

  local dest_dir="$HOME/.local/bin"

  ensure_dir "$dest_dir"

  local cmd src
  for cmd in "${DOTFILES_COMMANDS[@]}"; do
    src="$DOTFILES_ROOT/bin/$cmd"

    if [ -f "$src" ]; then
      create_symlink "$src" "$dest_dir/$cmd" "bin/$cmd"
    else
      log_verbose "Source file not found: $src"
    fi
  done
}

create_vim_links() {
  log_info "Creating Vim configuration..."

  local vimrc_src="$DOTFILES_ROOT/.vimrc"
  local vimrc_dest="$HOME/.vimrc"

  if [ -f "$vimrc_src" ]; then
    create_symlink "$vimrc_src" "$vimrc_dest" ".vimrc"
  fi
}

create_x11_links() {
  log_info "Creating X Window System configuration..."

  local file
  for file in "${DOTFILES_X11[@]}"; do
    local src="$DOTFILES_ROOT/$file"
    local dest="$HOME/$file"

    if [ -f "$src" ]; then
      create_symlink "$src" "$dest" "$file"
    else
      log_verbose "Source file not found: $src"
    fi
  done
}

create_gui_links() {
  log_info "Creating GUI application configurations..."

  local app_dirs=("${DOTFILES_GUI_DIRS[@]}")

  if [ "$ENABLE_I3WM" = true ]; then
    app_dirs+=("${DOTFILES_I3WM_DIRS[@]}")
  fi

  local dir
  for dir in "${app_dirs[@]}"; do
    link_config_dir "$dir"
  done
}

create_agent_links() {
  log_info "Creating AI agent configurations..."

  # 将来的に他エージェントの設定を追加する場合はここに追記する
  create_claude_agent_links
}

create_claude_agent_links() {
  local src_dir="$DOTFILES_ROOT/.claude"
  local dest_dir="$HOME/.claude"

  if [ ! -d "$src_dir" ]; then
    log_verbose "Source directory not found: $src_dir"
    return
  fi

  local files=("${DOTFILES_AGENT[@]}")

  ensure_dir "$dest_dir"

  for file in "${files[@]}"; do
    local src="$src_dir/$file"
    local dest="$dest_dir/$file"

    if [ -e "$src" ]; then
      create_symlink "$src" "$dest" ".claude/$file"
    else
      log_verbose "Source file not found: $src"
    fi
  done
}

# ============================================================
# エントリポイント
# ============================================================

main() {
  log_info "Dotfiles symlink creation script"
  log_info "Repository: $DOTFILES_ROOT"
  echo

  parse_options "$@"

  apply_preset

  resolve_dependencies

  if [ "$ENABLE_BASIC" != true ] &&
    [ "$ENABLE_VIM" != true ] &&
    [ "$ENABLE_X11" != true ] &&
    [ "$ENABLE_GUI" != true ] &&
    [ "$ENABLE_AGENT" != true ]; then
    log_error "No configuration options specified"
    echo "Use --help for usage information"
    exit 1
  fi

  if [ "$DRY_RUN" = true ]; then
    log_info "DRY-RUN mode: No actual changes will be made"
    echo
  fi

  [ "$ENABLE_BASIC" = true ] && create_basic_links
  [ "$ENABLE_BASIC" = true ] && create_command_links
  [ "$ENABLE_VIM" = true ] && create_vim_links
  [ "$ENABLE_X11" = true ] && create_x11_links
  [ "$ENABLE_GUI" = true ] && create_gui_links
  [ "$ENABLE_AGENT" = true ] && create_agent_links

  echo
  if [ "$DRY_RUN" = true ]; then
    log_info "DRY-RUN completed. Run without --dry-run to apply changes."
  else
    log_ok "All symbolic links created successfully!"
  fi
}

main "$@"
