# Install + Config for Arch on a Thinkpad X1 (6th) WQHD

In case of a fire, lost computer or a new machine, I saved the steps and dotfiles to be able to quickly reproduce my setup.


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

#### Install Arch
1. `pacstrap /mnt/ base
2. `genfstab -p /mnt >> /mnt/etc/fstab

#### Setup Arch

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
6. NEOVIM `pacman -S nvim`
7. Enable encryption
    - Modify `etc/mkinitcpio.conf`
    ```
    HOOKS=(base udev autodetect keyboard keymap modconf block encrypt lvm2 filesystems fsck)
    ```
    - Regenerate `mkinitcpio -p linux`
8. Setup the bootloader
    - Create the loader with `bootctl`
    ```
    bootctl --path=/boot/ install
    ```
    - Create the Arch entry
    ```
    default arch
	timeout 3
	editor 0
	auto-entries 0
    ```
