//
//  UIView+PinEdges.swift
//  Stock MessagesExtension
//
//  Created by Ayden Panhuyzen on 2019-07-19.
//  Copyright © 2019 Ayden Panhuyzen. All rights reserved.
//

import UIKit

// MARK - Protocol & Conformance
protocol Pinnable {
    var leftAnchor: NSLayoutXAxisAnchor { get }
    var rightAnchor: NSLayoutXAxisAnchor { get }
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
}
extension UILayoutGuide: Pinnable {}
extension UIView: Pinnable {}

// MARK: - Methods

extension Pinnable {
    func pin(edges: UIRectEdge = .all, to view: Pinnable, constant: CGFloat = 0, priority: UILayoutPriority? = nil) {
        var constraints = [NSLayoutConstraint]()
        
        if (edges.contains(.top)) { constraints.append(topAnchor.constraint(equalTo: view.topAnchor, constant: constant)) }
        if (edges.contains(.left)) {constraints.append(leftAnchor.constraint(equalTo: view.leftAnchor, constant: constant)) }
        if (edges.contains(.bottom)) { constraints.append(bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -constant)) }
        if (edges.contains(.right)) { constraints.append(rightAnchor.constraint(equalTo: view.rightAnchor, constant: -constant)) }
        
        if let priority = priority {
            constraints.forEach { $0.priority = priority }
        }
        
        NSLayoutConstraint.activate(constraints)
    }
}

extension UIView {
    func pinToSuperview(edges: UIRectEdge = .all, constant: CGFloat = 0, priority: UILayoutPriority? = nil) {
        guard let superview = superview else { fatalError("Tried to pin superview edges on view without a superview. That's not nice!") }
        pin(edges: edges, to: superview, constant: constant, priority: priority)
    }
}
