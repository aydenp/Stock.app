//
//  PersistentStockPhotoStore.swift
//  Stock MessagesExtension
//
//  Created by Ayden Panhuyzen on 2019-07-21.
//  Copyright © 2019 Ayden Panhuyzen. All rights reserved.
//

import Foundation
import StockKit

class PersistentStockPhotoStore {
    static let favourites = PersistentStockPhotoStore(name: "Favourites"), recents = PersistentStockPhotoStore(name: "Recents", limit: 30)
    
    static let didChangeNotification = Notification.Name("PersistentStockPhotoStore.didChangeNotification.name")
    private let key: String, _photos: NSMutableOrderedSet
    let limit: Int?
    
    /**
     Initialize the photo store with the provided parameters.
     
     - parameter name: The name to store photos with. This must be unique, as it is used for persistence.
     - parameter limit: The optional limit to enforce when adding items. If too many items are added, the oldest will be removed first.
         */
    init(name: String, limit: Int? = nil) {
        self.key = "Stock.PersistentStockPhotoStore.\(name)"
        self.limit = limit
        if let data = UserDefaults.standard.data(forKey: key), let photos = try? JSONDecoder().decode([StockPhoto].self, from: data) {
            self._photos = NSMutableOrderedSet(array: photos)
        } else {
            self._photos = NSMutableOrderedSet()
        }
    }
    
    var photos: [StockPhoto] {
        return _photos.array as! [StockPhoto]
    }
    
    func add(photo: StockPhoto) {
        _photos.add(photo)
        if let limit = limit, _photos.count > limit {
            let newStartItemIndex = _photos.count - limit
            _photos.removeObjects(at: IndexSet(integersIn: 0..<newStartItemIndex))
        }
        dataDidChange()
    }
    
    func remove(photo: StockPhoto) {
        _photos.remove(photo)
        dataDidChange()
    }
    
    func clear() {
        _photos.removeAllObjects()
        dataDidChange()
    }
    
    private func dataDidChange() {
        // Post update notification
        NotificationCenter.default.post(name: PersistentStockPhotoStore.didChangeNotification, object: self)
        
        // Save to user defaults
        do {
            let data = try JSONEncoder().encode(photos)
            UserDefaults.standard.set(data, forKey: key)
        } catch let error {
            print("An error occurred while attempting to save persistent stock photo store (key: \(key)):", error)
        }
    }
}
