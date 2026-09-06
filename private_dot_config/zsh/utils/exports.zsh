#!/usr/bin/env zsh
HISTSIZE=1000000
SAVEHIST=1000000
export TERMINAL="kitty"
export BROWSER="firefox"
export EDITOR=nvim
# eval "`pip completion --zsh`"

#zoxide
(( $+commands[zoxide] )) && eval "$(zoxide init zsh --cmd cd)"
export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND=(bg=none,fg=magenta,bold)

# add cargo to path
export PATH="$PATH:$HOME/.cargo/bin"

# add toolbox scripts to path
export PATH="$PATH:$HOME/.local/share/JetBrains/Toolbox/scripts"


# add own scripts to path
export PATH="$PATH:$HOME/.local/scripts"

# disable webkit dmabuf renderer
export WEBKIT_DISABLE_DMABUF_RENDERER=1

# GEMINI_API_KEY

export CRYPTOGRAPHY_OPENSSL_NO_LEGACY='1'

# eval pyenv virtualenv to path
# eval "$(pyenv init --path)"
# eval "$(pyenv init - zsh)"
# eval "$(pyenv virtualenv-init -)"
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# eval starship to path
(( $+commands[starship] )) && eval "$(starship init zsh)"
[ -f /opt/miniconda3/etc/profile.d/conda.sh ] && source /opt/miniconda3/etc/profile.d/conda.sh

# # Set JAVA_HOME for JDK 17
# export JAVA_HOME="/usr/lib/jvm/java-17-openjdk"
# # Add JAVA_HOME/bin to your PATH
# export PATH="$JAVA_HOME/bin:$PATH"

# Store private environment variables here; never add this file to chezmoi.
[[ -r "$ZDOTDIR/secrets.zsh" ]] && source "$ZDOTDIR/secrets.zsh"
