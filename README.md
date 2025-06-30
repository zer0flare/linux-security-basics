# linux-security-basics
Many cloud VMs and game hosting nodes ship with minimal security. This script helps you lock things down really fast.

This is a simple and beginner-friendly Bash script that applies basic security hardening to newly deployed Linux servers.

## Features (for now)

- Prompts for and creates a new sudo user
- Copies SSH keys from root to the new user (if available)
- Disables root SSH login safely
- Reloads SSH daemon automatically
- **Interactive firewall setup (UFW) with protocol selection**
- Secure default rules: deny all incoming, allow outgoing, keep SSH open
- All additional ports are applied **only after confirmation**
- User can add more ports or cancel firewall setup safely

This script is intended for **manual server preparation** where SSH access and basic Linux tools are already available.

## Usage

```bash
wget https://raw.githubusercontent.com/zer0flare/linux-hardening-basics/main/harden.sh
chmod +x harden.sh
sudo ./harden.sh
