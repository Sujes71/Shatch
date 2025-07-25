import Foundation

protocol DragDetectorDelegate: AnyObject {
    func didAddFiles(_ files: [FileItem])
}

class DragDetector {
    weak var delegate: DragDetectorDelegate?
    
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
} 