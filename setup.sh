#!/bin/bash

# ==============================================================================
# DocIntellect Automated Setup & Launch Script (v6.2 - Modern Docker Compose)
# ==============================================================================
# This definitive script uses the modern 'docker compose' (with a space) syntax
# to ensure full compatibility with Docker Desktop and its integrated tools.
# ==============================================================================

# --- Style and Color Definitions ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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
echo -e "-> Find the 'volumes:' section and add lines for your drives."
echo -e "-> Press ${GREEN}Ctrl+X${NC}, then ${GREEN}Y${NC}, then ${GREEN}Enter${NC} to save and exit."
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
    echo -e "If you see network errors, ensure the DNS fix in Docker Desktop settings has been applied and Docker has been restarted."
    echo ""
    exit 1
fi