# Login shell (SDDM starts the Hyprland session through one): export the
# ~/.config/environment.d variables, so Hyprland and its apps see them too.
if [[ -x /usr/lib/systemd/user-environment-generators/30-systemd-environment-d-generator ]]; then
    set -a
    eval "$(/usr/lib/systemd/user-environment-generators/30-systemd-environment-d-generator)"
    set +a
fi
