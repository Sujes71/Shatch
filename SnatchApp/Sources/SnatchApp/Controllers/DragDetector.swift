import Foundation

protocol DragDetectorDelegate: AnyObject {
    func didAddFiles(_ files: [FileItem])
}

class DragDetector {
    weak var delegate: DragDetectorDelegate?
    
    func handleDrag(with urls: [URL]) {
        let items = urls.map { FileItem(url: $0) }
        delegate?.didAddFiles(items)
    }
} 