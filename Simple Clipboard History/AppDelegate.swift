// Import Cocoa framework - provides all the UI and application foundation classes for macOS
import Cocoa
// Import ServiceManagement - provides APIs for managing login items and launch services
import ServiceManagement

// MARK: - AppDelegate

/// The main application delegate that manages the app's lifecycle and coordinates all components.
///
/// Key Responsibilities:
/// - Sets up the menu bar interface (status bar item)
/// - Manages clipboard monitoring through ClipboardManager
/// - Handles global keyboard shortcuts through HotKeyManager
/// - Provides UI for viewing and selecting clipboard history
/// - Manages "Launch at Login" functionality
///
/// The @main attribute marks this as the entry point for the application.
/// NSApplicationDelegate is a protocol that receives notifications about the app's lifecycle.
@main
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    /// The status bar item that appears in the macOS menu bar.
    /// Optional because it might fail to create (though this is rare).
    var statusItem: NSStatusItem?

    /// Manages clipboard monitoring and maintains history of copied items.
    /// Uses implicitly unwrapped optional (!) because it's initialized in applicationDidFinishLaunching
    /// and will always exist after that point.
    var clipboardManager: ClipboardManager!

    /// Manages the global keyboard shortcut (Shift+Command+V).
    /// Implicitly unwrapped because it's initialized at startup and always exists after.
    var hotKeyManager: HotKeyManager!

    /// The floating window that displays clipboard history.
    /// Optional because the window is only created when the user requests to see history,
    /// and is nil when not displayed.
    var historyWindow: ClipboardHistoryWindow?

    // MARK: - Application Lifecycle

    /// Called when the application finishes launching and is ready to run.
    ///
    /// This is where we set up all the components of our app:
    /// 1. Configure the app to run as a menu bar app (no dock icon)
    /// 2. Create the status bar item with icon and menu
    /// 3. Initialize clipboard monitoring
    /// 4. Register global keyboard shortcuts
    ///
    /// - Parameter notification: Contains information about the launch (we don't use it here)
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure app to be an "accessory" - this means:
        // - No dock icon (the app only appears in the menu bar)
        // - Can't be brought to front via Cmd+Tab
        // - Perfect for background utilities like clipboard managers
        NSApp.setActivationPolicy(.accessory)

        // Create a status bar item (the icon in the menu bar)
        // variableLength means the width adjusts to fit the content
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Set the icon for the status bar item
        // Using SF Symbols (systemSymbolName) for a native macOS look
        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "doc.on.clipboard",
                accessibilityDescription: "Clipboard History"
            )
        }

        // Create the menu that appears when clicking the status bar icon
        let menu = NSMenu()

        // Add menu items:
        // - #selector() converts a Swift method name to an Objective-C selector
        // - keyEquivalent is the keyboard shortcut (empty string means none)
        menu.addItem(NSMenuItem(
            title: "Show History (⇧⌘V)",
            action: #selector(showHistory),
            keyEquivalent: ""
        ))

        // Clear History menu item for security
        menu.addItem(NSMenuItem(
            title: "Clear History",
            action: #selector(clearHistory),
            keyEquivalent: ""
        ))

        // Add a visual separator line
        menu.addItem(NSMenuItem.separator())

        // Clear on Screen Lock toggle (security feature)
        menu.addItem(NSMenuItem(
            title: "Clear on Screen Lock",
            action: #selector(toggleClearOnLock),
            keyEquivalent: ""
        ))

        // Launch at Login toggle
        menu.addItem(NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        ))

        menu.addItem(NSMenuItem.separator())

        // Quit menu item - uses system's terminate method
        // keyEquivalent "q" means Cmd+Q will trigger this
        menu.addItem(NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        // Attach the menu to our status bar item
        statusItem?.menu = menu

        // Set the initial state of the "Launch at Login" menu item
        updateLaunchAtLoginMenuItem()

        // Set the initial state of the "Clear on Screen Lock" menu item
        updateClearOnLockMenuItem()

        // Create and start the clipboard monitor
        // This will begin polling the system clipboard for changes
        clipboardManager = ClipboardManager()
        clipboardManager.startMonitoring()

        // Register the global hotkey (Shift+Command+V)
        // The closure (code in { }) is what happens when the hotkey is pressed
        // [weak self] prevents a retain cycle (memory leak) by not strongly capturing self
        hotKeyManager = HotKeyManager()
        hotKeyManager.registerHotKey { [weak self] in
            // self? is optional chaining - only calls showHistory if self still exists
            self?.showHistory()
        }

        // Register for screen lock notifications (for security feature)
        // This allows us to clear history when the Mac is locked
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(screenDidLock),
            name: NSWorkspace.screensDidSleepNotification,
            object: nil
        )
    }

    // MARK: - Menu Actions

    /// Displays the clipboard history window.
    ///
    /// This method is called when:
    /// - User clicks "Show History" in the menu bar menu
    /// - User presses the global hotkey (Shift+Command+V)
    ///
    /// The @objc attribute is required because this method is called via Objective-C's
    /// selector mechanism (used by NSMenuItem's action property).
    @objc func showHistory() {
        // Close any existing history window first
        // This ensures we only have one window open at a time
        historyWindow?.close()

        // Create a new history window, passing in our clipboard manager
        // so it can access the clipboard history
        historyWindow = ClipboardHistoryWindow(clipboardManager: clipboardManager)

        // Show the window (makes it visible)
        // showWindow is a method on NSWindowController that shows its managed window
        historyWindow?.showWindow(nil)

        // Bring the window to the front and make it the key window (receives keyboard input)
        // Note: makeKeyAndOrderFront is a method on NSWindow, not NSWindowController
        // So we access it through the window property
        historyWindow?.window?.makeKeyAndOrderFront(nil)

        // Activate our app, bringing it to the foreground
        // ignoringOtherApps: true means we steal focus even if another app is active
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Toggles the "Launch at Login" setting.
    ///
    /// Uses macOS's ServiceManagement framework to register/unregister the app
    /// as a login item. This is the modern way to handle launch at login
    /// (available in macOS 13+).
    ///
    /// If the operation fails, displays an alert to the user.
    @objc func toggleLaunchAtLogin() {
        // Check current status - is the app already set to launch at login?
        let currentStatus = SMAppService.mainApp.status == .enabled

        // Try to update the setting
        // 'do-catch' handles errors that might occur
        do {
            if currentStatus {
                // Currently enabled, so disable it
                try SMAppService.mainApp.unregister()
            } else {
                // Currently disabled, so enable it
                try SMAppService.mainApp.register()
            }

            // Update the menu item to show the new state (checkmark on/off)
            updateLaunchAtLoginMenuItem()

        } catch {
            // If something went wrong, show an error dialog
            // NSAlert is a standard macOS dialog box
            let alert = NSAlert()
            alert.messageText = "Failed to update launch at login"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning

            // runModal() displays the alert and waits for user to dismiss it
            alert.runModal()
        }
    }

    /// Updates the checkmark state of the "Launch at Login" menu item.
    ///
    /// This is called after toggling the setting or when the app first launches
    /// to ensure the menu item accurately reflects the current state.
    func updateLaunchAtLoginMenuItem() {
        // Try to get the menu and find the "Launch at Login" item
        // Using 'if let' for safe optional unwrapping
        if let menu = statusItem?.menu,
           let item = menu.item(withTitle: "Launch at Login") {
            // Set the menu item's state to show a checkmark (on) or no checkmark (off)
            // Uses a ternary operator: condition ? valueIfTrue : valueIfFalse
            item.state = SMAppService.mainApp.status == .enabled ? .on : .off
        }
    }

    /// Clears all clipboard history.
    ///
    /// This is a manual security action that immediately deletes all stored
    /// clipboard items from memory. Useful when you've copied sensitive data
    /// (passwords, credit cards, etc.) and want to ensure it's removed.
    @objc func clearHistory() {
        clipboardManager.clearHistory()
    }

    /// Toggles the "Clear on Screen Lock" security setting.
    ///
    /// When enabled, clipboard history is automatically cleared whenever
    /// the Mac is locked or goes to sleep. This prevents sensitive data
    /// from being accessible if someone else accesses your Mac.
    ///
    /// The preference is saved using UserDefaults so it persists across app launches.
    @objc func toggleClearOnLock() {
        // Get current setting (default is false if never set)
        let currentSetting = UserDefaults.standard.bool(forKey: "clearOnScreenLock")

        // Toggle it
        UserDefaults.standard.set(!currentSetting, forKey: "clearOnScreenLock")

        // Update the menu item checkmark
        updateClearOnLockMenuItem()
    }

    /// Updates the checkmark state of the "Clear on Screen Lock" menu item.
    ///
    /// Called after toggling the setting or when the app first launches
    /// to ensure the menu item reflects the saved preference.
    func updateClearOnLockMenuItem() {
        // Get the saved preference (defaults to false)
        let isEnabled = UserDefaults.standard.bool(forKey: "clearOnScreenLock")

        // Find the menu item and update its checkmark
        if let menu = statusItem?.menu,
           let item = menu.item(withTitle: "Clear on Screen Lock") {
            item.state = isEnabled ? .on : .off
        }
    }

    /// Called when the screen locks or Mac goes to sleep.
    ///
    /// This notification fires when:
    /// - User explicitly locks the screen (Control+Command+Q)
    /// - Mac goes to sleep (lid closes, sleep timer, etc.)
    /// - Screen saver with password protection activates
    ///
    /// If the "Clear on Screen Lock" preference is enabled, we clear all
    /// clipboard history for security.
    @objc func screenDidLock() {
        // Check if the user has enabled the "clear on lock" feature
        let shouldClear = UserDefaults.standard.bool(forKey: "clearOnScreenLock")

        // If enabled, clear the history
        if shouldClear {
            clipboardManager.clearHistory()
        }
    }

    /// Called just before the application terminates.
    ///
    /// This is our chance to clean up resources. We stop monitoring the clipboard
    /// to properly invalidate the timer and release resources.
    ///
    /// - Parameter notification: Contains information about termination (unused here)
    func applicationWillTerminate(_ notification: Notification) {
        // Stop the clipboard monitoring timer
        clipboardManager.stopMonitoring()
    }
}
