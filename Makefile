#!/bin/env make

SCRIPT_DIR := $(shell pwd)
INSTALL_DIR := /usr/local/bin

# デフォルトターゲット
all: help

# プリセットを使用したセットアップ
minimal:
	@echo "Setting up minimal configuration..."
	${SCRIPT_DIR}/bin/create-symlinks.sh --preset minimal

standard:
	@echo "Setting up standard configuration..."
	${SCRIPT_DIR}/bin/create-symlinks.sh --preset standard
	${SCRIPT_DIR}/bin/install-zsh-plugins.sh

desktop:
	@echo "Setting up desktop environment..."
	${SCRIPT_DIR}/bin/create-symlinks.sh --preset desktop
	${SCRIPT_DIR}/bin/install-zsh-plugins.sh

full:
	@echo "Setting up full configuration..."
	${SCRIPT_DIR}/bin/create-symlinks.sh --preset full
	cp ${SCRIPT_DIR}/bin/xinit.sh ${HOME}/.xinit.sh
	${SCRIPT_DIR}/bin/install-zsh-plugins.sh

# ドライラン（確認用）
dry-run-minimal:
	${SCRIPT_DIR}/bin/create-symlinks.sh --preset minimal --dry-run

dry-run-standard:
	${SCRIPT_DIR}/bin/create-symlinks.sh --preset standard --dry-run

dry-run-desktop:
	${SCRIPT_DIR}/bin/create-symlinks.sh --preset desktop --dry-run

dry-run-full:
	${SCRIPT_DIR}/bin/create-symlinks.sh --preset full --dry-run

# SSH設定
.ssh:
	${SCRIPT_DIR}/bin/authorized_keys.sh

# anyenv のインストール（anyenv-update プラグイン含む）
anyenv:
	@if [ -d ~/.anyenv ]; then \
		echo "anyenv is already installed"; \
	else \
		echo "Installing anyenv..."; \
		git clone https://github.com/anyenv/anyenv ~/.anyenv; \
		echo "Installing anyenv-update plugin..."; \
		mkdir -p ~/.anyenv/plugins; \
		git clone https://github.com/znz/anyenv-update.git ~/.anyenv/plugins/anyenv-update; \
		echo ""; \
		echo "anyenv installed successfully!"; \
		echo "Next steps:"; \
		echo "  1. Add 'export PATH=\"\$$HOME/.anyenv/bin:\$$PATH\"' to your shell profile"; \
		echo "  2. Run: exec \$$SHELL -l"; \
		echo "  3. Run: anyenv init"; \
		echo "  4. Run: anyenv install --init"; \
		echo "  5. Use 'anyenv update' to update all *env and plugins"; \
	fi

# Docker のインストール（Docker Engine + Lazydocker）
docker:
	@echo "Installing Docker and Lazydocker..."
	${SCRIPT_DIR}/bin/install-docker.sh
	@echo ""
	@echo "Docker installation completed!"
	@echo "Please log out and log back in for the changes to take effect."

# ヘルプ
help:
	@echo "Available targets:"
	@echo ""
	@echo "Setup targets:"
	@echo "  minimal      - Setup minimal configuration (basic dotfiles)"
	@echo "  standard     - Setup standard configuration (minimal + vim + zsh plugins) [default]"
	@echo "  desktop      - Setup desktop environment (standard + X11 + GUI apps)"
	@echo "  full         - Setup full configuration (all settings including i3wm)"
	@echo ""
	@echo "Dry-run targets (preview without applying):"
	@echo "  dry-run-minimal"
	@echo "  dry-run-standard"
	@echo "  dry-run-desktop"
	@echo "  dry-run-full"
	@echo ""
	@echo "Other targets:"
	@echo "  .ssh         - Setup SSH authorized_keys"
	@echo "  anyenv       - Install anyenv with anyenv-update plugin"
	@echo "  docker       - Install Docker Engine and Lazydocker"
	@echo "  help         - Show this help message"

.PHONY: all minimal standard desktop full dry-run-minimal dry-run-standard dry-run-desktop dry-run-full .ssh anyenv docker help
