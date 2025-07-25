import Cocoa

class ShelfWindow: NSWindow {
    private let tabWidth: CGFloat = 16
    private let fullWidth: CGFloat = 240
    private let windowHeight: CGFloat = 400
    private let animationDuration: TimeInterval = 0.25
    private let showAnimationDuration: TimeInterval = 0.3
    private let hideAnimationDuration: TimeInterval = 0.2
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
        
        // Animación inicial suave
        self.alphaValue = 0.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.4
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                self.animator().alphaValue = 0.8
            })
        }
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
        
        // Cancelar animaciones previas
        contentView?.layer?.removeAllAnimations()
        
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
        
        // Animación suave de entrada
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = showAnimationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            // Animar frame
            animator().setFrame(shownRect, display: true)
            
            // Animar opacidad (fade in)
            animator().alphaValue = 1.0
            
            // Animar escala (slight bounce effect)
            let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
            scaleAnimation.fromValue = 0.95
            scaleAnimation.toValue = 1.0
            scaleAnimation.duration = showAnimationDuration
            scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            contentView?.layer?.add(scaleAnimation, forKey: "scale")
        }) {
            // Completado
            // Asegurar estado final correcto
            self.alphaValue = 1.0
            (self.contentView as? ShelfView)?.frame = NSRect(x: 0, y: 0, width: self.frame.width, height: useHeight)
            (self.contentView as? ShelfView)?.layout()
        }
        
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
        
        // Cancelar animaciones previas
        contentView?.layer?.removeAllAnimations()
        
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let y = screenFrame.midY - minHeight / 2
        // Solo asoma 10px en el borde derecho
        let hiddenRect = NSRect(
            x: screenFrame.maxX - 10,
            y: y,
            width: fullWidth,
            height: minHeight
        )
        
        // Animación suave de salida
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = hideAnimationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            
            // Animar frame
            animator().setFrame(hiddenRect, display: true)
            
            // Animar opacidad (fade out parcial)
            animator().alphaValue = 0.8
            
            // Animar escala (slight shrink)
            let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
            scaleAnimation.fromValue = 1.0
            scaleAnimation.toValue = 0.98
            scaleAnimation.duration = hideAnimationDuration
            scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
            contentView?.layer?.add(scaleAnimation, forKey: "scale")
        }) {
            // Completado
            // Asegurar estado final correcto
            self.alphaValue = 0.8
            (self.contentView as? ShelfView)?.frame = NSRect(x: 0, y: 0, width: self.frame.width, height: self.minHeight)
            (self.contentView as? ShelfView)?.layout()
        }
    }

    func updateWindowHeight(forItemCount count: Int) {
        let visibleItems = min(count, maxVisibleItems)
        let newHeight = dropAreaHeight + CGFloat(visibleItems) * itemHeight
        lastKnownHeight = newHeight
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let y = screenFrame.midY - newHeight / 2
        let newRect = NSRect(x: frame.origin.x, y: y, width: frame.width, height: newHeight)
        
        // Solo animar si está visible y no está en medio de show/hide
        guard isShown else {
            // Si está oculto, solo actualizar el frame sin animar
            setFrame(newRect, display: true, animate: false)
            (contentView as? ShelfView)?.frame = NSRect(x: 0, y: 0, width: frame.width, height: newHeight)
            (contentView as? ShelfView)?.layout()
            return
        }
        
        // Animación suave de cambio de altura
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            // Animar frame
            animator().setFrame(newRect, display: true)
        }) {
            // Completado
            (self.contentView as? ShelfView)?.frame = NSRect(x: 0, y: 0, width: self.frame.width, height: newHeight)
            (self.contentView as? ShelfView)?.layout()
        }
    }
} 