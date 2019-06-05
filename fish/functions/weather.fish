# Defined in - @ line 1
function weather --description 'alias weather=curl wttr.in/Berlin'
	curl wttr.in/Berlin $argv;
end
