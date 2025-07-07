#!/bin/bash

# ==============================================================================
# DocIntellect Local Setup & Configuration Script (v3.3 - Ubuntu 24.04+ Fix)
# ==============================================================================
# This script is updated to handle package name changes in modern Linux
# distributions like Ubuntu 24.04, where 'python3-distutils' is obsolete
# and has been replaced by 'python3-setuptools'.
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

# Check if required files exist
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
sudo -v # Prompt for password upfront
sudo apt-get update -y
# On Ubuntu 24.04+, python3-distutils is replaced by python3-setuptools.
# python3-dev is added for build robustness.
sudo apt-get install -y default-jre python3-pip python3-venv python3-setuptools python3-dev build-essential
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
    python create_dummy_model.py
    echo "Model 'model.pkl' created."
else
    echo -e "${RED}Warning: 'create_dummy_model.py' not found. Ensure a valid 'model.pkl' exists.${NC}"
fi
echo ""

# Deactivate the virtual environment
deactivate
echo "Local setup steps are complete."

# --- Final Instructions ---
echo -e "${GREEN}--- SETUP COMPLETE ---${NC}"
echo ""
echo -e "${YELLOW}!!! IMPORTANT: FINAL STEPS REQUIRED !!!${NC}"
echo ""
echo -e "1. ${YELLOW}Configure Drives:${NC} Edit 'docker-compose.yml' to add your document folders."
echo "   Command: ${GREEN}nano docker-compose.yml${NC}"
echo ""
echo -e "2. ${YELLOW}Launch App:${NC} Run this command from the current directory:"
echo "   ${GREEN}docker-compose up --build -d${NC}"
echo ""
echo -e "3. ${YELLOW}Access Dashboard:${NC} Open your browser to ${GREEN}http://localhost${NC}"
echo ""