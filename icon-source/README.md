# App Icon Source

This directory contains the master SVG icon for Simple Clipboard History (Wayfarer Works).

## Workflow

1. **Edit the icon**: `app-icon.svg`
   - Use Inkscape or hand-code in VSCode
   - Master size: 1024x1024
   - Keep it clean and scalable

2. **Generate PNG assets**:
   ```bash
   ./generate-icons.sh
   ```

3. **Install librsvg** (if not already installed):
   ```bash
   brew install librsvg
   ```

## Current Design

The starter icon features:
- **Clipboard** with a layered "history stack" effect
- **Blue gradient** (Wayfarer Works brand colors - customize as needed)
- **Text lines** representing clipboard entries
- **History indicator** (clock/arrow) in the corner

## Customization Ideas

### For Wayfarer Works branding:
- Add a compass or waypoint symbol
- Use brand colors
- Incorporate journey/path elements

### Design tips:
- Keep it simple at 16px size (test the small versions!)
- Use bold, clear shapes
- Avoid fine details that disappear when scaled down
- macOS icons typically use subtle gradients and shadows

## SVG Structure

The icon is organized into clean groups:
- `#history-stack` - Background layered papers
- `#main-clipboard` - Primary clipboard shape
- `#clip` - Metal clip at top
- `#text-lines` - Content representation
- `#history-icon` - History indicator badge

All easily modifiable in the SVG code!

## Testing

After generating icons:
1. Open Xcode
2. Check Assets.xcassets → AppIcon
3. Clean build folder (Cmd+Shift+K)
4. Rebuild and run

## Version Control

- Keep `app-icon.svg` in version control
- The generated PNGs can be ignored or committed (your choice)
- Document brand color codes here as you finalize them
