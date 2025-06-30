# linux-security-basics
Many cloud VMs and game hosting nodes ship with minimal security. This script helps you lock things down really fast.

This is a simple and beginner-friendly Bash script that applies basic security hardening to newly deployed Linux servers.

## Features (for now)

- Creates a new admin user with sudo privileges
- Copies root SSH keys to new user (if available)
- Disables direct root SSH login
- Interactive UFW firewall setup:
  - Choose specific ports
  - Select protocol (TCP/UDP/Both)
  - Summary + confirmation before applying rules
- Installs and configures Fail2Ban for SSH brute-force protection
- Designed for first-run security setup on fresh servers

This script is intended for **manual server preparation** where SSH access and basic Linux tools are already available.

## Usage

```bash
wget https://raw.githubusercontent.com/zer0flare/linux-hardening-basics/main/harden.sh
chmod +x harden.sh
sudo ./harden.sh


