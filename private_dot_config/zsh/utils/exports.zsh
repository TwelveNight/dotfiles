#!/bin/sh
HISTSIZE=1000000
SAVEHIST=1000000
export TERMINAL="kitty"
export BROWSER="firefox"
export EDITOR=nvim
# eval "`pip completion --zsh`"

#zoxide
eval "$(zoxide init zsh --cmd cd)"
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
export GEMINI_API_KEY=AIzaSyCKaWey9jBVqxTtnMl_tiPoke2F4w1luNU

export CRYPTOGRAPHY_OPENSSL_NO_LEGACY='1'

# eval pyenv virtualenv to path
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# eval starship to path
eval "$(starship init zsh)"
[ -f /opt/miniconda3/etc/profile.d/conda.sh ] && source /opt/miniconda3/etc/profile.d/conda.sh
