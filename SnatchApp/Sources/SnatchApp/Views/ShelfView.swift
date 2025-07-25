import Cocoa

class ShelfView: NSView, DragDetectorDelegate {
    private var files: [FileItem] = []
    private let dragDetector = DragDetector()
    private var isDragOver = false
    private let dropAreaHeight: CGFloat = 80
    private let itemHeight: CGFloat = 48
    private let iconSize: CGFloat = 32
    private var draggingIndex: Int? = nil
    private let scrollView: NSScrollView
    private let documentView: NSView
    private let maxVisibleItems: Int = 6
    private weak var windowRef: ShelfWindow?

    init(frame frameRect: NSRect, window: ShelfWindow) {
        self.windowRef = window
        scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: frameRect.width, height: frameRect.height - dropAreaHeight))
        documentView = NSView(frame: NSRect(x: 0, y: 0, width: frameRect.width, height: 0))
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.backgroundColor = SolarizedTheme.base03.cgColor
        registerForDraggedTypes([.fileURL])
        dragDetector.delegate = self
        scrollView.hasVerticalScroller = true
        scrollView.documentView = documentView
        scrollView.drawsBackground = false
        addSubview(scrollView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        scrollView.frame = NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height - dropAreaHeight)
        updateDocumentView()
    }

    private func updateDocumentView() {
        let totalHeight = CGFloat(files.count) * itemHeight
        documentView.frame = NSRect(x: 0, y: 0, width: bounds.width, height: totalHeight)
        documentView.subviews.forEach { $0.removeFromSuperview() }
        for (i, file) in files.enumerated() {
            let y = totalHeight - CGFloat(i + 1) * itemHeight
            let itemView = FileItemView(file: file, frame: NSRect(x: 0, y: y, width: bounds.width, height: itemHeight), iconSize: iconSize)
            documentView.addSubview(itemView)
        }
    }

    // Drag & Drop: entrada
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        isDragOver = true
        setNeedsDisplay(NSRect(x: 0, y: bounds.height - dropAreaHeight, width: bounds.width, height: dropAreaHeight))
        return .copy
    }
    override func draggingExited(_ sender: NSDraggingInfo?) {
        isDragOver = false
        setNeedsDisplay(NSRect(x: 0, y: bounds.height - dropAreaHeight, width: bounds.width, height: dropAreaHeight))
    }
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        isDragOver = false
        setNeedsDisplay(NSRect(x: 0, y: bounds.height - dropAreaHeight, width: bounds.width, height: dropAreaHeight))
        let pasteboard = sender.draggingPasteboard
        let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] ?? []
        let newFiles = urls.filter { url in !files.contains(where: { $0.url == url }) }
        guard !newFiles.isEmpty else { return false }
        dragDetector.handleDrag(with: newFiles)
        return true
    }

    func didAddFiles(_ files: [FileItem]) {
        self.files.append(contentsOf: files)
        updateDocumentView()
        windowRef?.updateWindowHeight(forItemCount: self.files.count)
        setNeedsDisplay(bounds)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Área de drop arriba
        let dropRect = NSRect(x: 0, y: bounds.height - dropAreaHeight, width: bounds.width, height: dropAreaHeight)
        let dropPath = NSBezierPath(roundedRect: dropRect.insetBy(dx: 8, dy: 8), xRadius: 16, yRadius: 16)
        (isDragOver ? SolarizedTheme.base01 : SolarizedTheme.base02).setFill()
        dropPath.fill()
        // Dibuja el + grande
        let plusAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: SolarizedTheme.base0,
            .font: NSFont.systemFont(ofSize: 40, weight: .bold)
        ]
        let plus = "+"
        let plusSize = plus.size(withAttributes: plusAttrs)
        let plusPoint = NSPoint(x: dropRect.midX - plusSize.width/2, y: dropRect.midY - plusSize.height/2)
        plus.draw(at: plusPoint, withAttributes: plusAttrs)
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard let (index, file) = fileAtPoint(point) else { return }
        beginDrag(for: file, at: index, event: event)
    }

    override func rightMouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard let (index, _) = fileAtPoint(point) else { return }
        let menu = NSMenu(title: "Context Menu")
        menu.addItem(withTitle: "Remove", action: #selector(removeFile(_:)), keyEquivalent: "").tag = index
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    @objc private func removeFile(_ sender: NSMenuItem) {
        let index = sender.tag
        guard files.indices.contains(index) else { return }
        files.remove(at: index)
        setNeedsDisplay(bounds)
    }

    private func fileAtPoint(_ point: NSPoint) -> (Int, FileItem)? {
        for (i, file) in files.enumerated() {
            let y = bounds.height - dropAreaHeight - CGFloat(i + 1) * itemHeight
            let rect = NSRect(x: 16, y: y, width: bounds.width - 32, height: itemHeight)
            if rect.contains(point) {
                return (i, file)
            }
        }
        return nil
    }

    private func beginDrag(for file: FileItem, at index: Int, event: NSEvent) {
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(file.url.absoluteString, forType: .fileURL)
        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        let y = bounds.height - dropAreaHeight - CGFloat(index + 1) * itemHeight
        let rect = NSRect(x: 16, y: y, width: bounds.width - 32, height: itemHeight)
        let dragImage = makeDragImage(for: file)
        draggingItem.setDraggingFrame(rect, contents: dragImage)
        draggingIndex = index
        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }

    private func makeDragImage(for file: FileItem) -> NSImage {
        let iconSize: CGFloat = 128
        let icon = NSWorkspace.shared.icon(forFile: file.url.path)
        icon.size = NSSize(width: iconSize, height: iconSize)
        let image = NSImage(size: NSSize(width: iconSize, height: iconSize))
        image.lockFocus()
        icon.draw(in: NSRect(x: 0, y: 0, width: iconSize, height: iconSize))
        image.unlockFocus()
        return image
    }

    var fileCount: Int { files.count }
}

extension ShelfView: NSDraggingSource {
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .move
    }
    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        // Eliminar el archivo de la bandeja tras un drag out exitoso
        if operation == .move, let index = draggingIndex, files.indices.contains(index) {
            files.remove(at: index)
            draggingIndex = nil
            setNeedsDisplay(bounds)
        }
    }
}

class FileItemView: NSView {
    let file: FileItem
    let iconSize: CGFloat
    init(file: FileItem, frame: NSRect, iconSize: CGFloat) {
        self.file = file
        self.iconSize = iconSize
        super.init(frame: frame)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func draw(_ dirtyRect: NSRect) {
        let icon = NSWorkspace.shared.icon(forFile: file.url.path)
        icon.size = NSSize(width: iconSize, height: iconSize)
        let iconRect = NSRect(x: 24, y: (bounds.height - iconSize)/2, width: iconSize, height: iconSize)
        icon.draw(in: iconRect)
        let nameAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: SolarizedTheme.base0,
            .font: NSFont.systemFont(ofSize: 15)
        ]
        let nameRect = NSRect(x: 24 + iconSize + 12, y: (bounds.height - 20)/2, width: bounds.width - 24 - iconSize - 32, height: 20)
        file.name.draw(in: nameRect, withAttributes: nameAttrs)
    }
} 