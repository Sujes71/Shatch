import Cocoa

class ShelfWindow: NSWindow {
    private let tabWidth: CGFloat = 16
    private let fullWidth: CGFloat = 240
    private let windowHeight: CGFloat = 400
    private let animationDuration: TimeInterval = 0.25
    var isShown = false
    private var hideTimer: Timer?
    let dropAreaHeight: CGFloat = 80
    let itemHeight: CGFloat = 48
    let maxVisibleItems: Int = 5
    let minHeight: CGFloat
    let maxHeight: CGFloat
    private var lastKnownHeight: CGFloat

    init() {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        minHeight = dropAreaHeight
        maxHeight = dropAreaHeight + CGFloat(maxVisibleItems) * itemHeight
        lastKnownHeight = minHeight
        let shelfViewFrame = NSRect(x: 0, y: 0, width: fullWidth, height: minHeight)
        let y = screenFrame.midY - minHeight / 2
        // Asoma 10px desde el arranque
        let hiddenRect = NSRect(
            x: screenFrame.maxX - 10,
            y: y,
            width: fullWidth,
            height: minHeight
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
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = false
        let shelfView = ShelfView(frame: shelfViewFrame, window: self)
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
        let itemCount = (contentView as? ShelfView)?.fileCount ?? 0
        let useHeight = itemCount > 0 ? lastKnownHeight : minHeight
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let y = screenFrame.midY - useHeight / 2
        let shownRect = NSRect(
            x: screenFrame.maxX - fullWidth,
            y: y,
            width: fullWidth,
            height: useHeight
        )
        setFrame(shownRect, display: true, animate: true)
        (contentView as? ShelfView)?.frame = NSRect(x: 0, y: 0, width: frame.width, height: useHeight)
        (contentView as? ShelfView)?.layout()
        scheduleAutoHide()
    }

    func scheduleAutoHide() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            self?.hideShelf()
        }
    }

    func cancelAutoHide() {
        hideTimer?.invalidate()
    }

    func hideShelf() {
        guard isShown else { return }
        isShown = false
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let y = screenFrame.midY - minHeight / 2
        // Solo asoma 10px en el borde derecho
        let hiddenRect = NSRect(
            x: screenFrame.maxX - 10,
            y: y,
            width: fullWidth,
            height: minHeight
        )
        setFrame(hiddenRect, display: true, animate: true)
        (contentView as? ShelfView)?.frame = NSRect(x: 0, y: 0, width: frame.width, height: minHeight)
        (contentView as? ShelfView)?.layout()
    }

    func updateWindowHeight(forItemCount count: Int) {
        let visibleItems = min(count, maxVisibleItems)
        let newHeight = dropAreaHeight + CGFloat(visibleItems) * itemHeight
        lastKnownHeight = newHeight
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let y = screenFrame.midY - newHeight / 2
        let newRect = NSRect(x: frame.origin.x, y: y, width: frame.width, height: newHeight)
        setFrame(newRect, display: true, animate: true)
        (contentView as? ShelfView)?.frame = NSRect(x: 0, y: 0, width: frame.width, height: newHeight)
        (contentView as? ShelfView)?.layout()
    }
} 