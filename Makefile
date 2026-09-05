#!/bin/env make

SCRIPT_DIR  := $(shell pwd)
SYMLINKS    := $(SCRIPT_DIR)/bin/create-symlinks.sh
ZSH_PLUGINS := $(SCRIPT_DIR)/bin/install-zsh-plugins.sh

PRESETS := minimal standard desktop full agent

all: help

# --- セットアップ ---

minimal:
	@echo "Setting up minimal configuration..."
	$(SYMLINKS) --preset minimal

standard desktop:
	@echo "Setting up $@ configuration..."
	$(SYMLINKS) --preset $@
	$(ZSH_PLUGINS)

full:
	@echo "Setting up full configuration..."
	$(SYMLINKS) --preset full
	cp $(SCRIPT_DIR)/bin/xinit.sh $(HOME)/.xinit.sh
	$(ZSH_PLUGINS)

agent:
	@echo "Setting up AI agent configuration..."
	$(SYMLINKS) --preset agent

# プリセットごとの dry-run-<preset>（例: make dry-run-full）
dry-run-%:
	$(SYMLINKS) --preset $* --dry-run

# --- 追加ツールのインストール ---

.ssh:
	$(SCRIPT_DIR)/bin/authorized_keys.sh

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
		echo "See docs/anyenv.md for the next steps."; \
	fi

docker:
	@echo "Installing Docker and Lazydocker..."
	$(SCRIPT_DIR)/bin/install-docker.sh
	@echo ""
	@echo "Docker installation completed!"
	@echo "Please log out and log back in for the changes to take effect."

bun:
	@echo "Installing bun..."
	$(SCRIPT_DIR)/bin/install-bun.sh

# --- 開発用 ---

# シェルスクリプトを .editorconfig に合わせて整形する
fmt:
	@command -v shfmt >/dev/null 2>&1 || { \
		echo "shfmt is not installed. Install it with:"; \
		echo "  go install mvdan.cc/sh/v3/cmd/shfmt@latest"; \
		exit 1; \
	}
	shfmt -w -i 2 bin shell

help:
	@echo "Available targets:"
	@echo ""
	@echo "Setup targets:"
	@echo "  minimal      - Basic dotfiles only"
	@echo "  standard     - minimal + Vim + AI agent + zsh plugins (recommended)"
	@echo "  desktop      - standard + X11 + GUI apps"
	@echo "  full         - desktop + i3wm"
	@echo "  agent        - AI agent configs only (~/.claude)"
	@echo "  dry-run-<preset>"
	@echo "               - Preview a preset without applying it"
	@echo ""
	@echo "Install targets:"
	@echo "  .ssh         - Add GitHub public keys to ~/.ssh/authorized_keys"
	@echo "  anyenv       - Install anyenv with the anyenv-update plugin"
	@echo "  docker       - Install Docker Engine and Lazydocker"
	@echo "  bun          - Install bun"
	@echo ""
	@echo "Other targets:"
	@echo "  fmt          - Format shell scripts with shfmt"
	@echo "  help         - Show this message"
	@echo ""
	@echo "Run './bin/create-symlinks.sh --help' for per-file options."

.PHONY: all $(PRESETS) .ssh anyenv docker bun fmt help
