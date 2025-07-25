import Foundation

struct FileItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let name: String
    let dateAdded: Date
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        self.dateAdded = Date()
    }
} 