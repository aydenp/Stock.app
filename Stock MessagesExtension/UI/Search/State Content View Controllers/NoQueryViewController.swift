//
//  NoQueryViewController.swift
//  Stock MessagesExtension
//
//  Created by Ayden Panhuyzen on 2019-07-20.
//  Copyright © 2019 Ayden Panhuyzen. All rights reserved.
//

import UIKit

class NoQueryViewController: StockPhotoCollectionViewController {
    private var noItemsMessageView: MessageView!
    private var viewHasLoaded = false
    
    enum Section: CaseIterable {
        case favourites, recents
        
        var title: String {
            switch self {
            case .favourites: return "Favourites"
            case .recents: return "Recents"
            }
        }
        
        func getItems() -> [StockPhoto] {
            switch self {
            case .favourites: return PersistentStockPhotoStore.favourites.photos
            case .recents: return PersistentStockPhotoStore.recents.photos.reversed()
            }
        }
    }
    private var sections = [Section](), items = [Section: [StockPhoto]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        layout.headerReferenceSize = StockPhotoCollectionViewSectionHeader.referenceSize
        
        noItemsMessageView = MessageView(title: "Find an image", subtitle: "Start typing your query to find relevant stock images.")
        view.addSubview(noItemsMessageView)
        noItemsMessageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        noItemsMessageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
        noItemsMessageView.leftAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leftAnchor, constant: 8).isActive = true
        noItemsMessageView.rightAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.rightAnchor, constant: -8).isActive = true
        
        reloadSections()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadSections), name: PersistentStockPhotoStore.didChangeNotification, object: nil)
        
        viewHasLoaded = true
    }
    
    private var numberOfColumnsLastSizeChange: CGFloat = 0
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { (_) in
            guard self.viewHasLoaded, self.numberOfColumns != self.numberOfColumnsLastSizeChange, let index = self.sections.firstIndex(of: .recents) else { return }
            self.numberOfColumnsLastSizeChange = self.numberOfColumns
            self.collectionView.reloadSections(IndexSet(integer: index))
        }
    }
    
    @objc func reloadSections() {
        sections.removeAll()
        items.removeAll()
        for section in Section.allCases {
            let items = section.getItems()
            if !items.isEmpty {
                sections.append(section)
                self.items[section] = items
            }
        }
        if viewHasLoaded { collectionView.reloadData() }
        noItemsMessageView.isHidden = !sections.isEmpty
    }

    // MARK: - Collection view data source
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = sections[section]
        switch sectionInfo {
        case .recents:
            let itemLimit = CGFloat(PersistentStockPhotoStore.recents.limit!)
            let effectiveNumberOfColumns = max(1, numberOfColumns)
            let maxRows = Int(max(1, min(floor(itemLimit / effectiveNumberOfColumns), 3)))
            return min(items[sectionInfo]?.count ?? 0, maxRows * Int(effectiveNumberOfColumns))
        default: return items[sectionInfo]?.count ?? 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SearchCollectionViewController.reuseIdentifier, for: indexPath) as! StockPhotoCollectionViewCell
        cell.photo = items[sections[indexPath.section]]?[indexPath.item]
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else { fatalError("I only know how to provide headers!") }
        let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NoQueryViewController.titledHeaderReuseIdentifier, for: indexPath) as! StockPhotoCollectionViewSectionHeader
        cell.title = sections[indexPath.section].title
        return cell
    }
    
    // MARK: - Collection view delegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        guard let photo = items[sections[indexPath.section]]?[indexPath.item] else { return }
        attach(photo: photo)
    }
    
}
