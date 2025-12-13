//
//  HotkeyManager.swift
//  Appkeys
//

import Carbon
import Foundation

class HotkeyManager {
    static let shared = HotkeyManager()

    private var hotkeyRefs: [UUID: EventHotKeyRef] = [:]
    private var hotkeyCallbacks: [UInt32: () -> Void] = [:]
    private var nextHotkeyID: UInt32 = 1

    private init() {
        installEventHandler()
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let event = event else { return OSStatus(eventNotHandledErr) }

            var hotkeyID = EventHotKeyID()
            let err = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotkeyID
            )

            guard err == noErr else { return err }

            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData!).takeUnretainedValue()
            if let callback = manager.hotkeyCallbacks[hotkeyID.id] {
                DispatchQueue.main.async {
                    callback()
                }
            }

            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            nil
        )
    }

    func register(hotkey: AppHotkey, callback: @escaping () -> Void) -> Bool {
        guard hotkey.hasHotkey, let keyCode = hotkey.keyCode else { return false }

        // Unregister if already registered
        unregister(hotkey: hotkey)

        let hotkeyID = nextHotkeyID
        nextHotkeyID += 1

        var hotkeyRef: EventHotKeyRef?
        let hotkeyIDStruct = EventHotKeyID(signature: OSType(0x4150_5056), id: hotkeyID) // "APPV"

        let status = RegisterEventHotKey(
            keyCode,
            hotkey.modifiers,
            hotkeyIDStruct,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )

        guard status == noErr, let ref = hotkeyRef else {
            print("Failed to register hotkey: \(status)")
            return false
        }

        hotkeyRefs[hotkey.id] = ref
        hotkeyCallbacks[hotkeyID] = callback

        return true
    }

    func unregister(hotkey: AppHotkey) {
        guard let ref = hotkeyRefs.removeValue(forKey: hotkey.id) else { return }
        UnregisterEventHotKey(ref)
    }

    func unregisterAll() {
        for (_, ref) in hotkeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotkeyRefs.removeAll()
        hotkeyCallbacks.removeAll()
    }
}
