#!/bin/bash

# Ensure the script is run with sufficient arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <username> <download_url>"
    exit 1
fi

# Parameters
USERNAME=$1
DOWNLOAD_URL=$2

# Step 1: Disable password login for the specified user
echo "Disabling password login for user '$USERNAME'..."
sudo sed -i "/^Match User $USERNAME\$/,/^$/d" /etc/ssh/sshd_config
echo -e "\nMatch User $USERNAME\n    PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config

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
