# Simple Clipboard History

A lightweight, native macOS clipboard manager built with Swift, designed as both a functional tool and an educational resource for learning macOS development.

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## 🎯 Overview

Simple Clipboard History is a menu bar app that automatically saves your last 10 clipboard items, allowing you to quickly access and paste previous copies. Press `Shift+Command+V` to bring up your clipboard history and select items using number keys 1-9 and 0.

This project was created as a modern, native alternative to older clipboard managers like [Clipy](https://github.com/Clipy/Clipy), which haven't been updated in years and may not be optimized for Apple Silicon Macs. While this is entirely fresh code, we owe a debt of gratitude to Clipy and similar projects for pioneering the clipboard manager concept on macOS.

## 📚 Learning Resource

**This is a heavily documented educational project!** If you're learning Swift and macOS development, this codebase is designed for you. Every file contains extensive inline documentation explaining:

- **Swift Fundamentals**: Optionals, closures, protocols, structs vs classes, memory management
- **macOS APIs**: Cocoa, AppKit, Carbon, Core Graphics, ServiceManagement
- **Design Patterns**: Delegation, MVC, notification observers
- **Advanced Topics**: C interop, global hotkeys, event handling, bitwise operations
- **Best Practices**: Access control, error handling, resource cleanup

Each method includes detailed comments explaining not just *what* the code does, but *why* certain approaches are used and *how* they work under the hood.

## ⚠️ Security Warning

**Important**: Clipboard managers inherently pose security risks because they store everything you copy in memory. This includes:
- Passwords and API keys
- Credit card numbers
- Private messages
- Sensitive documents

### Security Features

To mitigate these risks, Simple Clipboard History includes:

- **Manual Clear**: Clear history anytime via the menu bar
- **Clear on Lock**: Automatically clear history when your Mac locks or sleeps (optional)
- **Memory Only**: History is never written to disk
- **Limited History**: Only keeps the last 10 items

### Best Practices

- Enable "Clear on Screen Lock" for shared/public computers
- Manually clear history after copying sensitive data
- Be mindful of what you copy when the app is running
- Consider quitting the app when handling highly sensitive information

## ✨ Features

- ✅ **Quick Access**: Press `Shift+Command+V` to show history
- ✅ **Keyboard Shortcuts**: Press 1-9 or 0 to instantly paste items
- ✅ **Menu Bar App**: Lightweight, no dock icon
- ✅ **Launch at Login**: Start automatically when you log in
- ✅ **Native & Fast**: Built with Swift for Apple Silicon
- ✅ **Security Controls**: Manual and automatic history clearing
- ✅ **Auto-Paste**: Automatically pastes selected item with `Command+V`
- ✅ **Smart Deduplication**: Moves duplicates to the top instead of creating copies

## 🚀 Installation

### Option 1: Build from Source (Recommended for Learning)

#### Requirements
- macOS 13.0 (Ventura) or later
- Xcode 14.0 or later
- An Apple Developer account (free tier is fine)

#### Build Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/simple-clipboard-history.git
   cd simple-clipboard-history
   ```

2. **Open in Xcode**
   ```bash
   open "Simple Clipboard History.xcodeproj"
   ```

3. **Configure Code Signing**
   - Select the project in the navigator (top item)
   - Select the "Simple Clipboard History" target
   - Go to "Signing & Capabilities" tab
   - Select your Team from the dropdown
   - Xcode will automatically create a provisioning profile

4. **Build the app**
   - Press `Command+B` to build
   - Or select `Product > Build` from the menu

5. **Run the app**
   - Press `Command+R` to run
   - Or select `Product > Run` from the menu

6. **Grant Permissions**
   - On first launch, you'll need to grant **Accessibility permissions**
   - Go to `System Settings > Privacy & Security > Accessibility`
   - Click the lock to make changes
   - Enable "Simple Clipboard History"
   - Restart the app

7. **Install to Applications (Optional)**
   - Build the app for release: `Product > Archive`
   - Or copy from `~/Library/Developer/Xcode/DerivedData/.../Build/Products/Debug/Simple Clipboard History.app`
   - Move to `/Applications`

### Option 2: Download Pre-built Binary

Pre-built binaries are available in the [Releases](https://github.com/yourusername/simple-clipboard-history/releases) section.

1. Download the latest `.dmg` or `.zip`
2. Move `Simple Clipboard History.app` to `/Applications`
3. Right-click and select "Open" (first time only, to bypass Gatekeeper)
4. Grant Accessibility permissions when prompted

### Homebrew

*Homebrew distribution is planned for a future release. Track progress in [Issue #1](https://github.com/yourusername/simple-clipboard-history/issues/1).*

To add to Homebrew, we need to:
- Create a signed release build
- Get it notarized by Apple
- Create a Homebrew tap or submit to homebrew-cask

## 📖 Usage

### Basic Usage

1. **Copy normally**: Use `Command+C` as usual
2. **View history**: Press `Shift+Command+V` or click the menu bar icon → "Show History"
3. **Paste an item**:
   - Press number keys `1-9` or `0` (for item 10)
   - Or double-click an item
   - Or select and press `Enter`
4. **Close without pasting**: Press `Escape` or click outside the window

### Security Features

- **Clear History Manually**: Menu bar icon → "Clear History"
- **Auto-clear on Lock**: Menu bar icon → "Clear on Screen Lock" (toggle)

### Preferences

- **Launch at Login**: Menu bar icon → "Launch at Login" (toggle)

## 🏗️ Project Structure

```
Simple Clipboard History/
├── AppDelegate.swift              # Main app controller, menu bar setup
├── ClipboardManager.swift         # Clipboard monitoring and history storage
├── ClipboardHistoryWindow.swift   # History display window with table view
├── HotKeyManager.swift            # Global keyboard shortcut registration
├── Assets.xcassets/               # App icon and visual assets
├── Main.storyboard                # Minimal storyboard (menu bar apps)
└── Simple_Clipboard_History.entitlements  # Required permissions
```

## 🔧 Technical Details

### Technologies Used

- **Swift 5.0**: Modern, safe, and fast
- **Cocoa/AppKit**: macOS UI framework
- **Carbon Event Manager**: Global hotkey registration (legacy but necessary)
- **Core Graphics**: Event simulation for auto-paste
- **ServiceManagement**: Launch at Login functionality
- **NSWorkspace**: Screen lock detection

### Why Certain Approaches?

- **Polling vs. Notifications**: macOS doesn't provide clipboard change notifications, so we poll every 0.5 seconds using the clipboard's change count
- **Carbon for Hotkeys**: Global hotkeys require Carbon Event Manager, the only supported API for this
- **Event Simulation**: Auto-paste uses CGEvent to simulate `Command+V` keypresses
- **Menu Bar App**: Uses `.accessory` activation policy for no dock icon

## 🤝 Contributing

Contributions are welcome! This is both a learning resource and a functional tool, so please:

- Keep documentation thorough and educational
- Follow existing code style and commenting patterns
- Add comments explaining *why*, not just *what*
- Test on Apple Silicon and Intel Macs if possible

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **[Clipy](https://github.com/Clipy/Clipy)**: The inspiration for this project, a beloved clipboard manager that served the Mac community for years
- **[Flycut](https://github.com/TermiT/Flycut)**: Another excellent clipboard manager that influenced the design
- The broader macOS developer community for countless tutorials and documentation

## 🐛 Known Issues

- Requires Accessibility permissions for auto-paste functionality
- Only supports text clipboard items (images/files not supported)
- History is cleared when app quits (intentional for security)

## 🗺️ Roadmap

- [ ] Support for images and rich text
- [ ] Persistent history with encryption
- [ ] Customizable hotkeys
- [ ] Search/filter history
- [ ] Homebrew distribution
- [ ] Snippets and templates

## 💬 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/simple-clipboard-history/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/simple-clipboard-history/discussions)

---

**Built with ❤️ for learners and productivity enthusiasts**
