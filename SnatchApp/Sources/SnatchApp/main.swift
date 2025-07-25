import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        window = ShelfWindow()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        setupGlobalHotkey()
    }

    private func setupGlobalHotkey() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.command, .option]) && event.keyCode == 1 { // 1 = S
                DispatchQueue.main.async {
                    self?.toggleShelf()
                }
            }
        }
    }

    private func toggleShelf() {
        guard let shelfWindow = window as? ShelfWindow else { return }
        if shelfWindow.isShown {
            shelfWindow.hideShelf()
        } else {
            shelfWindow.showShelf()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// Punto de entrada manual para SPM
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run() 