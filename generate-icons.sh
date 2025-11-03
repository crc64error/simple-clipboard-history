#!/bin/bash

# Icon Generation Script for Simple Clipboard History
# Converts a master SVG icon to all required PNG sizes for macOS

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SVG_SOURCE="${1:-$SCRIPT_DIR/icon-source/app-icon.svg}"
OUTPUT_DIR="$SCRIPT_DIR/Simple Clipboard History/Assets.xcassets/AppIcon.appiconset"

# Check if source SVG exists
if [ ! -f "$SVG_SOURCE" ]; then
    echo -e "${RED}Error: SVG source file not found: $SVG_SOURCE${NC}"
    echo "Usage: ./generate-icons.sh [path-to-svg]"
    echo "Default: ./icon-source/app-icon.svg"
    exit 1
fi

# Check for required tools
if ! command -v rsvg-convert &> /dev/null; then
    echo -e "${RED}Error: rsvg-convert not found${NC}"
    echo "Install with: brew install librsvg"
    exit 1
fi

echo -e "${GREEN}Generating app icons from: $SVG_SOURCE${NC}"
echo ""

# macOS icon sizes needed
# Format: base_size filename pixel_size
SIZES=(
    "16x16 icon_16x16.png 16"
    "16x16@2x icon_16x16@2x.png 32"
    "32x32 icon_32x32.png 32"
    "32x32@2x icon_32x32@2x.png 64"
    "128x128 icon_128x128.png 128"
    "128x128@2x icon_128x128@2x.png 256"
    "256x256 icon_256x256.png 256"
    "256x256@2x icon_256x256@2x.png 512"
    "512x512 icon_512x512.png 512"
    "512x512@2x icon_512x512@2x.png 1024"
)

# Generate each size
for size_info in "${SIZES[@]}"; do
    read -r label filename pixel_size <<< "$size_info"
    output_path="$OUTPUT_DIR/$filename"

    echo -e "${YELLOW}Generating ${filename} (${pixel_size}px)...${NC}"
    rsvg-convert -w $pixel_size -h $pixel_size "$SVG_SOURCE" -o "$output_path"
done

# Update Contents.json with filenames
cat > "$OUTPUT_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo ""
echo -e "${GREEN}✓ Icon generation complete!${NC}"
echo "Generated 10 PNG files in: $OUTPUT_DIR"
echo ""
echo "Next steps:"
echo "1. Open Xcode and verify the icons appear in Assets.xcassets"
echo "2. Clean build folder (Cmd+Shift+K)"
echo "3. Rebuild the app"
