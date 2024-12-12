#!/bin/bash

# Ensure the script is run with sufficient arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <username> <download_url>"
    exit 1
fi

# Parameters
USERNAME=$1
DOWNLOAD_URL=$2

# Step 1: Disable password login for all users
echo "Disabling password login globally..."
SSH_CONFIG_FILE="/etc/ssh/sshd_config"

# Define settings and their desired values
declare -A SETTINGS=(
    ["PasswordAuthentication"]="no"
    ["ChallengeResponseAuthentication"]="no"
    ["PubkeyAuthentication"]="yes"
)

# Loop through the settings and apply changes
for KEY in "${!SETTINGS[@]}"; do
    VALUE="${SETTINGS[$KEY]}"
    
    # Remove duplicate or existing lines for the key
    sudo sed -i "/^#\?$KEY .*/d" "$SSH_CONFIG_FILE"

    # Append the correct setting at the end of the file
    echo "$KEY $VALUE" | sudo tee -a "$SSH_CONFIG_FILE" > /dev/null
done

# Restart SSH service to apply changes
echo "Restarting SSH service to apply changes..."
sudo systemctl restart sshd

# Step 2: Show UFW status
echo "Checking UFW status..."
sudo ufw status verbose

# Step 3: Create and navigate to 'bot' directory
echo "Creating 'bot' directory..."
mkdir -p bot
cd bot

# Step 4: Download the file from the provided URL
echo "Downloading file from $DOWNLOAD_URL..."
wget $DOWNLOAD_URL

# Step 5: Extract the downloaded file
DOWNLOADED_FILE=$(basename "$DOWNLOAD_URL")
echo "Extracting $DOWNLOADED_FILE..."
tar -xvzf $DOWNLOADED_FILE

# Step 6: Navigate into the extracted directory
EXTRACTED_FOLDER=$(tar -tzf $DOWNLOADED_FILE | head -1 | cut -f1 -d"/")
echo "Navigating into $EXTRACTED_FOLDER..."
cd $EXTRACTED_FOLDER

# Step 7: Make all files in the directory executable
echo "Making all files executable..."
chmod +x *

echo "Script completed successfully."
