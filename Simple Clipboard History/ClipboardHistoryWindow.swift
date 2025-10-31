// Import Cocoa for all UI components (NSWindow, NSTableView, etc.)
import Cocoa

// MARK: - ClipboardHistoryWindow

/// A floating window that displays clipboard history in a list.
///
/// This window controller manages:
/// - A table view showing clipboard items numbered 1-10 (0 for item 10)
/// - Keyboard shortcuts for quick selection (press 1-9 or 0)
/// - Mouse interaction (double-click to paste)
/// - Automatic window centering and dismissal
/// - Simulating Command+V to paste the selected item
///
/// Design Pattern: NSWindowController
/// - Manages a single window and its content
/// - Separates window management from app logic
///
/// Protocols:
/// - NSTableViewDelegate: Customizes table view appearance and behavior
/// - NSTableViewDataSource: Provides data to display in the table view
class ClipboardHistoryWindow: NSWindowController, NSTableViewDelegate, NSTableViewDataSource {

    // MARK: - Properties

    /// Reference to the clipboard manager to access history data.
    /// Private and immutable (let) because the window doesn't change which manager it uses.
    private let clipboardManager: ClipboardManager

    /// The table view that displays the clipboard history items.
    /// Implicitly unwrapped (!) because it's created in setupUI() and always exists after.
    private var tableView: NSTableView!

    // MARK: - Initialization

    /// Creates a new clipboard history window.
    ///
    /// This initializer:
    /// 1. Creates and configures a floating window
    /// 2. Sets up the table view UI
    /// 3. Centers the window on screen
    /// 4. Registers to auto-close when focus is lost
    ///
    /// - Parameter clipboardManager: The clipboard manager containing history to display
    init(clipboardManager: ClipboardManager) {
        self.clipboardManager = clipboardManager

        // Create the window with specific configuration
        let window = NSWindow(
            // Initial size and position (will be centered later)
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),

            // Style mask defines window appearance and capabilities:
            // - .titled: Shows title bar
            // - .closable: Shows close button
            // - .fullSizeContentView: Content extends under title bar (modern macOS style)
            styleMask: [.titled, .closable, .fullSizeContentView],

            // Backing store type - .buffered is standard for performance
            backing: .buffered,

            // defer: false means create the window immediately
            defer: false
        )

        // Configure window properties
        window.title = "Clipboard History"

        // .floating keeps window above normal windows (like Spotlight)
        window.level = .floating

        // Collection behavior controls window management:
        // - .canJoinAllSpaces: Window appears in all Mission Control spaces
        // - .fullScreenAuxiliary: Can appear alongside fullscreen apps
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Don't release the window when closed (we reuse it)
        // Without this, the window would be deallocated when closed
        window.isReleasedWhenClosed = false

        // Disable automatic window restoration
        // macOS tries to restore windows after app relaunch, but we create this window
        // on-demand, so we don't want it automatically restored
        // This prevents the warning: "Unable to find className=(null)"
        window.isRestorable = false

        // Call superclass (NSWindowController) initializer with our configured window
        super.init(window: window)

        // Set up the table view and other UI elements
        setupUI()

        // Position the window in the center of the screen
        centerWindow()

        // Register for notification when window loses focus
        // This allows us to auto-dismiss the window when user clicks elsewhere
        NotificationCenter.default.addObserver(
            self,                                    // Observer object
            selector: #selector(windowDidResignKey), // Method to call
            name: NSWindow.didResignKeyNotification, // Event to watch for
            object: window                           // Specific window to observe
        )
    }

    /// Required initializer for loading from Interface Builder/Storyboard.
    ///
    /// We don't support loading this window from a storyboard, so this crashes.
    /// The 'required' keyword means we must implement this because NSWindowController has it,
    /// but we can make it crash since we never use it.
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    /// Sets up the table view and scroll view.
    ///
    /// Creates a scrollable table view that fills the entire window.
    /// The table view is configured to display clipboard items and respond
    /// to both mouse clicks and keyboard input.
    private func setupUI() {
        // Ensure we have a valid window (should always be true)
        guard let window = window else { return }

        // Create a scroll view to contain the table view
        // This allows scrolling if we have more items than fit on screen
        let scrollView = NSScrollView(frame: window.contentView!.bounds)

        // autoresizingMask controls how view resizes when window resizes
        // [.width, .height] means "stretch to fill window in both directions"
        scrollView.autoresizingMask = [.width, .height]

        // Show vertical scrollbar when needed
        scrollView.hasVerticalScroller = true

        // Create the table view inside the scroll view
        tableView = NSTableView(frame: scrollView.bounds)

        // Set delegate and data source to self
        // Delegate: Controls appearance and behavior (how rows look)
        // DataSource: Provides the data (what rows contain)
        tableView.delegate = self
        tableView.dataSource = self

        // Configure table view actions
        tableView.target = self  // Send actions to this object

        // doubleAction is called when user double-clicks a row
        tableView.doubleAction = #selector(tableViewDoubleClick)

        // action is called when user single-clicks a row
        tableView.action = #selector(tableViewSingleClick)

        // Hide the column headers (we don't need them)
        tableView.headerView = nil

        // Alternate row colors for better readability
        tableView.usesAlternatingRowBackgroundColors = true

        // Each row is 60 points tall (enough for 2 lines of text)
        tableView.rowHeight = 60

        // Add a single column to the table
        // NSTableView requires at least one column, even if headers are hidden
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("ContentColumn"))
        column.width = scrollView.bounds.width
        tableView.addTableColumn(column)

        // Put the table view inside the scroll view
        scrollView.documentView = tableView

        // Add the scroll view to the window's content area
        window.contentView?.addSubview(scrollView)

        // Make the table view the first responder (receives keyboard input)
        // This allows number keys to work immediately when window opens
        window.makeFirstResponder(tableView)
    }

    /// Centers the window on the main screen.
    ///
    /// Calculates the center position of the screen and positions
    /// the window so it appears in the middle.
    private func centerWindow() {
        // Ensure we have both a window and a screen to work with
        guard let window = window, let screen = NSScreen.main else { return }

        // visibleFrame is the screen area excluding menu bar and dock
        let screenRect = screen.visibleFrame
        let windowRect = window.frame

        // Calculate center position
        // midX/midY are the center points of the screen
        // Subtract half the window size to center it
        let x = screenRect.midX - windowRect.width / 2
        let y = screenRect.midY - windowRect.height / 2

        // Move the window to the calculated position
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    // MARK: - Window Events

    /// Called when the window loses focus (user clicks elsewhere).
    ///
    /// We automatically close the window when it loses focus, similar to
    /// how Spotlight or Quick Look behave. This creates a lightweight,
    /// non-intrusive UX.
    @objc private func windowDidResignKey() {
        close()
    }

    // MARK: - Table View Actions

    /// Called when user single-clicks a table row.
    ///
    /// We don't do anything on single click - user must double-click or press
    /// a number key to actually select and paste an item.
    @objc private func tableViewSingleClick() {
        // Single click does nothing, wait for double click or key press
    }

    /// Called when user double-clicks a table row.
    ///
    /// Pastes the double-clicked item and closes the window.
    @objc private func tableViewDoubleClick() {
        // Get which row was selected
        let selectedRow = tableView.selectedRow

        // Validate that the row is within bounds
        guard selectedRow >= 0 && selectedRow < clipboardManager.history.count else { return }

        // Paste the selected item
        pasteItem(at: selectedRow)
    }

    // MARK: - Keyboard Handling

    /// Handles keyboard input for the window.
    ///
    /// Supports three types of keyboard shortcuts:
    /// - Number keys 1-9, 0: Select and paste items 1-10 (0 = item 10)
    /// - Escape: Close window without pasting
    /// - Enter/Return: Paste currently highlighted item
    ///
    /// This method overrides NSResponder's keyDown to intercept keys before
    /// they reach the table view.
    ///
    /// - Parameter event: The keyboard event containing key information
    override func keyDown(with event: NSEvent) {
        // Check if this is a single character key press
        if let characters = event.characters, characters.count == 1 {
            let character = characters.first!

            // Try to convert the character to an array index
            var index: Int?

            if character >= "1" && character <= "9" {
                // Keys 1-9 map to indices 0-8
                // Int(String(character))! converts the character to an integer
                // We force-unwrap (!) because we know it's a valid digit
                index = Int(String(character))! - 1

            } else if character == "0" {
                // Key 0 maps to index 9 (the 10th item)
                index = 9
            }

            // If we got a valid index and it's within history bounds, paste it
            if let index = index, index < clipboardManager.history.count {
                pasteItem(at: index)
                return  // Exit - we handled this key
            }
        }

        // Handle escape key to close without pasting
        // Key code 53 is the ESC key (macOS uses virtual key codes)
        if event.keyCode == 53 {
            close()
            return
        }

        // Handle enter/return keys to paste selected item
        // Key code 36 = Return, 76 = Enter (on numeric keypad)
        if event.keyCode == 36 || event.keyCode == 76 {
            let selectedRow = tableView.selectedRow

            // Only paste if a valid row is selected
            if selectedRow >= 0 && selectedRow < clipboardManager.history.count {
                pasteItem(at: selectedRow)
                return
            }
        }

        // If we didn't handle the key, pass it to the superclass
        // This allows arrow keys, Tab, etc. to work normally
        super.keyDown(with: event)
    }

    // MARK: - Paste Logic

    /// Pastes the clipboard item at the specified index.
    ///
    /// This method:
    /// 1. Copies the item to the system clipboard
    /// 2. Closes the history window
    /// 3. Simulates Command+V to paste into the active application
    ///
    /// The delay before simulating paste allows time for:
    /// - The window to close
    /// - The previous application to become active again
    /// - Focus to return to the original text field
    ///
    /// - Parameter index: The index of the history item to paste
    private func pasteItem(at index: Int) {
        // Get the item from history
        let item = clipboardManager.history[index]

        // Put it on the system clipboard
        clipboardManager.copyToClipboard(item: item)

        // Close this window immediately
        close()

        // Wait a moment, then simulate Command+V
        // DispatchQueue.main.asyncAfter schedules code to run later on the main thread
        // .now() + 0.1 means "100 milliseconds from now"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulatePaste()
        }
    }

    /// Simulates a Command+V key press to paste the clipboard content.
    ///
    /// Uses Core Graphics Event APIs to create synthetic keyboard events.
    /// This requires Accessibility permissions to work.
    ///
    /// How it works:
    /// 1. Creates a keyboard event source
    /// 2. Creates "V key down" and "V key up" events
    /// 3. Adds the Command modifier flag
    /// 4. Posts the events to the system event stream
    ///
    /// The system processes these as if the user actually pressed Command+V.
    private func simulatePaste() {
        // Create an event source representing keyboard input
        // .hidSystemState means "simulate hardware input"
        let source = CGEventSource(stateID: .hidSystemState)

        // Create keyboard events for the V key
        // Virtual key 0x09 is the V key in the USB HID standard
        let keyVDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        let keyVUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)

        // Add the Command modifier to both events
        // .maskCommand is the Command (⌘) key flag
        keyVDown?.flags = .maskCommand
        keyVUp?.flags = .maskCommand

        // Post the events to the system
        // .cghidEventTap sends them to the HID event stream (keyboard/mouse events)
        // This makes them indistinguishable from real keypresses
        keyVDown?.post(tap: .cghidEventTap)
        keyVUp?.post(tap: .cghidEventTap)
    }

    // MARK: - NSTableViewDataSource

    /// Returns the number of rows to display in the table.
    ///
    /// This is a required method of NSTableViewDataSource protocol.
    /// The table view calls this to know how many rows to create.
    ///
    /// - Parameter tableView: The table view requesting this information
    /// - Returns: The number of items in clipboard history
    func numberOfRows(in tableView: NSTableView) -> Int {
        return clipboardManager.history.count
    }

    // MARK: - NSTableViewDelegate

    /// Creates and returns the view to display for a specific row.
    ///
    /// This method is called by the table view for each visible row.
    /// We create a custom view containing:
    /// - A number label (1-9, or 0 for item 10) on the left
    /// - The clipboard content text on the right
    ///
    /// Note: We create new views each time rather than reusing cells.
    /// For a small list like this (max 10 items), the performance difference
    /// is negligible and the code is simpler.
    ///
    /// - Parameters:
    ///   - tableView: The table view requesting the view
    ///   - tableColumn: The column (we only have one)
    ///   - row: The row index (0-based)
    /// - Returns: A view to display for this row
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        // Get the clipboard item for this row
        let item = clipboardManager.history[row]

        // Create a container view for this row
        let cellView = NSView(frame: NSRect(x: 0, y: 0, width: tableView.bounds.width, height: 60))

        // Create the number label (shows which key to press)
        // Display 1-9 for first 9 items, then 0 for the 10th item
        // Using ternary operator: condition ? valueIfTrue : valueIfFalse
        let numberLabel = NSTextField(labelWithString: "\(row < 9 ? row + 1 : 0)")
        numberLabel.frame = NSRect(x: 10, y: 20, width: 30, height: 20)
        numberLabel.font = NSFont.boldSystemFont(ofSize: 14)
        numberLabel.alignment = .center  // Center the number in its box

        // secondaryLabelColor is a system color that adapts to light/dark mode
        numberLabel.textColor = .secondaryLabelColor
        cellView.addSubview(numberLabel)

        // Create the content label (shows the clipboard text)
        // wrappingLabelWithString creates a non-editable, non-selectable text field
        let contentLabel = NSTextField(wrappingLabelWithString: item.content)

        // Position next to the number, with some padding
        contentLabel.frame = NSRect(x: 50, y: 5, width: tableView.bounds.width - 60, height: 50)

        contentLabel.font = NSFont.systemFont(ofSize: 12)

        // If text is too long, add "..." at the end
        contentLabel.lineBreakMode = .byTruncatingTail

        // Show at most 2 lines of text
        contentLabel.maximumNumberOfLines = 2

        cellView.addSubview(contentLabel)

        return cellView
    }

    /// Determines whether a row can be selected.
    ///
    /// Called when the user tries to select a row. We allow all rows
    /// to be selected (returns true for all).
    ///
    /// - Parameters:
    ///   - tableView: The table view
    ///   - row: The row index
    /// - Returns: true (all rows are selectable)
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return true
    }
}
