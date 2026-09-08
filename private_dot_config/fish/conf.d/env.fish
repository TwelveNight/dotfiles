### EXPORT ###
set fish_greeting # Supresses fish's intro message
# set TERM xterm-256color # Sets the terminal type
# Keep TERM supplied by the terminal emulator.
set -x EDITOR nvim # $EDITOR use nvim in terminal
set -x VISUAL nvim # $VISUAL use nvim in GUI mode

### ADDING TO THE PATH
# First line removes the path; second line sets it.  Without the first line,
# your path gets massive and fish becomes very slow.
fish_add_path --global $HOME/.bin $HOME/.local/bin $HOME/Applications


### SET MANPAGER
### Uncomment only one of these!

### "bat" as manpager
#set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"

### "vim" as manpager
# set -x MANPAGER '/bin/bash -c "vim -MRn -c \"set buftype=nofile showtabline=0 ft=man ts=8 nomod nolist norelativenumber nonu noma\" -c \"normal L\" -c \"nmap q :qa<CR>\"</dev/tty <(col -b)"'

### "nvim" as manpager
set -x MANPAGER "nvim -c 'set ft=man' -"

# SET RANGER SELFCONFIG #
set -gx RANGER_LOAD_DEFAULT_RC FALSE


# ADD NPM PATH #
set -g -x PATH $HOME/.npm-global/bin $PATH

# ADD CARGO PATH #
set -g -x PATH $HOME/.cargo/bin $PATH

# ADD PYENV PATH #
set -g -x PYENV_ROOT $HOME/.pyenv
set -g -x PATH $PYENV_ROOT/shims $PATH

# ADD RUST PATH #
set -g -x PATH $HOME/.local/share/gem/ruby/3.0.0/bin $PATH

# ADD GO PATH #
set -g -x PATH $HOME/go/bin $PATH

# ADD SSH_AUTH_SOCK
set -g -x SSH_AUTH_SOCK $HOME/.1password/agent.sock



# Load machine-local secrets when present. Keep this file out of chezmoi.
set -l fish_secrets "$HOME/.config/fish/conf.d/secrets.fish"
if test -r "$fish_secrets"
    source "$fish_secrets"
end

# fctx5
set -g -x GTK_IM_MODULE fcitx
set -g -x QT_IM_MODULE fcitx
set -g -x SDL_IM_MODULE fcitx
set -g -x XMODIFIERS @im=fcitx
set -g -x GLFW_IM_MODULE ibus

set -x _ZO_ECHO 1
