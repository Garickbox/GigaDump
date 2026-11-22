#!/bin/sh
[ "$table" = "filter" ] || [ "$table" = "nat" ] || exit 0
sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1 || true
if [ "$table" = "filter" ]; then
  iptables -C INPUT -i tailscale0 -j ACCEPT 2>/dev/null || iptables -I INPUT 1 -i tailscale0 -j ACCEPT
  iptables -C FORWARD -i tailscale0 -j ACCEPT 2>/dev/null || iptables -I FORWARD 1 -i tailscale0 -j ACCEPT
  iptables -C FORWARD -o tailscale0 -j ACCEPT 2>/dev/null || iptables -I FORWARD 2 -o tailscale0 -j ACCEPT
elif [ "$table" = "nat" ]; then
  iptables -t nat -C POSTROUTING -s 100.64.0.0/10 ! -o tailscale0 -j MASQUERADE 2>/dev/null || iptables -t nat -I POSTROUTING 1 -s 100.64.0.0/10 ! -o tailscale0 -j MASQUERADE
fi
