#!/bin/bash

# Simple Clipboard History Build Script
# This script builds the app and optionally copies it to /Applications

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="Simple Clipboard History"
SCHEME="Simple Clipboard History"
CONFIGURATION="${1:-Release}"  # Default to Release, or use first argument

echo -e "${GREEN}Building ${PROJECT_NAME}...${NC}"
echo "Configuration: $CONFIGURATION"
echo ""

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Error: Xcode is not installed or xcodebuild is not in PATH${NC}"
    echo "Please install Xcode from the Mac App Store"
    exit 1
fi

# Clean build folder
echo -e "${YELLOW}Cleaning build folder...${NC}"
xcodebuild -project "${PROJECT_NAME}.xcodeproj" \
           -scheme "$SCHEME" \
           -configuration "$CONFIGURATION" \
           clean

# Build the app
echo -e "${YELLOW}Building app...${NC}"
xcodebuild -project "${PROJECT_NAME}.xcodeproj" \
           -scheme "$SCHEME" \
           -configuration "$CONFIGURATION" \
           build

# Find the built app
BUILD_DIR=~/Library/Developer/Xcode/DerivedData
APP_PATH=$(find "$BUILD_DIR" -name "${PROJECT_NAME}.app" -path "*/$CONFIGURATION/*" | head -n 1)

if [ -z "$APP_PATH" ]; then
    echo -e "${RED}Error: Could not find built app${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Build successful!${NC}"
echo "App location: $APP_PATH"
echo ""

# Ask if user wants to copy to Applications
read -p "Copy to /Applications? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Remove existing app if it exists
    if [ -d "/Applications/${PROJECT_NAME}.app" ]; then
        echo -e "${YELLOW}Removing existing app from /Applications...${NC}"
        rm -rf "/Applications/${PROJECT_NAME}.app"
    fi

    # Copy to Applications
    echo -e "${YELLOW}Copying to /Applications...${NC}"
    cp -R "$APP_PATH" /Applications/

    echo -e "${GREEN}✓ Installed to /Applications/${PROJECT_NAME}.app${NC}"
    echo ""
    echo -e "${YELLOW}Important:${NC} On first launch, you'll need to:"
    echo "1. Right-click the app and select 'Open' (to bypass Gatekeeper)"
    echo "2. Grant Accessibility permissions in System Settings"
    echo "   → Privacy & Security → Accessibility"
    echo ""

    # Ask if user wants to launch the app
    read -p "Launch the app now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "/Applications/${PROJECT_NAME}.app"
        echo -e "${GREEN}✓ App launched!${NC}"
    fi
else
    echo -e "${YELLOW}App not copied to /Applications${NC}"
    echo "You can manually copy it from: $APP_PATH"
fi

echo ""
echo -e "${GREEN}Done!${NC}"
