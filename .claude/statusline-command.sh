#!/bin/bash
# Claude Code status line
# Shows: profile · account | current working directory | model (effort) | tokens used (k, %)

input=$(cat)

# Which account this session runs under: CLAUDE_CONFIG_DIR picks the profile,
# the default one being ~/.claude. Each profile keeps its own .claude.json.
if [[ -n $CLAUDE_CONFIG_DIR ]]; then
  cfg_json="$CLAUDE_CONFIG_DIR/.claude.json"
  profile=${CLAUDE_CONFIG_DIR##*/}
  profile=${profile#.claude-}
  [[ $profile == .claude ]] && profile=personal
else
  cfg_json="$HOME/.claude.json"
  profile=personal
fi

account="not logged in"
[[ -f $cfg_json ]] && account=$(jq -r '.oauthAccount.emailAddress // "not logged in"' "$cfg_json" 2>/dev/null)
[[ -z $account ]] && account="not logged in"

dim=$'\033[2m'
reset=$'\033[0m'
# personal blends into the rest of the line; any other profile turns yellow, so
# a corporate session is impossible to mistake for the personal one
if [[ $profile == personal ]]; then acct=$dim; else acct=$'\033[33m'; fi

line=$(jq -r '
  (.workspace.current_dir // .cwd // "") as $cwd
  | (.model.display_name // "") as $model
  | (if .effort.level then "\($model) (\(.effort.level))" else $model end) as $model
  | (if .context_window.used_percentage != null
     then "\((.context_window.total_input_tokens // 0) / 1000 | round)k (\(.context_window.used_percentage | round)%)"
     else "n/a" end) as $tokens
  | "\($cwd) | \($model) | \($tokens)"
' <<<"$input")

printf '%s%s · %s%s %s| %s%s\n' "$acct" "$profile" "$account" "$reset" "$dim" "$line" "$reset"
