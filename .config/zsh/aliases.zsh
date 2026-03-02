PATH="$HOME/.cargo/bin:$HOME/.local/npm/bin:$PATH"

alias dotgit="git --git-dir=$HOME/code/dotfiles.git/ --work-tree=$HOME"
alias open=xdg-open

aws-mfa() {
   op item get "AWS Prod" --otp | aws configure mfa-login --profile naga-prod --update-profile naga-prod-mfa
}

eks-prod() {
  aws eks update-kubeconfig --name naga-trading --region eu-west-2 --profile naga-prod-mfa --alias prod-eks
}

msvc_old() {
  echo "Activating MSVC environment..."
  export PATH="/home/envilogger/msvc/bin/x64:$PATH"
  export CMAKE_TOOLCHAIN_FILE="/home/envilogger/work/toolchains/msvc-wine.toolchain.cmake"
  . msvcenv.sh
}

msvc() {
    # Save original environment variables
    export _OLD_MSVC_PS1="$PS1"
    export _OLD_MSVC_PATH="$PATH"
    
    # Update prompt to show MSVC environment
    export PS1="[msvc] $PS1"
    
    # Your existing MSVC setup goes here
    # Example variables (replace with your actual setup):

    # Add other MSVC environment variables...
    export PATH="/home/envilogger/msvc/bin/x64:$PATH"
    export CMAKE_TOOLCHAIN_FILE="/home/envilogger/work/toolchains/msvc-wine.toolchain.cmake"
    export CMAKE_INSTALL_PREFIX=/home/envilogger/.msvc
    export CMAKE_CXX_STANDARD=20
    . msvcenv.sh
    
    # Create deactivate function
    deactivate() {
        # Restore original environment
        if [ -n "$_OLD_MSVC_PS1" ]; then
            export PS1="$_OLD_MSVC_PS1"
            unset _OLD_MSVC_PS1
        fi
        
        if [ -n "$_OLD_MSVC_PATH" ]; then
            export PATH="$_OLD_MSVC_PATH"
            unset _OLD_MSVC_PATH
        fi
        
        # Unset MSVC-specific variables
        unset WINEPREFIX
        unset MSVC_ROOT
	unset CMAKE_TOOLCHAIN_FILE
        
        # Remove the deactivate function itself
        unset -f deactivate
        
        echo "MSVC environment deactivated"
    }
    
    echo "MSVC environment activated. Type 'deactivate' to exit."
}

java17() {
  export JAVA_HOME=/usr/lib/jvm/java-17-openjdk/
  export PATH=$JAVA_HOME/bin:$PATH
}

java21() {
  export JAVA_HOME=/usr/lib/jvm/java-17-openjdk/
  export PATH=$JAVA_HOME/bin:$PATH
}
