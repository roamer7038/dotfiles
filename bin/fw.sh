#!/bin/sh

IPTABLES=`which iptables`

$IPTABLES -F
$IPTABLES -X
$IPTABLES -t nat -F
$IPTABLES -t nat -X
$IPTABLES -t mangle -F
$IPTABLES -t mangle -X

$IPTABLES -P INPUT DROP
$IPTABLES -P FORWARD DROP
$IPTABLES -P OUTPUT ACCEPT

$IPTABLES -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A INPUT -m conntrack --ctstate INVALID -j DROP

$IPTABLES -A INPUT -i lo -j ACCEPT
$IPTABLES -A INPUT -p icmp -j ACCEPT

# Example: 
# $IPTABLES -A INPUT -p tcp --dport 22 -j ACCEPT
# $IPTABLES -A INPUT -s 192.168.1.0/24 -p tcp -j ACCEPT

# Display the configuration in the console.
$IPTABLES -L

# Persistence of configuration
# Arch Linux:
# iptables-save > /etc/iptables/iptables.rules
# systemctl enable --now iptables
