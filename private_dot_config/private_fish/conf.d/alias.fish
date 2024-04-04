### ALIASES ###
# \x1b[2J   <- clears tty
# \x1b[1;1H <- goes to (1, 1) (start)
alias clear='echo -en "\x1b[2J\x1b[1;1H" ; echo; echo; seq 1 (tput cols) | sort -R | spark | lolcat; echo; echo'

# 1password-cli
op completion fish | source

# undefind
alias mk='mkdir'
alias unrar='unrar x'

#cd
alias cdz='cd'
alias z='cd'

# navigation
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'

#cat
alias cat='bat'

# vim
alias vim='nvim'
alias vi='vim'

# Changing "ls" to "exa"
# alias ls='eza -al --color=always --group-directories-first' # my preferred listing
alias ls='lsd  --color=always --group-directories-first'
alias la='lsd --all --icons --color=always --group-directories-first' # all files and dirs(including hidden)
alias ll='lsd  -g --all --header --long  --git --color=always --group-directories-first' # long format
alias lt='lsd --tree --color=always --group-directories-first' # tree listing
alias l.='lsd --all | grep -E "^\."' # show only hidden files

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
alias ra='ranger'
