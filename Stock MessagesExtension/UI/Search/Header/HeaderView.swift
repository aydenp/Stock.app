//
//  HeaderView.swift
//  Stock MessagesExtension
//
//  Created by Ayden Panhuyzen on 2019-07-19.
//  Copyright © 2019 Ayden Panhuyzen. All rights reserved.
//

import UIKit

class HeaderView: UIView {
    private var barsStackView: UIStackView!
    let inputBar = HeaderInputBar()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        barsStackView = UIStackView(arrangedSubviews: [inputBar])
        barsStackView.axis = .vertical
        barsStackView.alignment = .fill
        barsStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(barsStackView)
        barsStackView.pinToSuperview()
        
        let hairlineView = HairlineView()
        hairlineView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hairlineView)
        hairlineView.pinToSuperview(edges: [.left, .bottom, .right])
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
