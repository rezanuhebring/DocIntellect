#!/bin/bash

# ==============================================================================
# DocIntellect Local Setup Script (v9.0 - WSL-Only Prep)
# ==============================================================================
# This script ONLY prepares the local files (virtual environment and model).
# The Docker commands will be run from Windows PowerShell to bypass the
# broken WSL integration issue.
# ==============================================================================

# --- Style and Color Definitions ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

set -e

echo -e "${GREEN}--- DocIntellect WSL Preparation ---${NC}"
echo ""

# --- Step 1: Prepare Local Python Environment ---
echo -e "${YELLOW}Step 1: Preparing local Python environment...${NC}"
sudo -v
sudo apt-get update -y > /dev/null
sudo apt-get install -y python3-pip python3-venv > /dev/null
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip > /dev/null
pip install scikit-learn==1.5.0 > /dev/null
echo "Local Python environment is ready."
echo ""

# --- Step 2: Create Initial Model ---
echo -e "${YELLOW}Step 2: Creating the initial machine learning model...${NC}"
python create_dummy_model.py
deactivate
echo "Model file 'model.pkl' created."
echo ""

# --- Final Instructions ---
echo -e "${GREEN}--- WSL PREPARATION COMPLETE ---${NC}"
echo ""
echo -e "${YELLOW}!!! ACTION REQUIRED IN POWERSHELL !!!${NC}"
echo "The local files are ready. The next steps MUST be done in a Windows PowerShell terminal."
echo ""
echo "1. Open the Windows Start Menu and type ${GREEN}PowerShell${NC}. Open it."
echo "2. Copy and paste the following commands into PowerShell to launch the application."
echo ""