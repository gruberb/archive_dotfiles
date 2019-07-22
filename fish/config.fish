# Start X at login
if status is-login
	if test -z "$DISPLAY" -a $XDG_VTNR = 1 
		exec ssh-agent startx -- -keeptty
	end
end

set -x EDITOR nvim

set PATH $HOME/.cargo/bin $PATH
