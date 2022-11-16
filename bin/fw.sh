#!/bin/bash

# set -xe

###########################################################
# チートシート
#
# -A, --append       指定チェインに1つ以上の新しいルールを追加
# -D, --delete       指定チェインから1つ以上のルールを削除
# -P, --policy       指定チェインのポリシーを指定したターゲットに設定
# -N, --new-chain    新しいユーザー定義チェインを作成
# -X, --delete-chain 指定ユーザー定義チェインを削除
# -F                 テーブル初期化
#
# -p, --protocol      プロトコル         プロトコル(tcp，udp，icmp，all)を指定
# -s, --source        IPアドレス[/mask]  送信元のアドレス。IPアドレスorホスト名を記述
# -d, --destination   IPアドレス[/mask]  送信先のアドレス。IPアドレスorホスト名を記述
# -i, --in-interface  デバイス           パケットが入ってくるインターフェイスを指定
# -o, --out-interface デバイス           パケットが出ていくインターフェイスを指定
# -j, --jump          ターゲット         条件に合ったときのアクションを指定
# -t, --table         テーブル           テーブルを指定
# -m state --state    状態              パケットの状態を条件として指定
#                                       stateは， NEW，ESTABLISHED，RELATED，INVALIDが指定できる
# !                   条件を反転（～以外となる）
###########################################################

# 実行パス
IPTABLES=`which iptables`

# 全てのIPを表す設定を定義
ANY=0.0.0.0/0

# 信頼するIPアドレス
ALLOW_ADDRESSES=(
  192.168.1.0/24
  192.168.10.0/24
  192.168.50.0/24
)

###########################################################
# ポート定義
###########################################################

# Well Known Ports
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

# Registered Ports
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

# Development
DEV=3000,3001,8080,8443
WEB_SOCKET=3333,3334
OVT=9000
SRT=9999
ICE=10000,10001,10002,10003,10004,10005

# Game
VALHEIM=2456,2457
MINECRAFT_JE=25565

###########################################################
# 関数
###########################################################

# iptablesの初期化，デフォルト動作の定義
initialize() 
{
  $IPTABLES -F # テーブルの初期化
  $IPTABLES -X # チェーン初期化
  $IPTABLES -t nat -F
  $IPTABLES -t nat -X
  $IPTABLES -t mangle -F
  $IPTABLES -t mangle -X

  $IPTABLES -P INPUT   DROP
  $IPTABLES -P OUTPUT  ACCEPT
  $IPTABLES -P FORWARD DROP
}

# 終了前処理
finailize()
{
  # 設定の確認
  $IPTABLES -L

  # 設定の出力と保存（Arch Linux）
  iptables-save > /etc/iptables/iptables.rules
  # 再起動（systemd）
  systemctl restart iptables
  return 0
}

###########################################################
# 初期化
###########################################################

initialize

###########################################################
# セッション確立後のパケット疎通は許可
###########################################################
$IPTABLES -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A INPUT -m conntrack --ctstate INVALID -j DROP

###########################################################
# 信頼可能なホストからの接続は許可
###########################################################

# ローカルホストの許可
$IPTABLES -A INPUT -i lo -j ACCEPT

# 信頼するIPアドレスの許可
for addr in ${ALLOW_ADDRESSES[@]}
do
  # ICMPの許可
  $IPTABLES -A INPUT -p icmp -s $addr -j ACCEPT

  # TCPの許可
  # $IPTABLES -A INPUT -p tcp -s $addr -j ACCEPT

  # UDPの許可
  # $IPTABLES -A INPUT -p udp -s $addr -j ACCEPT

  # SSHの許可
  $IPTABLES -A INPUT -p tcp -s $addr -m multiport --dports $SSH -j ACCEPT

  # HTTP/HTTPSの許可
  $IPTABLES -A INPUT -p tcp -s $addr -m multiport --dports $HTTP -j ACCEPT

  # DEV SERVERの許可
  $IPTABLES -A INPUT -p tcp -s $addr -m multiport --dports $DEV -j ACCEPT
done

###########################################################
# 攻撃対策: SSH Brute Force
# SSHはパスワード認証を利用しているサーバの場合，パスワード総当り攻撃に備える。
# 1分間に5回しか接続トライをできないようにする。
# SSHクライアント側が再接続を繰り返すのを防ぐためDROPではなくREJECTにする。
###########################################################
iptables -A INPUT -p tcp --syn -m multiport --dports $SSH -m recent --name ssh_attack --set
iptables -A INPUT -p tcp --syn -m multiport --dports $SSH -m recent --name ssh_attack --rcheck --seconds 60 --hitcount 5 -j LOG --log-prefix "ssh_brute_force: "
iptables -A INPUT -p tcp --syn -m multiport --dports $SSH -m recent --name ssh_attack --rcheck --seconds 60 --hitcount 5 -j REJECT --reject-with tcp-reset

###########################################################
# 保存・反映
###########################################################

finailize

