import Cocoa

class ShelfWindow: NSWindow {
    private let tabWidth: CGFloat = 16
    private let minWidth: CGFloat = 320
    private let maxWidth: CGFloat = 960 // 3 columnas
    private let minHeight: CGFloat = 80 // solo drop
    private let itemHeight: CGFloat = 48
    private let dropAreaHeight: CGFloat = 80
    private let animationDuration: TimeInterval = 0.25
    private var isShown = false
    private var hideTimer: Timer?
    private var fileCount: Int = 0 // para ajustar tamaño

    init() {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let y = screenFrame.midY - minHeight / 2
        let hiddenRect = NSRect(
            x: screenFrame.maxX + 10,
            y: y,
            width: minWidth,
            height: minHeight
        )
        super.init(
            contentRect: hiddenRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = SolarizedTheme.base03
        self.level = .floating
        self.hasShadow = true
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = false
        let shelfView = ShelfView(frame: NSRect(x: 0, y: 0, width: minWidth, height: minHeight))
        shelfView.onFileCountChanged = { [weak self] count in
            self?.adjustWindowSize(for: count)
        }
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
        let y = screenFrame.midY - minHeight / 2
        let shownRect = NSRect(
            x: screenFrame.maxX - minWidth,
            y: y,
            width: minWidth,
            height: minHeight
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
        let y = screenFrame.midY - minHeight / 2
        let hiddenRect = NSRect(
            x: screenFrame.maxX + 10, // fuera de la pantalla
            y: y,
            width: minWidth,
            height: minHeight
        )
        setFrame(hiddenRect, display: true, animate: true)
    }

    private func adjustWindowSize(for fileCount: Int) {
        self.fileCount = fileCount
        let columns = min(3, max(1, (fileCount + 4) / 5))
        let rows = fileCount == 0 ? 0 : ((fileCount - 1) / columns + 1)
        let width = minWidth * CGFloat(columns)
        let height = max(minHeight, dropAreaHeight + CGFloat(rows) * itemHeight)
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let y = screenFrame.midY - height / 2
        let x = screenFrame.maxX - width
        let newRect = NSRect(x: x, y: y, width: width, height: height)
        setFrame(newRect, display: true, animate: true)
        (contentView as? ShelfView)?.frame = NSRect(x: 0, y: 0, width: width, height: height)
    }
} 