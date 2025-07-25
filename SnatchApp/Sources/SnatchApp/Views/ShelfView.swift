import Cocoa

class ShelfView: NSView, DragDetectorDelegate {
    private var files: [FileItem] = []
    private let dragDetector = DragDetector()
    private var isDragOver = false
    private let dropAreaHeight: CGFloat = 80
    private let itemHeight: CGFloat = 48
    private let iconSize: CGFloat = 32
    private var draggingIndex: Int? = nil
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.backgroundColor = SolarizedTheme.base03.cgColor
        registerForDraggedTypes([.fileURL])
        dragDetector.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Drag & Drop: entrada
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        isDragOver = true
        setNeedsDisplay(bounds)
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        isDragOver = false
        setNeedsDisplay(bounds)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        isDragOver = false
        setNeedsDisplay(bounds)
        let pasteboard = sender.draggingPasteboard
        let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] ?? []
        guard !urls.isEmpty else { return false }
        // Evitar duplicados
        let newFiles = urls.filter { url in !files.contains(where: { $0.url == url }) }
        guard !newFiles.isEmpty else { return false }
        dragDetector.handleDrag(with: newFiles)
        return true
    }

    func didAddFiles(_ files: [FileItem]) {
        self.files.append(contentsOf: files)
        setNeedsDisplay(bounds)
    }

    // Aquí se añadirá la lógica para mostrar archivos y permitir drag out
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
        // Lista de archivos/carpeta
        for (i, file) in files.enumerated() {
            let y = bounds.height - dropAreaHeight - CGFloat(i + 1) * itemHeight
            let iconRect = NSRect(x: 24, y: y + (itemHeight - iconSize)/2, width: iconSize, height: iconSize)
            let icon = NSWorkspace.shared.icon(forFile: file.url.path)
            icon.size = NSSize(width: iconSize, height: iconSize)
            icon.draw(in: iconRect)
            let nameAttrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: SolarizedTheme.base0,
                .font: NSFont.systemFont(ofSize: 15)
            ]
            let nameRect = NSRect(x: 24 + iconSize + 12, y: y + (itemHeight - 20)/2, width: bounds.width - 24 - iconSize - 32, height: 20)
            file.name.draw(in: nameRect, withAttributes: nameAttrs)
        }
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
        let icon = NSWorkspace.shared.icon(forFile: file.url.path)
        icon.size = NSSize(width: iconSize, height: iconSize)
        draggingItem.setDraggingFrame(rect, contents: icon)
        draggingIndex = index
        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }
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