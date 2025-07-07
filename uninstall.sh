#!/bin/bash

# ==============================================================================
# DocIntellect Uninstaller Script
# ==============================================================================
# This script will stop and remove all components of the DocIntellect
# application, including Docker containers, networks, and optionally, the
# database, custom Docker image, and the project directory itself.
# ==============================================================================

# --- Style and Color Definitions ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Initial Safety Checks ---
echo -e "${YELLOW}--- DocIntellect Uninstaller ---${NC}"
echo ""
echo -e "${RED}WARNING: This script will stop and permanently remove application components.${NC}"
read -p "Are you sure you want to proceed? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY])
        # Continue with the script
        ;;
    *)
        echo "Uninstallation aborted by user."
        exit 0
        ;;
esac
echo ""

# Verify we are in the correct directory
if ! [ -f "docker-compose.yml" ]; then
    echo -e "${RED}Error: 'docker-compose.yml' not found.${NC}"
    echo "Please run this script from the root of the DocIntellect project directory."
    exit 1
fi

# --- Step 1: Stop and Remove Docker Containers & Networks ---
echo -e "${YELLOW}Step 1: Stopping and removing Docker containers and networks...${NC}"
if [ "$(docker-compose ps -q)" ]; then
    docker-compose down
    echo "Containers and networks have been successfully removed."
else
    echo "No running containers found for this project. Skipping."
fi
echo ""

# --- Step 2: Remove the Database File ---
echo -e "${YELLOW}Step 2: Handling the database file...${NC}"
if [ -f "database.db" ]; then
    read -p "Do you want to permanently delete the database file ('database.db')? [y/N] " del_db
    case "$del_db" in
        [yY][eE][sS]|[yY])
            rm -f database.db database.db-journal
            echo "Database file deleted."
            ;;
        *)
            echo "Database file has been kept."
            ;;
    esac
else
    echo "No database file found to delete."
fi
echo ""

# --- Step 3: Remove the Custom Docker Image ---
# Construct the image name based on the directory name (e.g., 'docintellect_web')
IMAGE_NAME=$(basename "$PWD" | tr '[:upper:]' '[:lower:]')_web
echo -e "${YELLOW}Step 3: Handling the custom Docker image...${NC}"
# Check if the image exists
if docker image inspect "$IMAGE_NAME" &> /dev/null; then
    read -p "Do you want to remove the custom Docker image ('$IMAGE_NAME') to free up disk space? [y/N] " del_image
    case "$del_image" in
        [yY][eE][sS]|[yY])
            docker rmi "$IMAGE_NAME"
            echo "Docker image '$IMAGE_NAME' removed."
            ;;
        *)
            echo "Docker image has been kept."
            ;;
    esac
else
    echo "No custom Docker image named '$IMAGE_NAME' found."
fi
echo ""

# --- Step 4: Remove the Project Directory ---
echo -e "${YELLOW}Step 4: Handling the project directory...${NC}"
read -p "Do you want to permanently delete the entire project directory ('$(pwd)')? THIS CANNOT BE UNDONE. [y/N] " del_dir
case "$del_dir" in
    [yY][eE][sS]|[yY])
        echo "Removing project directory..."
        # Store the directory path, move out of it, then delete it
        PROJECT_PATH=$(pwd)
        cd ..
        rm -rf "$PROJECT_PATH"
        echo -e "${GREEN}Project directory has been successfully deleted.${NC}"
        echo -e "${GREEN}--- UNINSTALLATION COMPLETE ---${NC}"
        exit 0
        ;;
    *)
        echo "Project directory has been kept."
        ;;
esac
echo ""

# --- Final Message ---
echo -e "${GREEN}--- UNINSTALLATION COMPLETE ---${NC}"
echo "All selected components have been removed."
echo "If you chose not to delete the project directory, you can remove it manually with 'rm -rf $(pwd)'"