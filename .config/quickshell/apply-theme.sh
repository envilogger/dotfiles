#!/usr/bin/env bash
# Apply a colour theme from ~/.config/themes/<name>/ to Quickshell.
#
# Usage: apply-theme.sh <name>
#
# Reads the theme's base24.yaml (or base16.yaml, filling base10-base17 with the
# standard base24 fallbacks) in the tinted-theming format, and writes the palette to
# $XDG_STATE_HOME/theme/palette.json. Quickshell's Theme.qml watches that file and
# switches colours live.
set -euo pipefail

usage() { echo "Usage: ${0##*/} <name>   (themes: $(ls "$themes" 2>/dev/null | tr '\n' ' '))" >&2; exit 1; }

themes=${XDG_CONFIG_HOME:-$HOME/.config}/themes
state=${XDG_STATE_HOME:-$HOME/.local/state}/theme
[[ $# -eq 1 ]] || usage
dir=$themes/$1
[[ -d $dir ]] || { echo "No theme directory: $dir" >&2; usage; }

if [[ -f $dir/base24.yaml ]]; then
    scheme=$dir/base24.yaml
elif [[ -f $dir/base16.yaml ]]; then
    scheme=$dir/base16.yaml
else
    echo "No base24.yaml or base16.yaml in $dir" >&2
    exit 1
fi

# Scheme files are flat YAML: top-level `key: "value"` lines, then `palette:` with
# indented `baseXX: "#rrggbb"` lines. Comments after values are ignored.
field() { sed -nE "s/^$1:[[:space:]]*\"?([^\"#]*[^\"#[:space:]])\"?.*/\1/p" "$scheme" | head -1; }
declare -A palette
while read -r key value; do
    palette[$key]=$value
done < <(sed -nE 's/^[[:space:]]+(base[0-9A-Fa-f]{2}):[[:space:]]*"?#?([0-9A-Fa-f]{6})"?.*/\1 #\2/p' "$scheme")

# base16 schemes lack base10-base17; base24 defines these fallbacks for them.
declare -A fallback=(
    [base10]=base00 [base11]=base00
    [base12]=base08 [base13]=base0A [base14]=base0B [base15]=base0C [base16]=base0D [base17]=base0E
)
for key in "${!fallback[@]}"; do
    [[ -n ${palette[$key]:-} ]] || palette[$key]=${palette[${fallback[$key]}]:-}
done

keys=(base0{0..9} base0{A..F} base1{0..7})
for key in "${keys[@]}"; do
    [[ -n ${palette[$key]:-} ]] || { echo "$scheme: missing $key" >&2; exit 1; }
done

mkdir -p "$state"
tmp=$(mktemp "$state/.palette.XXXXXX")
{
    for key in "${keys[@]}"; do printf '%s\n%s\n' "$key" "${palette[$key]}"; done
} | jq -nR --arg name "$(field name)" --arg variant "$(field variant)" --arg theme "$1" '
    [inputs] as $lines
    | { theme: $theme, name: $name, variant: $variant,
        palette: ([range(0; $lines | length; 2) | { key: $lines[.], value: $lines[. + 1] }] | from_entries) }
' >"$tmp"
# Replace atomically so Quickshell never reads a half-written file.
mv "$tmp" "$state/palette.json"

echo "Applied $(field name) ($1, $(field variant)) -> $state/palette.json"
