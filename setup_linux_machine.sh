#!/bin/bash

# Ensure the script is run with sufficient arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <username> <password> <public_rsa_key>"
    exit 1
fi

# Parameters
USERNAME=$1
PASSWORD=$2
PUBLIC_RSA_KEY=$3

# Update Linux system
echo "Updating the system..."
sudo apt update && sudo apt upgrade -y

# Create a new user with the provided username and password
echo "Creating user '$USERNAME'..."
sudo adduser --gecos "$USERNAME,,," --disabled-password $USERNAME
echo "$USERNAME:$PASSWORD" | sudo chpasswd

# Give admin permissions to the user
echo "Granting admin permissions to '$USERNAME'..."
sudo usermod -aG sudo $USERNAME

# Switch to the new user
echo "Switching to '$USERNAME' user..."
sudo -i -u $USERNAME bash <<EOF

# Create .ssh directory and set permissions
echo "Setting up SSH for '$USERNAME'..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add the provided public RSA key to authorized_keys
echo "$PUBLIC_RSA_KEY" > ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

EOF

# Ensure PermitRootLogin is set to no in sshd_config
echo "Configuring SSH to disable root login..."
SSH_CONFIG_FILE="/etc/ssh/sshd_config"

# Ensure PermitRootLogin is set to no and appears only once
if grep -q "^#\?PermitRootLogin" "$SSH_CONFIG_FILE"; then
    sudo sed -i '/^#\?PermitRootLogin.*/d' "$SSH_CONFIG_FILE" # Remove any existing lines
fi
echo "PermitRootLogin no" | sudo tee -a "$SSH_CONFIG_FILE" > /dev/null

# Restart SSH service to apply changes
echo "Restarting SSH service..."
sudo systemctl restart sshd

# Configure UFW firewall
echo "Configuring UFW firewall..."
sudo ufw allow OpenSSH  # Step 1: Allow OpenSSH to avoid lockout
sudo ufw enable         # Step 2: Enable UFW
sudo ufw allow http     # Step 3: Allow HTTP traffic
sudo ufw allow https    # Step 4: Allow HTTPS traffic

# Install and configure Fail2Ban
echo "Installing and configuring Fail2Ban..."
sudo apt install -y fail2ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Restart Fail2Ban to apply changes
echo "Restarting Fail2Ban service..."
sudo systemctl restart fail2ban

echo "Script completed successfully."
