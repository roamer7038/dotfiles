#!/bin/sh
#
# 一部の Dell Inspiron で、USB xHCI コントローラ（PCI 00:14.0）が原因で
# サスペンドに失敗しフリーズする問題を回避する。サスペンド前に wakeup を
# 無効化し、レジューム後に戻す。
#
#   kernel: PM: Device 0000:00:14.0 failed to suspend async: error -16
#
# systemd から呼ばれる位置に置いて使う:
#   sudo install -m 755 system-sleep-xhci.sh /usr/lib/systemd/system-sleep/xhci.sh
#
# 動作ログは /tmp/systemd_suspend_test に残る。

# /proc/acpi/wakeup への XHC の書き込みは enable と disable を切り替える。
# 現在の状態を grep で確かめてから書き、二重に切り替えないようにする

if [ "${1}" == "pre" ]; then
  echo "Disable broken xhci module before suspending at $(date)..." >/tmp/systemd_suspend_test
  grep XHC.*enable /proc/acpi/wakeup && echo XHC >/proc/acpi/wakeup

elif [ "${1}" == "post" ]; then
  echo "Enable broken xhci module at wakeup from $(date)" >>/tmp/systemd_suspend_test
  grep XHC.*disable /proc/acpi/wakeup && echo XHC >/proc/acpi/wakeup
fi
