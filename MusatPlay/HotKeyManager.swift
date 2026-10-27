import AppKit
import Carbon

final class HotKeyManager {
    static let shared = HotKeyManager()

    private var refs: [EventHotKeyRef?] = []
    private var actions: [UInt32: () -> Void] = [:]
    private var nextID: UInt32 = 1
    private var handlerInstalled = false

    func register(keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) {
        installHandlerIfNeeded()

        let id = nextID
        nextID += 1
        actions[id] = action

        var ref: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x4D535450), id: id)
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &ref)
        refs.append(ref)
    }

    private func installHandlerIfNeeded() {
        guard !handlerInstalled else { return }
        handlerInstalled = true

        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ -> OSStatus in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event,
                              EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID),
                              nil,
                              MemoryLayout<EventHotKeyID>.size,
                              nil,
                              &hotKeyID)
            DispatchQueue.main.async {
                HotKeyManager.shared.actions[hotKeyID.id]?()
            }
            return noErr
        }, 1, &spec, nil, nil)
    }

    func registerAll() {
        let mods = UInt32(controlKey | optionKey)

        register(keyCode: 49, modifiers: mods) { PlayerController.shared.playPause() }
        register(keyCode: 124, modifiers: mods) { PlayerController.shared.next() }
        register(keyCode: 123, modifiers: mods) { PlayerController.shared.previous() }
        register(keyCode: 1, modifiers: mods) { PlayerController.shared.shuffle() }
        register(keyCode: 15, modifiers: mods) { PlayerController.shared.cycleRepeat() }
    }
}
