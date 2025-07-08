#!/bin/bash

# ==============================================================================
# DocIntellect Setup Script (v8.0 - Surgical Strike)
# ==============================================================================
# This definitive script solves the conflicting Docker installation problem by
# explicitly using the full path to the correct Docker Desktop executable,
# bypassing any system-level PATH issues.
# ==============================================================================

# --- Style and Color Definitions ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Main Setup Logic ---
echo -e "${GREEN}--- DocIntellect Automated Setup & Launch ---${NC}"
echo ""

# --- Step 0: Pre-flight Check ---
echo -e "${YELLOW}--- Performing System Pre-flight Check ---${NC}"
DOCKER_DESKTOP_CMD="/usr/local/bin/docker"

if ! [ -f "$DOCKER_DESKTOP_CMD" ]; then
    echo -e "${RED}FATAL ERROR: Docker Desktop is not correctly integrated with WSL.${NC}"
    echo "The required command at '$DOCKER_DESKTOP_CMD' was not found."
    echo ""
    echo -e "${YELLOW}Please ensure Docker Desktop is running and WSL integration is enabled for your Ubuntu distribution in Docker Desktop's Settings > Resources.${NC}"
    exit 1
fi
echo -e "${GREEN}System check passed. Docker Desktop command found.${NC}"
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
echo "This will use the correct Docker from Docker Desktop at '$DOCKER_DESKTOP_CMD'"
echo "This may take several minutes the first time."

# Use the full path to the correct Docker command to bypass any conflicts.
if sudo "$DOCKER_DESKTOP_CMD" compose up --build -d; then
    # --- Success Message ---
    echo ""
    echo -e "${GREEN}--- DEPLOYMENT COMPLETE ---${NC}"
    echo ""
    echo "The application is running. Wait about a minute for it to initialize."
    echo -e "Dashboard: ${YELLOW}http://localhost${NC}"
    echo ""
    echo -e "${YELLOW}IMPORTANT:${NC} To manage your app from the command line, always use the full path:"
    echo -e "View Logs: ${GREEN}sudo /usr/local/bin/docker compose logs -f${NC}"
    echo -e "Stop App:  ${GREEN}sudo /usr/local/bin/docker compose down${NC}"
    echo ""
else
    # --- Failure Message ---
    echo ""
    echo -e "${RED}--- DOCKER BUILD FAILED ---${NC}"
    echo -e "The build process failed. Please check the error messages above."
    echo ""
    exit 1
fi