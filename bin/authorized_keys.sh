#!/bin/sh
#
# GitHub に登録された公開鍵を取得して ~/.ssh/authorized_keys に追記する
# （上書きはしない）。
#
#   authorized_keys.sh [github-user]   既定のユーザは roamer7038

if [ -t 1 ]; then
  N=$(printf '\033[0m') G=$(printf '\033[0;32m') Y=$(printf '\033[0;33m') B=$(printf '\033[0;34m') R=$(printf '\033[0;31m')
else N='' G='' Y='' B='' R=''; fi
log_info() { echo "$B[INFO]$N $*"; }
log_ok() { echo "$G[OK]$N $*"; }
log_skip() { echo "$Y[SKIP]$N $*"; }
log_warn() { echo "$Y[WARN]$N $*"; }
log_error() { echo "$R[ERROR]$N $*" >&2; }
log_verbose() { [ "${VERBOSE:-false}" = true ] && echo "$B[VERBOSE]$N $*" || :; }

DEFAULT_USER="roamer7038"

show_help() {
  cat <<EOM
Usage: $(basename "$0") [GITHUB_USERNAME]

Append the public keys registered on GitHub to ~/.ssh/authorized_keys.

ARGUMENTS:
  GITHUB_USERNAME   GitHub account (default: $DEFAULT_USER)

OPTIONS:
  -h, --help        Show this message

EXAMPLES:
  $(basename "$0")
  $(basename "$0") username

EOM
  exit 0
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  show_help
fi

if [ -n "$1" ]; then
  GITHUB_USER="$1"
else
  GITHUB_USER="$DEFAULT_USER"
fi

log_info "Fetching the public keys of GitHub user $GITHUB_USER..."

mkdir -p ~/.ssh && chmod 700 ~/.ssh

GITHUB_URL="https://github.com/${GITHUB_USER}.keys"

KEYS=$(curl -fsSL "$GITHUB_URL" 2>&1)
CURL_EXIT_CODE=$?

if [ $CURL_EXIT_CODE -ne 0 ]; then
  log_error "Cannot fetch the public keys of GitHub user '$GITHUB_USER'"
  log_error "Check the user name and the network connection"
  exit 1
fi

if [ -z "$KEYS" ]; then
  log_warn "GitHub user '$GITHUB_USER' has no public key registered"
  exit 1
fi

echo "$KEYS" >>~/.ssh/authorized_keys

# 所有者以外が読める authorized_keys は SSH に無視される
chmod 600 ~/.ssh/authorized_keys

KEY_COUNT=$(echo "$KEYS" | wc -l)
log_ok "Added $KEY_COUNT public key(s) to ~/.ssh/authorized_keys"
log_info "Added keys:"
echo "$KEYS" | sed 's/^/  /'
