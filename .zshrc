function source_profile_impl {
  if [[ -f "$1" ]]; then
    source "$1"
  fi
}

function source_profile {
  source_profile_impl "$HOME/.config/profiles/$1"
}

function source_private_profile {
  source_profile_impl "$HOME/.config/private/profiles/$1"
}

source_profile "p10k"
source_profile "zinit"

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  source_profile "linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  source_profile "mac"
fi

source_profile_impl "$HOME/.profile"

# private profiles might contain sensitive info
source_private_profile "private"
