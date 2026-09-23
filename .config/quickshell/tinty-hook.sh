#!/usr/bin/env bash
# tinty hook: write the applied scheme's palette for Quickshell.
#
# tinty passes the scheme to hooks as environment variables
# (TINTY_SCHEME_PALETTE_BASE00_HEX_R, ..., TINTY_SCHEME_NAME, ...). This writes them
# to $XDG_STATE_HOME/theme/palette.json, which Quickshell's Theme.qml watches and
# follows live. base16 schemes get base10-base17 from the standard base24 fallbacks.
set -euo pipefail

state=${XDG_STATE_HOME:-$HOME/.local/state}/theme

# "#rrggbb" for a palette slot, or nothing if the scheme doesn't define it.
hex() {
    local prefix=TINTY_SCHEME_PALETTE_${1^^}_HEX
    local r=${prefix}_R g=${prefix}_G b=${prefix}_B
    [[ -n ${!r:-} ]] && printf '#%s%s%s' "${!r}" "${!g}" "${!b}"
}

declare -A fallback=(
    [base10]=base00 [base11]=base00
    [base12]=base08 [base13]=base0A [base14]=base0B [base15]=base0C [base16]=base0D [base17]=base0E
)

keys=(base0{0..9} base0{A..F} base1{0..7})
declare -A palette
for key in "${keys[@]}"; do
    palette[$key]=$(hex "$key" || true)
done
for key in "${!fallback[@]}"; do
    [[ -n ${palette[$key]} ]] || palette[$key]=${palette[${fallback[$key]}]}
done
for key in "${keys[@]}"; do
    [[ -n ${palette[$key]} ]] || { echo "tinty-hook: scheme has no $key" >&2; exit 1; }
done

mkdir -p "$state"
tmp=$(mktemp "$state/.palette.XXXXXX")
for key in "${keys[@]}"; do printf '%s\n%s\n' "$key" "${palette[$key]}"; done |
    jq -nR --arg theme "${TINTY_SCHEME_ID:-}" --arg name "${TINTY_SCHEME_NAME:-}" --arg variant "${TINTY_SCHEME_VARIANT:-}" '
        [inputs] as $lines
        | { theme: $theme, name: $name, variant: $variant,
            palette: ([range(0; $lines | length; 2) | { key: $lines[.], value: $lines[. + 1] }] | from_entries) }
    ' >"$tmp"
# Replace atomically so Quickshell never reads a half-written file.
mv "$tmp" "$state/palette.json"
