#!/bin/bash

# ==============================================================================
# DocIntellect Setup Script (for a dedicated VirtualBox VM)
# ==============================================================================
# This script is designed to be run inside a clean Ubuntu Server VM. It will:
# 1. Check for Docker and Git.
# 2. Add the current user to the Docker group to avoid using 'sudo'.
# 3. Create the initial machine learning model.
# 4. Guide the user through the final volume configuration.
# 5. Build and launch the application using Docker Compose.
# ==============================================================================

# --- Style and Color Definitions ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Main Setup Logic ---
echo -e "${GREEN}--- DocIntellect VM Setup & Launch ---${NC}"
echo ""

# --- Step 1: Pre-flight Checks ---
echo -e "${YELLOW}Step 1: Verifying environment...${NC}"

if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: Git is not installed.${NC} Please run: sudo apt-get update && sudo apt-get install -y git"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed.${NC} Please follow the official Docker installation guide for Ubuntu."
    exit 1
fi
echo "Environment verified."
echo ""

# --- Step 2: Configure Docker Permissions ---
echo -e "${YELLOW}Step 2: Configuring Docker permissions...${NC}"
if ! groups $USER | grep &>/dev/null '\bdocker\b'; then
    echo "Adding current user ($USER) to the 'docker' group to avoid using sudo."
    echo "This requires your password."
    sudo usermod -aG docker $USER
    echo ""
    echo -e "${RED}IMPORTANT:${NC} You must log out and log back in for this change to take effect."
    echo -e "Please run 'exit', then SSH back into the VM and run this script again."
    exit 0
else
    echo "User is already in the 'docker' group. No action needed."
fi
echo ""

# --- Step 3: Prepare Local Files ---
echo -e "${YELLOW}Step 3: Preparing local project files...${NC}"
# Create a virtual environment just for running the model creation script
if [ -d "venv" ]; then
    echo "Removing old local virtual environment..."
    rm -rf venv
fi
echo "Creating temporary Python environment..."
python3 -m venv venv
source venv/bin/activate
pip3 install --upgrade pip > /dev/null
pip3 install scikit-learn==1.5.0 > /dev/null

echo "Creating the initial machine learning model..."
python3 create_dummy_model.py
deactivate
rm -rf venv # Clean up the temporary venv
echo "Model file 'model.pkl' created."
echo ""

# --- Step 4: Interactive Volume Configuration ---
echo -e "${YELLOW}Step 4: Please Configure Your Document Directories${NC}"
echo "The application needs to know where your documents are located inside this VM."
echo "The file 'docker-compose.yml' will now be opened with 'nano'."
echo ""
echo "-> Inside the VM, you might create a folder like '/home/$USER/my_docs'."
echo "-> Then, in the 'volumes:' section, add a line like:"
echo "   '- /home/$USER/my_docs:/scan-targets/my_docs:ro'"
echo ""
echo -e "-> Press ${GREEN}Ctrl+X${NC}, then ${GREEN}Y${NC}, then ${GREEN}Enter${NC} to save and exit."
echo ""
read -p "Press [Enter] to open docker-compose.yml now..."

nano docker-compose.yml

echo "Configuration file saved."
echo ""

# --- Step 5: Build and Launch Application ---
echo -e "${YELLOW}Step 5: Building and launching the application...${NC}"
echo "This may take a few minutes the first time."
# No 'sudo' is needed here because the user is in the 'docker' group.
docker compose up --build -d

# --- Final Message ---
echo ""
echo -e "${GREEN}--- DEPLOYMENT COMPLETE ---${NC}"
echo ""
echo "The application containers are running in the background."
echo "Please wait about a minute for them to fully initialize."
echo ""
echo -e "You can now access the dashboard from your Windows browser at: ${YELLOW}http://localhost${NC}"
echo "(This requires port forwarding to be set up in VirtualBox settings)."
echo ""
echo -e "To view logs, run: ${GREEN}docker compose logs -f${NC}"
echo -e "To stop the app, run: ${GREEN}docker compose down${NC}"
echo ""