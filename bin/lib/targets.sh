# 配置対象の一覧。create-symlinks.sh と doctor.sh が共有する。
# 配置先の組み立て規則は名前ごとに決まっている。

# $HOME/<name> へ置く
DOTFILES_BASIC=(.bashrc .zshrc .tmux.conf .gitconfig .latexmkrc)
DOTFILES_VIM=(.vimrc)
DOTFILES_X11=(.Xmodmap .xprofile .picom.conf)

# bin/<name> -> $HOME/.local/bin/<name>
# コマンドとして直接呼ぶものだけを挙げる。フックや設定ファイルから
# 絶対パスで呼ばれるスクリプトは対象にしない。
DOTFILES_COMMANDS=(pane multissh wsl-chrome anyenv-setup)

# config/<dir>/* -> $HOME/.config/<dir>/*
# profile.d には bash と zsh の共通設定（00-common.sh）が入る。
# 利用者が同じディレクトリに置いたファイルは名前順で後に読まれる。
DOTFILES_SHELL_DIRS=(profile.d)
DOTFILES_GUI_DIRS=(terminator dunst ranger)
DOTFILES_I3WM_DIRS=(i3 i3status)

# .claude/<name> -> $HOME/.claude/<name>
# settings.local.json はローカル専用（.gitignore 対象）のため含めない
DOTFILES_AGENT=(CLAUDE.md statusline-command.sh)
