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
        navigationBar.shadowImage = UIImage()
        
        let hairlineView = HairlineView()
        hairlineView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hairlineView)
        hairlineView.pinToSuperview(edges: [.left, .right])
        hairlineView.pin(edges: .bottom, to: navigationBar)
        
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
