#!/bin/bash
# ============================================================
# create-symlinks.sh
# ============================================================
#
# 概要:
#   dotfilesリポジトリから各種設定ファイルへのシンボリックリンクを作成する
#
# 用途:
#   新しい環境のセットアップ時に、dotfilesを一括で配置
#   プリセットまたは個別オプションで必要な設定のみをリンク可能
#
# 依存関係:
#   - bash
#
# 使用例:
#   # プリセットを使用
#   $ ./create-symlinks.sh --preset minimal    # 基本のみ
#   $ ./create-symlinks.sh --preset standard   # 基本 + vim
#   $ ./create-symlinks.sh --preset desktop    # GUI環境向け
#   $ ./create-symlinks.sh --preset full       # すべて
#
#   # 個別に指定
#   $ ./create-symlinks.sh --basic --vim --x11
#   $ ./create-symlinks.sh --gui --i3wm
#   $ ./create-symlinks.sh --all               # すべて
#
#   # オプション付き
#   $ ./create-symlinks.sh --preset full --dry-run  # 実行内容を確認
#   $ ./create-symlinks.sh --basic --force          # 既存ファイルを上書き
#
# ============================================================

set -e

# dotfilesリポジトリのルートディレクトリを取得
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DOTFILES_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

# 設定フラグ
PRESET=""
ENABLE_BASIC=false
ENABLE_VIM=false
ENABLE_X11=false
ENABLE_GUI=false
ENABLE_I3WM=false
DRY_RUN=false
FORCE=false
VERBOSE=false

# 色定義
if [[ -t 1 ]]; then
	COLOR_RESET='\033[0m'
	COLOR_GREEN='\033[0;32m'
	COLOR_YELLOW='\033[0;33m'
	COLOR_BLUE='\033[0;34m'
	COLOR_RED='\033[0;31m'
else
	COLOR_RESET=''
	COLOR_GREEN=''
	COLOR_YELLOW=''
	COLOR_BLUE=''
	COLOR_RED=''
fi

# ログ出力関数
log_info() {
	echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*"
}

log_success() {
	echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $*"
}

log_skip() {
	echo -e "${COLOR_YELLOW}[SKIP]${COLOR_RESET} $*"
}

log_error() {
	echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
}

log_verbose() {
	if [ "$VERBOSE" = true ]; then
		echo -e "${COLOR_BLUE}[VERBOSE]${COLOR_RESET} $*"
	fi
}

# ヘルプメッセージの表示
function show_usage {
	cat <<EOM
Usage: $(basename "$0") [OPTIONS]

Dotfiles setup script - Create symbolic links for configuration files

PRESET OPTIONS:
  --preset minimal     Basic dotfiles only (.bashrc, .zshrc, .tmux.conf, etc.)
  --preset standard    Minimal + Vim configuration
  --preset desktop     Standard + X11 + GUI applications (excluding i3wm)
  --preset full        All configurations

INDIVIDUAL OPTIONS:
  --basic, --dotfiles  Basic dotfiles (.bashrc, .zshrc, .tmux.conf, .gitconfig, .latexmkrc)
  --vim                Vim configuration files
  --x11, --xorg        X Window System configuration
  --gui                GUI application configs (terminator, dunst, ranger)
  --i3wm, --i3         i3 window manager configuration (auto-enables --gui)
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
  - Existing .bashrc will be skipped by default (use --force to overwrite)
  - Use --dry-run to preview changes before applying them

EOM
	exit 0
}

# オプション解析
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
		--all)
			ENABLE_BASIC=true
			ENABLE_VIM=true
			ENABLE_X11=true
			ENABLE_GUI=true
			ENABLE_I3WM=true
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

# プリセット適用
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
		;;
	desktop)
		ENABLE_BASIC=true
		ENABLE_VIM=true
		ENABLE_X11=true
		ENABLE_GUI=true
		;;
	full)
		ENABLE_BASIC=true
		ENABLE_VIM=true
		ENABLE_X11=true
		ENABLE_GUI=true
		ENABLE_I3WM=true
		;;
	*)
		log_error "Unknown preset: $PRESET"
		echo "Available presets: minimal, standard, desktop, full"
		exit 1
		;;
	esac
}

# 依存関係の解決
resolve_dependencies() {
	# i3wmを有効にする場合、自動的にGUI設定も有効にする
	if [ "$ENABLE_I3WM" = true ]; then
		log_verbose "Enabling --gui (required by --i3wm)"
		ENABLE_GUI=true
	fi
}

# シンボリックリンク作成関数
create_symlink() {
	local src="$1"
	local dest="$2"
	local description="$3"

	if [ "$DRY_RUN" = true ]; then
		log_info "[DRY-RUN] Would create: $dest -> $src"
		return 0
	fi

	# 既存ファイルのチェック
	if [ -e "$dest" ] || [ -L "$dest" ]; then
		if [ "$FORCE" = true ]; then
			log_verbose "Removing existing: $dest"
			rm -f "$dest"
		else
			log_skip "$dest (already exists, use --force to overwrite)"
			return 0
		fi
	fi

	# シンボリックリンク作成
	if ln -s "$src" "$dest" 2>/dev/null; then
		log_success "$description: $dest"
	else
		log_error "Failed to create link: $dest"
		return 1
	fi
}

# 基本dotfilesのリンク作成
create_basic_links() {
	log_info "Creating basic dotfiles..."

	local dotfiles=(.bashrc .zshrc .tmux.conf .gitconfig .latexmkrc)

	for file in "${dotfiles[@]}"; do
		local src="$DOTFILES_ROOT/$file"
		local dest="$HOME/$file"

		# .bashrcは特別扱い（システムデフォルトを保持）
		if [ "$file" = ".bashrc" ] && [ -e "$HOME/.bashrc" ] && [ "$FORCE" != true ]; then
			log_skip ".bashrc (preserving system default, use --force to overwrite)"
			continue
		fi

		if [ -f "$src" ]; then
			create_symlink "$src" "$dest" "$file"
		else
			log_verbose "Source file not found: $src"
		fi
	done
}

# Vim設定のリンク作成
create_vim_links() {
	log_info "Creating Vim configuration..."

	# .vimrcのリンク
	local vimrc_src="$DOTFILES_ROOT/.vimrc"
	local vimrc_dest="$HOME/.vimrc"

	if [ -f "$vimrc_src" ]; then
		create_symlink "$vimrc_src" "$vimrc_dest" ".vimrc"
	fi

	# .vimディレクトリ
	local vim_dir="$DOTFILES_ROOT/.vim"
	if [ -d "$vim_dir" ]; then
		if [ "$DRY_RUN" != true ]; then
			mkdir -p "$HOME/.vim"
		fi

		for file in "$vim_dir"/*; do
			if [ -e "$file" ]; then
				local filename=$(basename "$file")
				create_symlink "$file" "$HOME/.vim/$filename" ".vim/$filename"
			fi
		done
	fi
}

# X11設定のリンク作成
create_x11_links() {
	log_info "Creating X Window System configuration..."

	local x11_files=(.Xmodmap .xprofile .picom.conf)

	for file in "${x11_files[@]}"; do
		local src="$DOTFILES_ROOT/$file"
		local dest="$HOME/$file"

		if [ -f "$src" ]; then
			create_symlink "$src" "$dest" "$file"
		else
			log_verbose "Source file not found: $src"
		fi
	done
}

# GUI設定のリンク作成
create_gui_links() {
	log_info "Creating GUI application configurations..."

	local app_dirs=(terminator dunst ranger)

	# i3wmが有効な場合は追加
	if [ "$ENABLE_I3WM" = true ]; then
		app_dirs+=(i3 i3status)
	fi

	for dir in "${app_dirs[@]}"; do
		local src_dir="$DOTFILES_ROOT/config/$dir"
		local dest_dir="$HOME/.config/$dir"

		if [ ! -d "$src_dir" ]; then
			log_verbose "Source directory not found: $src_dir"
			continue
		fi

		if [ "$DRY_RUN" != true ]; then
			mkdir -p "$dest_dir"
		fi

		for file in "$src_dir"/*; do
			if [ -e "$file" ]; then
				local filename=$(basename "$file")
				create_symlink "$file" "$dest_dir/$filename" "$dir/$filename"
			fi
		done
	done
}

# メイン処理
main() {
	log_info "Dotfiles symlink creation script"
	log_info "Repository: $DOTFILES_ROOT"
	echo

	# オプション解析
	parse_options "$@"

	# プリセット適用
	apply_preset

	# 依存関係解決
	resolve_dependencies

	# 何も有効になっていない場合
	if [ "$ENABLE_BASIC" != true ] &&
		[ "$ENABLE_VIM" != true ] &&
		[ "$ENABLE_X11" != true ] &&
		[ "$ENABLE_GUI" != true ]; then
		log_error "No configuration options specified"
		echo "Use --help for usage information"
		exit 1
	fi

	# ドライランモードの通知
	if [ "$DRY_RUN" = true ]; then
		log_info "DRY-RUN mode: No actual changes will be made"
		echo
	fi

	# 各設定のリンク作成
	[ "$ENABLE_BASIC" = true ] && create_basic_links
	[ "$ENABLE_VIM" = true ] && create_vim_links
	[ "$ENABLE_X11" = true ] && create_x11_links
	[ "$ENABLE_GUI" = true ] && create_gui_links

	echo
	if [ "$DRY_RUN" = true ]; then
		log_info "DRY-RUN completed. Run without --dry-run to apply changes."
	else
		log_success "All symbolic links created successfully!"
	fi
}

main "$@"
