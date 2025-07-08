#!/bin/bash

# ==============================================================================
# DocIntellect Automated Setup & Launch Script (v6.0 - Final)
# ==============================================================================
# This script prepares the local environment AND launches the application.
# It uses Python 3.10 in the Dockerfile to ensure full dependency compatibility.
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

# --- Step 1: Local Environment Setup ---
echo -e "${YELLOW}Step 1: Preparing local environment for one-time setup...${NC}"
# (This section is minimal as the main app runs in Docker)
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
echo "Local setup complete. Model file 'model.pkl' created."
echo ""

# --- Step 2: Interactive Configuration ---
echo -e "${YELLOW}Step 2: Please Configure Your Document Drives${NC}"
echo "The application needs to know where your documents are."
echo "The file 'docker-compose.yml' will now be opened with 'nano'."
echo ""
echo -e "-> Find the 'volumes:' section under 'web'."
echo -e "-> Add lines for your drives (e.g., '- /mnt/d:/scan-targets/d_drive:ro')."
echo -e "-> Press ${GREEN}Ctrl+X${NC}, then ${GREEN}Y${NC}, then ${GREEN}Enter${NC} to save and exit."
echo ""
read -p "Press [Enter] to open docker-compose.yml now..."

# Open nano for the user to edit the file
nano docker-compose.yml

echo "Configuration file saved."
echo ""

# --- Step 3: Build and Launch Application ---
echo -e "${YELLOW}Step 3: Building and launching the application with Docker...${NC}"
echo "This may take several minutes the first time."
# Use sudo as docker-compose often requires it.
sudo docker-compose up --build -d

# --- Final Message ---
echo ""
echo -e "${GREEN}--- DEPLOYMENT COMPLETE ---${NC}"
echo ""
echo "The application containers are starting up in the background."
echo "Please wait about a minute for them to fully initialize."
echo ""
echo -e "You can now access the dashboard at: ${YELLOW}http://localhost${NC}"
echo ""
echo -e "To view logs, run: ${GREEN}sudo docker-compose logs -f${NC}"
echo -e "To stop the app later, run: ${GREEN}sudo docker-compose down${NC}"
echo ""