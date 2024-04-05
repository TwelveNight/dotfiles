#!/bin/sh
# get fastest mirrors
alias mirror="sudo reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist"
alias mirrord="sudo reflector --latest 50 --number 20 --sort delay --save /etc/pacman.d/mirrorlist"
alias mirrors="sudo reflector --latest 50 --number 20 --sort score --save /etc/pacman.d/mirrorlist"
alias mirrora="sudo reflector --latest 50 --number 20 --sort age --save /etc/pacman.d/mirrorlist"


# easier to read disk
alias df='df -h'     # human-readable sizes
alias free='free -m' # show sizes in MB

# get top process eating memory
alias psmem='ps auxf | sort -nr -k 4 | head -5'

# get top process eating cpu ##
alias pscpu='ps auxf | sort -nr -k 3 | head -5'

# gpg encryption
# verify signature for isos
alias gpg-check="gpg2 --keyserver-options auto-key-retrieve --verify"
# receive the key of a developer
alias gpg-retrieve="gpg2 --keyserver-options auto-key-retrieve --receive-keys"

# For when keys break
alias archlinx-fix-keys="sudo pacman-key --init && sudo pacman-key --populate archlinux && sudo pacman-key --refresh-keys"

# systemd
alias mach_list_systemctl="systemctl list-unit-files --state=enabled"

alias un='sudo pacman -Rns' # uninstall package
alias up='sudo pacman -Syu' # update system/package/aur
alias pl='pacman -Qs' # list installed package
alias pa='pacman -Ss' # list availabe package
alias pc='sudo pacman -Sc' # remove unused cache
alias po='pacman -Qtdq | sudo pacman -Rns -' # remove unused packages, also try > pacman -Qqd | pacman -Rsu --print -

# undefind
alias mk='mkdir'
alias unrar='unrar x'

# navigation
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'
alias cz='cd'

#cat
alias cat='bat'
alias ca='cat'

# vim
alias vv='vi'
alias vvv='vim'
alias vim='nvim'
alias vi='neovide'
alias v='lvim'
alias lv='neovide-lunarvim'


# Changing "ls" to "lsd"
alias ld='eza -lDh --group --icons'
alias lf='eza -lFh --group --icons --color=always | grep -v /'
alias l.='eza -dlh --group .* --icons --group-directories-first'
alias ll='eza -alh --group --icons --group-directories-first'
alias ls='eza -alF --group -h --icons --color=always --sort=size | grep -v /'
alias lt='eza -alh --group --icons --sort=modified'
alias tree='eza --tree --icons'
# alias ls='lsd --all' # short list
# alias  l='lsd --long' # long list
# alias la='lsd --all' # all files and dirs(including hidden)
# alias ld='lsd -lD' # long list dirs
# alias ll='lsd --all --header --long' # long format
# alias lt='lsd --tree' # tree listing
# alias l.='lsd --all | grep -E "^\."' # show only hidden files

# Colorize grep output (good for log files)
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# confirm before overwriting something
alias cp="cp -i"
alias mv='mv -i'
alias rm='rm -i'

# ps
alias psa="ps auxf"
alias psgrep="ps aux | grep -v grep | grep -i -e VSZ -e"
alias psmem='ps auxf | sort -nr -k 4'
alias pscpu='ps auxf | sort -nr -k 3'

# git
alias lg='lazygit'
alias addup='git add -u'
alias addall='git add .'
alias branch='git branch'
alias checkout='git checkout'
alias clone='git clone'
alias commit='git commit -m'
alias fetch='git fetch'
alias pull='git pull origin'
alias push='git push origin'
alias tag='git tag'
alias newtag='git tag -a'

# get error messages from journalctl
alias jctl="journalctl -p 3 -xb"

# switch between shells
# I do not recommend switching default SHELL from bash.
alias tobash="sudo chsh $USER -s /bin/bash && echo 'Now log out.'"
alias tozsh="sudo chsh $USER -s /bin/zsh && echo 'Now log out.'"
alias tofish="sudo chsh $USER -s /bin/fish && echo 'Now log out.'"

#docker
alias dk='docker'
alias dki='docker images'
alias dkc='docker container ls'
alias dkr='docker run'
alias dke='docker exec -it'
alias dkp='docker ps'
alias dkpa='docker ps -a'
alias dkrmi='docker rmi'
alias dkrm='docker rm'
alias dkb='docker build'
alias dkt='docker tag'
alias dkl='docker logs'
alias dklf='docker logs -f'

# clear
alias cl='clear'

# ranger
# alias ra='ranger'
function ranger_wrapper {
    /usr/bin/env ranger $*
    local quit_cd_wd_file="$HOME/.cache/ranger/quit_cd_wd"
    if [ -s "$quit_cd_wd_file" ]; then
        cd "$(cat $quit_cd_wd_file)"
        true > "$quit_cd_wd_file"
    fi
}

alias ra='ranger_wrapper'

# zsh
alias zshrc='nvim ~/.zshrc'
alias zsha='nvim ~/.config/zsh/aliases.zsh'
alias zshe='nvim ~/.config/zsh/exports.zsh'
alias zshb='nvim ~/.config/zsh/bindkey.zsh'

# hyprland
alias hypr='nvim ~/.config/hypr/userprefs.conf'
alias hyprbug='cat /tmp/hypr/$(ls -t /tmp/hypr/ | head -n 2 | tail -n 1)/hyprland.log'

# lexido
alias ido="lexido"

# tmux
alias t='tmux'
alias ta='tmux a'

# musicfox
alias mfox='musicfox'

# trans
alias trbz='trans -b :zh'
alias trbe='trans -b :en'

# chezmoi
alias cm='chezmoi'
alias cmcd='cd $HOME/.local/share/chezmoi'
alias cmv='chezmoi edit --apply'
alias cmw='chezmoi edit --watch'
alias cmadd='chezmoi add'
alias cmreadd='chezmoi re-add'
alias cmdiff='chezmoi diff'
alias cmmerge='chezmoi merge'

# wget
alias wget=wget --hsts-file="$XDG_DATA_HOME/wget-hsts"

eval "$(zoxide init zsh --cmd cd)"

if [[ $TERM == "xterm-kitty" ]]; then
  alias ssh="kitty +kitten ssh"
fi

case "$(uname -s)" in

Darwin)
	# echo 'Mac OS X'
	# alias ls='eza'
	;;

Linux)
	# alias ls='lsd'
	;;

CYGWIN* | MINGW32* | MSYS* | MINGW*)
	# echo 'MS Windows'
	;;
*)
	# echo 'Other OS'
	;;
esac
