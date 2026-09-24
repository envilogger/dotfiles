PATH="$HOME/.cargo/bin:$HOME/.local/npm/bin:$PATH:$HOME/.local/bin"
DOTFILES_DIR="$HOME/.dotfiles"

alias dot="git --git-dir=$DOTFILES_DIR --work-tree=$HOME"
alias lazydot="lazygit --git-dir=$DOTFILES_DIR --work-tree=$HOME"
alias open=xdg-open

# eza instead of ls (overrides oh-my-zsh's ls aliases)
if command -v eza >/dev/null; then
  alias ls='eza --icons=auto --group-directories-first'
  alias l='ls -la --git --header'
  alias ll='ls -l --git'
  alias la='ls -la --git'
  alias lsa='l'
  alias lt='ls --tree --level=2'
  alias lta='lt -a --git-ignore'
fi

java17() {
  export JAVA_HOME=/usr/lib/jvm/java-17-openjdk/
  export PATH=$JAVA_HOME/bin:$PATH
}

java21() {
  export JAVA_HOME=/usr/lib/jvm/java-17-openjdk/
  export PATH=$JAVA_HOME/bin:$PATH
}
