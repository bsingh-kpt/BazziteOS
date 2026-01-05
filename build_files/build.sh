#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
#dnf5 install -y tmux

### 1. Install Packages
dnf5 install -y \
    yubikey-manager \
    opensc \
    libfido2 \
    pam-u2f pamu2fcfg \
    sbsigntools \
    cairo-dock

### 2. Configure Yubikey for Sudo (PAM)
#sed -i '1i auth sufficient pam_u2f.so cue' /etc/pam.d/sudo

### 3. Disable Automatic Updates
systemctl disable ublue-update.timer
systemctl mask ublue-update.service

### 4. Deploy KDE Layouts & Widgets
mkdir -p /etc/skel/.config
# Reference /ctx/ because that's where the bind mount is
cp /ctx/config/plasmashellrc /etc/skel/.config/plasmashellrc
cp /ctx/config/appletrc /etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc

# Deploy Widgets
mkdir -p /usr/share/plasma/plasmoids
cp -r /ctx/widgets/KdeControlStation /usr/share/plasma/plasmoids/
cp -r /ctx/widgets/luisbocanegra.panel.colorizer /usr/share/plasma/plasmoids/
cp -r /ctx/widgets/org.kde.windowtitle /usr/share/plasma/plasmoids/
cp -r /ctx/widgets/zayron.chaac.weather /usr/share/plasma/plasmoids/
cp -r /ctx/widgets/zayron.simple.separator /usr/share/plasma/plasmoids/

### 5. Install Secure Boot Signing Hook
cp /ctx/scripts/yubikey-sign-kernel /usr/bin/yubikey-sign-kernel
chmod +x /usr/bin/yubikey-sign-kernel

### 6. Create 'just' command for Manual Updates
mkdir -p /usr/share/ublue-os/just
cat << 'EOF' >> /usr/share/ublue-os/just/60-custom.just
# Perform manual system update and sign with Yubikey
manual-update:
    rpm-ostree upgrade
    sudo /usr/bin/yubikey-sign-kernel
    echo "Update complete. Please reboot."
EOF

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket
