import Cocoa
import UniformTypeIdentifiers

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
        let newFiles = urls.filter { url in
            !files.contains(where: { $0.urls.contains(url) })
        }
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
        // Icono de descarga grande y centrado
        if let downloadIcon = NSImage(named: NSImage.touchBarDownloadTemplateName) {
            let iconSize: CGFloat = 48
            let iconRect = NSRect(
                x: dropRect.midX - iconSize/2,
                y: dropRect.midY - iconSize/2,
                width: iconSize,
                height: iconSize
            )
            downloadIcon.size = NSSize(width: iconSize, height: iconSize)
            downloadIcon.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 0.7)
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
        updateDocumentView()
        windowRef?.updateWindowHeight(forItemCount: files.count)
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
        let draggingItems: [NSDraggingItem] = file.urls.enumerated().map { (i, url) in
            let pasteboardItem = NSPasteboardItem()
            pasteboardItem.setString(url.absoluteString, forType: .fileURL)
            let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
            let y = bounds.height - dropAreaHeight - CGFloat(index + 1 + i) * itemHeight
            let rect = NSRect(x: 16, y: y, width: bounds.width - 32, height: itemHeight)
            // Icono real de cada archivo
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            icon.size = NSSize(width: 128, height: 128)
            let image = NSImage(size: NSSize(width: 128, height: 128))
            image.lockFocus()
            icon.draw(in: NSRect(x: 0, y: 0, width: 128, height: 128))
            image.unlockFocus()
            draggingItem.setDraggingFrame(rect, contents: image)
            return draggingItem
        }
        draggingIndex = index
        beginDraggingSession(with: draggingItems, event: event, source: self)
    }

    private func makeDragImage(for file: FileItem) -> NSImage {
        let iconSize: CGFloat = 128
        if file.urls.count == 1 {
            let icon = NSWorkspace.shared.icon(forFile: file.urls[0].path)
            icon.size = NSSize(width: iconSize, height: iconSize)
            let image = NSImage(size: NSSize(width: iconSize, height: iconSize))
            image.lockFocus()
            icon.draw(in: NSRect(x: 0, y: 0, width: iconSize, height: iconSize))
            image.unlockFocus()
            return image
        } else {
            // Grupo: iconos apilados
            var icons: [NSImage] = []
            var seenTypes = Set<String>()
            for url in file.urls {
                let type = (try? url.resourceValues(forKeys: [.contentTypeKey]).contentType) ?? nil
                let icon: NSImage
                if let type = type {
                    if type == .folder {
                        icon = NSWorkspace.shared.icon(for: UTType.folder)
                    } else if type.conforms(to: .image) {
                        icon = NSWorkspace.shared.icon(for: UTType.jpeg)
                    } else if type.conforms(to: .plainText) {
                        icon = NSWorkspace.shared.icon(for: UTType.plainText)
                    } else {
                        icon = NSWorkspace.shared.icon(forFile: url.path)
                    }
                    if !seenTypes.contains(type.identifier) {
                        icons.append(icon)
                        seenTypes.insert(type.identifier)
                    }
                } else {
                    icon = NSWorkspace.shared.icon(forFile: url.path)
                    icons.append(icon)
                }
                if icons.count == 3 { break }
            }
            // Si hay menos de 3 tipos, repite el primero
            while icons.count < 3 {
                icons.append(icons.first ?? NSWorkspace.shared.icon(for: UTType.folder))
            }
            // Componer imagen apilada
            let stackOffset: CGFloat = 24
            let image = NSImage(size: NSSize(width: iconSize + stackOffset * 2, height: iconSize + stackOffset * 2))
            image.lockFocus()
            for (i, icon) in icons.prefix(3).enumerated().reversed() {
                icon.size = NSSize(width: iconSize, height: iconSize)
                let offset = CGFloat(i) * stackOffset
                icon.draw(in: NSRect(x: offset, y: offset, width: iconSize, height: iconSize), from: .zero, operation: .sourceOver, fraction: 1.0)
            }
            image.unlockFocus()
            return image
        }
    }

    var fileCount: Int { files.count }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        self.trackingAreas.forEach { self.removeTrackingArea($0) }
        let area = NSTrackingArea(rect: self.bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self, userInfo: nil)
        self.addTrackingArea(area)
    }

    override func mouseEntered(with event: NSEvent) {
        windowRef?.cancelAutoHide()
    }

    override func mouseExited(with event: NSEvent) {
        windowRef?.scheduleAutoHide()
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
            updateDocumentView()
            windowRef?.updateWindowHeight(forItemCount: files.count)
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
        if file.urls.count == 1 {
            let icon = NSWorkspace.shared.icon(forFile: file.urls[0].path)
            icon.size = NSSize(width: iconSize, height: iconSize)
            let iconRect = NSRect(x: 24, y: (bounds.height - iconSize)/2, width: iconSize, height: iconSize)
            icon.draw(in: iconRect)
        } else {
            // Grupo: iconos apilados solo de tipos distintos (sin límite)
            var icons: [NSImage] = []
            var seenTypes = Set<String>()
            for url in file.urls {
                let type = (try? url.resourceValues(forKeys: [.contentTypeKey]).contentType) ?? nil
                let icon: NSImage
                let typeId: String
                if let type = type {
                    typeId = type.identifier
                    if type == .folder {
                        icon = NSWorkspace.shared.icon(for: UTType.folder)
                    } else if type.conforms(to: .image) {
                        icon = NSWorkspace.shared.icon(for: UTType.jpeg)
                    } else if type.conforms(to: .plainText) {
                        icon = NSWorkspace.shared.icon(for: UTType.plainText)
                    } else {
                        icon = NSWorkspace.shared.icon(forFile: url.path)
                    }
                } else {
                    typeId = url.pathExtension.lowercased()
                    icon = NSWorkspace.shared.icon(forFile: url.path)
                }
                if !seenTypes.contains(typeId) {
                    icons.append(icon)
                    seenTypes.insert(typeId)
                }
            }
            // Dibuja todos los iconos realmente distintos
            let stackOffset: CGFloat = 8
            for (i, icon) in icons.enumerated().reversed() {
                icon.size = NSSize(width: iconSize, height: iconSize)
                let offset = CGFloat(i) * stackOffset
                let iconRect = NSRect(x: 24 + offset, y: (bounds.height - iconSize)/2 - offset, width: iconSize, height: iconSize)
                icon.draw(in: iconRect)
            }
        }
        let nameAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: SolarizedTheme.base0,
            .font: NSFont.systemFont(ofSize: 15)
        ]
        let nameRect = NSRect(x: 24 + iconSize + 12, y: (bounds.height - 20)/2, width: bounds.width - 24 - iconSize - 32, height: 20)
        file.name.draw(in: nameRect, withAttributes: nameAttrs)
    }
} 