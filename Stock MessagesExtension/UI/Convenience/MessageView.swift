//
//  MessageView.swift
//  Stock MessagesExtension
//
//  Created by Ayden Panhuyzen on 2019-07-20.
//  Copyright © 2019 Ayden Panhuyzen. All rights reserved.
//

import UIKit

class MessageView: UIStackView {
    private let titleLabel = UILabel(), subtitleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        titleLabel.textColor = .gray
        titleLabel.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: .systemFont(ofSize: 21, weight: .semibold))
        titleLabel.textAlignment = .center
        
        subtitleLabel.textColor = .gray
        subtitleLabel.font = .preferredFont(forTextStyle: .body)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: 300).isActive = true
        
        spacing = 6
        alignment = .center
        axis = .vertical
        
        addArrangedSubview(titleLabel)
        addArrangedSubview(subtitleLabel)
    }
    
    convenience init(title: String?, subtitle: String? = nil) {
        self.init(frame: .zero)
        defer {
            self.title = title
            self.subtitle = subtitle
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var title: String? {
        get { return titleLabel.text }
        set { titleLabel.text = newValue }
    }
    
    var subtitle: String? {
        get { return subtitleLabel.text }
        set { subtitleLabel.text = newValue }
    }
}
