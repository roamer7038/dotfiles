#!/bin/bash
#
# iptables でファイアウォールを設定する。INPUT は既定で DROP し、
# ALLOW_ADDRESSES に挙げた送信元のみ許可する。SSH の総当たり対策を含む。
#
# 要 root。ALLOW_ADDRESSES を環境に合わせて直してから実行すること。
# 設定を誤ると SSH 接続が切れる。

# set -xe

# ============================================================
# 定義
# ============================================================

IPTABLES=$(which iptables)

ANY=0.0.0.0/0

# 信頼する送信元。ここに挙げたネットワークだけが INPUT を通る
ALLOW_ADDRESSES=(
  192.168.1.0/24  # ホームネットワーク1
  192.168.10.0/24 # ホームネットワーク2
  192.168.50.0/24 # VPNネットワーク
)

# --- ポート定義 ---

# Well Known Ports (0-1023)
SSH=22
FTP=20,21
DNS=53
SMTP=25,465,587
POP3=110,995
IMAP=143,993
HTTP=80,443
IDENT=113
NTP=123
NET_BIOS=135,137,138,139,445
SYSLOG=514
DHCP=67,68
TELNET=992
RTSP=554

# Registered Ports (1024-49151)
SOCKS=1080
OPENVPN=1194
VLC=1234
RTMP=1935
MYSQL=3306
STUN=3478
TURN=3478
RTP=5004
RTCP=5005
POSTGRE=5432
SMQTT=8883

# Development Ports
DEV=3000,3001,8080,8443
WEB_SOCKET=3333,3334
OVT=9000
SRT=9999
ICE=10000,10001,10002,10003,10004,10005

# Game Server Ports
VALHEIM=2456,2457
MINECRAFT_JE=25565

# ============================================================
# 関数定義
# ============================================================

# 全テーブルを空にし、既定のポリシーを引き直す
initialize() {
  echo "Initializing iptables..."

  $IPTABLES -F
  $IPTABLES -X
  $IPTABLES -t nat -F
  $IPTABLES -t nat -X
  $IPTABLES -t mangle -F
  $IPTABLES -t mangle -X

  $IPTABLES -P INPUT DROP
  $IPTABLES -P OUTPUT ACCEPT
  $IPTABLES -P FORWARD DROP

  echo "Initialization completed."
}

finailize() {
  echo "Finalizing iptables configuration..."

  echo "Current iptables rules:"
  $IPTABLES -L

  # 保存先は Arch Linux の iptables.service が読む位置
  echo "Saving iptables rules..."
  iptables-save >/etc/iptables/iptables.rules

  echo "Restarting iptables service..."
  systemctl restart iptables

  echo "Firewall configuration completed successfully."
  return 0
}

# ============================================================
# ルールの適用
# ============================================================

initialize

# --- 確立済みの接続 ---

# RELATED は FTP のデータ接続のように、既存の接続から派生するもの
$IPTABLES -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A INPUT -m conntrack --ctstate INVALID -j DROP

# --- 信頼する送信元 ---

$IPTABLES -A INPUT -i lo -j ACCEPT

for addr in ${ALLOW_ADDRESSES[@]}; do
  echo "Allowing access from: $addr"

  $IPTABLES -A INPUT -p icmp -s $addr -j ACCEPT

  # 全ポートを開けるなら、次の2行を有効にする
  # $IPTABLES -A INPUT -p tcp -s $addr -j ACCEPT
  # $IPTABLES -A INPUT -p udp -s $addr -j ACCEPT

  $IPTABLES -A INPUT -p tcp -s $addr -m multiport --dports $SSH -j ACCEPT
  $IPTABLES -A INPUT -p tcp -s $addr -m multiport --dports $HTTP -j ACCEPT
  $IPTABLES -A INPUT -p tcp -s $addr -m multiport --dports $DEV -j ACCEPT
done

# --- SSH の総当たり対策 ---
#
# 60秒間に5回を超える接続試行を記録して拒否する。
# DROP ではなく REJECT にして、クライアントの再接続ループを避ける

iptables -A INPUT -p tcp --syn -m multiport --dports $SSH -m recent --name ssh_attack --set
iptables -A INPUT -p tcp --syn -m multiport --dports $SSH -m recent --name ssh_attack --rcheck --seconds 60 --hitcount 5 -j LOG --log-prefix "ssh_brute_force: "
iptables -A INPUT -p tcp --syn -m multiport --dports $SSH -m recent --name ssh_attack --rcheck --seconds 60 --hitcount 5 -j REJECT --reject-with tcp-reset

finailize
