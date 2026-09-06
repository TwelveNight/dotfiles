# using yy shell wrapper that provides the ability to change the current working directory when exiting Yazi.
function y() {
	(( $+commands[yazi] )) || { print -u2 "yazi is not installed"; return 127; }
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

alias aa='y'
