//
//  StockPhotoCollectionViewSectionHeader.swift
//  Stock MessagesExtension
//
//  Created by Ayden Panhuyzen on 2019-07-21.
//  Copyright © 2019 Ayden Panhuyzen. All rights reserved.
//

import UIKit

class StockPhotoCollectionViewSectionHeader: UICollectionReusableView {
    private let label = UILabel()
    static let referenceSize = CGSize(width: 0, height: 50)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        addSubview(label)
        label.pinToSuperview(edges: [.left, .right], constant: 16)
        label.pinToSuperview(edges: [.top, .bottom], constant: 4)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        title = nil
    }
    
    var title: String? {
        didSet { label.text = title }
    }
}
