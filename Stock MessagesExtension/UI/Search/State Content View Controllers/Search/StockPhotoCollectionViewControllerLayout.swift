//
//  SearchCollectionViewControllerLayout.swift
//  Stock MessagesExtension
//
//  Created by Ayden Panhuyzen on 2019-07-20.
//  Copyright © 2019 Ayden Panhuyzen. All rights reserved.
//

import UIKit

class StockPhotoCollectionViewControllerLayout: UICollectionViewFlowLayout {
    private var insertingIndexPaths = Set<IndexPath>()
    var isInitialInsertion = true
    
    override init() {
        super.init()
        minimumInteritemSpacing = 1
        minimumLineSpacing = 1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)
        insertingIndexPaths = Set(updateItems.lazy.filter { $0.indexPathAfterUpdate != nil && $0.updateAction == .insert }.map { $0.indexPathAfterUpdate! })
    }
    
    override func finalizeCollectionViewUpdates() {
        super.finalizeCollectionViewUpdates()
        insertingIndexPaths.removeAll()
    }
    
    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)
        
        if !isInitialInsertion && insertingIndexPaths.contains(itemIndexPath) {
            attributes?.alpha = 0
            attributes?.transform = CGAffineTransform.identity.scaledBy(x: 0.8, y: 0.8)
        }
        
        return attributes
    }
}
