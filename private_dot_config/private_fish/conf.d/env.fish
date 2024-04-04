### EXPORT ###
set fish_greeting # Supresses fish's intro message
# set TERM xterm-256color # Sets the terminal type
set -g -x TERM xterm-kitty
set -x EDITOR nvim # $EDITOR use nvim in terminal
set -x VISUAL nvim # $VISUAL use nvim in GUI mode

### ADDING TO THE PATH
# First line removes the path; second line sets it.  Without the first line,
# your path gets massive and fish becomes very slow.
set -e fish_user_paths
set -U fish_user_paths $HOME/.bin $HOME/.local/bin $HOME/Applications $fish_user_paths


### SET MANPAGER
### Uncomment only one of these!

### "bat" as manpager
#set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"

### "vim" as manpager
# set -x MANPAGER '/bin/bash -c "vim -MRn -c \"set buftype=nofile showtabline=0 ft=man ts=8 nomod nolist norelativenumber nonu noma\" -c \"normal L\" -c \"nmap q :qa<CR>\"</dev/tty <(col -b)"'

### "nvim" as manpager
set -x MANPAGER "nvim -c 'set ft=man' -"

# SET RANGER SELFCONFIG #
set -g -x RANGER_LOAD_DEFAULT_RC = FALSE

# SET RANGER SELFCONFIG #
set -g -x RANGER_LOAD_DEFAULT_RC = FALSE

# ADD NPM PATH #
set -g -x PATH /home/night/.npm-global/bin $PATH

# ADD CARGO PATH #
set -g -x PATH /home/night/.cargo/bin $PATH

# ADD PYENV PATH #
set -g -x PYENV_ROOT $HOME/.pyenv
set -g -x PATH $PYENV_ROOT/shims $PATH

# ADD RUST PATH #
set -g -x PATH $HOME/.local/share/gem/ruby/3.0.0/bin $PATH

# ADD GO PATH #
set -g -x PATH $HOME/go/bin $PATH

# ADD SSH_AUTH_SOCK
set -g -x SSH_AUTH_SOCK $HOME/.1password/agent.sock


# ADD db pssword
set -g -x PASSPORT_PASSWORD GostdGVkX1
set -g -x LABOR_PASSWORD ApQyeA4PLzWikcUs6Wwp

# fctx5
set -g -x GTK_IM_MODULE fcitx5
set -g -x QT_IM_MODULE fcitx5
set -g -x SDL_IM_MODULE fcitx5
set -g -x XMODIFIERS @im=fcitx5
set -g -x GLFW_IM_MODULE ibus

set -x _ZO_ECHO 1
