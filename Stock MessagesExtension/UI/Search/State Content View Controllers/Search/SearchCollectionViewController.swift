//
//  SearchCollectionViewController.swift
//  Stock MessagesExtension
//
//  Created by Ayden Panhuyzen on 2019-07-20.
//  Copyright © 2019 Ayden Panhuyzen. All rights reserved.
//

import UIKit

class SearchCollectionViewController: StockPhotoCollectionViewController {
    private let loadingView = UIActivityIndicatorView(style: .gray), noItemsMessageView = MessageView(title: "No items found")
    private var items = [StockPhoto]()
    private let coordinator = SearchIntentCoordinator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.prefetchDataSource = self
        coordinator.delegate = self
        
        // Setup loading view
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)
        loadingView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        loadingView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
        
        // Setup no items view
        view.addSubview(noItemsMessageView)
        noItemsMessageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        noItemsMessageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
        noItemsMessageView.leftAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leftAnchor, constant: 8).isActive = true
        noItemsMessageView.rightAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.rightAnchor, constant: -8).isActive = true
    }
    
    var query: String? {
        didSet {
            guard query != oldValue else { return }
            
            // Clean up existing data
            coordinator.resetIntents()
            items.removeAll()
            collectionView.reloadSections(IndexSet(integer: 0))
            
            // Setup for new search
            guard let query = query else { return }
            noItemsMessageView.subtitle = "We searched far and wide, but couldn't find anything matching \"\(query)\"."
            coordinator.run(intents: StockPhotoSearchManager.shared.getStartingIntents(for: query))
        }
    }
    
    override var numberOfColumns: CGFloat {
        didSet {
            // Set the ideal search results count to be so that we get enough to fill at least 10 rows (adjusted based on screen size)
            StockPhotoSearchManager.shared.idealSearchResultsCount = Int(numberOfColumns) * 10
        }
    }
    
    // MARK: - Collection view data source

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SearchCollectionViewController.reuseIdentifier, for: indexPath) as! StockPhotoCollectionViewCell
        cell.photo = items[indexPath.item]
        return cell
    }
    
    // MARK: - Collection view delegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        let photo = items[indexPath.item]
        
        // Add to recents!
        PersistentStockPhotoStore.recents.add(photo: photo)
        
        // Download and attach the photo!
        attach(photo: photo)
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        super.collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)
        // Check if this is at least the second last row!
        let rows = ceil(CGFloat(items.count) / numberOfColumns), row = floor(CGFloat(indexPath.item) / numberOfColumns)
        if row >= rows - 2 && !coordinator.isRunningIntents { coordinator.runNextIntents() }
    }
    
}

extension SearchCollectionViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        indexPaths.lazy.map { self.items[$0.item] }
            .filter { $0.thumbnailURL != nil }
            .forEach { ThumbnailManager.shared.prefetchThumbnail(at: $0.thumbnailURL!) }
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        indexPaths.lazy.filter { self.items.indices.contains($0.item) }.map { self.items[$0.item] }
            .filter { $0.thumbnailURL != nil }
            .forEach { ThumbnailManager.shared.cancelPrefetchOfThumbnail(at: $0.thumbnailURL!) }
    }
}

// MARK: - Search Coordinator Delegate

extension SearchCollectionViewController: SearchIntentCoordinatorDelegate {
    func add(photos: [StockPhoto]) {
        let paths = (items.count..<(items.count + photos.count)).map { IndexPath(item: $0, section: 0) }
        layout.isInitialInsertion = items.isEmpty
        items.append(contentsOf: photos)
        collectionView.insertItems(at: paths)
    }
    
    func intentStateChanged() {
        // We're still trying, no items yet!
        if coordinator.isRunningIntents && items.isEmpty {
            loadingView.startAnimating()
        } else {
            loadingView.stopAnimating()
        }
        
        // Hide no items if we still are trying or have items!
        noItemsMessageView.isHidden = coordinator.isRunningIntents || !items.isEmpty
    }
}
