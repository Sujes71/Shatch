import Foundation

struct FileItem: Identifiable, Equatable {
    let id = UUID()
    let urls: [URL]
    let name: String
    let dateAdded: Date
    
    // Si es grupo, name será 'N files', si no, el nombre del archivo
    init(urls: [URL]) {
        self.urls = urls
        if urls.count == 1 {
            self.name = urls[0].lastPathComponent
        } else {
            self.name = "\(urls.count) files"
        }
        self.dateAdded = Date()
    }
    
    // Conveniencia para un solo archivo
    init(url: URL) {
        self.init(urls: [url])
    }
} 