# Building Simple Clipboard History

This guide walks you through building the app from source, from opening the project to installing it on your Mac.

## Prerequisites

Before you begin, ensure you have:

- **macOS 13.0 (Ventura) or later**
- **Xcode 14.0 or later** (download from the Mac App Store)
- **An Apple Developer account** (free tier works fine)
  - You'll need this for code signing
  - Sign up at [developer.apple.com](https://developer.apple.com)

## Step-by-Step Build Instructions

### 1. Get the Source Code

```bash
# Clone the repository
git clone https://github.com/yourusername/simple-clipboard-history.git

# Navigate to the project directory
cd simple-clipboard-history
```

### 2. Open the Project in Xcode

```bash
# Open the Xcode project
open "Simple Clipboard History.xcodeproj"
```

Alternatively, you can:
- Launch Xcode
- Select "Open a project or file"
- Navigate to `Simple Clipboard History.xcodeproj` and open it

### 3. Configure Code Signing

Code signing is required for the app to run on macOS.

1. **Select the Project**
   - In the left sidebar (Project Navigator), click the top-level project icon
   - It should be named "Simple Clipboard History"

2. **Select the Target**
   - In the main editor area, you'll see "TARGETS" list
   - Select "Simple Clipboard History" (the app icon)

3. **Go to Signing & Capabilities Tab**
   - Click the "Signing & Capabilities" tab at the top

4. **Configure Your Team**
   - Find "Team" dropdown
   - Select your Apple ID / team
   - If you don't see your team:
     - Click "Add an Account..."
     - Sign in with your Apple ID
     - Return to this dropdown

5. **Automatic Signing** (Recommended)
   - Ensure "Automatically manage signing" is checked
   - Xcode will create a provisioning profile automatically
   - You should see "Provisioning Profile: Xcode Managed Profile"

### 4. Build the App

#### Option A: Build for Testing (Debug)

```bash
# Build from command line
xcodebuild -project "Simple Clipboard History.xcodeproj" \
           -scheme "Simple Clipboard History" \
           -configuration Debug \
           build
```

Or in Xcode:
- Press `Command+B`
- Or: Menu bar → `Product` → `Build`

The app will be built to:
```
~/Library/Developer/Xcode/DerivedData/Simple_Clipboard_History-*/Build/Products/Debug/Simple Clipboard History.app
```

#### Option B: Build for Release

For a production-ready build:

```bash
# Build Release version
xcodebuild -project "Simple Clipboard History.xcodeproj" \
           -scheme "Simple Clipboard History" \
           -configuration Release \
           build
```

Or in Xcode:
- Menu bar → `Product` → `Scheme` → `Edit Scheme`
- Select "Run" in the left sidebar
- Change "Build Configuration" to "Release"
- Close the dialog
- Press `Command+B` to build

The Release build will be at:
```
~/Library/Developer/Xcode/DerivedData/Simple_Clipboard_History-*/Build/Products/Release/Simple Clipboard History.app
```

### 5. Run the App

#### From Xcode (easiest for development)

- Press `Command+R`
- Or: Menu bar → `Product` → `Run`

The app will launch with the debugger attached. You can see console output in Xcode.

#### From Finder

1. Find the built app:
   ```bash
   # For Debug builds
   cd ~/Library/Developer/Xcode/DerivedData
   find . -name "Simple Clipboard History.app" -path "*/Debug/*"
   ```

2. Double-click the app to run it

### 6. Grant Permissions

On first launch, the app needs Accessibility permissions to function properly.

1. **You'll see an error or the auto-paste won't work**

2. **Open System Settings**
   - Apple menu → System Settings
   - Or: Command+Space, type "System Settings"

3. **Navigate to Accessibility**
   - Click "Privacy & Security" in the sidebar
   - Click "Accessibility"

4. **Grant Permission**
   - Click the lock icon and authenticate
   - Find "Simple Clipboard History" in the list
   - Toggle it ON
   - If you don't see it, click the "+" button and add it

5. **Restart the App**
   - Quit and relaunch
   - The app should now work fully

### 7. Install to Applications Folder

#### Option A: Manual Copy

```bash
# Find the built app
cd ~/Library/Developer/Xcode/DerivedData
APP_PATH=$(find . -name "Simple Clipboard History.app" -path "*/Release/*" | head -n 1)

# Copy to Applications
cp -R "$APP_PATH" /Applications/
```

#### Option B: Create an Archive

This is the "official" way to create a distributable app:

1. **In Xcode**:
   - Menu bar → `Product` → `Archive`
   - Wait for the build to complete
   - The Organizer window will open

2. **Distribute the App**:
   - Select your archive
   - Click "Distribute App"
   - Choose "Copy App"
   - Choose a destination folder
   - Click "Export"

3. **Install**:
   ```bash
   # Copy to Applications
   cp -R ~/Desktop/SimpleClipboardHistory.app /Applications/
   ```

## Troubleshooting

### Build Errors

#### "No signing certificate found"

**Solution**:
- Xcode → Settings → Accounts
- Select your Apple ID
- Click "Manage Certificates"
- Click "+" → "Apple Development"
- Return to project settings and reselect your team

#### "Command line tools not found"

**Solution**:
```bash
# Install command line tools
xcode-select --install
```

#### "Unable to find className=(null)" warning

This is harmless and has been fixed in the code. If you see it:
- Pull the latest code
- Clean build folder: `Command+Shift+K`
- Rebuild

### Runtime Errors

#### App won't launch / crashes immediately

**Solution**:
- Check Console.app for crash logs
- Ensure you granted Accessibility permissions
- Try a clean build: `Product` → `Clean Build Folder`

#### Hotkey doesn't work

**Solution**:
- Grant Accessibility permissions (see step 6)
- Check if another app is using Shift+Command+V
- Restart the app after granting permissions

#### "App is damaged" error

**Solution**:
This happens when code signing fails. Try:
```bash
# Remove quarantine flag
xattr -cr "/Applications/Simple Clipboard History.app"
```

Or rebuild with proper code signing.

## Advanced: Creating a Distributable Build

For sharing with others, you'll need to notarize the app with Apple.

### 1. Create an App-Specific Password

1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign in
3. Security → App-Specific Passwords
4. Generate a new password
5. Save it securely

### 2. Create Keychain Entry

```bash
xcrun notarytool store-credentials "notarytool-password" \
  --apple-id "your-apple-id@email.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "app-specific-password"
```

### 3. Archive and Export

```bash
# Archive
xcodebuild -project "Simple Clipboard History.xcodeproj" \
           -scheme "Simple Clipboard History" \
           -configuration Release \
           -archivePath ./build/SimpleClipboardHistory.xcarchive \
           archive

# Export
xcodebuild -exportArchive \
           -archivePath ./build/SimpleClipboardHistory.xcarchive \
           -exportPath ./build \
           -exportOptionsPlist ExportOptions.plist
```

### 4. Create ExportOptions.plist

Create a file named `ExportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
</dict>
</plist>
```

### 5. Notarize

```bash
# Zip the app
ditto -c -k --keepParent "./build/Simple Clipboard History.app" "./build/SimpleClipboardHistory.zip"

# Submit for notarization
xcrun notarytool submit "./build/SimpleClipboardHistory.zip" \
  --keychain-profile "notarytool-password" \
  --wait

# Staple the notarization
xcrun stapler staple "./build/Simple Clipboard History.app"
```

### 6. Create DMG (Optional)

```bash
# Install create-dmg (if not already installed)
brew install create-dmg

# Create DMG
create-dmg \
  --volname "Simple Clipboard History" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "Simple Clipboard History.app" 175 120 \
  --hide-extension "Simple Clipboard History.app" \
  --app-drop-link 425 120 \
  "SimpleClipboardHistory.dmg" \
  "./build/Simple Clipboard History.app"
```

## Homebrew Distribution (Future)

To distribute via Homebrew:

1. Create a signed, notarized release
2. Upload to GitHub Releases
3. Create a Homebrew cask formula
4. Submit to homebrew-cask repository

Detailed instructions will be added when this becomes available.

## Questions?

- Open an [issue on GitHub](https://github.com/yourusername/simple-clipboard-history/issues)
- Check existing [discussions](https://github.com/yourusername/simple-clipboard-history/discussions)

---

**Happy Building! 🛠️**
