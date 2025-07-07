#!/bin/bash

# ==============================================================================
# DocIntellect Local Setup & Configuration Script (v3.2 - Python 3.12+ Fix)
# ==============================================================================
# This script handles the "externally-managed-environment" error and the
# missing 'distutils' module in Python 3.12.
# ==============================================================================

# --- Style and Color Definitions ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Main Setup Logic ---
echo -e "${GREEN}--- DocIntellect Local Setup ---${NC}"
echo ""

# --- Step 1: Verify Location and Base Dependencies ---
echo -e "${YELLOW}Step 1: Verifying environment...${NC}"

# Check if required files exist, ensuring the script is run from the project root
if ! [ -f "docker-compose.yml" ] || ! [ -f "requirements.txt" ]; then
    echo -e "${RED}Error: Critical files not found.${NC}"
    echo "Please make sure you are running this script from the root of the cloned DocIntellect project directory."
    exit 1
fi

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed.${NC}"
    echo "Please install Docker Desktop for Windows and ensure it's running with the WSL 2 backend."
    exit 1
fi
echo "Environment verified successfully."
echo ""

# --- Step 2: Install System Dependencies ---
echo -e "${YELLOW}Step 2: Installing required system packages...${NC}"
echo "This step may require you to enter your password for 'sudo'."
# Use 'sudo -v' to prompt for the password upfront if needed.
sudo -v
# Update package list and install dependencies non-interactively
sudo apt-get update -y
# 'python3-distutils' is now added to fix build issues on Python 3.12+
sudo apt-get install -y default-jre python3-pip python3-venv python3-distutils build-essential
echo "System dependencies installed."
echo ""

# --- Step 3: Create Virtual Environment and Install Python Packages ---
VENV_DIR="venv"
echo -e "${YELLOW}Step 3: Creating Python virtual environment in './$VENV_DIR'...${NC}"

if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
    echo "Virtual environment created."
else
    echo "Virtual environment already exists. Skipping creation."
fi

# Activate the venv for the subsequent commands
source "$VENV_DIR/bin/activate"

echo "Installing Python dependencies from requirements.txt into the virtual environment..."
pip install -r requirements.txt
echo "Python packages installed."
echo ""

# --- Step 4: Build Initial Model ---
echo -e "${YELLOW}Step 4: Building the initial machine learning model...${NC}"
if [ -f "create_dummy_model.py" ]; then
    # The 'python' command now correctly refers to the interpreter inside the venv
    python create_dummy_model.py
    echo "Model 'model.pkl' created."
else
    echo -e "${RED}Warning: 'create_dummy_model.py' not found. Ensure a valid 'model.pkl' exists.${NC}"
fi
echo ""

# Deactivate the virtual environment, as its purpose is served
deactivate
echo "Local setup steps are complete. The virtual environment is no longer active."

# --- Final Instructions ---
echo -e "${GREEN}--- SETUP COMPLETE ---${NC}"
echo ""
echo -e "${YELLOW}!!! IMPORTANT: FINAL STEPS REQUIRED !!!${NC}"
echo "Your local environment is ready. Please complete the following to run the app:"
echo ""
echo -e "1. ${YELLOW}Configure Your Drives for Scanning:${NC}"
echo "   You must edit 'docker-compose.yml' to tell the app which folders to scan."
echo "   Open the file with your favorite editor:"
echo "   ${GREEN}nano docker-compose.yml${NC}"
echo "   Find the 'volumes' section and add paths to your document drives/folders."
echo "   Detailed examples are provided inside the file. Save and exit when done."
echo ""
echo -e "2. ${YELLOW}Launch the Application:${NC}"
echo "   Once you have configured the drives, run this command from the current directory:"
echo "   ${GREEN}docker-compose up --build -d${NC}"
echo ""
echo -e "3. ${YELLOW}Access the Dashboard:${NC}"
echo "   Wait about a minute for the services to start, then open your web browser and go to:"
echo "   ${GREEN}http://localhost${NC}"
echo ""