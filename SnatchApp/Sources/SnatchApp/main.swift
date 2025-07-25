import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        window = ShelfWindow()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        setupGlobalHotkey()
        setupStatusBar()
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
            shelfWindow.disableManualMode()
        } else {
            shelfWindow.enableManualMode()
            shelfWindow.showShelf()
        }
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "tray.and.arrow.down", accessibilityDescription: "Snatch")
            button.imagePosition = .imageOnly
        }
        
        // Detectar idioma del sistema para el menú
        let languageCode = NSLocale.current.language.languageCode?.identifier ?? "en"
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Snatch", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        let toggleItem = NSMenuItem(title: languageCode == "es" ? "Mostrar/Ocultar" : "Show/Hide", 
                                  action: #selector(toggleShelfFromMenu), 
                                  keyEquivalent: "s")
        toggleItem.keyEquivalentModifierMask = [.command, .option]
        menu.addItem(toggleItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: languageCode == "es" ? "Salir" : "Quit", 
                               action: #selector(quitApp), 
                               keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc private func toggleShelfFromMenu() {
        toggleShelf()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
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