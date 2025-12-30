#!/bin/bash
# ============================================================
# fw.sh
# ============================================================
#
# 概要:
#   iptablesを使用したファイアウォール設定スクリプト
#
# 用途:
#   Linuxサーバーのファイアウォールルールを設定
#   信頼できるネットワークからのアクセスを許可し、外部からの不正アクセスを防ぐ
#
# セキュリティポリシー:
#   - デフォルトでINPUTはDROP（すべて拒否）
#   - デフォルトでOUTPUTはACCEPT（すべて許可）
#   - 信頼するIPアドレスからのアクセスのみ許可
#   - SSH Brute Force攻撃対策を実装
#
# 依存関係:
#   - iptables
#   - systemd（iptablesサービスの管理用）
#
# 使用例:
#   $ sudo ./fw.sh
#
# 注意事項:
#   - root権限が必要です
#   - 設定を変更する場合は、ALLOW_ADDRESSESを環境に合わせて修正してください
#   - 誤った設定によりSSH接続が切断される可能性があるため、注意が必要です
#
# ============================================================

# set -xe

###########################################################
# iptables コマンドチートシート
###########################################################
#
# チェイン操作:
# -A, --append       指定チェインに1つ以上の新しいルールを追加
# -D, --delete       指定チェインから1つ以上のルールを削除
# -P, --policy       指定チェインのポリシーを指定したターゲットに設定
# -N, --new-chain    新しいユーザー定義チェインを作成
# -X, --delete-chain 指定ユーザー定義チェインを削除
# -F                 テーブル初期化
#
# マッチング条件:
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
#
###########################################################

# iptablesコマンドのパス
IPTABLES=$(which iptables)

# 全てのIPアドレスを表す定数
ANY=0.0.0.0/0

# 信頼するIPアドレス（プライベートネットワーク）
# 環境に応じて修正してください
ALLOW_ADDRESSES=(
	192.168.1.0/24  # ホームネットワーク1
	192.168.10.0/24 # ホームネットワーク2
	192.168.50.0/24 # VPNネットワーク
)

###########################################################
# ポート定義
###########################################################

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

###########################################################
# 関数定義
###########################################################

# iptablesの初期化とデフォルトポリシーの設定
initialize() {
	echo "Initializing iptables..."

	# 全テーブルのルールをクリア
	$IPTABLES -F           # filterテーブルのルールをクリア
	$IPTABLES -X           # ユーザー定義チェインを削除
	$IPTABLES -t nat -F    # natテーブルのルールをクリア
	$IPTABLES -t nat -X    # natテーブルのユーザー定義チェインを削除
	$IPTABLES -t mangle -F # mangleテーブルのルールをクリア
	$IPTABLES -t mangle -X # mangleテーブルのユーザー定義チェインを削除

	# デフォルトポリシーの設定
	$IPTABLES -P INPUT DROP    # 入力パケットは基本的に拒否
	$IPTABLES -P OUTPUT ACCEPT # 出力パケットは基本的に許可
	$IPTABLES -P FORWARD DROP  # 転送パケットは基本的に拒否

	echo "Initialization completed."
}

# 終了処理：設定の保存と反映
finailize() {
	echo "Finalizing iptables configuration..."

	# 設定内容の確認表示
	echo "Current iptables rules:"
	$IPTABLES -L

	# 設定をファイルに保存（Arch Linux形式）
	echo "Saving iptables rules..."
	iptables-save >/etc/iptables/iptables.rules

	# iptablesサービスを再起動して設定を反映
	echo "Restarting iptables service..."
	systemctl restart iptables

	echo "Firewall configuration completed successfully."
	return 0
}

###########################################################
# 初期化実行
###########################################################

initialize

###########################################################
# セッション確立後のパケット疎通を許可
###########################################################

# 既に確立された接続と関連する接続を許可
# ESTABLISHED: 既存の接続の一部であるパケット
# RELATED: 既存の接続に関連する新しい接続（FTPのデータ接続等）
$IPTABLES -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# 無効なパケットを破棄
$IPTABLES -A INPUT -m conntrack --ctstate INVALID -j DROP

###########################################################
# 信頼可能なホストからの接続を許可
###########################################################

# ローカルホスト（lo）からの通信を無条件で許可
$IPTABLES -A INPUT -i lo -j ACCEPT

# 信頼するIPアドレスからのアクセスを許可
for addr in ${ALLOW_ADDRESSES[@]}; do
	echo "Allowing access from: $addr"

	# ICMPプロトコル（ping等）を許可
	$IPTABLES -A INPUT -p icmp -s $addr -j ACCEPT

	# 全TCPポートを許可（必要に応じてコメントアウトを解除）
	# $IPTABLES -A INPUT -p tcp -s $addr -j ACCEPT

	# 全UDPポートを許可（必要に応じてコメントアウトを解除）
	# $IPTABLES -A INPUT -p udp -s $addr -j ACCEPT

	# SSHポートを許可（リモート管理用）
	$IPTABLES -A INPUT -p tcp -s $addr -m multiport --dports $SSH -j ACCEPT

	# HTTP/HTTPSポートを許可（Webサーバー用）
	$IPTABLES -A INPUT -p tcp -s $addr -m multiport --dports $HTTP -j ACCEPT

	# 開発用サーバーポートを許可
	$IPTABLES -A INPUT -p tcp -s $addr -m multiport --dports $DEV -j ACCEPT
done

###########################################################
# 攻撃対策: SSH Brute Force
###########################################################
#
# SSHへのパスワード総当たり攻撃を防ぐための設定
# 60秒間に5回以上の接続試行があった場合、それ以降の接続を拒否
# DROPではなくREJECTを使用することで、クライアント側の再接続ループを防止
#
###########################################################

# SSH接続試行を記録
iptables -A INPUT -p tcp --syn -m multiport --dports $SSH -m recent --name ssh_attack --set

# 60秒以内に5回以上の試行があった場合はログに記録
iptables -A INPUT -p tcp --syn -m multiport --dports $SSH -m recent --name ssh_attack --rcheck --seconds 60 --hitcount 5 -j LOG --log-prefix "ssh_brute_force: "

# 60秒以内に5回以上の試行があった場合は接続を拒否
iptables -A INPUT -p tcp --syn -m multiport --dports $SSH -m recent --name ssh_attack --rcheck --seconds 60 --hitcount 5 -j REJECT --reject-with tcp-reset

###########################################################
# 設定の保存と反映
###########################################################

finailize
