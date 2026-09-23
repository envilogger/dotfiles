# Wallpapers

Picked on every `tinty apply` by `~/.config/hypr/tinty-hook.sh`. This folder is kept
per machine and isn't in the dotfiles repo, since each machine has its own resolution.

## Naming

Name each image after a tinty scheme, without the `base16-`/`base24-` prefix
(`.png`, `.jpg`, `.jpeg`, `.webp` or `.jxl`). The hook uses the most specific match,
dropping one `-part` at a time. For example, `base16-gruvbox-dark-hard` tries:

1. `gruvbox-dark-hard.*`
2. `gruvbox-dark.*`
3. `gruvbox.*`
4. `default-dark.*` or `default-light.*`, depending on the scheme's variant

If nothing matches, the wallpaper stays as it is. Symlinks work, so one image can serve
several schemes.

## What happens to the image

`frame-wallpaper` scales it to the screen and paints a frame in the scheme's `base00`
colour. The result goes to `~/.local/state/theme/wallpaper-<id>.png`, which
`~/.local/state/theme/wallpaper.png` links to. hyprpaper switches to it right away and
loads that link at login. New images appear on the next `tinty apply`.
