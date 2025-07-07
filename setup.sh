#!/bin/bash

# ==============================================================================
# DocIntellect Local Setup & Configuration Script (v4.0 - Final)
# ==============================================================================
# This definitive script handles modern Linux packaging changes and ensures
# pip's own tools are up-to-date before installing project dependencies,
# providing the most reliable setup experience.
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

if ! [ -f "docker-compose.yml" ]; then
    echo -e "${RED}Error: Critical files not found.${NC}"
    echo "Please run this script from the project root directory."
    exit 1
fi
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed.${NC}"
    echo "Please install Docker Desktop and ensure it's running."
    exit 1
fi
echo "Environment verified."
echo ""

# --- Step 2: Install System Dependencies ---
echo -e "${YELLOW}Step 2: Installing required system packages...${NC}"
echo "This step may require your password for 'sudo'."
sudo -v
sudo apt-get update -y
sudo apt-get install -y default-jre python3-pip python3-venv python3-setuptools python3-dev build-essential
echo "System dependencies installed."
echo ""

# --- Step 3: Create Virtual Environment and Install Dependencies ---
VENV_DIR="venv"
echo -e "${YELLOW}Step 3: Setting up Python virtual environment in './$VENV_DIR'...${NC}"

if [ -d "$VENV_DIR" ]; then
    echo "Removing existing virtual environment to ensure a clean slate."
    rm -rf "$VENV_DIR"
fi

python3 -m venv "$VENV_DIR"
echo "Virtual environment created."

# Activate the venv for the subsequent commands
source "$VENV_DIR/bin/activate"

# BEST PRACTICE: Upgrade pip's own tools first
echo "Upgrading pip, setuptools, and wheel..."
pip install --upgrade pip setuptools wheel

# Now, install the project requirements
echo "Installing Python dependencies from requirements.txt..."
pip install -r requirements.txt
echo "Python packages installed."
echo ""

# --- Step 4: Build Initial Model ---
echo -e "${YELLOW}Step 4: Building the initial machine learning model...${NC}"
python create_dummy_model.py
echo "Model 'model.pkl' created."
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