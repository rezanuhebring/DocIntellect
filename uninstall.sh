#!/bin/bash

# ==============================================================================
# DocIntellect Uninstaller Script (for VirtualBox VM)
# ==============================================================================
# This script stops and removes all components of the application.

# --- Style and Color Definitions ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- Initial Safety Checks ---
echo -e "${YELLOW}--- DocIntellect Uninstaller ---${NC}"
read -p "Are you sure you want to stop and remove application components? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY]) ;;
    *) echo "Uninstallation aborted."; exit 0 ;;
esac
echo ""

if ! [ -f "docker-compose.yml" ]; then
    echo -e "${RED}Error: 'docker-compose.yml' not found. Run this from the project root.${NC}"; exit 1
fi

# --- Step 1: Stop and Remove Docker Components ---
echo -e "${YELLOW}Step 1: Stopping containers and removing images/networks...${NC}"
# Use '--rmi all' to remove the custom-built images (web and tika)
docker compose down --rmi all
echo "Containers, networks, and custom images removed."
echo ""

# --- Step 2: Remove the Database File ---
echo -e "${YELLOW}Step 2: Handling the database file...${NC}"
if [ -f "database.db" ]; then
    read -p "Delete the database file ('database.db')? [y/N] " del_db
    case "$del_db" in
        [yY][eE][sS]|[yY]) rm -f database.db*; echo "Database deleted." ;;
        *) echo "Database kept." ;;
    esac
else
    echo "No database file found."
fi
echo ""

# --- Final Message ---
echo -e "${GREEN}--- UNINSTALLATION COMPLETE ---${NC}"
echo "The project directory itself has been kept."