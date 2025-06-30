#!/bin/bash
# Linux Security Script - Basic Edition
# Author: Zer0Flare
# Description: Improves newly deployed nodes/servers security and configuration.

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
echo ""
echo "======================================="
echo "Step 1 complete: Admin user created and root SSH login disabled."
echo "Next up: Firewall configuration (UFW)."
echo "======================================="
read -p "Press Enter to continue..." _

# Step 3: Set up UFW Firewall with User-Guided Rules (Dry Run Mode)
echo "[*] Configuring UFW firewall..."

# Install UFW if missing
if ! command -v ufw &> /dev/null; then
    echo "[*] UFW not found. Installing..."
    apt-get update && apt-get install -y ufw
fi

# Always allow SSH, this is applied immediately for safety
ufw allow OpenSSH

# Start clean temporary port list
declare -a QUEUED_PORTS

# Port input loop
while true; do
    echo ""
    echo "You can now specify additional ports to allow through the firewall."
    echo "Examples:"
    echo " - Minecraft (Java Edition): 25565 TCP"
    echo " - Pterodactyl Wings Daemon: 8080 TCP"
    echo " - Source/CS2 Server: 27015 UDP"
    echo " - Terraria: 7777 TCP"
    echo ""

    while true; do
        read -p "Enter a port number to allow (or press Enter to finish): " port
        [[ -z "$port" ]] && break

        if ! [[ "$port" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
            echo "[!] Invalid port number. Please enter a value between 1 and 65535."
            continue
        fi

        read -p "Specify protocol for port $port (tcp/udp/both): " proto
        proto_lc=$(echo "$proto" | tr '[:upper:]' '[:lower:]')

        case "$proto_lc" in
            tcp)
                QUEUED_PORTS+=("$port/tcp")
                echo "[+] Queued TCP port $port"
                ;;
            udp)
                QUEUED_PORTS+=("$port/udp")
                echo "[+] Queued UDP port $port"
                ;;
            both)
                QUEUED_PORTS+=("$port/tcp")
                QUEUED_PORTS+=("$port/udp")
                echo "[+] Queued BOTH TCP and UDP for port $port"
                ;;
            *)
                echo "[!] Invalid protocol. Please enter 'tcp', 'udp', or 'both'."
                continue
                ;;
        esac
    done

    # Show summary
    echo ""
    echo "[*] Summary of queued firewall rules:"
    echo " - Default incoming policy: deny"
    echo " - Default outgoing policy: allow"
    echo " - SSH allowed (OpenSSH)"
    for rule in "${QUEUED_PORTS[@]}"; do
        echo " - Will allow: $rule"
    done
    echo " - All other incoming ports will be blocked by default."
    echo ""
    echo "Ports will only be applied after confirmation."

    # Confirm or modify
    read -p "Apply these rules now? (y = yes / a = add more / n = cancel): " confirm
    confirm_lc=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')

    if [[ "$confirm_lc" == "y" || "$confirm_lc" == "yes" ]]; then
        echo "[*] Applying firewall rules..."
        ufw default deny incoming
        ufw default allow outgoing

        for rule in "${QUEUED_PORTS[@]}"; do
            ufw allow "$rule"
        done

        ufw --force enable
        echo "[+] UFW is now active with your selected rules:"
        ufw status verbose
        break

    elif [[ "$confirm_lc" == "a" ]]; then
        echo "[*] Returning to port selection..."
        continue

    else
        echo "[!] Firewall setup canceled. No additional ports were applied."
        break
    fi
done

# Step 4: Install and Configure Fail2Ban
echo ""
echo "======================================="
echo "Step 3: Installing and configuring Fail2Ban for SSH protection"
echo "======================================="
read -p "Press Enter to continue..."

# Install Fail2Ban
if ! command -v fail2ban-client &> /dev/null; then
    echo "[*] Installing Fail2Ban..."
    apt-get update && apt-get install -y fail2ban
else
    echo "[*] Fail2Ban already installed."
fi

# Enable and start the service
systemctl enable fail2ban
systemctl start fail2ban

# Create a local jail config these configs can be adjusted as needed
cat <<EOF > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
EOF

echo "[+] Fail2Ban jail.local config written."

# Restart to apply new config
systemctl restart fail2ban

# Show jail status
echo ""
echo "[*] Fail2Ban status:"
fail2ban-client status sshd || echo "[!] SSH jail status not found (verify logs and config)"





