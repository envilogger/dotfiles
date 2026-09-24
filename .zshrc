ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"
# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"
zstyle ':omz:update' mode reminder  # just remind me to update when it's time
zstyle ':omz:update' frequency 13
# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

case "$HOST" in
  archibook)    MACHINE_ICON="💻" ;;
  archistation) MACHINE_ICON="🖥️" ;;
esac

# Shown by starship (env_var.* in ~/.config/starship.toml)
[[ -n $MACHINE_ICON ]] && export STARSHIP_MACHINE=$MACHINE_ICON
[[ -n $SSH_CONNECTION || -n $SSH_TTY ]] && export STARSHIP_SSH=1

plugins=(git kubectl kubectx)

ZSH_CUSTOM=$HOME/.config/zsh

# User configuration
# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

ZSH_CACHE_DIR=$HOME/.cache/oh-my-zsh
if [[ ! -d $ZSH_CACHE_DIR ]]; then
  mkdir $ZSH_CACHE_DIR
fi

source "$ZSH"/oh-my-zsh.sh
source "$ZSH_CUSTOM"/aliases.zsh
# PROMPT="${MACHINE_COLOR}${MACHINE_LABEL}%f %F{cyan}%1~%f $ "

# lazygit: tinty.yml (theme, written by ~/.config/lazygit/tinty-hook.sh) over config.yml
export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml,$HOME/.config/lazygit/tinty.yml"

# fzf: Ctrl+R history, Ctrl+T files, Alt+C cd
source <(fzf --zsh)

# Prompt (config: ~/.config/starship.toml)
eval "$(starship init zsh)"
