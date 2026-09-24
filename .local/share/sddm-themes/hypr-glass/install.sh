#!/usr/bin/env bash
# Install this theme system-wide and make it SDDM's current theme. Run with sudo.
#
# SDDM runs as the sddm user, which can't read your home directory, so the theme is
# copied rather than linked. background.png is left owned by you so tinty-hook.sh can
# keep it in sync with the current wallpaper without sudo.
set -euo pipefail

src=$(cd "$(dirname "$0")" && pwd)
dest=/usr/share/sddm/themes/hypr-glass
owner=${SUDO_USER:-$(stat -c %U "$src")}

[[ $EUID -eq 0 ]] || { echo "Run with sudo: sudo $0" >&2; exit 1; }

install -d "$dest"
install -m 644 "$src"/{Main.qml,metadata.desktop,theme.conf,background.png} "$dest"/
chown "$owner" "$dest/background.png"

install -d /etc/sddm.conf.d
cat >/etc/sddm.conf.d/theme.conf <<CONF
[Theme]
Current=hypr-glass
CONF

echo "Installed to $dest and set as the current SDDM theme."
