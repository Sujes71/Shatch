import Cocoa

class ShelfWindow: NSWindow {
    private let tabWidth: CGFloat = 16
    private let fullWidth: CGFloat = 320
    private let windowHeight: CGFloat = 400
    private let animationDuration: TimeInterval = 0.25
    private var isShown = false
    private var hideTimer: Timer?

    init() {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let y = screenFrame.midY - windowHeight / 2
        // Completamente fuera de la pantalla al arrancar
        let hiddenRect = NSRect(
            x: screenFrame.maxX + 10, // fuera de la pantalla
            y: y,
            width: fullWidth,
            height: windowHeight
        )
        super.init(
            contentRect: hiddenRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.hasShadow = true
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = false
        let shelfView = ShelfView(frame: NSRect(x: 0, y: 0, width: fullWidth, height: windowHeight))
        shelfView.wantsLayer = true
        shelfView.layer?.cornerRadius = 28
        shelfView.layer?.masksToBounds = true
        self.contentView = shelfView
        startEdgeDetection()
    }

    private func startEdgeDetection() {
        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            self?.checkCursorNearEdge()
        }
    }

    private func checkCursorNearEdge() {
        guard let screen = NSScreen.main else { return }
        let mouseLoc = NSEvent.mouseLocation
        let edgeZone = NSRect(
            x: screen.frame.maxX - 2,
            y: screen.frame.minY,
            width: 2,
            height: screen.frame.height
        )
        if edgeZone.contains(mouseLoc) {
            showShelf()
        }
    }

    func showShelf() {
        guard !isShown else { return }
        isShown = true
        hideTimer?.invalidate()
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let y = screenFrame.midY - windowHeight / 2
        let shownRect = NSRect(
            x: screenFrame.maxX - fullWidth,
            y: y,
            width: fullWidth,
            height: windowHeight
        )
        setFrame(shownRect, display: true, animate: true)
        scheduleAutoHide()
    }

    private func scheduleAutoHide() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            self?.hideShelf()
        }
    }

    func hideShelf() {
        guard isShown else { return }
        isShown = false
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let y = screenFrame.midY - windowHeight / 2
        let hiddenRect = NSRect(
            x: screenFrame.maxX + 10, // fuera de la pantalla
            y: y,
            width: fullWidth,
            height: windowHeight
        )
        setFrame(hiddenRect, display: true, animate: true)
    }
} 