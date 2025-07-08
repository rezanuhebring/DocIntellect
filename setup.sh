#!/bin/bash

# ==============================================================================
# DocIntellect Fully-Automated Setup Script (for VirtualBox VM)
# ==============================================================================
# This script is designed to be run inside a clean Ubuntu Server VM. It will
# automatically detect and install missing dependencies like Git and Docker,
# then prepare and launch the application.
# ==============================================================================

# --- Style and Color Definitions ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Main Setup Logic ---
echo -e "${GREEN}--- DocIntellect Automated VM Setup & Launch ---${NC}"
echo ""

# --- Step 1: Install System Dependencies (Git & Docker) ---
echo -e "${YELLOW}Step 1: Checking and installing system dependencies...${NC}"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Use 'sudo -v' to prompt for password upfront if needed.
sudo -v
# Update package lists
sudo apt-get update -y

# Check for Git
if command_exists git; then
    echo "Git is already installed."
else
    echo "Git not found. Installing..."
    sudo apt-get install -y git
fi

# Check for Docker
if command_exists docker; then
    echo "Docker is already installed."
else
    echo "Docker not found. Installing..."
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo "Docker installed successfully."
fi
echo ""

# --- Step 2: Configure Docker Permissions ---
echo -e "${YELLOW}Step 2: Configuring Docker permissions...${NC}"
if ! groups $USER | grep &>/dev/null '\bdocker\b'; then
    echo "Adding current user ($USER) to the 'docker' group to avoid using sudo for Docker commands."
    sudo usermod -aG docker $USER
    echo ""
    echo -e "${RED}IMPORTANT:${NC} You must log out and log back in for this change to take effect."
    echo -e "Please run 'exit', then SSH back into the VM and run this script again."
    # We exit here to force the user to re-login. This is a crucial step.
    exit 0
else
    echo "User is already in the 'docker' group. No action needed."
fi
echo ""

# --- Step 3: Prepare Local Project Files ---
echo -e "${YELLOW}Step 3: Preparing local project files...${NC}"
rm -rf venv # Clean up any old venv
echo "Creating temporary Python environment for model creation..."
python3 -m venv venv
source venv/bin/activate
pip3 install --upgrade pip > /dev/null
pip3 install scikit-learn==1.5.0 > /dev/null
python3 create_dummy_model.py
deactivate
rm -rf venv # Clean up the temporary venv
echo "Model file 'model.pkl' created."
echo ""

# --- Step 4: Interactive Volume Configuration ---
echo -e "${YELLOW}Step 4: Please Configure Your Document Directories${NC}"
echo "The file 'docker-compose.yml' will now be opened for you."
echo "In the 'volumes:' section, add the path to your document folders *inside this VM*."
read -p "Press [Enter] to open docker-compose.yml in the nano editor..."

nano docker-compose.yml

echo "Configuration file saved."
echo ""

# --- Step 5: Build and Launch Application ---
echo -e "${YELLOW}Step 5: Building and launching the application...${NC}"
echo "This may take a few minutes the first time."
docker compose up --build -d

# --- Final Message ---
echo ""
echo -e "${GREEN}--- DEPLOYMENT COMPLETE ---${NC}"
echo ""
echo "The application is running. Wait about a minute for it to initialize."
echo -e "Access the dashboard from your host machine's browser at: ${YELLOW}http://localhost${NC}"
echo "(Requires port forwarding to be set up in VirtualBox settings)."
echo ""
echo -e "View Logs: ${GREEN}docker compose logs -f${NC}"
echo -e "Stop App:  ${GREEN}docker compose down${NC}"
echo ""