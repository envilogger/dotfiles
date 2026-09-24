#!/usr/bin/env bash
# Install keyd, copy the configs here to /etc/keyd and (re)load them. Run with sudo.
#
# Copied rather than linked so keyd doesn't depend on /home at boot. Safe to re-run.
set -euo pipefail

src=$(cd "$(dirname "$0")" && pwd)

[[ $EUID -eq 0 ]] || { echo "Run with sudo: sudo $0" >&2; exit 1; }

pacman -Q keyd &>/dev/null || pacman -S --needed --noconfirm keyd

install -d /etc/keyd
install -m 644 "$src"/*.conf /etc/keyd/

systemctl enable --now keyd
keyd reload

echo "Installed $(cd "$src" && echo *.conf) to /etc/keyd and reloaded keyd."
