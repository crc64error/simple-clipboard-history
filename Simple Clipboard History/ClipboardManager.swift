// Import Cocoa for NSPasteboard (clipboard) and Timer classes
import Cocoa

// MARK: - ClipboardManager

/// Manages clipboard monitoring and maintains a history of copied items.
///
/// This class continuously monitors the system clipboard (pasteboard) for changes
/// and maintains a rolling history of the last 10 items copied. It uses a polling
/// approach since macOS doesn't provide a direct notification API for clipboard changes.
///
/// Key Features:
/// - Automatic clipboard monitoring via timer
/// - Maintains up to 10 recent clipboard items
/// - Deduplicates items (moves duplicates to the front)
/// - Stores both content and timestamp for each item
class ClipboardManager {

    // MARK: - Properties

    /// The timer that periodically checks for clipboard changes.
    /// Optional because it's nil when monitoring is stopped.
    /// Private because only this class should manage the timer.
    private var timer: Timer?

    /// The last known change count from the system pasteboard.
    ///
    /// macOS increments this number each time the clipboard content changes.
    /// By comparing our stored value to the current value, we can detect when
    /// something new has been copied without constantly reading the clipboard content.
    private var lastChangeCount: Int = 0

    /// Array storing the clipboard history.
    ///
    /// private(set) means:
    /// - Other classes can READ this property (it's publicly readable)
    /// - Only ClipboardManager can WRITE to it (set/modify it)
    /// This is a common pattern for exposing data while maintaining control over how it changes.
    private(set) var history: [ClipboardItem] = []

    /// Maximum number of items to keep in history.
    /// Constant (let) because this limit doesn't change at runtime.
    private let maxHistorySize = 10

    // MARK: - ClipboardItem

    /// Represents a single item in the clipboard history.
    ///
    /// Conforming to Equatable allows us to compare items and remove duplicates.
    /// Using a struct (value type) instead of class (reference type) because:
    /// - ClipboardItems are immutable (let properties)
    /// - We don't need reference semantics
    /// - Structs are simpler and more efficient for small data like this
    struct ClipboardItem: Equatable {
        /// The text content that was copied.
        let content: String

        /// When this item was copied.
        /// Currently stored but not displayed - could be used for showing timestamps in UI.
        let timestamp: Date

        /// Defines how two ClipboardItems are compared for equality.
        ///
        /// We only compare content, not timestamps, because we consider two items
        /// with the same text to be duplicates even if copied at different times.
        ///
        /// - Parameters:
        ///   - lhs: Left-hand side of the == operator
        ///   - rhs: Right-hand side of the == operator
        /// - Returns: true if the content is the same, false otherwise
        static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
            return lhs.content == rhs.content
        }
    }

    // MARK: - Public Methods

    /// Starts monitoring the system clipboard for changes.
    ///
    /// Creates a timer that fires every 0.5 seconds to check if the clipboard
    /// has changed. This polling approach is necessary because macOS doesn't
    /// provide a notification-based API for clipboard changes.
    ///
    /// Why polling?
    /// - macOS has no built-in clipboard change notifications
    /// - 0.5 second interval balances responsiveness vs. performance
    /// - Very low CPU usage since we only check a counter, not the actual content
    func startMonitoring() {
        // Store the current clipboard change count as our baseline
        // This prevents us from adding the current clipboard content to history
        // when the app first starts
        lastChangeCount = NSPasteboard.general.changeCount

        // Create a repeating timer that checks the clipboard every 0.5 seconds
        // scheduledTimer automatically adds the timer to the run loop
        timer = Timer.scheduledTimer(
            withTimeInterval: 0.5,  // Fire every half second
            repeats: true            // Keep firing (not just once)
        ) { [weak self] _ in
            // [weak self] prevents a retain cycle:
            // Timer holds a reference to this closure
            // If closure captured self strongly, self would never be deallocated
            // weak self allows self to be deallocated, which stops the timer
            self?.checkClipboard()
        }
    }

    /// Stops monitoring the clipboard.
    ///
    /// Invalidates and releases the timer. Should be called when the app quits
    /// to properly clean up resources.
    func stopMonitoring() {
        // invalidate() stops the timer from firing and removes it from the run loop
        timer?.invalidate()

        // Set to nil to release the timer object
        // Even though invalidate() stops it, setting to nil ensures cleanup
        timer = nil
    }

    /// Clears all clipboard history.
    ///
    /// This is a security feature that allows users to clear sensitive data
    /// from memory. Called when:
    /// - User manually selects "Clear History" from menu
    /// - Screen locks (if auto-clear on lock is enabled)
    ///
    /// Note: This only clears our app's history, not the system clipboard itself.
    func clearHistory() {
        history.removeAll()
    }

    // MARK: - Private Methods

    /// Checks if the clipboard has changed and updates history if needed.
    ///
    /// This method is called by the timer every 0.5 seconds. It:
    /// 1. Checks if the clipboard change count has incremented
    /// 2. If so, reads the clipboard content
    /// 3. Adds valid content to history while removing duplicates
    ///
    /// Note: This method does nothing if the clipboard hasn't changed,
    /// making it very efficient to call frequently.
    private func checkClipboard() {
        // NSPasteboard.general is the system clipboard
        // macOS calls it "pasteboard" for historical reasons (copy/paste/cut)
        let pasteboard = NSPasteboard.general

        // Guard statement for early return if clipboard hasn't changed
        // If changeCount matches our stored value, nothing was copied since last check
        guard pasteboard.changeCount != lastChangeCount else {
            return  // Exit early - no changes to process
        }

        // Clipboard has changed, so update our stored count
        lastChangeCount = pasteboard.changeCount

        // Try to get the clipboard content as a string
        // guard let unwraps the optional and provides early return if nil
        // We also check that the string is not empty
        guard let content = pasteboard.string(forType: .string),
              !content.isEmpty else {
            return  // Clipboard doesn't contain text or is empty
        }

        // Create a new clipboard item with current content and timestamp
        let newItem = ClipboardItem(content: content, timestamp: Date())

        // Check if this is the same as the most recent item
        // This can happen if the user copies the same thing twice in a row
        if let firstItem = history.first, firstItem == newItem {
            return  // Don't add duplicate of most recent item
        }

        // Remove any existing occurrences of this content from history
        // $0 is shorthand for each element in the array
        // This ensures duplicates are removed before adding to front
        history.removeAll { $0 == newItem }

        // Insert the new item at the beginning of the history array
        // Most recent items are always at index 0
        history.insert(newItem, at: 0)

        // Ensure we don't exceed the maximum history size
        if history.count > maxHistorySize {
            // prefix() returns the first N elements
            // Array() converts the result back to a full array
            history = Array(history.prefix(maxHistorySize))
        }
    }

    /// Copies a history item back to the system clipboard.
    ///
    /// When the user selects an item from history, this method puts it back
    /// on the clipboard. We also update our changeCount to prevent this
    /// clipboard change from being added to history again.
    ///
    /// - Parameter item: The clipboard item to copy to the system clipboard
    func copyToClipboard(item: ClipboardItem) {
        let pasteboard = NSPasteboard.general

        // Clear the current clipboard contents
        // This is required before setting new content
        pasteboard.clearContents()

        // Set the item's content as a string on the clipboard
        pasteboard.setString(item.content, forType: .string)

        // Update our change count to match the new clipboard state
        // This prevents checkClipboard() from adding this item to history
        // (since we just took it FROM history)
        lastChangeCount = pasteboard.changeCount
    }
}
