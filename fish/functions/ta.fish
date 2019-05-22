# Defined in - @ line 1
function ta --description 'alias ta=tmux attach-session -t'
	tmux attach-session -t $argv;
end
