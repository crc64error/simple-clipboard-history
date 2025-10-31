// Import Cocoa for macOS app foundation
import Cocoa
// Import Carbon for legacy event handling APIs
// Carbon is an older macOS framework, but it's still the only way to register global hotkeys
import Carbon

// MARK: - HotKeyManager

/// Manages system-wide keyboard shortcuts (global hotkeys).
///
/// This class uses the Carbon Event Manager API, which is the only way to register
/// global keyboard shortcuts on macOS. While Carbon is a legacy framework, these
/// specific APIs are still supported and widely used.
///
/// Key Concepts:
/// - Global hotkeys work even when the app is in the background
/// - Requires registration with the system event manager
/// - Uses C-style callback functions (bridged from Swift)
/// - Must clean up resources in deinit to avoid leaks
///
/// The registered hotkey is: Shift + Command + V
class HotKeyManager {

    // MARK: - Properties

    /// Reference to the registered hotkey.
    /// Used to unregister the hotkey when the manager is deallocated.
    /// Optional because it's nil before registration.
    private var hotKeyRef: EventHotKeyRef?

    /// Reference to the event handler.
    /// Used to remove the handler when the manager is deallocated.
    /// Optional because it's nil before installation.
    private var eventHandler: EventHandlerRef?

    /// The callback function to execute when the hotkey is pressed.
    /// @escaping means this closure can be stored and called later.
    /// Optional because it's set during registration.
    private var callback: (() -> Void)?

    /// Unique identifier for our hotkey.
    ///
    /// EventHotKeyID has two parts:
    /// - signature: A 4-character code identifying our app ("CLPB" for clipboard)
    /// - id: A number to distinguish multiple hotkeys (we only have one, so: 1)
    ///
    /// FourCharCode is an old Mac OS concept where identifiers are 4 ASCII characters
    /// packed into a 32-bit integer. This was common in classic Mac OS.
    private let hotKeyID = EventHotKeyID(signature: OSType("CLPB".fourCharCodeValue), id: 1)

    // MARK: - Registration

    /// Registers a global hotkey (Shift+Command+V) with a callback.
    ///
    /// This method:
    /// 1. Stores the callback to execute when hotkey is pressed
    /// 2. Installs an event handler to receive hotkey events
    /// 3. Registers the specific key combination with the system
    ///
    /// The implementation uses Carbon APIs which are C-based and require
    /// careful memory management.
    ///
    /// - Parameter callback: Function to call when the hotkey is pressed
    func registerHotKey(callback: @escaping () -> Void) {
        // Store the callback so we can call it when the hotkey is pressed
        self.callback = callback

        // Define the key combination: Shift + Command + V
        let keyCode: UInt32 = 0x09  // V key (USB HID virtual key code)

        // Combine modifier keys using bitwise OR (|)
        // cmdKey = Command key, shiftKey = Shift key (defined in Carbon)
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)

        // Define what type of event we want to handle
        // EventTypeSpec describes a specific kind of event
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),  // Keyboard events
            eventKind: UInt32(kEventHotKeyPressed)    // Specifically, hotkey press events
        )

        // Install an event handler (a C callback function)
        // This is the function that gets called when ANY registered hotkey is pressed
        InstallEventHandler(
            GetApplicationEventTarget(),  // Where to install: our app's event target

            // The handler function (a closure that matches C callback signature)
            { (nextHandler, theEvent, userData) -> OSStatus in
                // Extract the hotkey ID from the event to see which hotkey was pressed
                var hotKeyID = EventHotKeyID()

                // GetEventParameter extracts data from the Carbon event
                let error = GetEventParameter(
                    theEvent,                              // The event that occurred
                    UInt32(kEventParamDirectObject),       // Parameter type we want
                    UInt32(typeEventHotKeyID),             // Expected data type
                    nil,                                   // We don't need the actual type back
                    MemoryLayout<EventHotKeyID>.size,      // Size of data to read
                    nil,                                   // We don't need bytes read
                    &hotKeyID                              // Where to write the result
                )

                // If extraction failed, return the error code
                guard error == noErr else { return error }

                // Retrieve the HotKeyManager instance from userData
                // userData is a raw pointer - we need to convert it back to Swift object
                // Unmanaged bridges between Swift object references and C pointers
                // fromOpaque: Convert pointer back to object reference
                // takeUnretainedValue: Get the object without changing retain count
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData!).takeUnretainedValue()

                // Execute the callback on the main thread
                // Carbon event handlers run on a background thread, but UI code
                // must run on main thread, so we dispatch there
                DispatchQueue.main.async {
                    manager.callback?()
                }

                // Return noErr to indicate we handled the event successfully
                return noErr
            },

            1,                                           // Number of event types (we handle 1)
            &eventType,                                  // Pointer to the event type array
            Unmanaged.passUnretained(self).toOpaque(),   // userData: pass self as raw pointer
            &eventHandler                                // Store handler reference for cleanup
        )

        // Explanation of Unmanaged.passUnretained(self).toOpaque():
        // - We need to pass 'self' to the C callback, but C doesn't understand Swift objects
        // - Unmanaged bridges between Swift object references and C void pointers
        // - passUnretained: Don't increase retain count (we manually manage lifetime)
        // - toOpaque: Convert object reference to void* (raw pointer)

        // Register the actual hotkey with the system
        RegisterEventHotKey(
            keyCode,                    // Which key (V)
            modifiers,                  // Which modifiers (Shift+Command)
            hotKeyID,                   // Our unique ID for this hotkey
            GetApplicationEventTarget(), // Where events should be sent
            0,                          // Options (none)
            &hotKeyRef                  // Store reference for cleanup later
        )
    }

    // MARK: - Cleanup

    /// Destructor - called when this object is being deallocated.
    ///
    /// Properly unregisters the hotkey and removes the event handler to avoid:
    /// - Memory leaks
    /// - Crashes if system tries to call our handler after object is gone
    /// - Hotkey remaining active after app quits
    ///
    /// deinit is Swift's equivalent to C++ destructors or Objective-C dealloc.
    deinit {
        // Unregister the hotkey from the system
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }

        // Remove the event handler
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
}

// MARK: - String Extension

/// Extension to String for converting to FourCharCode.
///
/// FourCharCode (also called OSType) is a classic Mac OS concept where
/// identifiers are represented as 4 ASCII characters packed into a 32-bit integer.
///
/// For example, "CLPB" becomes:
/// - 'C' = 0x43
/// - 'L' = 0x4C
/// - 'P' = 0x50
/// - 'B' = 0x42
/// Combined: 0x434C5042
extension String {
    /// Converts a string to a FourCharCode.
    ///
    /// Takes the first 4 bytes of the UTF-8 encoding and packs them into
    /// a 32-bit integer, with the first character in the most significant byte.
    ///
    /// Example: "CLPB" → 0x434C5042
    ///
    /// How the bit shifting works:
    /// - Start with result = 0x00000000
    /// - For 'C' (0x43): result = 0x00000043
    /// - Shift left 8: result = 0x00004300
    /// - For 'L' (0x4C): result = 0x0000434C
    /// - Shift left 8: result = 0x00434C00
    /// - For 'P' (0x50): result = 0x00434C50
    /// - Shift left 8: result = 0x434C5000
    /// - For 'B' (0x42): result = 0x434C5042
    var fourCharCodeValue: FourCharCode {
        var result: FourCharCode = 0

        // Iterate over each byte in the UTF-8 representation
        for char in self.utf8 {
            // Shift existing bits left by 8 to make room for new byte
            // Then add the new byte
            // << is the left shift operator (bitwise operation)
            result = (result << 8) + FourCharCode(char)
        }

        return result
    }
}
