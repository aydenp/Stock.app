//
//  ExpansionEnforcingNavigationController.swift
//  Stock MessagesExtension
//
//  Created by Ayden Panhuyzen on 2019-07-21.
//  Copyright © 2019 Ayden Panhuyzen. All rights reserved.
//

import UIKit

class ExpansionEnforcingNavigationController: UINavigationController {
    private var presentationStyleChangeToken: UUID?, wasExpandedBeforeAppearance = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationBar.isTranslucent = false
        
        if #available(iOS 13.0, *) {
            // Don't do anything special to the navbar, Apple got rid of the inconsistently coloured hairline
            // Just make it match the Apple header
            navigationBar.barTintColor = UIColor(named: "background")
        } else {
            navigationBar.shadowImage = UIImage()

            // Setup new hairline with more consistent colour with Messages-provided one
            let navbarBottomHairlineView = HairlineView()
            navbarBottomHairlineView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(navbarBottomHairlineView)
            navbarBottomHairlineView.pin(edges: .bottom, to: navigationBar)
            navbarBottomHairlineView.pinToSuperview(edges: [.left, .right])
        }
        
        presentationStyleChangeToken = PresentationStyleManager.shared.onWillChange(to: .compact) { self.dismiss(animated: true, completion: nil) }
    }
    
    deinit {
        guard let token = presentationStyleChangeToken else { return }
        PresentationStyleManager.shared.deregisterChangeNotifications(token: token)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        wasExpandedBeforeAppearance = PresentationStyleManager.shared.style != .expanded
        PresentationStyleManager.shared.style = .expanded
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if wasExpandedBeforeAppearance { PresentationStyleManager.shared.style = .compact }
    }
}
