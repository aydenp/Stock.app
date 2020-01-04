//
//  ThumbnailManager.swift
//  Stock MessagesExtension
//
//  Created by Ayden Panhuyzen on 2019-07-20.
//  Copyright © 2019 Ayden Panhuyzen. All rights reserved.
//

import UIKit

class ThumbnailManager {
    static let shared = ThumbnailManager()
    private var cache = NSCache<NSURL, UIImage>()
    private var currentDataTasks = [URL: URLSessionDataTask](), receiversForURL = [URL: NSHashTable<AnyObject>](), prefetchRequests = [URL]()
    private var accessQueue = DispatchQueue(label: "ThumbnailManagerQueue", attributes: .concurrent)
    
    private init() {}
    
    // MARK: - Thumbnail Receiving
    
    func getThumbnail(at url: URL, for receiver: ThumbnailReceiving) {
        if let cached = cache.object(forKey: url as NSURL) {
            receiver.received(thumbnail: cached, from: url)
            return
        }
        
        // Add receiver
        accessQueue.sync {
            if !receiversForURL.keys.contains(url) {
                receiversForURL[url] = NSHashTable.weakObjects()
            }
            accessQueue.async(flags: .barrier) {
                self.receiversForURL[url]!.add(receiver)
            }
        }
        
        // Fetch thumbnail
        _fetchThumbnail(at: url)
    }
    
    func stopReceivingThumbnail(at url: URL, for receiver: ThumbnailReceiving) {
        accessQueue.sync {
            // Remove receiver
            guard receiversForURL.keys.contains(url) else { return }
            
            accessQueue.async(flags: .barrier) {
                self.receiversForURL[url]!.remove(receiver)
            }
            
            // Check if we need to cancel
            _cancelRequestIfNecessary(for: url)
        }
    }
    
    // MARK: - Thumbnail Prefetching
    
    func prefetchThumbnail(at url: URL) {
        // Make sure we don't have a cached image already
        guard cache.object(forKey: url as NSURL) == nil else { return }
        
        // Record this request to prefetch so we can count if it is cancelled later
        accessQueue.async(flags: .barrier) {
            self.prefetchRequests.append(url)
        }
        
        // Fetch thumbnail
        _fetchThumbnail(at: url)
    }
    
    func cancelPrefetchOfThumbnail(at url: URL) {
        // Remove first prefetch request we can see
        accessQueue.sync {
            if let index = self.prefetchRequests.firstIndex(of: url) {
                accessQueue.async(flags: .barrier) {
                    self.prefetchRequests.remove(at: index)
                }
            }
            
            // Check if we need to cancel
            _cancelRequestIfNecessary(for: url)
        }
    }
    
    // MARK: - Request Handling
    
    private func _fetchThumbnail(at url: URL) {
        accessQueue.sync {
            // Only one request per URL!
            guard currentDataTasks[url] == nil else { return }
            
            let task = URLSession.shared.dataTask(with: url) { (data, _, error) in
                self.accessQueue.async(flags: .barrier) {
                    self.currentDataTasks[url] = nil
                    
                    // Clear prefetch requests
                    self.prefetchRequests = self.prefetchRequests.filter { $0 != url }
                }
                
                if error == nil, let data = data, let image = UIImage(data: data) {
                    // Cache image
                    self.cache.setObject(image, forKey: url as NSURL)
                    
                    self.accessQueue.sync {
                        // Notify receivers
                        if let enumerator = self.receiversForURL[url]?.objectEnumerator() {
                            while let receiver = enumerator.nextObject() as? ThumbnailReceiving {
                                receiver.received(thumbnail: image, from: url)
                            }
                        }
                    }
                } else {
                    print("Couldn't load thumbnail due to error: ", error ?? "unknown")
                }
                
                self.accessQueue.async(flags: .barrier) {
                    self.receiversForURL.removeValue(forKey: url)
                }
            }
            
            task.resume()
            self.accessQueue.async(flags: .barrier) {
                self.currentDataTasks[url] = task
            }
        }
    }
    
    private func _cancelRequestIfNecessary(for url: URL) {
        guard let task = currentDataTasks[url] else { return }
        // Only cancel if nobody wants the image anymore and nobody is prefetching it
        let hasReceivers = receiversForURL[url]?.count ?? 0 > 0, hasPrefetchRequests = !prefetchRequests.filter { $0 == url }.isEmpty
        guard !hasReceivers && !hasPrefetchRequests else { return }
        task.cancel()
        accessQueue.async(flags: .barrier) {
            self.currentDataTasks.removeValue(forKey: url)
        }
    }
}

protocol ThumbnailReceiving: class {
    func received(thumbnail: UIImage, from url: URL)
}
