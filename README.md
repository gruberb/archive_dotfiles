# Install + Config for Arch on a Thinkpad X1 (6th) WQHD

In case of a fire, lost computer or a new machine, I saved the steps and dotfiles to be able to quickly reproduce my setup.

Copied a fair share from [@ejmg](https://github.com/ejmg/an-idiots-guide-to-installing-arch-on-a-lenovo-carbon-x1-gen-6) and [@yoshuawuyts](https://github.com/yoshuawuyts/dotfiles)

![htop on Arch](https://raw.githubusercontent.com/gruberb/dotfiles/master/screen.png) ![Rust dev on Arch](https://raw.githubusercontent.com/gruberb/dotfiles/master/code.png)

## Install Arch

### Part 1 - Preperation

1. Download arch `.iso` from [https://www.archlinux.org/download](https://www.archlinux.org/download/)
2. Create a bootable USB (depending on your OS)
    - `lsblk` to list your drives
    - `unmount /dev/sdb` (instead of `sdb` use your drive)
    - `dd bs=4M if=/path/to/iso of=/path/to/usb status=progress oflag=sync`
3. Disable Safe Boot on Thinkpad
    - Turn on Laptop, press `Enter` to interrupt boot sequence
    - When BIOS is loaded, navigate to Security and turn off Safe Boot
4. Move USB up in Boot order
    - Still in BIOS, navigate to Startup > Boot
    - Use `-` and `+` to move USB to first position
5. Exit BIOS and reboot 
    - Hit either `F10` to save and exit, or
    - Hit `ESC` and navigate to reboot + save menu option

### Part 2 - Setup to Install Arch
1. Put USB Drive with Arch ISO in Thinkpad
2. Reboot Thinkpad
3. Select "USB" or "Arch" from boot menu

#### Configure WiFi Setup
1. Navigate to `/etc/pacman.d/`
2. Open `mirrorlist` and move your country entry on first position (via `vi` or `nano`)
3. Refresh mirrorlist: `pacman -Syu`
4. Find the name of your WiFi card: `ip link` (`wlp2s0`)
5. Set up `wpa`:
    - `cp /etc/netctl/examples/wireless-wpa /etc/netctl/<NAME_OF_WIFI_PROFILE>`
    - `vi /etc/netctl/<NAME_OF_WIFI_PROFILE>`
    ```
    Description='A simple WPA encrypted wireless connection'
    Interface=wlp2s0
    Connection=wireless

    Security=wpa
    IP=dhcp

    ESSID='YOUR_WIFI_NAME'
    # Prepend hexadecimal keys with \"
    # If your key starts with ", write it as '""<key>"'
    # See also: the section on special quoting rules in netctl.profile(5)
    Key='YOUR_WIFI_PASSWORD'
    # Uncomment this if your ssid is hidden
    #Hidden=yes
    # Set a priority for automatic profile selection
    #Priority=10
    ```
    - Save and exit
    - Connect: `netctl start <NAME_OF_WIFI_PROFILE>`
    - Test: `ping 8.8.8.8`

#### Partitioning Hard Drive
1. Figure out name of hard drive: `lsblk` (`nvme0n1`)
2. Format: `gdisk /dev/nvme0n1`
    - `o`, answer with `y`
    - `n` (new partition)
    - `Enter`
    - `Enter`
    - `+512MB` (EFI spec for the size)
    - `EF00` (EFI partition)
    - `n` (make another partition)
    - `Enter`
    - `Enter`
    - `Enter`
    - `8E00`
    - `w` (write to disk)
    - `y` (exit)

#### Encrypt the hard drive
1. `cryptsetup open --type luks /dev/nvme0n1p2 main_part` (use our second partition here)
2. Create a physical volume inside our just created LVM partition: `pvcreate /dev/mapper/main_part`
3. Create a volume group: `vgcreate main_group /dev/mapper/main_part`
4. Create SWAP `lvcreate -L8G main_group -n swap`
5. Create ROOT `lvcreate -L16G main_group -n root`
6. Create HOME `lvcreate -l 100%FREE main_group -n home`

#### Format and Mount
1. Root: `mkfs.ext4 /dev/mapper/main_group-root`
2. Home: `mkfs.ext4 /dev/mapper/main_group-home`
3. Swap: `mkswap /dev/mapper/main_group-swap`
4. Mount Root `mount /dev/mapper/main_group-root /mnt/`
5. Mount Home:
    ```
    mkdir /mnt/home
    mount /dev/mapper/main_group-home /mnt/home
    ```
6. Create Swap: `swapon /dev/mapper/main_group-swap`
7. Mount bootloader
    ```
    mkdir /mnt/boot/
    mount /dev/nvme0n1p1 /mnt/boot
    ```

### Part 3 - Install Arch
1. `pacstrap /mnt/ base`
2. `genfstab -p /mnt >> /mnt/etc/fstab`

### Part 4 - Setup Arch

#### Bootloader

> We are now moving from the LiveUSB to the hard drive

1. `arch-chroot /mnt`
2. `pacman -S wpa_supplicant networkmanager network-manager-applet dialog`
3. Uncomment two lines in `/etc/pacman.conf`
    ```
    [multilib]
    Include = /etc/pacman.d/mirrorlist
    ```
4. Install Intel Microcode `pacman -Sy intel-ucode`
5. Install the kernel as a backup `pacman -S linux-headers linux-lts linux-lts-headers`
6. Install NEOVIM for comfort `pacman -S nvim`
7. Enable encryption
    - Modify `nvim etc/mkinitcpio.conf`
    ```
    HOOKS=(base udev autodetect keyboard keymap modconf block encrypt lvm2 filesystems fsck)
    ```
    - Regenerate `mkinitcpio -p linux`
8. Setup the bootloader
    - Create the loader with `bootctl`
    ```
    bootctl --path=/boot/ install
    ```
    - Create the Arch entry `nvim /boot/loader/loader.conf`
    ```
    default arch
	timeout 3
	editor 0
	auto-entries 0
    ```
9. Create `arch.conf`
    - `nvim`
    - `:r !blkid`
    - Copy `UUID` from entry:
    ```
    /dev/nvme0n1p2: UUID="really-long-string-of-alphanumericals" TYPE="crypto_LUKS" PARTLABEL="Linux LVM" PARTUUID="another-long-string-of-alphanumericals"
    ```
    - Create `arch.conf`: `nvim /boot/loader/entries/arch.conf`
    ```
    title Arch Linux
    linux /vmlinuz-linux
    initrd /intel-ucode.img
    initrd /initramfs-linux.img
    options cryptdevice=UUID=long-alphanumerica-string-WITHOUT-QUOTES:cryptlvm root=/dev/mapper/main_group-root quiet rw
    ```
10. Reboot and start Arch via
    - `exit`
    - `reboot now`
    - Remove USB drive
    - Select Arch in Boot Menu

#### Drivers, WiFi, Sudo, User

##### WiFi
- Same as above:
    - Reconfigure mirrorlist `nvim /etc/pacman.d/mirrorlist`
    - `cp /etc/netctl/examples/wireless-wpa /etc/netctl/<NAME_OF_WIFI_PROFILE>`
    - `nvm /etc/netctl/<NAME_OF_WIFI_PROFILE>`
    - Fill in information, save and exit
    - `netctl start <NAME_OF_WIFI_PROFILE>
    - Test: `ping 8.8.8.8`

##### Locale
1. `/etc/locale.gen`
2. `locale-gen`
3. `localectl set-locale LANG="en_US.UTF8"`
4. `hwclock --systohc --utc`
5. `timedatectl set-ntp true`

##### Change Password
- `passwd`

##### Environment, Drivers
- Touchpad: `pacman -S xf86-input-libinput`
- xorg: `pacman -S xorg-server xorg-xinit xorg-apps mesa xterm`
- Intel Drivers: `pacman -S xf86-video-intel lib32-intel-dri lib32-mesa lib32-libgl`

##### Sudo, User, Root
1. Sudo: `pacman -S sudo`
2. Enable sudo:
    - `EDITOR=nvim visudo`
    - `visudo`
    - Uncomment:
    ```
    ## Uncomment to allow members of group wheel to execute any command
    # %wheel ALL=(ALL) ALL # <-- this line if its now clear enough, fam
    ```
3. Create a new User: `useradd -m -G wheel -s /bin/bash <NAME>`
4. Set Password: `passwd <NAME>`
5. `sudo reboot now` to check if everything worked

#### Desktop
1. `pacman -S i3`
2. `pacman -S ttf-dejavu ttf-liberation noto-fonts`
3. `pacman -S openssh`
4. Setup SSH
```
mkdir ~/.ssh
cp <private key> ~/.ssh/<private key>
cp <public key> ~/.ssh/<public key>.pub
chmod 700 ~/.ssh
chmod 600 ~/.ssh/<private key>
chmod 600 ~/.ssh/<public key>.pub
```
5. Aurman
	-	`curl -sSL https://github.com/polygamma.gpg | gpg --import -`
	- Install
	```
	mkdir ~/aur_pkg
    cd aur_pkg
    git clone https://aur.archlinux.org/aurman.git
    cd aurmen/
    makepkg -si # DO NOT USE SUDO HERE
	```

#### Lenovo Thinkpad X1 specifics
- CPU Throttling
	```
	aurman -S lenovo-throttling-fix-git
	sudo systemctl enable --now lenovo_fix.service
	```
- BIOS update
	- `sudo pacman -S fwupd`
	- `fwupdmgr refresh`
	- `fwupdmgr get-updates`
	- Hook up Thinkpad to power
	- `fwupdmgr update`
- Trimming SSD `systemctl enable fstrim.timer`
- Hibernate support
	- Update HOOKS `nvim /etc/mkinitcpio.conf`
	```
	HOOKS=(base udev autodetect keyboard keymap modconf block encrypt lvm2 resume filesystems fsck)
	```
	- Regenerate initramfs
	```
	mkinitcpio -p linux
	mkinitcpio -p linux-lts
	```
	- Update `arch.conf`
	```
	title Arch Linux
    linux /vmlinuz-linux
    initrd /intel-ucode.img
    initrd /initramfs-linux.img
    options cryptdevice=UUID=<LONG-ALPHANUM-STRING>:cryptlvm root=/dev/mapper/main_group-root resume=/dev/mapper/main_group-swap quiet rw
	```
- Suspend Support
	- !!Bios has to be >= 1.30!!
	- Reboot to Bios and change `Config > Power > Sleep State > Linux`
	- Save and Reboot
