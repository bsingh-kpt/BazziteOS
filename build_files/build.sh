#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# Enable COPR
dnf5 -y copr enable ublue-os/staging

### 1. Install Packages
dnf5 install -y \
    yubikey-manager \
    opensc \
    libfido2 \
    pam-u2f pamu2fcfg \
    sbsigntools \
    crystal-dock

# Disable COPR
dnf5 -y copr disable ublue-os/staging

### 2. Configure Yubikey for Sudo (PAM)
sed -i '3i auth       required     pam_u2f.so cue' /etc/pam.d/sudo

### 3. Disable Automatic Updates
systemctl disable ublue-update.timer
systemctl mask ublue-update.service

### 4. Deploy KDE Layouts & Widgets
mkdir -p /etc/skel/.config
# Reference /ctx/ because that's where the bind mount is
cp /ctx/config/starship.toml /etc/skel/.config/starship.toml
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

# Install and default to starship prompt
curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir /usr/bin/ -y
cat << 'EOF' >> /etc/skel/.bashrc

if [[ $- == *i* ]]
then
    fastfetch
fi
eval "$(starship init bash)"
EOF

### DELL test pc related only. REMOVE AFTER TESTING ###
# Blacklist TPM modules to stop the 45s timeouts
printf "blacklist tpm_tis\nblacklist tpm_crb\nblacklist tpm\n" > /etc/modprobe.d/blacklist-tpm.conf
# Force dracut to omit TPM modules in the initramfs
mkdir -p /usr/lib/dracut/dracut.conf.d && \
    echo 'omit_dracutmodules+=" tpm2-tss "' > /usr/lib/dracut/dracut.conf.d/omit-tpm.conf
systemctl mask dev-tpmrm0.device tpm2.target
# Install xrdp
dnf5 install -y xrdp
systemctl enable xrdp
cat << 'EOF' >> /usr/lib/firewalld/zones/public.xml
<?xml version="1.0" encoding="utf-8"?>
<zone>
  <short>Public</short>
  <description>For use in public areas.</description>
  <service name="ssh"/>
  <service name="dhcpv6-client"/>
  <port port="3389" protocol="tcp"/>
</zone>
EOF

#### Example for enabling a System Unit File

systemctl enable podman.socket

# Disable the automatic login to Gamescope/Steam
# systemctl mask bazzite-user-setup.service && \
#     systemctl disable bazzite-steam-setup.service && \
#     rm -f /etc/sddm.conf.d/autologin.conf
