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

# Synchronize clock
info "Synchronizing clock"
sudo timedatectl set-ntp true
sudo hwclock --systohc
completed "Clock synchronized"

# Update mirrors
info "Updating mirrors"
sudo reflector -c BR -a 6 --sort rate --save /etc/pacman.d/mirrorlist
sudo pacman -Syy
completed "Mirrors updated"

# Install gnome
info "Installing gnome"
sudo pacman -S xorg gdm gnome firefox-developer-edition gnome-tweaks
sudo systemctl enable gdm
completed "Gnome installed"

# Install auto-cpufreq
info "Installing auto-cpufreq"
paru -S --noconfirm auto-cpufreq-git
sudo systemctl enable auto-cpufreq
sudo sed -i 's/^\(GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet\)"$/\1 intel_pstate=disable"/' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
completed "auto-cpufreq installed"

info "REBOOTING IN 5..4..3..2..1.."
sleep 5
sudo reboot