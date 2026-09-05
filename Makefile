#!/bin/env make

SCRIPT_DIR  := $(shell pwd)
SYMLINKS    := $(SCRIPT_DIR)/bin/create-symlinks.sh
ZSH_PLUGINS := $(SCRIPT_DIR)/bin/install-zsh-plugins.sh

# プリセット = タグの組。プリセットの定義はここだけにある
TAGS_minimal  := basic
TAGS_standard := basic vim agent
TAGS_desktop  := basic vim agent x11 gui
TAGS_agent    := agent

PRESETS := minimal standard desktop agent

all: help

# --- セットアップ ---

minimal agent:
	@echo "Setting up $@ configuration..."
	$(SYMLINKS) $(TAGS_$@)

standard desktop:
	@echo "Setting up $@ configuration..."
	$(SYMLINKS) $(TAGS_$@)
	$(ZSH_PLUGINS)

# プリセットごとの dry-run-<preset>（例: make dry-run-desktop）
dry-run-%:
	$(SYMLINKS) --dry-run $(TAGS_$*)

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

# tmux のウィンドウ状態表示に必要なフックを ~/.claude/settings.json へ追加する
claude-hooks:
	@$(SCRIPT_DIR)/bin/install-claude-hooks.sh

# 導入済みのプラグイン・ツールをまとめて更新する
update:
	@$(SCRIPT_DIR)/bin/update.sh

# --- 点検 ---

# 配置状態を点検する（変更はしない）
doctor:
	@$(SCRIPT_DIR)/bin/doctor.sh

# 構文・書式・ドライランを検査する（変更はしない）
check:
	@$(SCRIPT_DIR)/bin/check.sh

# --- 開発用 ---

# シェルスクリプトを .editorconfig に合わせて整形する
fmt:
	@command -v shfmt >/dev/null 2>&1 || { \
		echo "shfmt is not installed. Install it with:"; \
		echo "  sudo apt install shfmt"; \
		exit 1; \
	}
	shfmt -w -i 2 bin config/profile.d

help:
	@echo "Setup:    $(PRESETS)"
	@echo "          make dry-run-<preset> で適用内容を確認する"
	@echo "Install:  .ssh anyenv docker bun claude-hooks update"
	@echo "Check:    doctor  環境の配置状態を点検する"
	@echo "          check   リポジトリを静的検査する"
	@echo "Dev:      fmt     シェルスクリプトを整形する"
	@echo ""
	@echo "詳細は README.md を参照。"

.PHONY: all $(PRESETS) .ssh anyenv docker bun claude-hooks update doctor check fmt help
