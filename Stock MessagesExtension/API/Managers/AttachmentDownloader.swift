//
//  AttachmentDownloader.swift
//  Stock MessagesExtension
//
//  Created by Ayden Panhuyzen on 2019-07-20.
//  Copyright © 2019 Ayden Panhuyzen. All rights reserved.
//

import Foundation

class AttachmentDownloader {
    weak var delegate: AttachmentDownloaderDelegate?
    
    private var downloadInfo: (photo: StockPhoto, task: URLSessionDownloadTask)? {
        didSet { delegate?.currentlyDownloadingPhotoChanged(to: downloadInfo?.photo) }
    }
    
    var currentlyDownloadingPhoto: StockPhoto? {
        return downloadInfo?.photo
    }
    
    func download(photo: StockPhoto, completion: @escaping (Result<Attachment, Error>) -> Void) {
        guard downloadInfo?.photo.fullImageURL != photo.fullImageURL else { return }
        // Cancel existing download
        downloadInfo?.task.cancel()
        
        let task = URLSession.shared.downloadTask(with: photo.fullImageURL) { (fileURL, _, error) in
            self.downloadInfo = nil
            
            guard let fileURL = fileURL, error == nil else { completion(.failure(error ?? StockPhotoSearchError.noData)); return }
            
            do {
                // Messages ignores our alternate filename (its a bug since iOS 10) so we're going to move it to our temporary directory with a better filename so it doesn't think its some random other filetype yay extra code
                let fileExtension = try self.findAppropriateFileExtensionForFile(at: fileURL)
                let betterFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(UUID().uuidString)-\(photo.fullImageURL.lastPathComponent)\(try fileExtension)")
            
                try FileManager.default.moveItem(at: fileURL, to: betterFileURL)
                completion(.success(Attachment(fileURL: betterFileURL)))
            } catch let error {
                completion(.failure(error))
            }
        }
        task.resume()
        downloadInfo = (photo: photo, task: task)
    }
    
    private func findAppropriateFileExtensionForFile(at url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        
        var values = [UInt8](repeating: 0, count:  1)
        data.copyBytes(to: &values, count: 1)
        
        // Values from: https://stackoverflow.com/a/43250864/5539613
        switch values[0] {
        case 0xFF: return ".jpg"
        case 0x47: return ".gif"
        case 0x49, 0x4D: return ".tiff"
        default: return ".png"
        }
    }
    
    struct Attachment {
        let fileURL: URL
        
        func cleanUp() {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
}

protocol AttachmentDownloaderDelegate: class {
    func currentlyDownloadingPhotoChanged(to photo: StockPhoto?)
}
