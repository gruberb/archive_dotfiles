# Defined in - @ line 1
function backup --description 'alias backup=sudo rsync -avz -e "ssh -i /home/gruberbastian/.ssh/id_rsa" --del --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found", "/var/cache", "home/gruberbastian/.cache", "/home/gruberbastian/.rustup", "/home/gruberbastian/.cargo", "/home/gruberbastian/.mozilla"} / gruberbastian@37.59.39.154:/home/gruberbastian/arch_x1'
	sudo rsync -avz -e "ssh -i /home/gruberbastian/.ssh/id_rsa" --del --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found", "/var/cache", "home/gruberbastian/.cache", "/home/gruberbastian/.rustup", "/home/gruberbastian/.cargo", "/home/gruberbastian/.mozilla"} / gruberbastian@37.59.39.154:/home/gruberbastian/arch_x1 $argv;
end
