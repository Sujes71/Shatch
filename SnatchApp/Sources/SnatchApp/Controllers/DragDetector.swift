import Foundation
import AppKit
import UniformTypeIdentifiers

protocol DragDetectorDelegate: AnyObject {
    func didAddFiles(_ files: [FileItem])
}

class DragDetector {
    weak var delegate: DragDetectorDelegate?
    
    // Cache para evitar duplicados
    private var processedContentHashes: Set<String> = []
    
    // Tipos de contenido web que podemos manejar
    private let webContentTypes = [
        "public.url",
        "public.plain-text", 
        "public.html",
        "public.image",
        "public.file-url",
        "com.apple.web-inspector.plain-text",
        "com.apple.pasteboard.promised-file-url"
    ]
    
    func handleDrag(with urls: [URL]) {
        guard !urls.isEmpty else { return }
        let item: FileItem
        if urls.count == 1 {
            item = FileItem(url: urls[0])
        } else {
            item = FileItem(urls: urls)
        }
        delegate?.didAddFiles([item])
    }
    
    func handleWebContent(from pasteboard: NSPasteboard) {
        var createdFiles: [FileItem] = []
        
        // Verificar si hay imagen en el pasteboard (múltiples métodos)
        let hasImage = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage != nil ||
                       pasteboard.availableType(from: [NSPasteboard.PasteboardType("public.tiff")]) != nil ||
                       pasteboard.availableType(from: [NSPasteboard.PasteboardType("public.png")]) != nil ||
                       pasteboard.availableType(from: [NSPasteboard.PasteboardType("public.jpeg")]) != nil ||
                       pasteboard.availableType(from: [NSPasteboard.PasteboardType("public.image")]) != nil
        
        // Verificar si el texto contiene indicios de ser una imagen (como "image", "img", etc.)
        let textContent = pasteboard.string(forType: .string) ?? ""
        let hasImageIndicators = (textContent.lowercased().contains("image") || 
                                  textContent.lowercased().contains("photo") ||
                                  textContent.lowercased().contains("picture")) &&
                                 !textContent.lowercased().contains("http") &&
                                 !textContent.lowercased().contains("www")
        
        // Si hay indicios de imagen, tratar como imagen
        let shouldTreatAsImage = hasImage // Solo imágenes reales, no indicios de texto
        
        // PRIORIDAD 1: IMÁGENES - Si es imagen, SOLO procesar como imagen
        if shouldTreatAsImage {
            // Intentar obtener imagen real
            if let image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage {
                let imageHash = hashImage(image)
                if !processedContentHashes.contains(imageHash) {
                    if let fileItem = createFileFromImage(image) {
                        createdFiles.append(fileItem)
                        processedContentHashes.insert(imageHash)
                    }
                }
            } else if let tiffData = pasteboard.data(forType: NSPasteboard.PasteboardType("public.tiff")),
                      let image = NSImage(data: tiffData) {
                let imageHash = hashImage(image)
                if !processedContentHashes.contains(imageHash) {
                    if let fileItem = createFileFromImage(image) {
                        createdFiles.append(fileItem)
                        processedContentHashes.insert(imageHash)
                    }
                }
            } else if hasImageIndicators {
                // Si no podemos obtener la imagen pero hay indicios, crear un placeholder
                let timestamp = Int(Date().timeIntervalSince1970)
                let filename = "image_\(timestamp).png"
                let tempURL = getTempDirectory().appendingPathComponent(filename)
                
                // Crear un archivo de texto con información sobre la imagen
                let content = """
                Image content detected but could not be extracted.
                Original text: \(textContent)
                Date: \(Date().formatted())
                """
                
                do {
                    try content.write(to: tempURL, atomically: true, encoding: .utf8)
                    let fileItem = FileItem(url: tempURL)
                    createdFiles.append(fileItem)
                    processedContentHashes.insert("image_placeholder_\(timestamp)")
                } catch {
                    print("Error creating image placeholder: \(error)")
                }
            }
            // IMPORTANTE: Si es imagen, NO procesar nada más
            if !createdFiles.isEmpty {
                delegate?.didAddFiles(createdFiles)
            }
            return
        }
        
        // PRIORIDAD 2: URLs (links)
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
           // Solo procesar el primer URL para evitar duplicaciones
           if let firstURL = urls.first {
               let urlHash = firstURL.absoluteString
               if !processedContentHashes.contains(urlHash) {
                   if let fileItem = createFileFromURL(firstURL) {
                       createdFiles.append(fileItem)
                       processedContentHashes.insert(urlHash)
                   }
               }
           }
        }
        
        // PRIORIDAD 3: Texto plano
        if let text = pasteboard.string(forType: .string) {
           let textHash = text.trimmingCharacters(in: .whitespacesAndNewlines)
           if !processedContentHashes.contains(textHash) {
               if let fileItem = createFileFromText(text) {
                   createdFiles.append(fileItem)
                   processedContentHashes.insert(textHash)
               }
           }
        }
        
        // PRIORIDAD 4: HTML (convertir a texto)
        if let html = pasteboard.string(forType: .html) {
           let htmlHash = html.trimmingCharacters(in: .whitespacesAndNewlines)
           if !processedContentHashes.contains(htmlHash) {
               if let fileItem = createFileFromHTML(html) {
                   createdFiles.append(fileItem)
                   processedContentHashes.insert(htmlHash)
               }
           }
        }
        
        if !createdFiles.isEmpty {
            delegate?.didAddFiles(createdFiles)
        }
    }
    
    private func createFileFromURL(_ url: URL) -> FileItem? {
        // Crear nombre seguro basado en el dominio
        let domain = url.host ?? "unknown"
        let cleanDomain = domain.replacingOccurrences(of: "www.", with: "")
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "\(cleanDomain)_\(timestamp).txt"
        
        // Crear contenido con metadata
        let content = """
        URL: \(url.absoluteString)
        Domain: \(domain)
        Date: \(Date().formatted())
        """
        
        let tempURL = getTempDirectory().appendingPathComponent(filename)
        
        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
            return FileItem(url: tempURL)
        } catch {
            print("Error creating link file: \(error)")
            return nil
        }
    }
    
    private func createFileFromText(_ text: String) -> FileItem? {
        // Crear nombre basado en el contenido
        let lines = text.components(separatedBy: .newlines)
        let firstLine = lines.first?.trimmingCharacters(in: .whitespaces) ?? "text"
        let cleanName = firstLine.replacingOccurrences(of: "[^a-zA-Z0-9]", with: "_", options: .regularExpression)
        let truncatedName = String(cleanName.prefix(30))
        let filename = "\(truncatedName).txt"
        
        let tempURL = getTempDirectory().appendingPathComponent(filename)
        
        do {
            try text.write(to: tempURL, atomically: true, encoding: .utf8)
            return FileItem(url: tempURL)
        } catch {
            print("Error creating text file: \(error)")
            return nil
        }
    }
    
    private func createFileFromImage(_ image: NSImage) -> FileItem? {
        // Crear nombre descriptivo para imagen
        let filename = "image_\(Int(Date().timeIntervalSince1970)).png"
        let tempURL = getTempDirectory().appendingPathComponent(filename)
        
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            print("Error converting image to PNG")
            return nil
        }
        
        do {
            try pngData.write(to: tempURL)
            return FileItem(url: tempURL)
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    private func createFileFromHTML(_ html: String) -> FileItem? {
        // Convertir HTML a texto plano (básico)
        let plainText = html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Crear nombre basado en el contenido HTML
        let lines = plainText.components(separatedBy: .newlines)
        let firstLine = lines.first?.trimmingCharacters(in: .whitespaces) ?? "web_content"
        let cleanName = firstLine.replacingOccurrences(of: "[^a-zA-Z0-9]", with: "_", options: .regularExpression)
        let truncatedName = String(cleanName.prefix(30))
        let filename = "\(truncatedName).txt"
        
        let tempURL = getTempDirectory().appendingPathComponent(filename)
        
        do {
            try plainText.write(to: tempURL, atomically: true, encoding: .utf8)
            return FileItem(url: tempURL)
        } catch {
            print("Error creating HTML file: \(error)")
            return nil
        }
    }
    
    private func getTempDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let snatchDir = tempDir.appendingPathComponent("Snatch")
        
        // Crear directorio si no existe
        if !FileManager.default.fileExists(atPath: snatchDir.path) {
            try? FileManager.default.createDirectory(at: snatchDir, withIntermediateDirectories: true)
        }
        
        return snatchDir
    }
    
    // Método para limpiar cache cuando se borran archivos
    func clearContentCache() {
        processedContentHashes.removeAll()
    }
    
    private func hashImage(_ image: NSImage) -> String {
        // Crear un hash más robusto basado en el contenido de la imagen
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { 
            return "unknown" 
        }
        
        let size = image.size
        let width = Int(size.width)
        let height = Int(size.height)
        
        // Crear un hash basado en muestras de píxeles
        var hashComponents: [String] = []
        hashComponents.append("\(width)x\(height)")
        
        // Muestrear píxeles en diferentes posiciones para crear un hash único
        let samplePoints = [
            (0, 0),                    // Esquina superior izquierda
            (width/2, 0),              // Centro superior
            (width-1, 0),              // Esquina superior derecha
            (0, height/2),             // Centro izquierda
            (width/2, height/2),       // Centro
            (width-1, height/2),       // Centro derecha
            (0, height-1),             // Esquina inferior izquierda
            (width/2, height-1),       // Centro inferior
            (width-1, height-1)        // Esquina inferior derecha
        ]
        
        for (x, y) in samplePoints {
            if x < width && y < height {
                let color = bitmap.colorAt(x: x, y: y) ?? NSColor.clear
                let red = Int(color.redComponent * 255)
                let green = Int(color.greenComponent * 255)
                let blue = Int(color.blueComponent * 255)
                hashComponents.append("\(red),\(green),\(blue)")
            }
        }
        
        // También incluir el hash de los datos TIFF como respaldo
        hashComponents.append("\(tiffData.count)")
        
        return hashComponents.joined(separator: "_")
    }
} 