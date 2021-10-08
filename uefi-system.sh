#!/bin/bash

HOSTNAME="arch"

ROOT_PASSWORD="password"

USER_NAME="hdelazeri"
USER_PASSWORD="password"

BOLD="$(tput bold 2>/dev/null || printf '')"
GREY="$(tput setaf 0 2>/dev/null || printf '')"
GREEN="$(tput setaf 2 2>/dev/null || printf '')"
YELLOW="$(tput setaf 3 2>/dev/null || printf '')"
NO_COLOR="$(tput sgr0 2>/dev/null || printf '')"

info() {
  printf '%s\n' "${BOLD}${GREY}>${NO_COLOR} $*"
}

warn() {
  printf '%s\n' "${YELLOW}! $*${NO_COLOR}"
}

completed() {
  printf '%s\n' "${GREEN}✓${NO_COLOR} $*"
}

# Enable NTP protocol
info "Enabling NTP"
timedatectl set-ntp true
hwclock --systohc
completed "NTP enabled"

# Update mirrors
info "Updating mirrors"
reflector -c BR -a 6 --sort rate --save /etc/pacman.d/mirrorlist
completed "Mirrors updated"

# Change pacman config
info "Setting up pacman"
sed -i '/#Color/s/^#//' /etc/pacman.conf
sed -i '/#Parallel/s/^#//' /etc/pacman.conf
completed "Pacman configured"

# Setup makepkg
info "Setting up makepkg"
sed -i '/#MAKEFLAGS="-j2"/s/^#//' /etc/makepkg.conf
sed -i '/MAKEFLAGS="-j2"/s/2/$(nproc)/' /etc/makepkg.conf
sed -i 's/!ccache/ccache/' /etc/makepkg.conf
sed -i 's/gzip/pigz/' /etc/makepkg.conf
sed -i 's/bzip2/pbzip2/' /etc/makepkg.conf
sed -i 's/\(xz -c -z\) -/\1 --threads=0 -/' /etc/makepkg.conf
sed -i 's/\(zstd -c -z -q\) -/\1 --threads=0 -/' /etc/makepkg.conf
completed "makepkg configuration completed"

# Create swapfile
info "Creating swapfile"
dd if=/dev/zero of=/swapfile bs=1M count=4096 status=progress
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile   none    swap   defaults  0  0" >> /etc/fstab
completed "Swapfile created"

# Setting timezone
info "Setting timezone"
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
completed "Timezone cnofigured"

# Configure locale
info "Setting up locale"
sed -i '177s/.//' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
completed "Locale configured"

# Setup hosts file
info "Setting up hosts file"
echo "$HOSTNAME" >> /etc/hostname
{ echo "127.0.0.1 localhost"; echo "::1       localhost"; echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME"; } >> /etc/hosts
completed "Hosts file setup completed"

# Change root password
info "Changing root password"
echo "root:$ROOT_PASSWORD" | chpasswd
completed "Root password change completed"

# Install base packages
info "Installing base packages"
pacman -S --noconfirm grub efibootmgr networkmanager network-manager-applet dialog wpa_supplicant mtools dosfstools reflector base-devel linux-headers xdg-user-dirs xdg-utils inetutils dnsutils bluez bluez-utils cups alsa-utils pulseaudio pulseaudio-bluetooth bash-completion rsync reflector acpi acpi_call tlp powertop ccache
completed "Base package installation completed"

# Install graphics drivers
info "Installing graphics drivers"
pacman -S --noconfirm xf86-video-intel
pacman -S --noconfirm nvidia nvidia-utils nvidia-settings
completed "Graphics drivers installed"

# Create user
info "Creating user"
useradd -m $USER_NAME
echo $USER_NAME:$USER_PASSWORD | chpasswd
echo "$USER_NAME ALL=(ALL) ALL" >> /etc/sudoers.d/$USER_NAME
completed "User created"

# Install AUR helper
info "Installing AUR helper"
git clone https://aur.archlinux.org/paru.git
chown -R $USER_NAME:$USER_NAME paru
cd paru
sudo -u $USER_NAME makepkg -si --noconfirm
cd ..
rm -rf paru
completed "AUR hepler installed"

# Installing bootloader
info "Installing bootloader"
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg
completed "Bootloader installation completed"

# Enabling services
info "Enabling services"
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups
systemctl enable tlp
systemctl enable reflector.timer
systemctl enable fstrim.timer
completed "Services enabled"

completed "Done! Type exit, umount -a and reboot."