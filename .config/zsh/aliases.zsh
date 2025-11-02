PATH="$HOME/.cargo/bin:$HOME/.local/npm/bin:$PATH"

alias dotgit="git --git-dir=$HOME/code/dotfiles.git/ --work-tree=$HOME"

msvc() {
  echo "Activating MSVC environment..."
  export PATH="/home/envilogger/msvc/bin/x64:$PATH"
  export CMAKE_TOOLCHAIN_FILE="/home/envilogger/work/toolchains/msvc-wine.toolchain.cmake"
  . msvcenv.sh
}

java17() {
  export JAVA_HOME=/usr/lib/jvm/java-17-openjdk/
  export PATH=$JAVA_HOME/bin:$PATH
}

java21() {
  export JAVA_HOME=/usr/lib/jvm/java-17-openjdk/
  export PATH=$JAVA_HOME/bin:$PATH
}
