#!/bin/bash

# ==============================================================================
# DocIntellect Setup Script (v7.0 - Hardened Environment Check)
# ==============================================================================
# This script includes a pre-flight check that REFUSES to run if it detects
# a conflicting native Docker installation, providing precise cleanup commands.
# ==============================================================================

# --- Style and Color Definitions ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Step 0: Pre-flight Environment Check ---
echo -e "${YELLOW}--- Performing System Pre-flight Check ---${NC}"

# Check for the correct Docker installation from Docker Desktop.
# It should be located at /usr/local/bin/docker.
CORRECT_DOCKER_PATH="/usr/local/bin/docker"
if ! command -v docker >/dev/null || [[ "$(which docker)" != "$CORRECT_DOCKER_PATH" ]]; then
    echo -e "${RED}FATAL ERROR: A conflicting Docker installation was found.${NC}"
    echo "Your system is using a native Linux Docker instead of the one from Docker Desktop."
    echo ""
    echo -e "${YELLOW}To fix this permanently, please run these commands in your WSL terminal:${NC}"
    echo "1. Purge all conflicting packages:"
    echo -e "   ${GREEN}sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker.io docker-doc docker-compose podman-docker containerd runc${NC}"
    echo ""
    echo "2. Manually remove the incorrect Docker binary if it still exists:"
    echo -e "   ${GREEN}if [ -f /usr/bin/docker ]; then sudo rm /usr/bin/docker; fi${NC}"
    echo ""
    echo "3. Restart Docker Desktop on Windows and re-open this WSL terminal."
    echo ""
    echo "After completing these steps, you can run this setup script again."
    exit 1
fi
echo -e "${GREEN}System check passed. Docker Desktop integration is correct.${NC}"
echo ""


# --- Main Setup Logic ---
echo -e "${GREEN}--- DocIntellect Automated Setup & Launch ---${NC}"
echo ""

# --- Step 1: Local Environment Setup ---
echo -e "${YELLOW}Step 1: Preparing local environment...${NC}"
sudo -v
sudo apt-get update -y > /dev/null
sudo apt-get install -y python3-pip python3-venv > /dev/null
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip > /dev/null
pip install scikit-learn==1.5.0 > /dev/null
python create_dummy_model.py
deactivate
echo "Local setup complete."
echo ""

# --- Step 2: Interactive Configuration ---
echo -e "${YELLOW}Step 2: Please Configure Your Document Drives${NC}"
echo "The file 'docker-compose.yml' will be opened with 'nano'."
read -p "Press [Enter] to open docker-compose.yml now..."

nano docker-compose.yml

echo "Configuration file saved."
echo ""

# --- Step 3: Build and Launch Application ---
echo -e "${YELLOW}Step 3: Building and launching the application with Docker...${NC}"
echo "This may take several minutes the first time."

# Use modern 'docker compose' syntax
if sudo docker compose up --build -d; then
    # --- Success Message ---
    echo ""
    echo -e "${GREEN}--- DEPLOYMENT COMPLETE ---${NC}"
    echo ""
    echo "The application is running. Wait a minute for it to initialize."
    echo -e "Dashboard: ${YELLOW}http://localhost${NC}"
    echo -e "View Logs: ${GREEN}sudo docker compose logs -f${NC}"
    echo -e "Stop App:  ${GREEN}sudo docker compose down${NC}"
    echo ""
else
    # --- Failure Message ---
    echo ""
    echo -e "${RED}--- DOCKER BUILD FAILED ---${NC}"
    echo -e "The build process failed. Please check the error messages above."
    echo ""
    exit 1
fi