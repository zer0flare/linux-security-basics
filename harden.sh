#!/bin/bash
# Linux Security Script - Basic Edition
# Author: Zer0Flare
# Description: Improves newly deployed nodes/servers security.

set -e  # Exit on any error

echo "[+] Starting basic Linux hardening..."

# Step 1: Create a new admin user
read -p "Enter the username for the new admin user: " newuser

if id "$newuser" &>/dev/null; then
    echo "[!] User '$newuser' already exists. Skipping creation."
else
    echo "[*] Creating new user '$newuser'..."
    adduser "$newuser"
    usermod -aG sudo "$newuser"
    echo "[+] User '$newuser' created and added to the sudo group."
fi

# Optional: Copy root's authorized SSH keys to the new user
if [ -f /root/.ssh/authorized_keys ]; then
    mkdir -p /home/"$newuser"/.ssh
    cp /root/.ssh/authorized_keys /home/"$newuser"/.ssh/
    chown -R "$newuser":"$newuser" /home/"$newuser"/.ssh
    chmod 700 /home/"$newuser"/.ssh
    chmod 600 /home/"$newuser"/.ssh/authorized_keys
    echo "[+] SSH keys copied from root to '$newuser'."
else
    echo "[!] No SSH keys found in /root/.ssh/authorized_keys to copy."
fi

# Step 2: Disable root SSH login
echo "[*] Disabling root SSH login..."
SSHD_CONFIG="/etc/ssh/sshd_config"

if grep -q "^PermitRootLogin" $SSHD_CONFIG; then
    sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' $SSHD_CONFIG
else
    echo "PermitRootLogin no" >> $SSHD_CONFIG
fi

systemctl reload sshd
echo "[+] Root SSH login disabled."
