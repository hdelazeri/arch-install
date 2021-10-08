#!/bin/bash

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

confirm() {
    while true; do
        read -rp "$* (y/n) " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) warn "Please answer yes or no.";;
        esac
    done
}

# Checks for requirements
confirm "Are the partitions correctly mounted and formatted?"
confirm "Ready to start installation. Continue?"

# Enable NTP protocol
info "Enabling NTP"
timedatectl set-ntp true
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

# Install base system
info "Installing base system"
pacstrap /mnt base linux linux-firmware vim intel-ucode git
completed "Base system installed"

# Generate FSTAB
info "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab
completed "fstab generated"