//
//  HairlineView.swift
//  Stock MessagesExtension
//
//  Created by Ayden Panhuyzen on 2019-07-19.
//  Copyright © 2019 Ayden Panhuyzen. All rights reserved.
//

import UIKit

class HairlineView: UIView {
    private var heightConstraint: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        heightConstraint = heightAnchor.constraint(equalToConstant: 1)
        heightConstraint.isActive = true
        
        backgroundColor = UIColor(named: "defaultHairline")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        // Show the smallest hairline possible on our screen, by dividing 1 virtual 'pixel' by the screen's scale (1/2 on retina, 1/3 on retina HD, etc)
        heightConstraint.constant = 1 / (window?.screen.scale ?? 1)
    }
}
