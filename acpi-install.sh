#!/bin/bash

# acpi_call installer for Legion Go (SteamOS)
set -e

# Error handling
handle_error() {
    echo "ERROR: $1"
    sudo steamos-readonly enable || true
    exit 1
}

# 1. Disable readonly
echo "Disabling readonly filesystem..."
sudo steamos-readonly disable || handle_error "Failed to disable readonly."

# 2. Key management
echo "Syncing package keys..."
if ! sudo pacman -Sy --noconfirm archlinux-keyring holo-keyring; then
    sudo rm -rf /etc/pacman.d/gnupg
    sudo pacman-key --init
    sudo pacman-key --populate archlinux holo || handle_error "Keyring init failed."
    sudo pacman -Sy
fi

# 3. Dynamic header detection
echo "Detecting kernel headers..."
KERNEL_VER_MAJOR=$(uname -r | cut -d'.' -f1)
KERNEL_VER_MINOR=$(uname -r | cut -d'.' -f2)
TARGET_HEADERS="linux-neptune-${KERNEL_VER_MAJOR}${KERNEL_VER_MINOR}-headers"

if ! pacman -Ss "$TARGET_HEADERS" > /dev/null; then
    TARGET_HEADERS="linux-neptune-headers"
fi
echo "Using: $TARGET_HEADERS"

# 4. Install dependencies
echo "Installing dependencies..."
sudo pacman -S --noconfirm --needed "$TARGET_HEADERS" dkms git gcc make patch libmpc || handle_error "Dependency install failed."

# 5. Clone driver
echo "Cloning driver source..."
cd /usr/src
sudo rm -rf acpi_call-1.2.2
sudo git clone --depth=1 https://github.com/nix-community/acpi_call.git acpi_call-1.2.2 || handle_error "Clone failed."

# 6. DKMS build
echo "Building via DKMS..."
cd acpi_call-1.2.2
if [ ! -f dkms.conf ]; then
    sudo tee dkms.conf > /dev/null << 'EOF'
PACKAGE_NAME="acpi_call"
PACKAGE_VERSION="1.2.2"
CLEAN="make clean"
BUILT_MODULE_NAME[0]="acpi_call"
DEST_MODULE_LOCATION[0]="/kernel/drivers/acpi"
AUTOINSTALL="yes"
EOF
fi

sudo dkms remove acpi_call/1.2.2 --all 2>/dev/null || true
sudo dkms add -m acpi_call -v 1.2.2 || handle_error "DKMS add failed."
sudo dkms build -m acpi_call -v 1.2.2 || handle_error "DKMS build failed."
sudo dkms install -m acpi_call -v 1.2.2 || handle_error "DKMS install failed."

# 7. Activation
echo "Loading module..."
sudo depmod -a
sudo modprobe acpi_call || handle_error "Failed to load module."

# 8. Autoload config
echo "Configuring autoload..."
sudo mkdir -p /etc/modules-load.d
echo "acpi_call" | sudo tee /etc/modules-load.d/acpi_call.conf > /dev/null

# 9. Restore readonly
echo "Enabling readonly filesystem..."
sudo steamos-readonly enable
echo "Installation complete. Reboot required."
