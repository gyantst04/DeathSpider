#!/bin/bash

# RDP Desktop Installer Script
# This script installs XFCE4 desktop and XRDP for remote access

set -e  # Exit on error

echo "========================================"
echo "     RDP Desktop Installer 🚀"
echo "========================================"
echo ""
echo "This script will:"
echo "1. Update system packages"
echo "2. Install XFCE4 desktop environment"
echo "3. Install XRDP for remote desktop access"
echo "4. Configure RDP service"
echo ""
echo "========================================"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "⚠️  Please do not run this script as root. Use sudo when prompted."
    exit 1
fi

# Check if user has sudo privileges
echo "Checking sudo privileges..."
if ! sudo -v; then
    echo "❌ Error: User does not have sudo privileges or password is incorrect"
    exit 1
fi

# Confirmation
read -p "Do you want to continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

echo "📦 Starting installation process..."
echo "----------------------------------------"

# Step 1: Update and upgrade system
echo "🔄 Step 1/4: Updating system packages..."
sudo apt update && sudo apt upgrade -y
if [ $? -eq 0 ]; then
    echo "✅ System update completed successfully"
else
    echo "❌ System update failed"
    exit 1
fi

# Step 2: Install required packages
echo "📥 Step 2/4: Installing XFCE4 and XRDP..."
sudo apt install xfce4 xfce4-goodies xrdp -y
if [ $? -eq 0 ]; then
    echo "✅ Packages installed successfully"
else
    echo "❌ Package installation failed"
    exit 1
fi

# Step 3: Configure XFCE4 session
echo "⚙️  Step 3/4: Configuring desktop environment..."
echo "startxfce4" > ~/.xsession
sudo chown $(whoami):$(whoami) ~/.xsession
echo "✅ Desktop configuration completed"

# Step 4: Enable and start RDP service
echo "🚀 Step 4/4: Setting up RDP service..."
sudo systemctl enable xrdp
sudo systemctl restart xrdp
echo "✅ RDP service configured and started"

# Display status
echo ""
echo "----------------------------------------"
echo "Checking RDP service status..."
sudo systemctl status xrdp --no-pager | grep -E "(Active:|Loaded:|Main PID:)"

# Get IP address
echo ""
echo "----------------------------------------"
echo "📡 Network Information:"
ip_addr=$(hostname -I | awk '{print $1}')
echo "Your IP address: $ip_addr"
echo ""

# Display connection instructions
echo "========================================"
echo "     Installation Complete! ✅"
echo "========================================"
echo ""
echo "To connect to this RDP server:"
echo "1. Use an RDP client (Windows: mstsc.exe, Linux: Remmina)"
echo "2. Connect to: $ip_addr:3389"
echo "3. Use your Linux username and password"
echo ""
echo "⚠️  Important Notes:"
echo "• Make sure port 3389 is open in firewall: sudo ufw allow 3389"
echo "• The default session is XFCE4 desktop"
echo "• Reboot if the connection doesn't work immediately"
echo ""
echo "To check RDP status: sudo systemctl status xrdp"
echo "To restart RDP: sudo systemctl restart xrdp"
echo "To stop RDP: sudo systemctl stop xrdp"
echo "========================================"
