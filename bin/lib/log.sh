# bin/ 配下のスクリプトで共有するログ出力。
# 呼び出し側で VERBOSE=true を設定すると log_verbose が出力される。

if [ -t 1 ]; then
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

log_info() {
  echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*"
}

log_ok() {
  echo -e "${COLOR_GREEN}[OK]${COLOR_RESET} $*"
}

log_skip() {
  echo -e "${COLOR_YELLOW}[SKIP]${COLOR_RESET} $*"
}

log_warn() {
  echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*"
}

log_error() {
  echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
}

log_verbose() {
  if [ "${VERBOSE:-false}" = true ]; then
    echo -e "${COLOR_BLUE}[VERBOSE]${COLOR_RESET} $*"
  fi
}
