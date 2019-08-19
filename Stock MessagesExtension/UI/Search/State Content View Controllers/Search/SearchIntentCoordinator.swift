//
//  SearchIntentCoordinator.swift
//  Stock MessagesExtension
//
//  Created by Ayden Panhuyzen on 2019-07-20.
//  Copyright © 2019 Ayden Panhuyzen. All rights reserved.
//

import Foundation

class SearchIntentCoordinator {
    weak var delegate: SearchIntentCoordinatorDelegate?
    private var runningIntents = Set<StockPhotoSearchManager.SearchIntent>(), nextIntents = [StockPhotoSearchManager.SearchIntent]()
    
    func run(intents: [StockPhotoSearchManager.SearchIntent]) {
        let limit = concurrentIntentLimit - runningIntents.count
        for intent in intents.prefix(concurrentIntentLimit) {
            runningIntents.insert(intent)
            StockPhotoSearchManager.shared.search(intent: intent) { (result) in
                self.runningIntents.remove(intent)
                // Handle result
                switch result {
                case .success(let results):
                    DispatchQueue.main.async {
                        self.delegate?.add(photos: results.photos)
                        self.delegate?.intentStateChanged()
                    }
                    if let token = results.paginationToken {
                        self.nextIntents.append(intent.createNextPaginationIntent(paginationToken: token))
                    }
                case .failure(let error):
                    print("Failed to retrieve results for intent (\(intent)) due to error:", error)
                    DispatchQueue.main.async {
                        self.delegate?.intentStateChanged()
                    }
                }
            }
        }
        if intents.count > limit {
            nextIntents.append(contentsOf: intents.dropFirst(limit))
        }
        delegate?.intentStateChanged()
    }
    
    func runNextIntents() {
        guard !nextIntents.isEmpty else { return }
        let limit = concurrentIntentLimit - runningIntents.count
        let intentsToQueue = Array(nextIntents.prefix(limit))
        self.nextIntents.removeFirst(min(limit, nextIntents.count))
        run(intents: intentsToQueue)
    }
    
    var isRunningIntents: Bool {
        return !runningIntents.isEmpty
    }
    
    func resetIntents() {
        // Cancel any outstanding requests...
        runningIntents.forEach { $0.cancel() }
        
        // ...and then remove them!
        runningIntents.removeAll()
        nextIntents.removeAll()
    }
    
    /// The maximum number of intents that can execute simultaneously.
    var concurrentIntentLimit = 3
}

protocol SearchIntentCoordinatorDelegate: class {
    func add(photos: [StockPhoto])
    func intentStateChanged()
}
